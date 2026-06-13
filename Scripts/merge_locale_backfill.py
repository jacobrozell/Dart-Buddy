#!/usr/bin/env python3
"""Merge locale backfill JSON shards into Scripts/locale_data/{locale}.json."""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT / "Scripts/locale_data"

BACKFILL_FILES: dict[str, list[str]] = {
    "de": ["de_backfill.json"],
    "es": ["es_backfill.json"],
    "nl": ["nl_backfill.json"],
    "fr": ["fr_backfill.json", "fr_backfill2.json"],
}


def merge(locale: str) -> None:
    target = DATA_DIR / f"{locale}.json"
    if not target.exists():
        raise SystemExit(f"Missing locale data: {target}")

    data = json.loads(target.read_text(encoding="utf-8"))
    merged = 0
    for name in BACKFILL_FILES.get(locale, []):
        path = DATA_DIR / name
        if not path.exists():
            print(f"warning: skipping missing backfill {path}", file=sys.stderr)
            continue
        backfill = json.loads(path.read_text(encoding="utf-8"))
        data.update(backfill)
        merged += len(backfill)
        print(f"Merged {len(backfill)} keys from {name}")

    target.write_text(json.dumps(dict(sorted(data.items())), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Wrote {len(data)} keys to {target} ({merged} backfill entries applied)")


def main() -> None:
    locales = sys.argv[1:] if len(sys.argv) > 1 else list(BACKFILL_FILES)
    for locale in locales:
        merge(locale)


if __name__ == "__main__":
    main()
