#!/usr/bin/env python3
"""Audit shipped locales for key parity, rules coverage, and English leakage."""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
LOCALES = ("de", "es", "nl", "fr", "zh-Hans", "it")
SPECIFIER = re.compile(r"%%|%(?:\d+\$)?[-+ 0#]*\d*(?:\.\d+)?(?:l{0,2}[diouxX]|[@fFgGeEcsp])")
ENTRY = re.compile(r'^"([^"]+)"\s*=\s*"(.*)";\s*$')
EMBEDDED_EN = re.compile(
    r"\b(Boss|Raid|Fleet|MVP|MPR|DartBot|HP|Bot|Strike|strike|Par|runs|wickets|Double|Single|Triple)\b"
)


def parse_strings(path: Path) -> dict[str, str]:
    return {m.group(1): m.group(2) for line in path.read_text(encoding="utf-8").splitlines() if (m := ENTRY.match(line))}


def specifiers(value: str) -> list[str]:
    return [m.group(0) for m in SPECIFIER.finditer(value)]


def main() -> int:
    neutral = json.loads((ROOT / "Scripts/locale_neutral_keys.json").read_text(encoding="utf-8"))
    neutral_loc = set(neutral["localizable"])
    neutral_gm = set(neutral["gameplayModes"])

    en_loc = parse_strings(ROOT / "Resources/en.lproj/Localizable.strings")
    en_gm = parse_strings(ROOT / "Resources/en.lproj/GameplayModes.strings")
    rules_keys = [k for k in en_loc if k.startswith("play.rules.")]

    failures: list[str] = []
    print("locale | loc keys | gm keys | loc==en* | gm==en* | rules en | embed loc | embed gm")
    print("* excluding documented neutral keys")

    for locale in LOCALES:
        loc = parse_strings(ROOT / f"Resources/{locale}.lproj/Localizable.strings")
        gm = parse_strings(ROOT / f"Resources/{locale}.lproj/GameplayModes.strings")

        if set(loc) != set(en_loc):
            failures.append(f"{locale}: Localizable key set mismatch")
        if set(gm) != set(en_gm):
            failures.append(f"{locale}: GameplayModes key set mismatch")

        for key, en_value in en_loc.items():
            if key not in loc:
                continue
            if specifiers(en_value) != specifiers(loc[key]):
                failures.append(f"{locale}: specifier mismatch for {key}")

        loc_same = sum(1 for k in en_loc if k not in neutral_loc and loc.get(k) == en_loc[k])
        gm_same = sum(1 for k in en_gm if k not in neutral_gm and gm.get(k) == en_gm[k])
        rules_en = sum(1 for k in rules_keys if loc.get(k) == en_loc[k])
        embed_loc = sum(1 for v in loc.values() if EMBEDDED_EN.search(v))
        embed_gm = sum(1 for v in gm.values() if EMBEDDED_EN.search(v))

        print(
            f"{locale:7}| {len(loc):8} | {len(gm):7} | {loc_same:8} | {gm_same:7} | "
            f"{rules_en:8} | {embed_loc:9} | {embed_gm:8}"
        )

        if rules_en > 10:
            failures.append(f"{locale}: {rules_en} play.rules.* keys still English")

    print()
    if failures:
        print("FAILURES:")
        for item in failures:
            print(f"  - {item}")
        return 1

    print("All locales pass structural audit.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
