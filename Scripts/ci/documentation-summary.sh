#!/usr/bin/env bash
# Write a text documentation coverage summary for CI artifacts (no thresholds / gates).
set -euo pipefail

OUTPUT="${CI_DOCUMENTATION_SUMMARY:-documentation-summary.txt}"

python3 Scripts/ci/documentation-summary.py | tee "$OUTPUT"
