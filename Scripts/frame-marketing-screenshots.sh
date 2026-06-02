#!/usr/bin/env bash
# Wrap raw simulator screenshots in iPhone device bezels (ImageMagick + frameit frames).
#
# Usage:
#   ./Scripts/frame-marketing-screenshots.sh
#   FRAME_COLOR="Deep Blue" ./Scripts/frame-marketing-screenshots.sh
#   FRAME_DEVICE="iPhone 17 Pro Max" ./Scripts/frame-marketing-screenshots.sh
#
# Requires: brew install imagemagick
# Output: marketing-screenshots/framed/*-framed.png

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
RAW_DIR="${RAW_DIR:-$ROOT/marketing-screenshots/raw}"
FRAMED_DIR="${FRAMED_DIR:-$ROOT/marketing-screenshots/framed}"
FRAMES_DIR="${FRAMES_DIR:-$HOME/.fastlane/frameit/latest}"
FRAME_DEVICE="${FRAME_DEVICE:-iPhone 17 Pro}"
FRAME_COLOR="${FRAME_COLOR:-Deep Blue}"
# Match frameit for iPhone 14+ display corners; set to 0 to disable (e.g. iPad).
ROUND_RADIUS="${ROUND_RADIUS:-100}"

if ! command -v magick >/dev/null 2>&1; then
  echo "ImageMagick is required. Install with: brew install imagemagick" >&2
  exit 1
fi

if [[ ! -d "$RAW_DIR" ]] || [[ -z "$(ls -A "$RAW_DIR"/*.png 2>/dev/null)" ]]; then
  echo "No raw screenshots in $RAW_DIR. Run ./Scripts/capture-marketing-screenshots.sh first." >&2
  exit 1
fi

if [[ ! -d "$FRAMES_DIR" ]]; then
  echo "→ Downloading device frames…"
  fastlane frameit download_frames
fi

OFFSETS_JSON="$FRAMES_DIR/offsets.json"
if [[ ! -f "$OFFSETS_JSON" ]]; then
  echo "Missing offsets at $OFFSETS_JSON" >&2
  exit 1
fi

read -r OFFSET_X OFFSET_Y SCREEN_WIDTH <<<"$(python3 -c "
import json, sys
device, path = sys.argv[1], sys.argv[2]
data = json.load(open(path))['portrait'][device]
x, y = data['offset'].strip('+').split('+')
print(x, y, data['width'])
" "$FRAME_DEVICE" "$OFFSETS_JSON")"

FRAME_FILE="$FRAMES_DIR/Apple ${FRAME_DEVICE} ${FRAME_COLOR}.png"
if [[ ! -f "$FRAME_FILE" ]]; then
  FRAME_FILE="$(ls "$FRAMES_DIR"/"Apple ${FRAME_DEVICE}"*.png 2>/dev/null | head -1)"
fi
if [[ ! -f "$FRAME_FILE" ]]; then
  echo "No frame PNG found for $FRAME_DEVICE ($FRAME_COLOR) in $FRAMES_DIR" >&2
  exit 1
fi

mkdir -p "$FRAMED_DIR"
WORK_DIR="$(mktemp -d "${TMPDIR:-/tmp}/dartbuddy-frame.XXXXXX")"
trap 'rm -rf "$WORK_DIR"' EXIT

echo "→ Device: $FRAME_DEVICE ($FRAME_COLOR)"
echo "→ Frame: $(basename "$FRAME_FILE")"
echo "→ Slot: +${OFFSET_X}+${OFFSET_Y} (width ${SCREEN_WIDTH}px)"

for shot in "$RAW_DIR"/*.png; do
  base="$(basename "$shot" .png)"
  out="$FRAMED_DIR/${base}-framed.png"
  work="$WORK_DIR/prepared.png"
  echo "→ Framing ${base}..."

  read -r SHOT_W SHOT_H <<<"$(magick identify -format "%w %h" "$shot")"
  if [[ "$SHOT_W" -ne "$SCREEN_WIDTH" ]]; then
    magick "$shot" -resize "${SCREEN_WIDTH}x" "$work"
    read -r SHOT_W SHOT_H <<<"$(magick identify -format "%w %h" "$work")"
  else
    cp "$shot" "$work"
  fi

  if [[ "$ROUND_RADIUS" -gt 0 ]]; then
    # DstIn + alpha set (not CopyOpacity/-alpha off) — the latter zeroes RGB and yields a black screen.
    magick "$work" -alpha set \
      \( -size "${SHOT_W}x${SHOT_H}" xc:none \
          -draw "roundrectangle 0,0,$((SHOT_W - 1)),$((SHOT_H - 1)),${ROUND_RADIUS},${ROUND_RADIUS}" \) \
      -compose DstIn -composite "$work"
  fi

  # DstOver: screenshot under the bezel; PNG32 preserves transparency outside the device.
  magick "$FRAME_FILE" "$work" \
    -geometry "+${OFFSET_X}+${OFFSET_Y}" -compose DstOver -composite \
    PNG32:"$out"
done

echo ""
echo "Done. Framed screenshots:"
ls -1 "$FRAMED_DIR"/*-framed.png
echo ""
echo "App Store Connect: upload raw/ files only (no bezels)."
