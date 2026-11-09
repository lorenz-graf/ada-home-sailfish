#!/bin/sh
# Build the Patchmanager patch from the difference between stock/ and work/.
#   stock/ = unmodified files from the phone (read-only, not in git: proprietary)
#   work/  = the same tree with our changes (not in git)
# Output: patch/ada-home-sailfish/{patch.json,unified_diff.patch} (in git)
# Recreate work/ from it: cp -a stock work && patch -p1 -d work < patch/ada-home-sailfish/unified_diff.patch
set -eu
cd "$(dirname "$0")"

NAME=ada-home-sailfish
VERSION=0.2.0
OUT=patch/$NAME

rm -rf "$OUT"
mkdir -p "$OUT"

# Lint every changed or new QML file first
changed=$(diff -rqN stock work | awk '{print $4}' | grep '\.qml$' || true)
if [ -z "$changed" ]; then
    echo "No changes between stock/ and work/" >&2
    exit 1
fi
qmllint-qt5 $changed

# Missing imports only fail inside lipstick ("X is not a type"), so check
# them against the modules installed on the phone (needs SSH)
PHONE=${PHONE:-defaultuser@phone}
./check-imports.py "$PHONE" stock $changed

# a/ and b/ prefixes, no timestamps, so `patch -p1 -d /` applies it
diff -ruN stock work \
    | sed -e 's#^--- stock/[^\t]*\t1970-01-01.*#--- /dev/null#' \
          -e 's#^--- stock/\([^\t]*\).*#--- a/\1#' \
          -e 's#^+++ work/\([^\t]*\).*#+++ b/\1#' \
          -e 's#^diff -ruN stock/\([^ ]*\) work/.*#diff -ruN a/\1 b/\1#' \
    > "$OUT/unified_diff.patch" || true

cat > "$OUT/patch.json" <<EOF
{
    "name": "$NAME",
    "display_name": "Ada Home",
    "description": "Minimal text homescreen: big clock, apps as text and swipe apps on Home, notifications in the Top menu, weather, calendar and running apps on the second page.",
    "category": "homescreen",
    "author": "ada",
    "version": "$VERSION",
    "compatible": ["5.2.0.22"]
}
EOF

echo "Built $OUT:"
grep '^+++ ' "$OUT/unified_diff.patch"
