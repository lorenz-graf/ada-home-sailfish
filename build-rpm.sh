#!/bin/sh
# Packages the patch in patch/ada-home-sailfish/ (made by build-patch.sh) as
# build/ada-home-sailfish-<version>-<release>.noarch.rpm
# The version comes from patch.json (VERSION= in build-patch.sh), the release from
# rpm/ada-home-sailfish.spec.
# Needs rpmbuild (Arch: pacman -S rpm-tools). Sailfish has rpm 4.16, so the package is
# written in rpm v4 format with a gzip payload (rpm 6 defaults to v6 + zstd).
set -eu
cd "$(dirname "$0")"

NAME=ada-home-sailfish
VERSION=$(sed -n 's/^ *"version": *"\([^"]*\)".*/\1/p' patch/$NAME/patch.json)
[ -n "$VERSION" ] || { echo "no version in patch/$NAME/patch.json" >&2; exit 1; }

TOP=$(pwd)/build
rm -rf "$TOP" && mkdir -p "$TOP/SOURCES"
cp patch/$NAME/patch.json patch/$NAME/unified_diff.patch LICENSE "$TOP/SOURCES/"

rpmbuild -bb --quiet \
    --define "_topdir $TOP" \
    --define "ah_version $VERSION" \
    --define "_binary_payload w9.gzdio" \
    --define "_rpmformat 4" \
    --define "_prefix /usr" --define "_datadir /usr/share" \
    rpm/$NAME.spec
mv "$TOP"/RPMS/noarch/*.rpm "$TOP/"
echo "built: $(ls "$TOP"/*.rpm)"
