#!/usr/bin/env bash
# Capture Dynamic Type (accessibility largest) screenshots in landscape for WCAG evidence.
#
# Usage:
#   ./Scripts/capture-accessibility-screenshots-landscape.sh
#   APPEARANCE=light ./Scripts/capture-accessibility-screenshots-landscape.sh
#   SIM_NAME="iPad Pro 13-inch (M5)" ./Scripts/capture-accessibility-screenshots-landscape.sh
#   CONTENT_SIZE=accessibility-extra-extra-large ./Scripts/capture-accessibility-screenshots-landscape.sh
#
# Output: accessibility/screenshots/landscape/*.png
#         accessibility/screenshots/ipad/landscape/*.png (when SIM_NAME contains "iPad")
# Filenames use a -landscape suffix before .png.
# Sets simulator content size via `simctl ui` (AXXXL by default).

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=simulator-orientation.sh
source "$SCRIPT_DIR/simulator-orientation.sh"

SIM_NAME="${SIM_NAME:-iPhone 17 Pro}"
APPEARANCE="${APPEARANCE:-dark}"
CONTENT_SIZE="${CONTENT_SIZE:-accessibility-extra-extra-extra-large}"
BUNDLE_ID="com.jacobrozell.DartBuddy"
SCHEME="DartBuddy"
PROJECT="$ROOT/DartBuddy.xcodeproj"
DERIVED_DATA="${DERIVED_DATA:-$ROOT/.derivedData/accessibility-screenshots-landscape}"
LAUNCH_DELAY="${LAUNCH_DELAY:-4}"
ORIENTATION_SETTLE_SEC="${ORIENTATION_SETTLE_SEC:-1.5}"
ORIENTATION="landscape"

if [[ -z "${OUT_DIR:-}" ]]; then
  if [[ "$SIM_NAME" == *iPad* ]]; then
    OUT_DIR="$ROOT/accessibility/screenshots/ipad/landscape"
  else
    OUT_DIR="$ROOT/accessibility/screenshots/landscape"
  fi
fi

COMMON_ARGS=(-ui_test_reset -ui_test_disable_feedback -disable_firebase_analytics)

slugify() {
  echo "$1" | tr ' ' '-' | tr -d '()' | tr '[:upper:]' '[:lower:]'
}

echo "→ Project: $ROOT"
echo "→ Simulator: $SIM_NAME ($APPEARANCE, $CONTENT_SIZE, $ORIENTATION)"
echo "→ Output: $OUT_DIR"

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
xcrun simctl ui "$SIM_UDID" appearance "$APPEARANCE"
xcrun simctl ui "$SIM_UDID" content_size "$CONTENT_SIZE"
echo "→ Content size: $(xcrun simctl ui "$SIM_UDID" content_size)"

if [[ ! -d "$PROJECT" ]]; then
  echo "→ Generating Xcode project…"
  (cd "$ROOT" && xcodegen generate)
fi

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

xcrun simctl install "$SIM_UDID" "$APP_PATH"

capture() {
  local filename="$1"
  shift
  local -a args=("$@")

  echo "→ Capturing ${filename} (${ORIENTATION})…"
  xcrun simctl terminate "$SIM_UDID" "$BUNDLE_ID" 2>/dev/null || true
  sleep 0.5
  xcrun simctl launch "$SIM_UDID" "$BUNDLE_ID" \
    "${args[@]}" -snapshot_orientation "$ORIENTATION" >/dev/null
  sleep "$LAUNCH_DELAY"
  sleep "$ORIENTATION_SETTLE_SEC"
  xcrun simctl io "$SIM_UDID" screenshot "$OUT_DIR/$filename"
  normalize_screenshot_for_orientation "$OUT_DIR/$filename" "$ORIENTATION"
  verify_screenshot_orientation "$OUT_DIR/$filename" "$ORIENTATION"
}

DEVICE_SLUG="$(slugify "$SIM_NAME")"
SIZE_SLUG="$(echo "$CONTENT_SIZE" | tr '_' '-')"
LANDSCAPE_SUFFIX="-landscape"

capture "${DEVICE_SLUG}-match-setup_${APPEARANCE}_${SIZE_SLUG}${LANDSCAPE_SUFFIX}.png" \
  "${COMMON_ARGS[@]}" -seed_demo

capture "${DEVICE_SLUG}-x01-match_${APPEARANCE}_${SIZE_SLUG}${LANDSCAPE_SUFFIX}.png" \
  "${COMMON_ARGS[@]}" -snapshot_match_x01

capture "${DEVICE_SLUG}-cricket-match_${APPEARANCE}_${SIZE_SLUG}${LANDSCAPE_SUFFIX}.png" \
  "${COMMON_ARGS[@]}" -snapshot_match_cricket

capture "${DEVICE_SLUG}-activity-history_${APPEARANCE}_${SIZE_SLUG}${LANDSCAPE_SUFFIX}.png" \
  "${COMMON_ARGS[@]}" -seed_demo -snapshot_tab activity

capture "${DEVICE_SLUG}-activity-statistics_${APPEARANCE}_${SIZE_SLUG}${LANDSCAPE_SUFFIX}.png" \
  "${COMMON_ARGS[@]}" -seed_demo -snapshot_tab activity -snapshot_activity_segment statistics

capture "${DEVICE_SLUG}-modes_${APPEARANCE}_${SIZE_SLUG}${LANDSCAPE_SUFFIX}.png" \
  "${COMMON_ARGS[@]}" -seed_demo -snapshot_tab modes

capture "${DEVICE_SLUG}-settings_${APPEARANCE}_${SIZE_SLUG}${LANDSCAPE_SUFFIX}.png" \
  "${COMMON_ARGS[@]}" -seed_demo -snapshot_tab settings

capture "${DEVICE_SLUG}-onboarding_${APPEARANCE}_${SIZE_SLUG}${LANDSCAPE_SUFFIX}.png" \
  "${COMMON_ARGS[@]}" -ui_test_onboarding

echo ""
echo "Done. Landscape accessibility screenshots:"
ls -1 "$OUT_DIR"/*"${LANDSCAPE_SUFFIX}"*.png 2>/dev/null || ls -1 "$OUT_DIR"/*.png
