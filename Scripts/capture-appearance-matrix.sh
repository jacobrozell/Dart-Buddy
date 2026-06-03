#!/usr/bin/env bash
# Capture release §4 appearance matrix: setup + X01 in-match × portrait|landscape × light|dark.
#
# Usage:
#   ./Scripts/capture-appearance-matrix.sh
#
# Output: accessibility/wcag-2.1-aa/evidence/orientation/*.png

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SIM_NAME="${SIM_NAME:-iPhone 17 Pro}"
OUT_DIR="${OUT_DIR:-$ROOT/accessibility/wcag-2.1-aa/evidence/orientation}"
BUNDLE_ID="com.jacobrozell.DartBuddy"
SCHEME="DartBuddy"
PROJECT="$ROOT/DartBuddy.xcodeproj"
DERIVED_DATA="${DERIVED_DATA:-$ROOT/.derivedData/appearance-matrix}"
LAUNCH_DELAY="${LAUNCH_DELAY:-2.5}"

COMMON_ARGS=(-ui_test_reset -ui_test_disable_feedback -disable_firebase_analytics)

echo "→ Project: $ROOT"
echo "→ Simulator: $SIM_NAME"
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

rotate_simulator_left() {
  osascript <<'APPLESCRIPT' >/dev/null 2>&1 || true
tell application "Simulator" to activate
delay 0.2
tell application "System Events"
  tell process "Simulator"
    key code 123 using {command down}
  end tell
end tell
APPLESCRIPT
  sleep 0.6
}

ensure_portrait() {
  rotate_simulator_left
  rotate_simulator_left
  rotate_simulator_left
  rotate_simulator_left
}

ensure_landscape() {
  ensure_portrait
  rotate_simulator_left
}

echo "→ Booting $SIM_NAME ($SIM_UDID)…"
xcrun simctl boot "$SIM_UDID" 2>/dev/null || true
xcrun simctl bootstatus "$SIM_UDID" -b
open -a Simulator --args -CurrentDeviceUDID "$SIM_UDID"

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
  local appearance="$2"
  local orientation="$3"
  shift 3
  local -a args=("$@")

  if [[ "$orientation" == "landscape" ]]; then
    ensure_landscape
  else
    ensure_portrait
  fi

  xcrun simctl ui "$SIM_UDID" appearance "$appearance"
  echo "→ Capturing ${filename} (${appearance}, ${orientation})…"
  xcrun simctl terminate "$SIM_UDID" "$BUNDLE_ID" 2>/dev/null || true
  sleep 0.5
  xcrun simctl launch "$SIM_UDID" "$BUNDLE_ID" "${args[@]}" >/dev/null
  sleep "$LAUNCH_DELAY"
  xcrun simctl io "$SIM_UDID" screenshot "$OUT_DIR/$filename"
}

DEVICE_SLUG="$(echo "$SIM_NAME" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | tr -d '()')"

for appearance in light dark; do
  for orientation in portrait landscape; do
    capture "match-setup_${DEVICE_SLUG}_${appearance}_${orientation}.png" \
      "$appearance" "$orientation" \
      "${COMMON_ARGS[@]}" -appearance_mode "$appearance" -seed_demo

    capture "x01-match_${DEVICE_SLUG}_${appearance}_${orientation}.png" \
      "$appearance" "$orientation" \
      "${COMMON_ARGS[@]}" -appearance_mode "$appearance" -snapshot_match_x01
  done
done

ensure_portrait
echo ""
echo "Done. Appearance matrix screenshots:"
ls -1 "$OUT_DIR"/match-setup_*.png "$OUT_DIR"/x01-match_*.png 2>/dev/null || ls -1 "$OUT_DIR"/*.png
