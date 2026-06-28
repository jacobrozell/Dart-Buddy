#!/usr/bin/env python3
"""Unified localization CLI for Dart Buddy.

Typical workflow after editing .strings or JSON:
  python3 Scripts/l10n.py export all          # .strings → JSON
  python3 Scripts/l10n.py patch-gaps          # apply gap_patch.json to JSON
  python3 Scripts/l10n.py generate all          # JSON → shipped .strings
  python3 Scripts/l10n.py audit                 # key parity check
"""
from __future__ import annotations

import argparse
import sys

import l10n_toolkit as tk


def add_locale_arg(parser: argparse.ArgumentParser, *, default: str = "all") -> None:
    parser.add_argument(
        "locale",
        nargs="?",
        default=default,
        help=f"Locale or 'all' (shipped: {', '.join(tk.SHIPPED_LOCALES)})",
    )


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    sub = parser.add_subparsers(dest="command", required=True)

    sub.add_parser("audit", help="Key parity, specifier, and leakage report")

    export_p = sub.add_parser("export", help="Export .strings into locale_data JSON")
    export_p.add_argument(
        "target",
        choices=["localizable", "gameplay", "all"],
        default="all",
        nargs="?",
    )
    add_locale_arg(export_p)

    sync_p = sub.add_parser("sync-json", help="Fill missing JSON keys from .strings")
    add_locale_arg(sync_p)

    merge_p = sub.add_parser("merge-backfill", help="Merge *_backfill.json shards into locale JSON")
    merge_p.add_argument(
        "locale",
        nargs="?",
        default="all",
        help="Locale or 'all' (de, es, nl, fr)",
    )

    gen_p = sub.add_parser("generate", help="Generate .strings from locale_data JSON")
    gen_p.add_argument(
        "target",
        choices=["localizable", "gameplay", "all"],
        default="all",
        nargs="?",
    )
    add_locale_arg(gen_p)

    gaps_p = sub.add_parser("patch-gaps", help="Apply locale_data/patches/gap_patch.json")
    gaps_p.add_argument(
        "--write",
        action="store_true",
        help="Regenerate shipped .strings after patching JSON",
    )

    qual_p = sub.add_parser("patch-quality", help="Apply gameplay/localizable quality patches")
    qual_p.add_argument(
        "--write",
        action="store_true",
        help="Regenerate affected .strings after patching JSON",
    )

    args = parser.parse_args()

    if args.command == "audit":
        return tk.audit()

    if args.command == "export":
        locales = tk.resolve_locales(None if args.locale == "all" else args.locale)
        include_en = args.locale == "all" and args.target in ("gameplay", "all")
        tk.export_all(target=args.target, locales=locales, include_en_gameplay=include_en)
        return 0

    if args.command == "sync-json":
        locales = tk.resolve_locales(None if args.locale == "all" else args.locale)
        for locale in locales:
            tk.sync_json_localizable(locale)
        return 0

    if args.command == "merge-backfill":
        locales = list(tk.BACKFILL_FILES) if args.locale == "all" else [args.locale]
        for locale in locales:
            tk.merge_backfill(locale)
        return 0

    if args.command == "generate":
        locales = tk.resolve_locales(None if args.locale == "all" else args.locale)
        tk.generate_all(target=args.target, locales=locales)
        return 0

    if args.command == "patch-gaps":
        tk.patch_gaps(write_strings=args.write)
        return 0

    if args.command == "patch-quality":
        tk.patch_quality(write_strings=args.write)
        return 0

    raise SystemExit(f"Unknown command: {args.command}")


if __name__ == "__main__":
    sys.exit(main())
