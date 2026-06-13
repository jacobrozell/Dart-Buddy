#!/usr/bin/env bash
# Capture portrait, landscape, and accessibility Dynamic Type screenshots for every shipped game mode.
#
# Usage:
#   ./Scripts/capture_game_mode_screenshots.sh
#   OUT_DIR=Screenshots/game-modes/latest ./Scripts/capture_game_mode_screenshots.sh
#   TEST_FILTER="DartBuddyUIGameplayUITests/GameModeScreenshotUITests/testCaptureMickeyMouseScreenshots" ./Scripts/capture_game_mode_screenshots.sh
#
# Output layout:
#   Screenshots/game-modes/<timestamp>/
#     manifest.json
#     x01/portrait.png
#     x01/landscape.png
#     x01/massive-text-portrait.png
#     x01/massive-text-landscape.png
#     cricket/...
#
# Requires: Xcode, xcodegen (if DartBuddy.xcodeproj is missing)

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TIMESTAMP="$(date +%Y-%m-%d_%H%M%S)"
SIM_NAME="${SIM_NAME:-iPhone 17 Pro Max}"
OUT_DIR="${OUT_DIR:-$ROOT/Screenshots/game-modes/$TIMESTAMP}"
PROJECT="$ROOT/DartBuddy.xcodeproj"
SCHEME="DartBuddyUIGameplay"
DERIVED_DATA="${DERIVED_DATA:-$ROOT/.derivedData/game-mode-screenshots}"
TEST_CLASS="DartBuddyUIGameplayUITests/GameModeScreenshotUITests"
TEST_TARGET="${TEST_FILTER:-$TEST_CLASS/testCaptureAllShippedGameModeScreenshots}"

echo "→ Project: $ROOT"
echo "→ Simulator: $SIM_NAME"
echo "→ Output: $OUT_DIR"
echo "→ Test: $TEST_TARGET"

mkdir -p "$OUT_DIR"

export GAME_MODE_SCREENSHOT_OUTPUT_DIR="$OUT_DIR"
export SIMULATOR_DEVICE_NAME="$SIM_NAME"
echo "$OUT_DIR" > "$ROOT/.game-mode-screenshot-output-path"

if [[ ! -d "$PROJECT" ]]; then
  echo "→ Generating Xcode project…"
  (cd "$ROOT" && xcodegen generate)
fi

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
open -a Simulator --args -CurrentDeviceUDID "$SIM_UDID" 2>/dev/null || true

echo "→ Running screenshot UI test…"
set +e
if command -v xcbeautify >/dev/null 2>&1; then
  set -o pipefail
  xcodebuild test \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Debug \
    -destination "platform=iOS Simulator,id=$SIM_UDID" \
    -derivedDataPath "$DERIVED_DATA" \
    -only-testing:"$TEST_TARGET" \
    2>&1 | xcbeautify --quieter
  TEST_STATUS=${PIPESTATUS[0]}
  set +o pipefail
else
  xcodebuild test \
    -project "$PROJECT" \
    -scheme "$SCHEME" \
    -configuration Debug \
    -destination "platform=iOS Simulator,id=$SIM_UDID" \
    -derivedDataPath "$DERIVED_DATA" \
    -only-testing:"$TEST_TARGET"
  TEST_STATUS=$?
fi
set -e

if [[ "$TEST_STATUS" -ne 0 ]]; then
  if [[ -f "$OUT_DIR/manifest.json" ]] && find "$OUT_DIR" -name '*.png' | grep -q .; then
    echo "Screenshot capture test reported failures, but partial output exists in $OUT_DIR" >&2
  else
    echo "Screenshot capture test failed (exit $TEST_STATUS)." >&2
    exit "$TEST_STATUS"
  fi
fi

if [[ ! -f "$OUT_DIR/manifest.json" ]]; then
  if find "$OUT_DIR" -name '*.png' | grep -q .; then
    echo "→ Writing fallback manifest.json from captured PNGs…"
    python3 - "$OUT_DIR" <<'PY'
import json, sys
from pathlib import Path
root = Path(sys.argv[1])
modes = sorted({p.parent.name for p in root.rglob("*.png")})
payload = {
    "generatedAt": __import__("datetime").datetime.now().isoformat(),
    "captureCount": len(list(root.rglob("*.png"))),
    "modes": [
        {
            "folder": mode,
            "screenshots": sorted(p.name for p in (root / mode).glob("*.png")),
        }
        for mode in modes
    ],
}
(root / "manifest.json").write_text(json.dumps(payload, indent=2))
PY
  else
    echo "Test finished but no screenshots were written to $OUT_DIR" >&2
    exit 1
  fi
fi

LATEST_LINK="$ROOT/Screenshots/game-modes/latest"
rm -f "$LATEST_LINK"
ln -s "$OUT_DIR" "$LATEST_LINK"
rm -f "$ROOT/.game-mode-screenshot-output-path"

echo ""
echo "Done. Game mode screenshots:"
echo "  $OUT_DIR"
echo "  $LATEST_LINK -> $(basename "$OUT_DIR")"
find "$OUT_DIR" -name '*.png' | sort
