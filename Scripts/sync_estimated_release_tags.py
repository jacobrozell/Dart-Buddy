#!/usr/bin/env python3
"""Sync Estimated release tags from docs/release/estimated-releases.json into specs."""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[1]
REGISTRY_PATH = REPO_ROOT / "docs" / "release" / "estimated-releases.json"
SPECS_DIR = REPO_ROOT / "specs"

CATALOG_ID_RE = re.compile(r"`((?:standard|party|coop|practice)\.[a-zA-Z0-9]+)`")
ESTIMATED_HEADER_RE = re.compile(
    r"^\*\*Estimated release:\*\*\s*`[^`]+`.*$", re.MULTILINE
)
ESTIMATED_TABLE_RE = re.compile(
    r"^\| \*\*Estimated release\*\* \| `[^`]+` \|.*$", re.MULTILINE
)
VERIFICATION_TABLE_HEADER = re.compile(r"^\| Field \| Value \|", re.MULTILINE)


def load_registry() -> dict:
    with REGISTRY_PATH.open(encoding="utf-8") as handle:
        return json.load(handle)


def catalog_id_from_spec(path: Path) -> str | None:
    text = path.read_text(encoding="utf-8", errors="replace")
    for line in text.splitlines()[:40]:
        if "Catalog id" in line or "Status:" in line:
            match = CATALOG_ID_RE.search(line)
            if match:
                return match.group(1)
    for match in CATALOG_ID_RE.finditer(text):
        cid = match.group(1)
        if cid.startswith(("standard.", "party.", "coop.", "practice.")):
            return cid
    key_match = re.search(
        r"modes\.catalog\.((?:standard|party|coop|practice)\.[a-zA-Z0-9]+)\.",
        text,
    )
    if key_match:
        return key_match.group(1)
    return None


def spec_path_for_catalog_id(catalog_id: str) -> Path | None:
    for folder in ("implemented", "planned"):
        spec_dir = SPECS_DIR / "game-modes" / folder
        if not spec_dir.is_dir():
            continue
        for path in spec_dir.glob("*.md"):
            if catalog_id_from_spec(path) == catalog_id:
                return path
    return None


def format_tag(value: str) -> str:
    return f"`{value}`"


def upsert_header(text: str, tag: str) -> str:
    line = f"**Estimated release:** {format_tag(tag)}"
    if ESTIMATED_HEADER_RE.search(text):
        return ESTIMATED_HEADER_RE.sub(line, text, count=1)
    # Insert after Status line if present
    status_match = re.search(r"^(\*\*Status:\*\*.*)$", text, re.MULTILINE)
    if status_match:
        insert_at = status_match.end()
        return text[:insert_at] + "\n" + line + text[insert_at:]
    return line + "\n\n" + text


def upsert_catalog_table_row(text: str, tag: str) -> str:
    row = f"| **Estimated release** | {format_tag(tag)} |"
    if ESTIMATED_TABLE_RE.search(text):
        return ESTIMATED_TABLE_RE.sub(row, text, count=1)
    shipped_match = re.search(
        r"^(\| \*\*Shipped in app\*\* \|[^\n]+\n)", text, re.MULTILINE
    )
    if shipped_match:
        insert_at = shipped_match.end()
        return text[:insert_at] + row + "\n" + text[insert_at:]
    return text


def upsert_verification_row(text: str, tag: str) -> str:
    row = f"| **Estimated release** | {format_tag(tag)} |"
    if ESTIMATED_TABLE_RE.search(text):
        return ESTIMATED_TABLE_RE.sub(row, text, count=1)
    # Find last Verification section table
    sections = list(re.finditer(r"^## \d+\. Verification\s*$", text, re.MULTILINE))
    if not sections:
        return text
    start = sections[-1].start()
    section_text = text[start:]
    header = VERIFICATION_TABLE_HEADER.search(section_text)
    if not header:
        return text
    # Insert after | Field | Value | and separator
    lines = section_text.splitlines()
    insert_idx = None
    for idx, line in enumerate(lines):
        if line.strip().startswith("| **Last verified**"):
            insert_idx = idx
            break
    if insert_idx is None:
        for idx, line in enumerate(lines):
            if re.match(r"^\|[-: |]+\|$", line.strip()):
                insert_idx = idx + 1
                break
    if insert_idx is None:
        return text
    lines.insert(insert_idx, row)
    new_section = "\n".join(lines)
    return text[:start] + new_section


def sync_spec(path: Path, tag: str, is_game_mode: bool) -> bool:
    original = path.read_text(encoding="utf-8", errors="replace")
    updated = upsert_header(original, tag)
    if is_game_mode:
        updated = upsert_catalog_table_row(updated, tag)
    updated = upsert_verification_row(updated, tag)
    if updated != original:
        path.write_text(updated, encoding="utf-8")
        return True
    return False


def main() -> int:
    registry = load_registry()
    changed: list[str] = []

    for catalog_id, entry in registry.get("catalog", {}).items():
        path = spec_path_for_catalog_id(catalog_id)
        if not path:
            print(f"warn: no spec for catalog id {catalog_id}", file=sys.stderr)
            continue
        tag = entry["storeRelease"]
        if sync_spec(path, tag, is_game_mode=True):
            changed.append(str(path.relative_to(REPO_ROOT)))

    for spec_ref, entry in registry.get("features", {}).items():
        path = REPO_ROOT / spec_ref
        if not path.is_file():
            print(f"warn: missing feature spec {spec_ref}", file=sys.stderr)
            continue
        tag = entry["storeRelease"]
        if sync_spec(path, tag, is_game_mode=False):
            changed.append(spec_ref)

    print(f"Updated {len(changed)} spec(s)")
    for item in changed:
        print(f"  - {item}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
