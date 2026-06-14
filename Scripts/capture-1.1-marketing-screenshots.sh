#!/usr/bin/env bash
# Capture App Store marketing screenshots for Dart Buddy 1.1 Party Pack modes.
#
# Usage:
#   ./Scripts/capture-1.1-marketing-screenshots.sh
#   APPEARANCE=light ./Scripts/capture-1.1-marketing-screenshots.sh
#   SIM_NAME="iPhone 17 Pro Max" ./Scripts/capture-1.1-marketing-screenshots.sh
#   ORIENTATIONS=portrait ./Scripts/capture-1.1-marketing-screenshots.sh
#
# Output: marketing-screenshots/1.1/raw/*.png (resized for App Store Connect by default)
# Uses `-enable_lean_product_surface` so captures match the shipping 1.1 allowlist.
#
# Then run: FRAME_INPUT_DIR=marketing-screenshots/1.1/raw FRAME_OUTPUT_DIR=marketing-screenshots/1.1/framed ./Scripts/frame-marketing-screenshots.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=app-store-screenshot-size.sh
source "$SCRIPT_DIR/app-store-screenshot-size.sh"
# shellcheck source=simulator-orientation.sh
source "$SCRIPT_DIR/simulator-orientation.sh"
SIM_NAME="${SIM_NAME:-iPhone 17 Pro Max}"
APPEARANCE="${APPEARANCE:-dark}"
ORIENTATIONS="${ORIENTATIONS:-portrait landscape}"
OUT_DIR="${OUT_DIR:-$ROOT/marketing-screenshots/1.1/raw}"
BUNDLE_ID="com.jacobrozell.DartBuddy"
SCHEME="DartBuddy"
PROJECT="$ROOT/DartBuddy.xcodeproj"
DERIVED_DATA="${DERIVED_DATA:-$ROOT/.derivedData/marketing-screenshots-1.1}"
LAUNCH_DELAY="${LAUNCH_DELAY:-5}"
ORIENTATION_SETTLE_SEC="${ORIENTATION_SETTLE_SEC:-1.5}"
APP_STORE_RESIZE="${APP_STORE_RESIZE:-1}"

COMMON_ARGS=(
  -enable_lean_product_surface
  -ui_test_reset
  -ui_test_disable_feedback
  -disable_firebase_analytics
)

slugify() {
  echo "$1" | tr ' ' '-' | tr -d '()' | tr '[:upper:]' '[:lower:]'
}

echo "→ Project: $ROOT"
echo "→ Simulator: $SIM_NAME ($APPEARANCE)"
echo "→ Product surface: Party Pack 1.1 (lean)"
echo "→ Orientations: $ORIENTATIONS"
echo "→ Output: $OUT_DIR"

if [[ ! -d "$PROJECT" ]]; then
  echo "→ Generating Xcode project…"
  (cd "$ROOT" && xcodegen generate)
fi

mkdir -p "$OUT_DIR"
CAPTURE_TMP="${TMPDIR:-/tmp}/dartbuddy-1.1-marketing-capture-$$"
mkdir -p "$CAPTURE_TMP"
trap 'rm -rf "$CAPTURE_TMP"' EXIT

SIM_UDID="$(xcrun simctl list devices available -j | python3 -c "
import json, sys
name = sys.argv[1]
data = json.load(sys.stdin)
for runtime, devices in data.get('devices', {}).items():
    if 'iOS' not in runtime:
        continue
    for d in devices:
        if d.get('name') == name and d.get('isAvailable', True):
            print(d['udid'])
            sys.exit(0)
sys.exit(1)
" "$SIM_NAME")"
export SIM_UDID

echo "→ Booting $SIM_NAME ($SIM_UDID)…"
xcrun simctl boot "$SIM_UDID" 2>/dev/null || true
xcrun simctl bootstatus "$SIM_UDID" -b
open -a Simulator --args -CurrentDeviceUDID "$SIM_UDID"
xcrun simctl ui "$SIM_UDID" appearance "$APPEARANCE"
xcrun simctl ui "$SIM_UDID" content_size large

echo "→ Building app…"
xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination "platform=iOS Simulator,id=$SIM_UDID" \
  -derivedDataPath "$DERIVED_DATA" \
  build \
  | xcbeautify --quieter 2>/dev/null || xcodebuild \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Debug \
  -destination "platform=iOS Simulator,id=$SIM_UDID" \
  -derivedDataPath "$DERIVED_DATA" \
  build

