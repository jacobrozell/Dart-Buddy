#!/usr/bin/env python3
"""Generate a locale Localizable.strings file from English keys and locale JSON data."""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from localizable_strings import format_entries, parse_entries

ROOT = Path(__file__).resolve().parents[1]
EN_PATH = ROOT / "Resources/en.lproj/Localizable.strings"
DATA_DIR = ROOT / "Scripts/locale_data"
SUPPORTED_LOCALES = ("de", "es", "nl", "zh-Hans")


def load_translations(locale: str) -> dict[str, str]:
    path = DATA_DIR / f"{locale}.json"
    if not path.exists():
        raise SystemExit(f"Missing translation data: {path}")
    return json.loads(path.read_text(encoding="utf-8"))


def generate(locale: str) -> None:
    if locale not in SUPPORTED_LOCALES:
        raise SystemExit(f"Unsupported locale '{locale}'. Choose from: {', '.join(SUPPORTED_LOCALES)}")

    en_entries = parse_entries(EN_PATH.read_text(encoding="utf-8"))
    translations = load_translations(locale)

    missing = [key for key, _ in en_entries if key not in translations]
    if missing:
        sample = ", ".join(missing[:8])
        suffix = "…" if len(missing) > 8 else ""
        raise SystemExit(
            f"Missing {len(missing)} {locale} translations in {DATA_DIR / f'{locale}.json'}: {sample}{suffix}"
        )

    extra = sorted(set(translations) - {key for key, _ in en_entries})
    if extra:
        print(
            f"warning: {len(extra)} unused {locale} translation(s) in JSON (not in English file)",
            file=sys.stderr,
        )

    out_path = ROOT / f"Resources/{locale}.lproj/Localizable.strings"
    localized_entries = [(key, translations[key]) for key, _ in en_entries]
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(format_entries(localized_entries), encoding="utf-8")
    print(f"Wrote {len(localized_entries)} keys to {out_path}")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "locale",
        nargs="?",
        choices=[*SUPPORTED_LOCALES, "all"],
        default="all",
        help="Locale to generate (default: all shipped locales)",
    )
    args = parser.parse_args()

    locales = SUPPORTED_LOCALES if args.locale == "all" else (args.locale,)
    for locale in locales:
        generate(locale)


if __name__ == "__main__":
    main()
