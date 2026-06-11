# Solo Practice Modes — Shared Specification

## 1. Purpose
Define **cross-mode contracts** for solo-only practice drills in Dart Buddy: catalog registration, setup (no roster), match lifecycle, summary screen, history, and statistics. Mode-specific rules stay in each `*GameSpec.md`; this doc is the shared platform.

**Status:** Planned — applies when first solo practice mode ships (Call & Hit target).

**Consumers (planned Practice section):**

| Mode | Catalog id | Template | Stat kind | Solo-only |
|------|------------|----------|-----------|-----------|
| Call & Hit | `practice.callAndHit` | J — Voice drill | `practiceAccuracy` | Yes |
| Bob's 27 | `practice.bobs27` | F — Solo challenge | `soloScore` | Yes |
| Halve-It | `practice.halveIt` | F — Solo challenge | `soloScore` | Yes |

**Solo-capable but not solo-only** (different contract — roster stays): X01 (`minimumPlayers: 1`), Around the Clock (`minimumPlayers: 1`, `maximumPlayers: 8`). Do not use this spec for those modes.

**Related:**
- [`MatchSummarySpec.md`](MatchSummarySpec.md) + [`SoloPracticeMatchSummarySupplement.md`](SoloPracticeMatchSummarySupplement.md)
- [`SetupFlowSpec.md`](SetupFlowSpec.md) §13
- [`HistorySpec.md`](HistorySpec.md)
- [`StatsSpec.md`](StatsSpec.md) §12
- [`ModesTabSpec.md`](ModesTabSpec.md)
- [`game-modes/planned/SoloPracticeCatalogStubGuide.md`](game-modes/planned/SoloPracticeCatalogStubGuide.md)

---

## 2. Definitions

