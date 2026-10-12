#!/usr/bin/env bash
# Builds XiaomiMouseFix.app outside the (iCloud-synced) repo, in
# $XMF_BUILD_ROOT (default ~/Library/Caches/XiaomiMouseFix), and signs it with a
# stable identity when available, so the Accessibility permission survives rebuilds.
set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
CONFIG="${1:-release}"
IDENTITY="${SIGN_IDENTITY:-XiaomiMouseFix Dev}"
BUILD_ROOT="${XMF_BUILD_ROOT:-$HOME/Library/Caches/XiaomiMouseFix}"
APP="$BUILD_ROOT/XiaomiMouseFix.app"

swift build -c "$CONFIG" --product XiaomiMouseFix --scratch-path "$BUILD_ROOT/.build"
BIN_DIR="$(swift build -c "$CONFIG" --show-bin-path --scratch-path "$BUILD_ROOT/.build")"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS"
cp "$BIN_DIR/XiaomiMouseFix" "$APP/Contents/MacOS/XiaomiMouseFix"
cp Resources/Info.plist "$APP/Contents/Info.plist"

if security find-identity -p codesigning | grep -q "\"$IDENTITY\""; then
    codesign --force --sign "$IDENTITY" "$APP"
else
    echo "warning: signing identity '$IDENTITY' not found; using ad-hoc signature." >&2
    echo "         Accessibility must be re-granted after every build (see README)." >&2
    codesign --force --sign - "$APP"
fi
echo "Built $APP"
