#!/usr/bin/env python3
"""Export Resources/{locale}.lproj/GameplayModes.strings to locale_data JSON."""
from __future__ import annotations

import json
import sys
from pathlib import Path

from localizable_strings import parse_entry_map

ROOT = Path(__file__).resolve().parents[1]
LOCALES = ("de", "es", "nl", "fr", "zh-Hans", "it")


def export(locale: str) -> None:
    source = ROOT / f"Resources/{locale}.lproj/GameplayModes.strings"
    entries = parse_entry_map(source.read_text(encoding="utf-8"))
    out = ROOT / f"Scripts/locale_data/{locale}_gameplay_modes.json"
    out.write_text(json.dumps(dict(sorted(entries.items())), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print(f"Exported {len(entries)} keys to {out}")


def main() -> None:
    locales = sys.argv[1:] if len(sys.argv) > 1 else LOCALES
    for locale in locales:
        export(locale)


if __name__ == "__main__":
    main()
