"""Shared localization tooling for Dart Buddy (.strings ↔ JSON, audit, patches)."""
from __future__ import annotations

import json
import re
import sys
from pathlib import Path

from localizable_strings import format_entries, parse_entries, parse_entry_map

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS_DIR = ROOT / "Scripts"
DATA_DIR = SCRIPTS_DIR / "locale_data"
PATCHES_DIR = DATA_DIR / "patches"
NEUTRAL_KEYS_PATH = SCRIPTS_DIR / "locale_neutral_keys.json"

SHIPPED_LOCALES = ("de", "es", "nl", "fr", "zh-Hans", "it")
ALL_LOCALES = ("en", *SHIPPED_LOCALES)

EN_LOCALIZABLE = ROOT / "Resources/en.lproj/Localizable.strings"
EN_GAMEPLAY = ROOT / "Resources/en.lproj/GameplayModes.strings"

GAMEPLAY_HEADERS = {
    "de": "/* Gameplay mode strings — German */",
    "es": "/* Gameplay mode strings — Spanish */",
    "nl": "/* Gameplay mode strings — Dutch */",
    "fr": "/* Gameplay mode strings — French */",
    "zh-Hans": "/* Gameplay mode strings — Simplified Chinese */",
    "it": "/* Gameplay mode strings — Italian */",
}

BACKFILL_FILES: dict[str, list[str]] = {
    "de": ["de_backfill.json"],
    "es": ["es_backfill.json"],
    "nl": ["nl_backfill.json"],
    "fr": ["fr_backfill.json", "fr_backfill2.json"],
}

SPECIFIER = re.compile(r"%%|%(?:\d+\$)?[-+ 0#]*\d*(?:\.\d+)?(?:l{0,2}[diouxX]|[@fFgGeEcsp])")
ENTRY = re.compile(r'^"([^"]+)"\s*=\s*"(.*)";\s*$')
EMBEDDED_EN = re.compile(
    r"\b(Boss|Raid|Fleet|MVP|MPR|DartBot|HP|Bot|Strike|strike|Par|runs|wickets|Double|Single|Triple)\b"
)


def resolve_locales(selected: str | None, *, include_en: bool = False) -> tuple[str, ...]:
    pool = ALL_LOCALES if include_en else SHIPPED_LOCALES
    if selected is None or selected == "all":
        return pool
    if selected not in pool:
        raise SystemExit(f"Unknown locale '{selected}'. Choose from: all, {', '.join(pool)}")
    return (selected,)


def load_json(path: Path) -> dict[str, str]:
    return json.loads(path.read_text(encoding="utf-8"))


