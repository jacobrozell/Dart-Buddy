#!/usr/bin/env bash
set -euo pipefail

DESTINATION="${1:?destination required}"

PROJECT="${CI_XCODE_PROJECT:-DartBuddy.xcodeproj}"
SCHEME="${CI_XCODE_SCHEME:-DartBuddy}"
PACKAGES_ROOT="${CI_PACKAGES_ROOT:-.packages}"
LOG_FILE="${CI_XCODE_TEST_LOG:-xcodebuild-test.log}"
PARALLEL_TESTING="${CI_PARALLEL_TESTING:-YES}"

echo "::group::Running tests (without building)"
echo "Scheme: $SCHEME (parallel testing: $PARALLEL_TESTING)"

# AXXXL accessibility capture runs can leave the booted simulator at extra-large text,
# which breaks default-size UI tests that expect footer validation instead of inline hints.
if xcrun simctl list devices booted -j 2>/dev/null | python3 -c "import json,sys; print(len(json.load(sys.stdin).get('devices',{}).get('booted',[])))" | grep -qv '^0$'; then
  echo "→ Resetting booted simulator content size to large"
  xcrun simctl ui booted content_size large || true
fi
rm -rf TestResults.xcresult
set -o pipefail
xcodebuild test-without-building \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -destination "$DESTINATION" \
  -parallel-testing-enabled "$PARALLEL_TESTING" \
  -derivedDataPath DerivedData \
  -clonedSourcePackagesDirPath "./${PACKAGES_ROOT}/cloned_sources" \
  -packageCachePath "$(pwd)/${PACKAGES_ROOT}/cache" \
  -resultBundlePath TestResults.xcresult \
  CODE_SIGN_IDENTITY=- \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  2>&1 | tee "$LOG_FILE" | xcbeautify --renderer github-actions
echo "::endgroup::"
