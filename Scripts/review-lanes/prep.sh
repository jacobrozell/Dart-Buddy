#!/usr/bin/env bash
# Prep a review-lanes bundle (diff artifacts outside the repo).
# Usage: Scripts/review-lanes/prep.sh <REPO> <BASE> <BRANCH>
# Prints the absolute OUT directory path on stdout (last line).
set -euo pipefail

REPO="${1:?repo path}"
BASE="${2:?base ref}"
BRANCH="${3:?branch ref}"

REPO="$(cd "$REPO" && pwd)"
cd "$REPO"

OUT_ROOT="${REVIEW_LANES_OUT_ROOT:-/tmp/cursor/review-bundles}"
STAMP="$(date -u +%Y%m%dT%H%M%SZ)"
SAFE_BRANCH="$(echo "$BRANCH" | tr '/:' '__')"
OUT="${OUT_ROOT}/${SAFE_BRANCH}-${STAMP}"
mkdir -p "$OUT"

resolve_ref() {
  local ref="$1"
  if git rev-parse --verify --quiet "$ref" >/dev/null; then
    git rev-parse "$ref"
    return
  fi
  if git rev-parse --verify --quiet "origin/$ref" >/dev/null; then
    git rev-parse "origin/$ref"
    return
  fi
  echo "error: cannot resolve ref $ref" >&2
  exit 1
}

BASE_SHA="$(resolve_ref "$BASE")"
BRANCH_SHA="$(resolve_ref "$BRANCH")"

git diff --name-only "${BASE_SHA}...${BRANCH_SHA}" >"$OUT/changed-files.txt"
git diff --numstat "${BASE_SHA}...${BRANCH_SHA}" >"$OUT/numstat.txt"
git diff --binary "${BASE_SHA}...${BRANCH_SHA}" >"$OUT/diff.patch"

FILE_COUNT="$(wc -l <"$OUT/changed-files.txt" | tr -d ' ')"
SHORTSTAT="$(git diff --shortstat "${BASE_SHA}...${BRANCH_SHA}" || true)"

{
  echo "repo=$REPO"
  echo "base=$BASE"
  echo "base_sha=$BASE_SHA"
  echo "branch=$BRANCH"
  echo "branch_sha=$BRANCH_SHA"
  echo "files=$FILE_COUNT"
  echo "shortstat=$SHORTSTAT"
  echo "created_at=$STAMP"
} >"$OUT/meta.txt"

# Human-readable summary for the orchestrator
cat "$OUT/meta.txt" >&2
echo "$OUT"
