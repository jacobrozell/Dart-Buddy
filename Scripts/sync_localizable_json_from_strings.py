#!/usr/bin/env python3
"""Copy missing Localizable.strings values into locale_data JSON (strings → JSON sync)."""

from __future__ import annotations

import json
import sys
from pathlib import Path

from localizable_strings import parse_entries

ROOT = Path(__file__).resolve().parents[1]
DATA_DIR = ROOT / "Scripts/locale_data"
EN_PATH = ROOT / "Resources/en.lproj/Localizable.strings"
LOCALES = ("de", "es", "nl", "fr", "zh-Hans", "it")


def sync_locale(locale: str) -> int:
    en_entries = parse_entries(EN_PATH.read_text(encoding="utf-8"))
    en_keys = {key for key, _ in en_entries}

    strings_path = ROOT / f"Resources/{locale}.lproj/Localizable.strings"
    strings_entries = dict(parse_entries(strings_path.read_text(encoding="utf-8")))

    json_path = DATA_DIR / f"{locale}.json"
    data = json.loads(json_path.read_text(encoding="utf-8"))

    added = 0
    for key in en_keys:
        if key in data:
            continue
        if key not in strings_entries:
            raise SystemExit(f"{locale}: missing key in both JSON and .strings: {key}")
        data[key] = strings_entries[key]
        added += 1

    json_path.write_text(json.dumps(dict(sorted(data.items())), ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    return added


def main() -> None:
    locales = sys.argv[1:] if len(sys.argv) > 1 else LOCALES
    for locale in locales:
        added = sync_locale(locale)
        print(f"Updated {locale}.json (+{added} keys from Localizable.strings)")


if __name__ == "__main__":
    main()
