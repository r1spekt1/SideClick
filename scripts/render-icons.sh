#!/usr/bin/env bash
# Renders Resources/Icon/*.svg into the PNGs, AppIcon.icns and the menu bar template image.
# Quick Look renders the SVGs (filters and alpha included); sips downsizes from 1024.
set -euo pipefail
cd "$(dirname "$0")/.."
SRC="Resources/Icon"
OUT="$SRC/png"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

render() { # <svg> <png out>: render one SVG at 1024 px
    qlmanage -t -s 1024 -o "$WORK" "$1" >/dev/null 2>&1
    mv "$WORK/$(basename "$1").png" "$2"
}

resize() { # <png in> <size> <png out>
    sips -z "$2" "$2" "$1" --out "$3" >/dev/null
}

mkdir -p "$OUT"
for name in AppIcon AppIcon-Small AppIcon-Dark AppIcon-Clear AppIcon-Tinted AppIcon-Background AppIcon-Foreground; do
    render "$SRC/$name.svg" "$OUT/$name-1024.png"
done

# 16 and 32 px use the simplified drawing; 64 px and up use the detailed one.
ICONSET="$WORK/AppIcon.iconset"
mkdir -p "$ICONSET"
resize "$OUT/AppIcon-Small-1024.png" 16 "$ICONSET/icon_16x16.png"
resize "$OUT/AppIcon-Small-1024.png" 32 "$ICONSET/icon_16x16@2x.png"
resize "$OUT/AppIcon-Small-1024.png" 32 "$ICONSET/icon_32x32.png"
resize "$OUT/AppIcon-1024.png" 64 "$ICONSET/icon_32x32@2x.png"
for size in 128 256 512; do
    resize "$OUT/AppIcon-1024.png" "$size" "$ICONSET/icon_${size}x${size}.png"
    resize "$OUT/AppIcon-1024.png" $((size * 2)) "$ICONSET/icon_${size}x${size}@2x.png"
done
cp "$ICONSET"/icon_*.png "$OUT/"
iconutil -c icns "$ICONSET" -o Resources/AppIcon.icns

# Menu bar template image: NSBundle picks the @2x file on Retina screens.
# Quick Look draws an SVG at its own width/height, so render a copy declared at 1024 px.
sed 's/width="18" height="18"/width="1024" height="1024"/' "$SRC/MenuBarIcon.svg" > "$WORK/MenuBarIcon.svg"
render "$WORK/MenuBarIcon.svg" "$WORK/MenuBarIcon-1024.png"
resize "$WORK/MenuBarIcon-1024.png" 18 Resources/MenuBarIcon.png
resize "$WORK/MenuBarIcon-1024.png" 36 Resources/MenuBarIcon@2x.png

echo "Rendered $OUT, Resources/AppIcon.icns and Resources/MenuBarIcon{,@2x}.png"
