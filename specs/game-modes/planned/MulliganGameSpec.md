# Mulligan Game Specification

## 1. Purpose
Define Mulligan — a random-target mark-closure party game — for future implementation.

**Status:** Planned (`party.mulligan`).

References: [Darts Corner — Mulligan](https://www.dartscorner.com/blogs/how-to/what-darts-games-can-you-play).

---

## 2. Catalog metadata
| Field | Value |
|-------|-------|
| **Section** | Party |
| **UI template** | B — Mark board |
| **Stat kind** | Marks |
| **Ruleset (v1)** | `mulligan_six_plus_bull` |

---

## Player count

| Question | Answer |
|----------|--------|
| **Solo?** | No — randomized target race needs opponents |
| **Minimum** | 2 participants (≥1 human) |
| **Recommended** | 2–4 |
| **App maximum** | 8 |

### Brainstorm
- Mulligan is Mickey Mouse with a random draw — same multiplayer requirement.
- RNG target list is shared; solo would be time-trial only (out of scope for v1).

---

## 3. MVP Scope
- At match start, draw **6 distinct segments** from 1–20 (seeded RNG for replay) + **bull** as final target
- Close each drawn target in order with 3 marks (S/D/T = 1/2/3)
- First player to close bull wins (race; no point scoring in v1)
- Show drawn target list in setup summary and play header
- Per-dart entry; undo; local persistence

### Out of Scope (v1)
- Treble-only Mulligan, re-draw on miss (“mulligan” house rule)

---

## 4. Rules Engine (`MulliganEngine`)

### Config (`MatchConfigMulligan`, payload v1)
| Field | Default |
|-------|---------|
| `targetCount` | `6` |
| `rngSeed` | UUID-derived (stored for replay) |

### State
- `targetSequence: [DartSegment]` (6 numbers + bull)
- `currentTargetIndex`, per-player marks on active target

### Turn flow
Same as Mickey Mouse race logic but on **randomized** sequence.

### Undo
Replay restores RNG-derived sequence and mark state.

---

## 5. UI Specification
- Template B with horizontal **drawn target chips** (current highlighted)
- Setup reveals sequence after start (or on first throw — product choice; default: visible at start)

---

## How to Play

| | |
|---|---|
| **Key prefix** | `play.rules.mulligan.` |
| **Shipped in app** | Planned |

### Overview
| **Title key** | `play.rules.mulligan.overview.title` |
| **Body key** | `play.rules.mulligan.overview.body` |

Mulligan is Mickey Mouse with a twist: six random segments are drawn at the start, then the bull. Close each drawn number in order before your opponents.

### The draw
| **Title key** | `play.rules.mulligan.draw.title` |
| **Body key** | `play.rules.mulligan.draw.body` |

At the beginning of the match the app picks six different numbers from 1–20. Everyone sees the list. You must close them in that order — no choosing your own path.

### Closing targets
| **Title key** | `play.rules.mulligan.closing.title` |
| **Body key** | `play.rules.mulligan.closing.body` |

Only the active drawn number counts. Three marks closes it (single 1, double 2, triple 3). When any player closes the active target, the group advances to the next draw. The bull is always last.

### Winning
| **Title key** | `play.rules.mulligan.winning.title` |
| **Body key** | `play.rules.mulligan.winning.body` |

First player to close the bull after the six drawn numbers wins.

---

## Localization

| **Exists** | `modes.catalog.party.mulligan.name`, `.blurb` |

### New keys

**Setup:** `play.party.mulligan.title`, `.subtitle`; `play.mulligan.title`

**Gameplay:** `play.mulligan.navTitle`, `drawnTargets.title`, `drawnTargets.listAccessibilityFormat`, `activeTargetFormat`, `pad.lockedTargetHint`, `pad.disabledWhileBot`, `targetAdvanced`, `announce.turnFormat`

**How to play:** `play.rules.mulligan.overview|draw|closing|winning`

**History:** `history.timeline.mulliganTurnFormat`, `history.detail.mulliganSummaryFormat` (include drawn sequence in detail subtitle)

**Errors:** `error.match.mulligan.invalidDraw` (RNG / empty targets)

---

## 6. Data Capture
- `MulliganTurnEvent` includes `targetSequence` hash or embedded list in match config payload

---

## 7. Testing
- Unit: RNG determinism from seed, closure order, win detection
- Setup: sequence length validation

---

## 8. Verification
| Field | Value |
|-------|-------|
| **Status** | Planned |
