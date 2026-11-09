#!/usr/bin/env python3
"""Compile our own QML files on the phone before the patch is installed.

Catches QML compile errors that qmllint and check-imports.py miss, e.g.
"Cannot override FINAL property" or an unknown property name. Lipstick's
internal module (com.jolla.lipstick) only exists inside lipstick, so it is
replaced by an empty stub; "is not a type" / "not installed" errors are left
to check-imports.py and ignored here.

Copies the work tree to ~/ada-qmlcheck on the phone (removed afterwards),
creates each file with Qt.createComponent in qmlscene (offscreen) and
reports the component errors.

Usage: check-compile.py <ssh-host> <work-root> <file.qml>...
"""
import os
import subprocess
import sys
import tarfile
import io

REMOTE = 'ada-qmlcheck'
LIPSTICK = 'usr/share/lipstick-jolla-home-qt5'
IGNORED = ('is not a type', 'is not installed', 'Type ', 'unavailable')


def main():
    host, work_root, files = sys.argv[1], sys.argv[2], sys.argv[3:]
    tree = os.path.join(work_root, LIPSTICK)
    rels = [os.path.relpath(f, tree) for f in files]

    # Pack the lipstick tree plus a stub com.jolla.lipstick module
    buf = io.BytesIO()
    with tarfile.open(fileobj=buf, mode='w:gz') as tar:
        tar.add(tree, arcname='tree')
        for name, data in (
                ('stubs/com/jolla/lipstick/qmldir',
                 b'module com.jolla.lipstick\nAdaStub 0.1 AdaStub.qml\n'),
                ('stubs/com/jolla/lipstick/AdaStub.qml', b'import QtQuick 2.0\nQtObject {}\n')):
            info = tarfile.TarInfo(name)
            info.size = len(data)
            tar.addfile(info, io.BytesIO(data))
        # One harness per file (qmlscene takes the last argument as its file)
        for n, rel in enumerate(rels):
            harness = ('import QtQuick 2.6\n'
                       'Item {\n'
                       '    Timer { interval: 300; running: true; onTriggered: Qt.quit() }\n'
                       '    Component.onCompleted: {\n'
                       '        var c = Qt.createComponent(Qt.resolvedUrl("tree/%s"))\n'
                       '        console.log("ADA-RESULT", c.status === Component.Error ? c.errorString() : "OK")\n'
                       '    }\n'
                       '}\n' % rel).encode()
            info = tarfile.TarInfo('harness%d.qml' % n)
            info.size = len(harness)
            tar.addfile(info, io.BytesIO(harness))

    script = (
        'rm -rf ~/{r} && mkdir ~/{r} && cd ~/{r} && tar xzf - && '
        'n=0; for f in {files}; do echo "== $f"; '
        'QT_LOGGING_TO_CONSOLE=1 QT_QPA_PLATFORM=minimal QML2_IMPORT_PATH=$PWD/stubs '
        'qmlscene harness$n.qml 2>&1 | grep -A20 ADA-RESULT; n=$((n+1)); done; '
        'cd ~ && rm -rf ~/{r}'
    ).format(r=REMOTE, files=' '.join(rels))
    out = subprocess.run(['ssh', '-o', 'BatchMode=yes', host, script], input=buf.getvalue(),
                         capture_output=True, check=True).stdout.decode(errors='replace')

    problems = 0
    current = None
    for line in out.splitlines():
        if line.startswith('== '):
            current = line[3:]
            continue
        if 'ADA-RESULT' in line and line.rstrip().endswith('OK'):
            continue
        text = line.split('ADA-RESULT', 1)[-1].strip()
        if not text or any(s in text for s in IGNORED):
            continue
        print(f'{current}: {text}')
        problems += 1
    sys.exit(1 if problems else 0)


if __name__ == '__main__':
    main()
