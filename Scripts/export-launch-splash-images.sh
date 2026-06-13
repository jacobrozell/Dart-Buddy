#!/usr/bin/env bash
# Export launch splash background candidates (light/dark × 3 styles).
#
# Usage:
#   ./Scripts/export-launch-splash-images.sh
#
# Output:
#   Resources/LaunchSplashCandidates/{hero,ambient,soft}-{light,dark}.png
#   Resources/LaunchSplashCandidates/{hero,ambient,soft}-{light,dark}-composed.png

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCHEME="DartBuddy"
PROJECT="$ROOT/DartBuddy.xcodeproj"
DERIVED_DATA="${DERIVED_DATA:-$ROOT/.derivedData/launch-splash-export}"
SIM_NAME="${SIM_NAME:-iPhone 17 Pro}"

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

echo "→ Exporting launch splash candidates…"
xcodebuild test \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "platform=iOS Simulator,id=$SIM_UDID" \
  -derivedDataPath "$DERIVED_DATA" \
  -only-testing:DartBuddyTests/LaunchSplashExportTests/testExportLaunchSplashCandidates \
  CODE_SIGNING_ALLOWED=NO \
  | xcbeautify 2>/dev/null || true

echo "→ Done. Review PNGs in Resources/LaunchSplashCandidates/"
