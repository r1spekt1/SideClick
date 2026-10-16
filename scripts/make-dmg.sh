#!/usr/bin/env bash
# Builds SideClick.app signed with the release certificate and packs it into a
# drag-to-Applications DMG, in $XMF_BUILD_ROOT (default ~/Library/Caches/SideClick).
# Every release must use the same certificate: macOS ties the granted permissions to it,
# so users keep them across updates. Not notarized: Gatekeeper still blocks the first launch (see README).
set -euo pipefail
cd "$(dirname "$0")/.."
BUILD_ROOT="${XMF_BUILD_ROOT:-$HOME/Library/Caches/SideClick}"
APP="$BUILD_ROOT/SideClick.app"

# SHA-1 of the release certificate (security find-identity -p codesigning). Pinned rather than
# the name: a recreated `SideClick` certificate would pass a name check and drop every user's
# permissions, and two with the same name make codesign fail as ambiguous. Not secret: it is in
# every shipped app's designated requirement.
RELEASE_CERT_SHA1=""
IDENTITY="${SIGN_IDENTITY:-$RELEASE_CERT_SHA1}"

if [[ -z "$IDENTITY" ]]; then
    echo "error: RELEASE_CERT_SHA1 is not set in $0 (see README, Release signing)." >&2
    exit 1
fi
# build-app.sh falls back to an ad-hoc signature; a release must not.
# A SHA-1 is matched in upper case, as find-identity prints it; a name only in quotes, so
# "SideClick" doesn't match "SideClick Dev".
if [[ "$IDENTITY" =~ ^[0-9A-Fa-f]{40}$ ]]; then PATTERN="$(tr a-f A-F <<<"$IDENTITY")"; else PATTERN="\"$IDENTITY\""; fi
if ! grep -qF "$PATTERN" <<<"$(security find-identity -p codesigning)"; then
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
