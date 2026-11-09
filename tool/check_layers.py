"""Fails if a layer uses a class from a layer it must not (#621).

core and shared never use features or app; core never uses shared;
a feature never uses another feature. Run: python3 tool/check_layers.py
"""
import os, re, sys

os.chdir(os.path.join(os.path.dirname(__file__), '..', 'lib'))
files = {os.path.join(d, f)[2:]: open(os.path.join(d, f)).read()
         for d, _, fs in os.walk('.') for f in fs if f.endswith('.dart') and not f.startswith('main.')}

def layer(path):
    parts = path.split('/')
    return '/'.join(parts[:2]) if parts[0] == 'features' else parts[0]

def allowed(src, dst):
    if src == dst or src == 'app': return True
    if src == 'core': return False
    if src == 'shared': return dst == 'core'
    return dst in ('core', 'shared')  # features

defs = {}
decl = re.compile(r'^(?:abstract |sealed |final |base )*(?:class|enum|extension|mixin|typedef) ([A-Z]\w*)', re.M)
for path, src in files.items():
    for name in decl.findall(src): defs[name] = layer(path)

bad = []
for path, src in files.items():
    code = re.sub(r'//.*', '', src)
    for name, dst in defs.items():
        if not allowed(layer(path), dst) and re.search(rf'\b{name}\b', code):
            bad.append(f'{path}: uses {name} from {dst}')
print('\n'.join(sorted(bad)) or 'layers ok')
sys.exit(1 if bad else 0)
