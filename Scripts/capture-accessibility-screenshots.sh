#!/usr/bin/env bash
# Capture Dynamic Type (accessibility largest) screenshots for WCAG evidence.
#
# Usage:
#   ./Scripts/capture-accessibility-screenshots.sh
#   APPEARANCE=light ./Scripts/capture-accessibility-screenshots.sh
#   CONTENT_SIZE=accessibility-extra-extra-large ./Scripts/capture-accessibility-screenshots.sh
#
# Output: accessibility/screenshots/*.png
# Sets simulator content size via `simctl ui` (AXXXL by default).

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SIM_NAME="${SIM_NAME:-iPhone 17 Pro}"
APPEARANCE="${APPEARANCE:-dark}"
CONTENT_SIZE="${CONTENT_SIZE:-accessibility-extra-extra-extra-large}"
OUT_DIR="${OUT_DIR:-$ROOT/accessibility/screenshots}"
BUNDLE_ID="com.jacobrozell.DartBuddy"
SCHEME="DartBuddy"
PROJECT="$ROOT/DartBuddy.xcodeproj"
DERIVED_DATA="${DERIVED_DATA:-$ROOT/.derivedData/accessibility-screenshots}"
LAUNCH_DELAY="${LAUNCH_DELAY:-4}"

COMMON_ARGS=(-ui_test_reset -ui_test_disable_feedback -disable_firebase_analytics)

slugify() {
  echo "$1" | tr ' ' '-' | tr -d '()' | tr '[:upper:]' '[:lower:]'
}

echo "→ Project: $ROOT"
echo "→ Simulator: $SIM_NAME ($APPEARANCE, $CONTENT_SIZE)"
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

  echo "→ Capturing ${filename}…"
  xcrun simctl terminate "$SIM_UDID" "$BUNDLE_ID" 2>/dev/null || true
  sleep 0.5
  xcrun simctl launch "$SIM_UDID" "$BUNDLE_ID" "${args[@]}" >/dev/null
  sleep "$LAUNCH_DELAY"
  xcrun simctl io "$SIM_UDID" screenshot "$OUT_DIR/$filename"
}

DEVICE_SLUG="$(slugify "$SIM_NAME")"
SIZE_SLUG="$(echo "$CONTENT_SIZE" | tr '_' '-')"

capture "${DEVICE_SLUG}-match-setup_${APPEARANCE}_${SIZE_SLUG}.png" \
  "${COMMON_ARGS[@]}" -seed_demo

capture "${DEVICE_SLUG}-x01-match_${APPEARANCE}_${SIZE_SLUG}.png" \
  "${COMMON_ARGS[@]}" -snapshot_match_x01

capture "${DEVICE_SLUG}-cricket-match_${APPEARANCE}_${SIZE_SLUG}.png" \
  "${COMMON_ARGS[@]}" -snapshot_match_cricket

capture "${DEVICE_SLUG}-activity-history_${APPEARANCE}_${SIZE_SLUG}.png" \
  "${COMMON_ARGS[@]}" -seed_demo -snapshot_tab activity

capture "${DEVICE_SLUG}-activity-statistics_${APPEARANCE}_${SIZE_SLUG}.png" \
  "${COMMON_ARGS[@]}" -seed_demo -snapshot_tab activity -snapshot_activity_segment statistics

capture "${DEVICE_SLUG}-modes_${APPEARANCE}_${SIZE_SLUG}.png" \
  "${COMMON_ARGS[@]}" -seed_demo -snapshot_tab modes

capture "${DEVICE_SLUG}-settings_${APPEARANCE}_${SIZE_SLUG}.png" \
  "${COMMON_ARGS[@]}" -seed_demo -snapshot_tab settings

capture "${DEVICE_SLUG}-onboarding_${APPEARANCE}_${SIZE_SLUG}.png" \
  "${COMMON_ARGS[@]}" -ui_test_onboarding

echo ""
echo "Done. Accessibility screenshots:"
ls -1 "$OUT_DIR"/*"${SIZE_SLUG}"*.png 2>/dev/null || ls -1 "$OUT_DIR"/*.png
