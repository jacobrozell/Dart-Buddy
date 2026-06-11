#!/usr/bin/env bash
# Capture App Store marketing screenshots from the iOS Simulator.
#
# Usage:
#   ./Scripts/capture-marketing-screenshots.sh              # dark, iPhone 17 Pro, portrait + landscape
#   APPEARANCE=light ./Scripts/capture-marketing-screenshots.sh
#   SIM_NAME="iPhone 17 Pro Max" ./Scripts/capture-marketing-screenshots.sh
#   ORIENTATIONS=portrait ./Scripts/capture-marketing-screenshots.sh   # portrait only
#
# Output: marketing-screenshots/raw/*.png (resized for App Store Connect by default)
# Landscape files use a -landscape suffix before .png (e.g. …-dark-landscape.png).
# Then run: ./Scripts/frame-marketing-screenshots.sh
#
# App Store 6.5" slot requires 1284×2778 or 1242×2688 (portrait) and matching landscape sizes.
# iPhone 17 Pro captures 1206×2622 portrait; set APP_STORE_RESIZE=0 to keep native pixels.

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=app-store-screenshot-size.sh
source "$SCRIPT_DIR/app-store-screenshot-size.sh"
# shellcheck source=simulator-orientation.sh
source "$SCRIPT_DIR/simulator-orientation.sh"
SIM_NAME="${SIM_NAME:-iPhone 17 Pro}"
APPEARANCE="${APPEARANCE:-dark}"
ORIENTATIONS="${ORIENTATIONS:-portrait landscape}"
OUT_DIR="${OUT_DIR:-$ROOT/marketing-screenshots/raw}"
BUNDLE_ID="com.jacobrozell.DartBuddy"
SCHEME="DartBuddy"
PROJECT="$ROOT/DartBuddy.xcodeproj"
DERIVED_DATA="${DERIVED_DATA:-$ROOT/.derivedData/marketing-screenshots}"
LAUNCH_DELAY="${LAUNCH_DELAY:-5}"
APP_STORE_RESIZE="${APP_STORE_RESIZE:-1}"

COMMON_ARGS=(-ui_test_reset -ui_test_disable_feedback -disable_firebase_analytics)

slugify() {
  echo "$1" | tr ' ' '-' | tr -d '()' | tr '[:upper:]' '[:lower:]'
}

echo "→ Project: $ROOT"
echo "→ Simulator: $SIM_NAME ($APPEARANCE)"
echo "→ Orientations: $ORIENTATIONS"
echo "→ Output: $OUT_DIR"

if [[ ! -d "$PROJECT" ]]; then
  echo "→ Generating Xcode project…"
  (cd "$ROOT" && xcodegen generate)
fi

mkdir -p "$OUT_DIR"

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

echo "→ Booting $SIM_NAME ($SIM_UDID)…"
xcrun simctl boot "$SIM_UDID" 2>/dev/null || true
xcrun simctl bootstatus "$SIM_UDID" -b
open -a Simulator --args -CurrentDeviceUDID "$SIM_UDID"
reset_simulator_orientation
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
      ensure_landscape
    else
      ensure_portrait
    fi

    local filename="${DEVICE_SLUG}-${slug}-${APPEARANCE}${suffix}.png"
    echo "→ Capturing ${filename} (${orientation})..."
    xcrun simctl terminate "$SIM_UDID" "$BUNDLE_ID" 2>/dev/null || true
    sleep 0.5
    xcrun simctl launch "$SIM_UDID" "$BUNDLE_ID" "${args[@]}" >/dev/null
    sleep "$LAUNCH_DELAY"
    xcrun simctl io "$SIM_UDID" screenshot "$OUT_DIR/$filename"
    if [[ "$APP_STORE_RESIZE" == 1 ]]; then
      app_store_resize_png_for_orientation "$OUT_DIR/$filename" "$orientation"
    fi
  done
}

DEVICE_SLUG="$(slugify "$SIM_NAME")"

# App Store priority order (specs/AppStoreConnectSpec.md §8)
capture "01-x01-match" \
  "${COMMON_ARGS[@]}" -snapshot_match_x01

capture "02-cricket-match" \
  "${COMMON_ARGS[@]}" -snapshot_match_cricket

capture "03-match-setup" \
  "${COMMON_ARGS[@]}" -seed_demo -snapshot_play_setup

capture "04-activity-history" \
  "${COMMON_ARGS[@]}" -seed_demo -snapshot_tab activity

capture "04b-modes" \
  "${COMMON_ARGS[@]}" -seed_demo -snapshot_tab modes

capture "05-match-summary" \
  "${COMMON_ARGS[@]}" -snapshot_match_summary

capture "06-players" \
  "${COMMON_ARGS[@]}" -seed_demo -snapshot_tab players

capture "07-activity-statistics" \
  "${COMMON_ARGS[@]}" -seed_demo -snapshot_tab activity -snapshot_activity_segment statistics

capture "08-onboarding-welcome" \
  "${COMMON_ARGS[@]}" -ui_test_onboarding

capture "10-settings" \
  "${COMMON_ARGS[@]}" -seed_demo -snapshot_tab settings

ensure_portrait

echo ""
first_png="$(ls -1 "$OUT_DIR"/*.png | head -1)"
echo "Done. Raw screenshots ($(magick identify -format '%wx%h' "$first_png")):"
ls -1 "$OUT_DIR"/*.png
if [[ "$APP_STORE_RESIZE" == 1 ]]; then
  echo "App Store export (portrait): ${APP_STORE_WIDTH}×${APP_STORE_HEIGHT}"
  echo "App Store export (landscape): ${APP_STORE_HEIGHT}×${APP_STORE_WIDTH}"
fi
echo ""
echo "Next: ./Scripts/frame-marketing-screenshots.sh"
