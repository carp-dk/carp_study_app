"""Fails if a file imports from a layer it must not (#621).

core and shared never import features or app; core never imports shared;
a feature never imports another feature. main.dart (the global `bloc`) counts as app.
Run: python3 tool/check_layers.py
"""
import os, re, sys

os.chdir(os.path.join(os.path.dirname(__file__), '..', 'lib'))

def layer(path):
    parts = path.split('/')
    return '/'.join(parts[:2]) if parts[0] == 'features' else 'app' if path == 'main.dart' else parts[0]

def allowed(src, dst):
    if src == dst or src == 'app': return True
    if src == 'core': return False
    if src == 'shared': return dst == 'core'
    return dst in ('core', 'shared')  # features

bad = []
for d, _, fs in os.walk('.'):
    for f in fs:
        if not f.endswith('.dart') or f.endswith('.g.dart'): continue
        path = os.path.join(d, f)[2:]
        for dst in re.findall(r"^import 'package:carp_study_app/([\w/]+\.dart)'", open(path).read(), re.M):
            # ponytail: features still reach the global `bloc` in main.dart; drop once injected (#622).
            if dst == 'main.dart' and layer(path).startswith('features/'): continue
            if not allowed(layer(path), layer(dst)):
                bad.append(f'{path}: imports {dst}')
print('\n'.join(sorted(bad)) or 'layers ok')
sys.exit(1 if bad else 0)
