# Modes Tab Specification

## Purpose

Browse all 28 game modes (5 shipped + 23 planned), search the catalog, and quick-start into Play setup.

## Tab placement

`Play · Modes · Players · Activity · Settings` — see [`AppShellSpec.md`](AppShellSpec.md).

## Data source

[`Features/Modes/GameModeCatalog.swift`](../Features/Modes/GameModeCatalog.swift) is the single source of truth for catalog entries, sections, UI templates, and availability.

## Layout

- Title + search field
- Sections: Standard, Party, Co-op, Practice (display order from catalog)
- Each card: badge, title, blurb, player range, coming-soon badge when `status == .planned`
- Co-op section: amber catalog accent (`GameModeSection.coop`); see [`CoopPvEModesSpec.md`](CoopPvEModesSpec.md) §7.1
- iPad regular width: two-column card grid per section

## Behaviors

| Action | Result |
|--------|--------|
| Tap available card | `PendingModeSelection` enqueued → switch to Play tab → setup applies selection |
| Tap coming-soon card | No navigation; card is non-interactive |
| Learn rules (shipped modes) | Sheet with `GameRulesGuideView` — copy from spec § **How to Play** |
| Learn rules (planned co-op) | Same sheet once `play.rules.{mode}.*` keys + catalog hook land — see [`CoopPvEModesSpec.md`](CoopPvEModesSpec.md) §8 |
| Change mode (Play setup) | Switch to Modes tab |

## Out of scope (v1)

- Notify-me for planned modes
- Pinned/recent modes row

---

## Game mode families (planned addendum)

**Status:** Approved direction · not implemented  
**Full plan:** [`docs/plans/game-mode-families.md`](../docs/plans/game-mode-families.md)

Group related rulesets under **one catalog card** with a **variant sheet** on tap. Engines, `MatchType`, and persistence stay separate; family is browse/setup metadata only.

### Cricket marks family

One **Standard** card covers:

| Variant | `MatchType` | Notes |
|---------|-------------|-------|
| Standard Cricket | `.cricket` | Default. Cut Throat stays a **setup chip**, not a variant row |
| American Cricket | `.americanCricket` | |
| Mickey Mouse | `.mickeyMouse` | |

**Not in family:** Mulligan (standalone → **Practice**), English Cricket (standalone → **Party**; keep name; blurb alias *Wickets & Runs*).

### Catalog model (additive)

- `GameModeFamily` + `GameModeVariant` on `GameModeCatalogEntry`
- Family with multiple variants → one picker card; tap opens variant sheet
- `searchAliases` for mickey, american, wickets, runs, cut throat, etc.

### Behaviors (when implemented)

| Action | Result |
|--------|--------|
| Tap Cricket family card | Variant sheet → selection enqueues `PendingModeSelection` for chosen `MatchType` |
| Play setup header | `Cricket · {variant}` |
| Activity filter | Grouped: `Cricket ▸ Standard / American / Mickey Mouse` |
| App Intents | Unchanged — still target concrete `MatchType` (e.g. Start Mickey Mouse) |

### Supersedes

The earlier v1 note "Cricket variants collapsible section" is replaced by this family-card model (no duplicate listings, no separate collapsible section).

---

## Verification
| Field | Value |
|-------|--------|
| **Last verified** | 2026-06-11 |
| **Commit** | `340f788` |
| **Code** | `ModesRootView.swift`, `GameModeCatalog.swift` |
