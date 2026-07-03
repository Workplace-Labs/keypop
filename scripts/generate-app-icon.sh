#!/usr/bin/env bash
# Regenerate assets/AppIcon.icns from an SVG source using stock macOS tools
# (qlmanage for rasterization, sips for resizing, iconutil for packing).
#
# Usage: ./scripts/generate-app-icon.sh [path/to/icon.svg]
#   Defaults to assets/icons/keypop-icon-orbit-tilt.svg

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"
SOURCE_SVG="${1:-${PROJECT_DIR}/assets/icons/keypop-icon-orbit-tilt.svg}"
OUT_ICNS="${PROJECT_DIR}/assets/AppIcon.icns"

if [[ ! -f "$SOURCE_SVG" ]]; then
  echo "error: source SVG not found: $SOURCE_SVG" >&2
  exit 1
fi

WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

ICONSET="${WORK_DIR}/AppIcon.iconset"
mkdir -p "$ICONSET"

echo "Rasterizing ${SOURCE_SVG} at 1024x1024..."
qlmanage -t -s 1024 -o "$WORK_DIR" "$SOURCE_SVG" >/dev/null
BASE_PNG="${WORK_DIR}/$(basename "$SOURCE_SVG").png"

if [[ ! -f "$BASE_PNG" ]]; then
  echo "error: qlmanage failed to rasterize $SOURCE_SVG" >&2
  exit 1
fi

# macOS iconset naming convention: base size + @2x retina variant.
declare -a SIZES=(16 32 128 256 512)
for size in "${SIZES[@]}"; do
  double=$((size * 2))
  sips -z "$size" "$size" "$BASE_PNG" --out "${ICONSET}/icon_${size}x${size}.png" >/dev/null
  sips -z "$double" "$double" "$BASE_PNG" --out "${ICONSET}/icon_${size}x${size}@2x.png" >/dev/null
done

iconutil -c icns "$ICONSET" -o "$OUT_ICNS"
echo "Wrote ${OUT_ICNS}"