| Term | Rule |
|------|------|
| **Solo-only** | `GameModeCatalogEntry.maximumPlayers == 1` → `isSolo == true` |
| **Solo-capable** | `minimumPlayers == 1` but `maximumPlayers > 1` — full roster setup |
| **Practice section** | `GameModeSection.practice` — browsed under Modes → Practice |
| **Honor-scored** | Player reports outcome; app does not validate darts (Call & Hit) |
| **Engine-scored** | App computes outcome from dart input (Bob's 27) |

---

## 3. Catalog contract

Every solo-only mode **must** satisfy:

| Field | Value |
|-------|-------|
| `section` | `.practice` |
| `minimumPlayers` | `1` |
| `maximumPlayers` | `1` |
| `isSolo` | `true` (derived) |
| `matchType` | `nil` while planned; set when shipped |
| `status` | `.planned` until engine ships |
| `playerCountLabel` | `modes.playerCount.solo` |

### Allowed UI templates (solo-only)

| Template | Use |
|----------|-----|
| `soloChallenge` (F) | Scored drills with dart pad — Bob's 27, Halve-It |
| `voiceDrill` (J) | Honor-scored callout drills — Call & Hit |

**Test contract:** [`GameModeCatalogEntryTests.onlySoloChallengeDrillsAreSinglePlayerCapped`](../../Tests/Unit/GameModeCatalogEntryTests.swift) must broaden to **`soloOnlyModesUseAllowedSoloTemplates`** — accept `.soloChallenge` **or** `.voiceDrill` when `isSolo`.

Copy-paste stub rows: [`SoloPracticeCatalogStubGuide.md`](game-modes/planned/SoloPracticeCatalogStubGuide.md).

---

## 4. Discovery & entry

| Surface | Solo-only v1 policy |
|---------|---------------------|
| Modes tab → Practice card | **Primary** entry for all solo practice modes |
| Play home quick action | Deferred |
| Player detail shortcut | Deferred |
| Lean Play setup picker | Optional teaser row when Practice section ships |

Tap available card → `PendingModeSelection` → Play setup with mode pre-selected ([`ModesTabSpec.md`](ModesTabSpec.md)).

---

## 5. Setup contract

Shared rules for all `isSolo` modes ([`SetupFlowSpec.md`](SetupFlowSpec.md) §13):

1. **Skip roster section** — no player list, no bot menu, no reorder.
2. **Require one human** — active profile auto-selected, or single-player picker sheet if none active.
3. **Mode-specific option chips** below preset row (each game spec owns fields).
4. **Sticky Start Match** — same chrome as multiplayer setup.
5. **Persist last config** — per-mode preferences (e.g. `CallAndHitSetupPreferences`, `Bobs27SetupPreferences`) or keyed fields on `SettingsRecord`.
6. **Practice again** from summary preloads prior match config.

Validation keys shared prefix: `setup.validation.solo.*` where generic; mode-specific under `setup.validation.{mode}.*`.

---

## 6. Match lifecycle

Follows [`MatchSpec.md`](MatchSpec.md) fully:

- One active match at a time
- `inProgress` → `completed` | `abandoned`
- Resume from Play home banner
- Abandoned excluded from History / Statistics
- Completed writes `historyCardPayload` at finish

**Winner:** always the sole human participant — but solo summary **does not use winner/trophy framing** (see summary supplement).

**Undo:** mode-specific — last target (Call & Hit), last round (Bob's 27), last dart (engine-scored with pad). Summary undo availability defined per game spec.

---

## 7. Match summary contract

Solo practice uses **`SoloPracticeSummaryShell`** — shared layout variant of [`MatchSummaryScreen`](../../Features/Play/Shared/MatchSummaryScreen.swift).

| Multiplayer summary | Solo practice summary |
|--------------------|------------------------|
| Winner card + trophy | **Performance hero** — accuracy %, final score, or completion time |
| Participant stat rows | **Single participant strip** (name + avatar, no "winner") |
| New Match | **Practice again** (prefill setup) + **Done** |
| View in History | Same |
| Undo last throw | Mode-specific label ("Undo last target") |

Full wireframes: [`SoloPracticeMatchSummarySupplement.md`](SoloPracticeMatchSummarySupplement.md).

---

## 8. History contract

Completed solo sessions appear in Activity → History identically to competitive matches:

- Mode badge from catalog id / `MatchType`
- Participant snapshot name
- **No winner line** — subtitle uses primary metric chip instead
- Detail timeline: mode-specific events (targets, rounds, segments)

Filter: Practice modes appear under mode filter when user has played them ([`HistorySpec.md`](HistorySpec.md) + [`full-game-catalog-ui.md`](../docs/full-game-catalog-ui.md) §6).

---

## 9. Statistics contract

Each solo mode declares its own `ModeStatKind` — never force into X01 average:

| Stat kind | Modes | Primary metric |
|-----------|-------|----------------|
| `practiceAccuracy` | Call & Hit | Hit % + streak |
| `soloScore` | Bob's 27, Halve-It | Final score vs personal best |
| `sequence` | Around the Clock (when solo) | Completion / time — **not** solo-only catalog |

Player detail shows per-mode block when ≥1 session exists. Statistics segment adds mode filter entry when data present.

Config **fingerprints** required when setup dimensions affect comparability (Call & Hit darts/target kind — see [`CallAndHitStatsSupplement.md`](game-modes/planned/CallAndHitStatsSupplement.md)).

---

## 10. Localization

Shared keys (new):

| Key | Use |
|-----|-----|
| `modes.playerCount.solo` | Catalog card (exists) |
| `modes.section.practice` | Section header |
| `matchSummary.solo.performanceTitle` | Summary hero section label |
| `matchSummary.solo.practiceAgain` | Primary CTA |
| `matchSummary.solo.done` | Secondary dismiss |
| `history.solo.noWinnerSubtitle` | List card subtitle pattern |

Mode-specific keys remain under `play.{mode}.*`.

---

## 11. Analytics

Inherit [`MatchSpec.md`](MatchSpec.md) lifecycle events. Solo practice adds no special winner payload. Mode-specific completion events per game spec (e.g. `call_and_hit_match_completed`).

---

## 12. Accessibility

- Summary performance hero: spoken value includes metric + mode name
- No color-only success/fail in solo summary
- Per-mode screen docs under `accessibility/wcag-2.1-aa/screens/`

---

## 13. Promotion checklist (any solo practice mode)

1. Add catalog row per [`SoloPracticeCatalogStubGuide.md`](game-modes/planned/SoloPracticeCatalogStubGuide.md)
2. Game spec in `game-modes/planned/` → `implemented/` when shipped
3. `MatchType` + `GameplayUITemplate` case if new template
4. `ModeStatKind` + reducer in `StatsService` if new kind
5. SwiftData events + migration ([`SwiftData.md`](SwiftData.md))
6. `SoloPracticeSummaryShell` mode content provider
7. History card builder branch
8. Setup chips + validation
9. `GameRulesCatalog` + How to Play keys
10. Feature flag + `ProductSurface.isMatchTypeReachable`
11. Update [`docs/feature-inventory.md`](../docs/feature-inventory.md)
12. Broaden catalog unit tests for solo template allowlist

---

## 14. Verification
| Field | Value |
|-------|--------|
| **Status** | Planned |
