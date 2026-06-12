#!/usr/bin/env bash
# Capture iOS 26 Liquid Glass tab-root screenshots for release evidence.
#
# Usage:
#   ./Scripts/capture-ios26-liquid-glass.sh
#
# Env:
#   SIM_NAME   — default: iPhone 17 Pro (must be on iOS 26+ runtime)
#   OUT_DIR    — default: accessibility/wcag-2.1-aa/evidence/ios26-liquid-glass
#
# Output: tab-*.png per root tab (light + dark)

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SIM_NAME="${SIM_NAME:-iPhone 17 Pro}"
OUT_DIR="${OUT_DIR:-$ROOT/accessibility/wcag-2.1-aa/evidence/ios26-liquid-glass}"
BUNDLE_ID="com.jacobrozell.DartBuddy"
SCHEME="DartBuddy"
PROJECT="$ROOT/DartBuddy.xcodeproj"
DERIVED_DATA="${DERIVED_DATA:-$ROOT/.derivedData/ios26-liquid-glass}"
LAUNCH_DELAY="${LAUNCH_DELAY:-2.5}"

COMMON_ARGS=(-ui_test_reset -skip_onboarding -seed_demo -disable_firebase_analytics)

echo "→ Project: $ROOT"
echo "→ Simulator: $SIM_NAME (iOS 26+ required for Liquid Glass nav)"
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
candidates = []
for runtime, devices in data.get('devices', {}).items():
    if 'iOS-26' not in runtime and 'iOS 26' not in runtime:
        continue
    for d in devices:
        if d.get('name') == name and d.get('isAvailable', True):
            candidates.append((runtime, d['udid']))
if not candidates:
    sys.exit(1)
candidates.sort(reverse=True)
print(candidates[0][1])
" "$SIM_NAME")"

RUNTIME="$(xcrun simctl list devices available -j | python3 -c "
import json, sys
udid = sys.argv[1]
data = json.load(sys.stdin)
for runtime, devices in data.get('devices', {}).items():
    for d in devices:
        if d.get('udid') == udid:
            print(runtime)
            sys.exit(0)
" "$SIM_UDID")"

echo "→ Runtime: $RUNTIME"
echo "→ UDID: $SIM_UDID"

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

DEVICE_SLUG="$(echo "$SIM_NAME" | tr ' ' '-' | tr '[:upper:]' '[:lower:]' | tr -d '()')"

capture_tab() {
  local tab="$1"
  local appearance="$2"
  shift 2
  local -a extra_args=("$@")
  local filename="tab-${tab}_${DEVICE_SLUG}_${appearance}_portrait.png"

  xcrun simctl ui "$SIM_UDID" appearance "$appearance"
  echo "→ Capturing ${filename}…"
  xcrun simctl terminate "$SIM_UDID" "$BUNDLE_ID" 2>/dev/null || true
  sleep 0.5
  xcrun simctl launch "$SIM_UDID" "$BUNDLE_ID" \
    "${COMMON_ARGS[@]}" ${extra_args+"${extra_args[@]}"} -appearance_mode "$appearance" -snapshot_tab "$tab" >/dev/null
  sleep "$LAUNCH_DELAY"
  xcrun simctl io "$SIM_UDID" screenshot "$OUT_DIR/$filename"
}

for appearance in light dark; do
  capture_tab play "$appearance"
  capture_tab modes "$appearance" -enable_full_product_surface
  capture_tab players "$appearance"
  capture_tab activity "$appearance"
  capture_tab settings "$appearance"
done

echo ""
echo "Done. iOS 26 Liquid Glass tab screenshots:"
ls -1 "$OUT_DIR"/tab-*.png 2>/dev/null || ls -1 "$OUT_DIR"/*.png
