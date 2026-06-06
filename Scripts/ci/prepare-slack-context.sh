#!/usr/bin/env bash
# Build JSON context for slack-ci-notify from downloaded CI artifacts.
set -euo pipefail

OUTPUT="${1:-slack-context.json}"
ARTIFACTS_DIR="${ARTIFACTS_DIR:-.}"

python3 - "$OUTPUT" "$ARTIFACTS_DIR" <<'PY'
import json
import os
import re
import sys

output_path, artifacts_dir = sys.argv[1], sys.argv[2]

coverage_file = os.path.join(artifacts_dir, "coverage-summary.txt")
test_log = os.path.join(artifacts_dir, "xcodebuild-test.log")
build_log = os.path.join(artifacts_dir, "xcodebuild-build.log")

context = {
    "coverage": None,
    "coverage_target": None,
    "failed_tests": [],
    "failure_excerpt": None,
}


def read_text(path: str) -> str:
    if not os.path.isfile(path):
        return ""
    with open(path, encoding="utf-8", errors="replace") as handle:
        return handle.read()


def parse_coverage(text):
    if not text.strip():
        return None, None

    target_line = None
    total_line = None
    for line in text.splitlines():
        if re.search(r"\d+\.\d+%", line) is None:
            continue
        if "DartBuddy" in line:
            target_line = line
        if line.strip().startswith("TOTAL") or " TOTAL " in line:
            total_line = line

    chosen = target_line or total_line
    if not chosen:
        for line in text.splitlines():
            match = re.search(r"(\d+\.\d+)%", line)
            if match:
                return match.group(1) + "%", line.strip()
        return None, None

    match = re.search(r"(\d+\.\d+)%", chosen)
    if not match:
        return None, None
    return match.group(1) + "%", chosen.strip()


def parse_failed_tests(text):
    if not text:
        return []

    patterns = [
        re.compile(r"Test Case '-\[(.+?)\]' failed"),
        re.compile(r"Test case '-\[(.+?)\]' failed", re.IGNORECASE),
        re.compile(r"✖\s+(.+?)(?:\s+\(|$)"),
        re.compile(r"Failing tests:\s*\n((?:\s+.+\n?)+)"),
    ]

    found = []
    seen = set()

    for pattern in patterns[:3]:
        for match in pattern.finditer(text):
            name = match.group(1).strip()
            if name and name not in seen:
                seen.add(name)
                found.append(name)

    failing_block = patterns[3].search(text)
    if failing_block:
        for line in failing_block.group(1).splitlines():
            name = line.strip()
            if name and name not in seen:
                seen.add(name)
                found.append(name)

    return found[:15]


def failure_excerpt(test_text, build_text, max_chars=2400):
    sources = []
    if test_text:
        sources.append(("test log", test_text))
    if build_text:
        sources.append(("build log", build_text))
    if not sources:
        return None

    markers = (
        "error:",
        "failed",
        "✖",
        "Failing tests:",
        "TEST FAILED",
        "** TEST",
    )

    for label, text in sources:
        lines = text.splitlines()
        hit_indexes = [
            index
            for index, line in enumerate(lines)
            if any(marker in line for marker in markers)
        ]
        if not hit_indexes:
            continue

        start = max(0, hit_indexes[0] - 5)
        excerpt_lines = lines[start : start + 40]
        excerpt = "\n".join(excerpt_lines).strip()
        if excerpt:
            if len(excerpt) > max_chars:
                excerpt = excerpt[: max_chars - 3] + "..."
            return excerpt

    # Fall back to tail of the most relevant log.
    label, text = sources[0]
    tail = "\n".join(text.splitlines()[-25:]).strip()
    if not tail:
        return None
    if len(tail) > max_chars:
        tail = tail[: max_chars - 3] + "..."
    return tail


coverage_text = read_text(coverage_file)
coverage, coverage_target = parse_coverage(coverage_text)
if coverage:
    context["coverage"] = coverage
    context["coverage_target"] = coverage_target

test_text = read_text(test_log)
build_text = read_text(build_log)
failed_tests = parse_failed_tests(test_text)
if failed_tests:
    context["failed_tests"] = failed_tests

if failed_tests or "failed" in test_text.lower() or "error:" in build_text.lower():
    excerpt = failure_excerpt(test_text, build_text)
    if excerpt:
        context["failure_excerpt"] = excerpt

with open(output_path, "w", encoding="utf-8") as handle:
    json.dump(context, handle)
    handle.write("\n")

print(f"Wrote Slack context to {output_path}")
if context["coverage"]:
    print(f"Coverage: {context['coverage']}")
if context["failed_tests"]:
    print(f"Failed tests: {len(context['failed_tests'])}")
PY
