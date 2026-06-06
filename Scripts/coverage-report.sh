#!/usr/bin/env bash
# Generate a coverage summary from the latest DartBuddyCI test run.
#
# Usage:
#   Scripts/coverage-report.sh                    # use ./TestResults.xcresult
#   Scripts/coverage-report.sh path/to/foo.xcresult
#
# If no xcresult exists, runs DartBuddyCI tests with coverage first.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

XCRESULT="${1:-TestResults.xcresult}"
DERIVED="${DERIVED_DATA_PATH:-DerivedData}"
DESTINATION="${SIM_DESTINATION:-platform=iOS Simulator,name=iPhone 17}"

if [[ ! -d "$XCRESULT" ]]; then
  echo "No ${XCRESULT} — running DartBuddyCI tests with coverage enabled..."
  if [[ ! -d DartBuddy.xcodeproj ]]; then
    xcodegen generate
  fi
  rm -rf "$XCRESULT"
  xcodebuild test \
    -project DartBuddy.xcodeproj \
    -scheme DartBuddyCI \
    -destination "$DESTINATION" \
    -derivedDataPath "$DERIVED" \
    -resultBundlePath "$XCRESULT" \
    -clonedSourcePackagesDirPath "./.packages/cloned_sources" \
    -packageCachePath "$(pwd)/.packages/cache" \
    CODE_SIGN_IDENTITY=- \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO
fi

echo ""
echo "=== Coverage summary (DartBuddy target) ==="
xcrun xccov view --report "$XCRESULT"

if command -v bundle >/dev/null 2>&1 && bundle check >/dev/null 2>&1; then
  echo ""
  echo "=== Generating HTML report (Slather, optional) ==="
  if bundle exec slather coverage; then
    echo ""
    echo "HTML report: ${ROOT}/coverage_reports/index.html"
  else
    echo ""
    echo "Slather HTML failed — use Xcode Report navigator → Coverage, or xccov above."
  fi
else
  echo ""
  echo "Optional: bundle install && Scripts/coverage-report.sh"
  echo "  → adds an HTML report under coverage_reports/"
fi
