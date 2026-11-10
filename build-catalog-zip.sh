#!/bin/sh
# Makes the upload for Patchmanager's web catalog (coderus.openrepos.net/pm2):
# build-catalog/ada-home-sailfish-<version>.zip with unified_diff.patch at the top
# level (no subfolders, no patch.json: the catalog writes that from the web form).
# Packages the patch as it is in patch/ada-home-sailfish/ (run build-patch.sh first).
set -eu
cd "$(dirname "$0")"

NAME=ada-home-sailfish
VERSION=$(sed -n 's/^ *"version": *"\([^"]*\)".*/\1/p' patch/$NAME/patch.json)
[ -n "$VERSION" ] || { echo "no version in patch/$NAME/patch.json" >&2; exit 1; }

OUT=build-catalog
rm -rf "$OUT" && mkdir -p "$OUT"
# Python's zipfile (no zip tool needed); the files go in without any folder
python3 -I -c '
import os, sys, zipfile
with zipfile.ZipFile(sys.argv[1], "w", zipfile.ZIP_DEFLATED) as z:
    for f in sys.argv[2:]:
        z.write(f, os.path.basename(f))
' "$OUT/$NAME-$VERSION.zip" patch/$NAME/unified_diff.patch
echo "built: $(pwd)/$OUT/$NAME-$VERSION.zip"
python3 -I -m zipfile -l "$OUT/$NAME-$VERSION.zip"
