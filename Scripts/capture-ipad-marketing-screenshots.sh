#!/usr/bin/env bash
# Capture App Store iPad screenshots (12.9" / 13" slot: 2064×2752 portrait).
#
# Usage:
#   ./Scripts/capture-ipad-marketing-screenshots.sh
#   APPEARANCE=light ./Scripts/capture-ipad-marketing-screenshots.sh
#   SIM_NAME="iPad Pro 13-inch (M4)" ./Scripts/capture-ipad-marketing-screenshots.sh
#
# Output: marketing-screenshots/ipad/raw/*.png
# Upload to App Store Connect → iPad 12.9" or 13" Displays (portrait 2064×2752).

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Prefer M5 when available; M4/M5 both capture 2064×2752 on 13" Pro simulators.
if [[ -z "${SIM_NAME:-}" ]]; then
  SIM_NAME="$(xcrun simctl list devices available -j | python3 -c "
import json, sys
data = json.load(sys.stdin)
candidates = []
for runtime, devices in data.get('devices', {}).items():
    if 'iOS' not in runtime:
        continue
    for d in devices:
        n = d.get('name', '')
        if 'iPad Pro 13-inch' in n and d.get('isAvailable', True):
            candidates.append(n)
if not candidates:
    sys.exit(1)
# Stable pick: newest name sorts last for (M5) vs (M4)
print(sorted(set(candidates))[-1])
")" || SIM_NAME="iPad Pro 13-inch (M5)"
fi

export SIM_NAME
export OUT_DIR="${OUT_DIR:-$ROOT/marketing-screenshots/ipad/raw}"
export APP_STORE_WIDTH="${APP_STORE_WIDTH:-2064}"
export APP_STORE_HEIGHT="${APP_STORE_HEIGHT:-2752}"
export APP_STORE_RESIZE="${APP_STORE_RESIZE:-1}"
export LAUNCH_DELAY="${LAUNCH_DELAY:-5}"

exec "$ROOT/Scripts/capture-marketing-screenshots.sh"
