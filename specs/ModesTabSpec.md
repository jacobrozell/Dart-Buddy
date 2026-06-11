# Modes Tab Specification

## Purpose

Browse all 28 game modes (5 shipped + 23 planned), search the catalog, and quick-start into Play setup.

## Tab placement

`Play · Modes · Players · Activity · Settings` — see [`AppShellSpec.md`](AppShellSpec.md).

## Data source

[`Features/Modes/GameModeCatalog.swift`](../Features/Modes/GameModeCatalog.swift) is the single source of truth for catalog entries, sections, UI templates, and availability.

## Layout

- Title + search field
- Sections: Standard, Party, Practice (display order from catalog)
- Each card: badge, title, blurb, player range, coming-soon badge when `status == .planned`
- iPad regular width: two-column card grid per section

## Behaviors

| Action | Result |
|--------|--------|
| Tap available card | `PendingModeSelection` enqueued → switch to Play tab → setup applies selection |
| Tap coming-soon card | No navigation; card is non-interactive |
| Learn rules (shipped modes) | Sheet with `GameRulesGuideView` — copy from spec § **How to Play** |
| Change mode (Play setup) | Switch to Modes tab |

## Out of scope (v1)

- Notify-me for planned modes
- Pinned/recent modes row
- Cricket variants collapsible section (American Cricket listed under Standard)
