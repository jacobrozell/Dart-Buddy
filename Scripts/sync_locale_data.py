#!/usr/bin/env python3
"""Import translations from Resources/*.lproj into Scripts/locale_data/*.json."""
from __future__ import annotations

import json
from pathlib import Path

from localizable_strings import parse_entry_map

ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT / "Scripts/locale_data"
LOCALES = ("de", "es", "nl", "zh-Hans")


def main() -> None:
    DATA_DIR.mkdir(parents=True, exist_ok=True)
    for locale in LOCALES:
        source = ROOT / f"Resources/{locale}.lproj/Localizable.strings"
        entries = parse_entry_map(source.read_text(encoding="utf-8"))
        out = DATA_DIR / f"{locale}.json"
        out.write_text(json.dumps(entries, ensure_ascii=False, indent=2, sort_keys=True) + "\n", encoding="utf-8")
        print(f"Synced {len(entries)} keys to {out}")


if __name__ == "__main__":
    main()
