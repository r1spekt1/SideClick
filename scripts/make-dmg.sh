#!/usr/bin/env bash
# Builds SideClick.app signed with the release certificate and packs it into a
# drag-to-Applications DMG, in $XMF_BUILD_ROOT (default ~/Library/Caches/SideClick).
# Every release must use the same certificate: macOS ties the granted permissions to it,
# so users keep them across updates. Not notarized: Gatekeeper still blocks the first launch (see README).
set -euo pipefail
cd "$(dirname "$0")/.."
BUILD_ROOT="${XMF_BUILD_ROOT:-$HOME/Library/Caches/SideClick}"
APP="$BUILD_ROOT/SideClick.app"
IDENTITY="${SIGN_IDENTITY:-SideClick}"

# build-app.sh falls back to an ad-hoc signature; a release must not.
if ! grep -qF "\"$IDENTITY\"" <<<"$(security find-identity -p codesigning)"; then
    echo "error: signing identity '$IDENTITY' not found (see README, Release signing)." >&2
    exit 1
fi

SIGN_IDENTITY="$IDENTITY" scripts/build-app.sh release

VERSION="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$APP/Contents/Info.plist")"
DMG="$BUILD_ROOT/SideClick-$VERSION.dmg"
STAGING="$BUILD_ROOT/dmg-staging"

rm -rf "$STAGING" "$DMG"
mkdir -p "$STAGING"
ditto "$APP" "$STAGING/SideClick.app"
ln -s /Applications "$STAGING/Applications"

hdiutil create -volname "SideClick" -srcfolder "$STAGING" -fs HFS+ -format UDZO -ov "$DMG" >/dev/null
rm -rf "$STAGING"
hdiutil verify "$DMG" >/dev/null
echo "Built $DMG"
