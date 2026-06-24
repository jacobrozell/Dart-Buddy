# Around the Clock Game Specification

## 1. Purpose
Define Around the Clock — hit segments 1 through 20 in order — for future implementation.

**Status:** Shipped (`practice.aroundTheClock`). R&D: [`FutureIdeas/party-practice-modes.md`](../../../FutureIdeas/party-practice-modes.md).
**Estimated release:** `1.4`

**In-visit progression:** [`InVisitSequenceProgressionSupplement.md`](../InVisitSequenceProgressionSupplement.md) (reference implementation).

References: [darts501.com — Around the Clock](https://darts501.com/Games.html).

---

## 2. Catalog metadata
| Field | Value |
|-------|-------|
| **Section** | Practice |
| **UI template** | E — Sequence progress |
| **Stat kind** | Sequence |
| **Ruleset (v1)** | `around_the_clock_standard` |

---

## Player count

| Question | Answer |
|----------|--------|
| **Solo?** | Yes — primary practice use (time/darts to finish) |
| **Minimum** | 1 participant (human only OK; skip roster friction via `minimumPlayers: 1`) |
| **Recommended** | 1 solo; 2–4 for head-to-head race |
| **App maximum** | 8 |

### Brainstorm
- Classic pub ATC works solo or as a race — both are first-class.
- Multiplayer: first to bull wins; **2–4** is ideal, **8** is long but valid.
- `isSolo` is false in catalog (multiplayer-capable) even though solo is common — setup allows 1 player without bot.
- Reset-policy variants matter more at 2+ than solo.

---

## 3. MVP Scope
- Targets **1 → 20** in order; optional **bull finish** (setup chip)
- 3 darts per turn; **each hit** on the current target advances to the next target for the rest of the visit
- Solo: track time / dart count to finish; multiplayer: first to finish wins
- Reset policy (setup): `noReset` (default), `resetOnThreeMisses`, `resetEntireSequence`
- Sequence progress strip; per-dart entry; undo; local persistence

### Out of Scope (v1)
- Doubles-only ATC

---

## 4. Rules Engine (`AroundTheClockEngine`)

### Config (`MatchConfigAroundTheClock`, payload v1)
| Field | Default |
|-------|---------|
| `includeBullFinish` | `false` |
| `resetPolicy` | `noReset` |

### State
- `targetIndex[playerId]` (0 = segment 1)
- `missCountThisTurn` for reset policies

### Turn flow
1. Process darts in order; each hit on the **current** target advances index by one (see supplement §3).
2. Apply reset policy at end of visit when no advance occurred.
3. Win when index passes 20 (and bull if enabled).

### Undo
Replay restores indices.

---

## 5. UI Specification
- Template E: chip trail 1–20 (+ bull)
- Solo stats: darts thrown, elapsed time
- Scoring pad: [`InVisitSequenceProgressionSupplement.md`](../InVisitSequenceProgressionSupplement.md) §4 — `lockedSegment` projects through `enteredDarts`; `scoringSegmentsDisabled` after sequence complete mid-visit

---

## How to Play

| | |
|---|---|
| **Key prefix** | `play.rules.aroundTheClock.` |
| **Shipped in app** | Yes |
| **Estimated release** | `1.4` |

### Overview
| **Title key** | `play.rules.aroundTheClock.overview.title` |
| **Body key** | `play.rules.aroundTheClock.overview.body` |

Hit every number in order from 1 through 20, then optionally the bull. Three darts per turn. Each dart that hits the current target moves you to the next number for the rest of the visit — you can hit 1, 2, and 3 on the same turn.

### Solo play
| **Title key** | `play.rules.aroundTheClock.solo.title` |
| **Body key** | `play.rules.aroundTheClock.solo.body` |

Practice alone and track how many darts or how long it takes to finish. Great for accuracy training.

### Multiplayer
| **Title key** | `play.rules.aroundTheClock.multiplayer.title` |
| **Body key** | `play.rules.aroundTheClock.multiplayer.body` |

Players take turns. Everyone maintains their own position on the sequence. First to complete 1–20 (and bull if enabled) wins.

### Reset rules
| **Title key** | `play.rules.aroundTheClock.reset.title` |
| **Body key** | `play.rules.aroundTheClock.reset.body` |

Choose in setup: no reset (default), reset after three misses on the same target, or reset entire progress on a bad visit. House rules vary — pick what your group uses.

---

## Localization

| **Exists** | `modes.catalog.practice.aroundTheClock.name`, `.blurb` |

### New keys

**Setup:** `play.practice.aroundTheClock.title` (or `play.aroundTheClock.title`); `play.aroundTheClock.setup.includeBullFinish`; `play.aroundTheClock.setup.resetPolicy` + `resetPolicy.noReset` / `resetOnThreeMisses` / `resetEntireSequence`

**Gameplay:** `play.aroundTheClock.navTitle`, `currentTargetFormat`, `sequenceProgressFormat`, `targetAdvanced`, `progressReset`, `solo.dartCountFormat`, `solo.elapsedTimeFormat`, `bullFinishEnabled`, `announce.complete`

**How to play:** `play.rules.aroundTheClock.overview|solo|multiplayer|reset`

**History:** `history.timeline.aroundTheClockVisitFormat`, `history.detail.aroundTheClockSummaryFormat`

**Validation:** min 1 player — reuse generic minimum or `setup.validation.soloModeRequiresOnePlayer`

---

## 6. Data Capture
- `AroundTheClockVisitEvent`: `targetBefore`, `targetAfter`, `resetApplied`

---

## 7. Testing
- Unit: advance on hit, **multi-hit visit** (`hit(1), hit(2), hit(3)`), reset policies, bull finish
- View model: `lockedSegment` advances during `enteredDarts` entry
- Solo vs multiplayer win

---

## 8. Verification
| Field | Value |
|-------|-------|
| **Status** | Shipped |
