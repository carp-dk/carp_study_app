"""Fails if a layer uses a class from a layer it must not (#621).

core and shared never use features or app; core never uses shared;
a feature never uses another feature, nor `appViewModel` (app's view models).
ponytail: lexical - sees class names only, not functions/getters. The analyzer
takes over once files are imports instead of parts (#620).
Run: python3 tool/check_layers.py
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
    if layer(path) != 'app' and re.search(r'\bappViewModel\b', code):
        bad.append(f'{path}: uses appViewModel from app')
    if layer(path) in ('core', 'shared') and re.search(r'\bbloc\b', code):
        bad.append(f'{path}: uses bloc from app')
print('\n'.join(sorted(bad)) or 'layers ok')
sys.exit(1 if bad else 0)
