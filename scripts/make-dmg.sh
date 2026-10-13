#!/usr/bin/env bash
# Builds an ad-hoc signed SideClick.app and packs it into a drag-to-Applications DMG,
# in $XMF_BUILD_ROOT (default ~/Library/Caches/SideClick).
# Ad-hoc signed and not notarized: Gatekeeper still blocks the first launch (see README).
set -euo pipefail
cd "$(dirname "$0")/.."
BUILD_ROOT="${XMF_BUILD_ROOT:-$HOME/Library/Caches/SideClick}"
APP="$BUILD_ROOT/SideClick.app"

SIGN_IDENTITY=- scripts/build-app.sh release

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
