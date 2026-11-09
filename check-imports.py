#!/usr/bin/env python3
"""Catch missing QML imports before the patch reaches the phone.

qmllint only checks syntax, and lipstick's own module (com.jolla.lipstick)
can't be loaded outside lipstick, so a missing import only shows up as
"X is not a type" when lipstick starts (Patchmanager then turns all patches
off). This check asks the phone which installed QML modules mention each
type a changed file uses (in qmldir files or plugin libraries) and reports
types for which the file imports none of those modules.

Types defined as .qml files in the file's own directory or in a directory it
imports by path ("../notifications") are skipped, as are types no module
mentions (lipstick's own C++ types). A type is also not reported when some
stock file uses it without importing any of those modules (QtQuick built-ins
like Image, whose names also appear in unrelated libraries).

Usage: check-imports.py <ssh-host> <stock-root> <file.qml>...
"""
import os
import re
import subprocess
import sys

QML_ROOT = '/usr/lib64/qt5/qml/'
TYPE_USE = re.compile(r'^\s*([A-Z][A-Za-z0-9_]*)\s*\{', re.M)
MODULE_IMPORT = re.compile(r'^\s*import\s+([A-Za-z][\w.]*)\s', re.M)
PATH_IMPORT = re.compile(r'^\s*import\s+"([^"]+)"', re.M)


def local_types(path, text):
    dirs = [os.path.dirname(path)]
    dirs += [os.path.normpath(os.path.join(os.path.dirname(path), d))
             for d in PATH_IMPORT.findall(text)]
    names = set()
    for d in dirs:
        if os.path.isdir(d):
            names |= {n[:-4] for n in os.listdir(d) if n.endswith('.qml')}
    return names


def module_name(file_path):
    rel = os.path.dirname(file_path[len(QML_ROOT):])
    # QtQuick.2 -> QtQuick, Sailfish/Silica -> Sailfish.Silica
    return '.'.join(re.sub(r'\.\d+$', '', p) for p in rel.split('/'))


def main():
    host, stock_root, files = sys.argv[1], sys.argv[2], sys.argv[3:]
    stock = []
    for dirpath, _, names in os.walk(stock_root):
        for n in names:
            if n.endswith('.qml'):
                with open(os.path.join(dirpath, n), encoding='utf-8', errors='replace') as f:
                    t = f.read()
                stock.append((set(TYPE_USE.findall(t)), set(MODULE_IMPORT.findall(t))))
    wanted = {}
    for path in files:
        with open(path, encoding='utf-8', errors='replace') as f:
            text = f.read()
        types = set(TYPE_USE.findall(text)) - local_types(path, text)
        wanted[path] = (types, set(MODULE_IMPORT.findall(text)))

    all_types = sorted(set().union(*(t for t, _ in wanted.values())) or [])
    if not all_types:
        return
    # One SSH call: for every type, list the module files that mention it
    script = ('for f in $(find %s \\( -name qmldir -o -name "*.so" \\) 2>/dev/null); do '
              'grep -o -w -a -E "%s" "$f" | sort -u | sed "s|$| $f|"; done; exit 0'
              ) % (QML_ROOT, '|'.join(all_types))
    out = subprocess.run(['ssh', '-o', 'BatchMode=yes', host, script],
                         capture_output=True, text=True, check=True).stdout
    providers = {}
    for line in out.splitlines():
        t, f = line.split(' ', 1)
        providers.setdefault(t, set()).add(module_name(f))

    problems = 0
    for path, (types, ours) in wanted.items():
        for t in sorted(types):
            mods = providers.get(t)
            other_source = any(t in used and not (mods & imps) for used, imps in stock) if mods else True
            if mods and not (mods & ours) and not other_source:
                print(f'{path}: {t} is provided by {", ".join(sorted(mods))}, '
                      f'but the file imports none of them')
                problems += 1
    sys.exit(1 if problems else 0)


if __name__ == '__main__':
    main()
