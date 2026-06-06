#!/usr/bin/env bash
# Write a text coverage summary for CI artifacts (no thresholds / gates).
set -euo pipefail

XCRESULT="${CI_XCRESULT:-TestResults.xcresult}"
OUTPUT="${CI_COVERAGE_SUMMARY:-coverage-summary.txt}"

if [[ ! -d "$XCRESULT" ]]; then
  echo "No xcresult at ${XCRESULT}; skipping coverage summary." | tee "$OUTPUT"
  exit 0
fi

{
  echo "Coverage summary from ${XCRESULT}"
  echo "Generated: $(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  echo ""
  xcrun xccov view --report "$XCRESULT"
} | tee "$OUTPUT"