def save_json(path: Path, data: dict[str, str]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(
        json.dumps(dict(sorted(data.items())), ensure_ascii=False, indent=2) + "\n",
        encoding="utf-8",
    )


def localizable_json_path(locale: str) -> Path:
    return DATA_DIR / f"{locale}.json"


def gameplay_json_path(locale: str) -> Path:
    return DATA_DIR / f"{locale}_gameplay_modes.json"


def localizable_strings_path(locale: str) -> Path:
    return ROOT / f"Resources/{locale}.lproj/Localizable.strings"


def gameplay_strings_path(locale: str) -> Path:
    return ROOT / f"Resources/{locale}.lproj/GameplayModes.strings"


def parse_strings_raw(path: Path) -> dict[str, str]:
    return {m.group(1): m.group(2) for line in path.read_text(encoding="utf-8").splitlines() if (m := ENTRY.match(line))}


def specifiers(value: str) -> list[str]:
    return [m.group(0) for m in SPECIFIER.finditer(value)]


def load_patch(name: str) -> dict:
    return load_json(PATCHES_DIR / name)


# --- export ---


def export_localizable(locale: str) -> int:
    entries = parse_entry_map(localizable_strings_path(locale).read_text(encoding="utf-8"))
    save_json(localizable_json_path(locale), entries)
    print(f"Exported {len(entries)} Localizable keys → {localizable_json_path(locale).name}")
    return len(entries)


def export_gameplay(locale: str) -> int:
    entries = parse_entry_map(gameplay_strings_path(locale).read_text(encoding="utf-8"))
    save_json(gameplay_json_path(locale), entries)
    print(f"Exported {len(entries)} GameplayModes keys → {gameplay_json_path(locale).name}")
    return len(entries)


def export_all(*, target: str, locales: tuple[str, ...], include_en_gameplay: bool = False) -> None:
    if target in ("localizable", "all"):
        for locale in locales:
            if locale == "en":
                continue
            export_localizable(locale)
    if target in ("gameplay", "all"):
        gameplay_locales = locales
        if include_en_gameplay and "en" not in gameplay_locales:
            gameplay_locales = (*gameplay_locales, "en")
        for locale in gameplay_locales:
            export_gameplay(locale)


# --- sync-json (fill missing JSON keys from .strings) ---


def sync_json_localizable(locale: str) -> int:
    en_keys = {key for key, _ in parse_entries(EN_LOCALIZABLE.read_text(encoding="utf-8"))}
    strings_entries = parse_entry_map(localizable_strings_path(locale).read_text(encoding="utf-8"))
    data = load_json(localizable_json_path(locale))
    added = 0
    for key in en_keys:
        if key in data:
            continue
        if key not in strings_entries:
            raise SystemExit(f"{locale}: missing key in both JSON and .strings: {key}")
        data[key] = strings_entries[key]
        added += 1
    if added:
        save_json(localizable_json_path(locale), data)
    print(f"Synced {locale}.json (+{added} keys from Localizable.strings)")
    return added


# --- merge backfill ---


def merge_backfill(locale: str) -> None:
    target = localizable_json_path(locale)
    if not target.exists():
        raise SystemExit(f"Missing locale data: {target}")
    data = load_json(target)
    merged = 0
    for name in BACKFILL_FILES.get(locale, []):
        path = DATA_DIR / name
        if not path.exists():
            print(f"warning: skipping missing backfill {path}", file=sys.stderr)
            continue
        backfill = load_json(path)
        data.update(backfill)
        merged += len(backfill)
        print(f"Merged {len(backfill)} keys from {name}")
    save_json(target, data)
    print(f"Wrote {len(data)} keys to {target.name} ({merged} backfill entries applied)")


# --- generate ---


def generate_localizable(locale: str) -> None:
    en_entries = parse_entries(EN_LOCALIZABLE.read_text(encoding="utf-8"))
    translations = load_json(localizable_json_path(locale))
    missing = [key for key, _ in en_entries if key not in translations]
    if missing:
        sample = ", ".join(missing[:8])
        suffix = "…" if len(missing) > 8 else ""
        raise SystemExit(
            f"Missing {len(missing)} {locale} translations in {localizable_json_path(locale).name}: {sample}{suffix}"
        )
    extra = sorted(set(translations) - {key for key, _ in en_entries})
    if extra:
        print(
            f"warning: {len(extra)} unused {locale} translation(s) in JSON (not in English file)",
            file=sys.stderr,
        )
    localized_entries = [(key, translations[key]) for key, _ in en_entries]
    out_path = localizable_strings_path(locale)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text(format_entries(localized_entries), encoding="utf-8")
    print(f"Wrote {len(localized_entries)} keys to {out_path}")


def generate_gameplay(locale: str) -> None:
    translations = load_json(gameplay_json_path(locale))
    en_entries = parse_entries(EN_GAMEPLAY.read_text(encoding="utf-8"))
    missing = [key for key, _ in en_entries if key not in translations]
    if missing:
        raise SystemExit(
            f"Missing translations for {locale}: {missing[:8]}{'…' if len(missing) > 8 else ''}"
        )
    localized_entries = [(key, translations[key]) for key, _ in en_entries]
    lines = ["", GAMEPLAY_HEADERS[locale], ""]
    lines.extend(format_entries(localized_entries).splitlines())
    lines.append("")
    out_path = gameplay_strings_path(locale)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    out_path.write_text("\n".join(lines), encoding="utf-8")
    print(f"Wrote {out_path} ({len(localized_entries)} keys)")


def generate_all(*, target: str, locales: tuple[str, ...]) -> None:
    if target in ("localizable", "all"):
        for locale in locales:
            generate_localizable(locale)
    if target in ("gameplay", "all"):
        for locale in locales:
            generate_gameplay(locale)


# --- patch gaps ---


def build_mode_error_entries(locale: str, gameplay: dict[str, str], patch: dict) -> dict[str, str]:
    templates = patch["mode_error_templates"][locale]
    entries: dict[str, str] = {}
    for mode_prefix, title_key in patch["mode_title_keys"].items():
        mode_name = gameplay.get(title_key, mode_prefix)
        entries[f"{mode_prefix}.error.sessionMissing"] = templates["sessionMissing"].format(mode=mode_name)
        entries[f"{mode_prefix}.error.invalidTurn"] = templates["invalidTurn"].format(mode=mode_name)
        entries[f"{mode_prefix}.error.undoFailed"] = templates["undoFailed"].format(mode=mode_name)
    return entries


def upsert_strings_file(path: Path, new_entries: dict[str, str], *, marker: str) -> int:
    existing = parse_entry_map(path.read_text(encoding="utf-8"))
    added_entries = {k: v for k, v in new_entries.items() if k not in existing}
    if not added_entries:
        return 0
    text = path.read_text(encoding="utf-8")
    if not text.endswith("\n"):
        text += "\n"
    block = format_entries(list(added_entries.items())).rstrip("\n")
    text += f"\n{marker}\n{block}\n"
    path.write_text(text, encoding="utf-8")
    return len(added_entries)


def merge_into_json(path: Path, updates: dict[str, str]) -> int:
    data = load_json(path) if path.exists() else {}
    added = 0
    for key, value in updates.items():
        if key not in data:
            added += 1
        data[key] = value
    save_json(path, data)
    return added


def patch_gaps(*, write_strings: bool = False) -> None:
    patch = load_patch("gap_patch.json")
    total_gameplay = 0
    total_localizable = 0

    for locale in ALL_LOCALES:
        gameplay = parse_entry_map(gameplay_strings_path(locale).read_text(encoding="utf-8"))
        error_entries = build_mode_error_entries(locale, gameplay, patch)
        overrides = patch.get("gameplay_overrides", {}).get(locale, {})
        error_entries.update(overrides)

        if locale == "en":
            total_gameplay += upsert_strings_file(
                gameplay_strings_path(locale),
                error_entries,
                marker="/* Localization gap patch */",
            )
            continue

        path = gameplay_json_path(locale)
        before = len(load_json(path)) if path.exists() else 0
        merge_into_json(path, error_entries)
        after = len(load_json(path))
        total_gameplay += max(0, after - before)

        if locale in patch.get("localizable_backfill", {}):
            loc_path = localizable_json_path(locale)
            before = len(load_json(loc_path))
            merge_into_json(loc_path, patch["localizable_backfill"][locale])
            after = len(load_json(loc_path))
            total_localizable += max(0, after - before)

    print(f"Patched {total_gameplay} GameplayModes keys across JSON (+ en .strings)")
    print(f"Patched {total_localizable} Localizable keys across JSON")

    if write_strings:
        generate_all(target="all", locales=SHIPPED_LOCALES)


# --- patch quality ---


def patch_quality(*, write_strings: bool = False) -> None:
    gameplay_fixes = load_patch("gameplay_quality.json")
    localizable_fixes = load_patch("localizable_quality.json")
    touched_gameplay: set[str] = set()

    for locale, fixes in gameplay_fixes.items():
        path = gameplay_json_path(locale)
        if not path.exists():
            print(f"warning: skipping missing {path.name}", file=sys.stderr)
            continue
        data = load_json(path)
        updated = sum(1 for key, value in fixes.items() if data.get(key) != value)
        if updated:
            data.update(fixes)
            save_json(path, data)
            print(f"Updated {path.name} ({updated} fixes)")
            touched_gameplay.add(locale)

    for locale, fixes in localizable_fixes.items():
        path = localizable_json_path(locale)
        data = load_json(path)
        data.update(fixes)
        save_json(path, data)
        print(f"Updated {path.name} ({len(fixes)} Localizable fixes)")

    if write_strings:
        if touched_gameplay:
            for locale in sorted(touched_gameplay):
                generate_gameplay(locale)
        if localizable_fixes:
            generate_all(target="localizable", locales=tuple(localizable_fixes))


# --- audit ---


def audit() -> int:
    neutral = load_json(NEUTRAL_KEYS_PATH)
    neutral_loc = set(neutral["localizable"])
    neutral_gm = set(neutral["gameplayModes"])

    en_loc = parse_strings_raw(EN_LOCALIZABLE)
    en_gm = parse_strings_raw(EN_GAMEPLAY)
    rules_keys = [k for k in en_loc if k.startswith("play.rules.")]

    failures: list[str] = []
    print("locale | loc keys | gm keys | loc==en* | gm==en* | rules en | embed loc | embed gm")
    print("* excluding documented neutral keys")

    for locale in SHIPPED_LOCALES:
        loc = parse_strings_raw(localizable_strings_path(locale))
        gm = parse_strings_raw(gameplay_strings_path(locale))

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