APP_PATH="$DERIVED_DATA/Build/Products/Debug-iphonesimulator/DartBuddy.app"
if [[ ! -d "$APP_PATH" ]]; then
  echo "Build succeeded but app not found at $APP_PATH" >&2
  exit 1
fi

echo "→ Installing app…"
xcrun simctl install "$SIM_UDID" "$APP_PATH"

app_store_resize_png_for_orientation() {
  local path="$1"
  local orientation="$2"
  local width="$APP_STORE_WIDTH"
  local height="$APP_STORE_HEIGHT"

  if [[ "$orientation" == "landscape" ]]; then
    width="$APP_STORE_HEIGHT"
    height="$APP_STORE_WIDTH"
  fi

  verify_screenshot_orientation "$path" "$orientation"

  local w h
  w="$(magick identify -format "%w" "$path")"
  h="$(magick identify -format "%h" "$path")"
  if [[ "$w" == "$width" && "$h" == "$height" ]]; then
    return 0
  fi
  magick "$path" -filter Lanczos -resize "${width}x${height}!" "$path"
}

capture() {
  local slug="$1"
  shift
  local -a args=("$@")

  for orientation in $ORIENTATIONS; do
    local suffix=""
    if [[ "$orientation" == "landscape" ]]; then
      suffix="-landscape"
    fi

    local filename="${DEVICE_SLUG}-${slug}-${APPEARANCE}${suffix}.png"
    capture_frame "$filename" "$orientation" "${args[@]}"
  done
}

capture_frame() {
  local filename="$1"
  local orientation="$2"
  shift 2
  local -a args=("$@")

  echo "→ Capturing ${filename} (${orientation})..."
  xcrun simctl terminate "$SIM_UDID" "$BUNDLE_ID" 2>/dev/null || true
  sleep 0.5
  xcrun simctl launch "$SIM_UDID" "$BUNDLE_ID" \
    "${args[@]}" -snapshot_orientation "$orientation" >/dev/null
  sleep "$LAUNCH_DELAY"
  sleep "$ORIENTATION_SETTLE_SEC"
  local capture_path="$CAPTURE_TMP/$filename"
  xcrun simctl io "$SIM_UDID" screenshot "$capture_path"
  cp "$capture_path" "$OUT_DIR/$filename"
  normalize_screenshot_for_orientation "$OUT_DIR/$filename" "$orientation"
  verify_screenshot_orientation "$OUT_DIR/$filename" "$orientation"
  if [[ "$APP_STORE_RESIZE" == "1" ]]; then
    app_store_resize_png_for_orientation "$OUT_DIR/$filename" "$orientation"
  fi
}

DEVICE_SLUG="$(slugify "$SIM_NAME")"

# 1.1 Party Pack — in-match captures (App Store priority)
capture "11-baseball-match" \
  "${COMMON_ARGS[@]}" -snapshot_match_baseball

capture "12-killer-match" \
  "${COMMON_ARGS[@]}" -snapshot_match_killer

capture "13-shanghai-match" \
  "${COMMON_ARGS[@]}" -snapshot_match_shanghai

capture "14-around-the-clock-match" \
  "${COMMON_ARGS[@]}" -snapshot_match_aroundTheClock

# Play setup with demo roster (shows lean Play home; no Modes tab)
capture "15-play-setup" \
  "${COMMON_ARGS[@]}" -seed_demo -snapshot_play_setup

# Activity history includes completed Baseball from demo seed
capture "16-activity-history" \
  "${COMMON_ARGS[@]}" -seed_demo -snapshot_tab activity

echo ""
first_png="$(ls -1 "$OUT_DIR"/*.png | head -1)"
echo "Done. 1.1 marketing screenshots ($(magick identify -format '%wx%h' "$first_png")):"
ls -1 "$OUT_DIR"/*.png
if [[ "$APP_STORE_RESIZE" == "1" ]]; then
  echo "App Store export (portrait): ${APP_STORE_WIDTH}×${APP_STORE_HEIGHT}"
  echo "App Store export (landscape): ${APP_STORE_HEIGHT}×${APP_STORE_WIDTH}"
fi
echo ""
echo "Next: RAW_DIR=marketing-screenshots/1.1/raw FRAMED_DIR=marketing-screenshots/1.1/framed ./Scripts/frame-marketing-screenshots.sh"
