#!/usr/bin/env bash
# Renders Resources/Icon/*.svg into the PNGs, AppIcon.icns and the menu bar template image.
# scripts/render-svg.swift draws each size straight from the vector with WebKit, keeping
# transparency (Quick Look thumbnails would flatten it onto white).
set -euo pipefail
cd "$(dirname "$0")/.."
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Applications/Xcode.app/Contents/Developer}"
SRC="Resources/Icon"
OUT="$SRC/png"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

swiftc -O scripts/render-svg.swift -o "$WORK/render-svg"
render() { # <svg> <png out> <size>
    "$WORK/render-svg" "$1" "$2" "$3"
}

mkdir -p "$OUT"
for name in AppIcon AppIcon-Small AppIcon-Dark AppIcon-Clear AppIcon-Tinted AppIcon-Background AppIcon-Foreground; do
    render "$SRC/$name.svg" "$OUT/$name-1024.png" 1024
done

# 16 and 32 px use the simplified drawing; 64 px and up use the detailed one.
ICONSET="$WORK/AppIcon.iconset"
mkdir -p "$ICONSET"
render "$SRC/AppIcon-Small.svg" "$ICONSET/icon_16x16.png" 16
render "$SRC/AppIcon-Small.svg" "$ICONSET/icon_16x16@2x.png" 32
render "$SRC/AppIcon-Small.svg" "$ICONSET/icon_32x32.png" 32
render "$SRC/AppIcon.svg" "$ICONSET/icon_32x32@2x.png" 64
for size in 128 256 512; do
    render "$SRC/AppIcon.svg" "$ICONSET/icon_${size}x${size}.png" "$size"
    render "$SRC/AppIcon.svg" "$ICONSET/icon_${size}x${size}@2x.png" $((size * 2))
done
cp "$ICONSET"/icon_*.png "$OUT/"
iconutil -c icns "$ICONSET" -o Resources/AppIcon.icns

# Menu bar template image: NSBundle picks the @2x file on Retina screens.
render "$SRC/MenuBarIcon.svg" Resources/MenuBarIcon.png 18
render "$SRC/MenuBarIcon.svg" Resources/MenuBarIcon@2x.png 36

echo "Rendered $OUT, Resources/AppIcon.icns and Resources/MenuBarIcon{,@2x}.png"
