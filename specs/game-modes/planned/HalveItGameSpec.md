# Halve-It Game Specification

## 1. Purpose
Define Halve-It — descending target sequence with halve-on-miss scoring — for future implementation.

**Status:** Planned (`practice.halveIt`). R&D: [`FutureIdeas/party-practice-modes.md`](../../../FutureIdeas/party-practice-modes.md).
**Estimated release:** `TBD`

References: [darts501.com — Halve-it](https://darts501.com/Games.html).

---

## 2. Catalog metadata
| Field | Value |
|-------|-------|
| **Section** | Practice |
| **UI template** | F — Solo challenge |
| **Stat kind** | Solo score |
| **Ruleset (v1)** | `halve_it_curated_sequence` |

---

## Player count

| Question | Answer |
|----------|--------|
| **Solo?** | Yes — personal best after 6 rounds |
| **Minimum** | 1 participant |
| **Recommended** | 1 solo; 3–6 pub group |
| **App maximum** | 8 |

### Brainstorm
- Halve-It is commonly played solo (high score) **or** as a pub circle comparing totals after fixed rounds.
- `minimumPlayers: 1` — solo skips bot requirement; multiplayer needs no special floor beyond 2 for competition.
- **8** is fine: each round is one visit + halve check; scoreboard is a single column per player.
- Not `isSolo` in catalog (multiplayer allowed) unlike Bob's 27.

---

## 3. MVP Scope
- Starting score: **301** (configurable)
- **Curated 6-round sequence (v1):** 20, 19, 18, 17, 16, 15 (singles — any hit on segment counts segment face value summed for visit)
- Hit target in 3 darts → **add** visit score to running total
- Miss (zero on target) → **halve** running total (round down)
- After all rounds, **highest total wins** (multiplayer) or beat personal best (solo)
- Named ruleset locked in setup; link to house-rules doc
- Undo last round; local persistence

### Out of Scope (v1)
- Custom target picker, double/treble-only rounds (v2 `halve_it_advanced`)

---

## 4. Rules Engine (`HalveItEngine`)

### Config (`MatchConfigHalveIt`, payload v1)
| Field | Default |
|-------|---------|
| `startingScore` | `301` |
| `targetSequence` | `[20,19,18,17,16,15]` |

### State
- `roundIndex`, `total[playerId]`

### Turn flow
1. Sum scoring darts on current target segment.
2. If sum > 0, add to total; else total = total / 2 (integer halve).
3. Advance round; rank at end.

### Undo
Replay restores totals and round index.

---

## 5. UI Specification
- Template F: running total + current target prominently displayed
- Halve warning on miss visit

---

## How to Play

| | |
|---|---|
| **Key prefix** | `play.rules.halveIt.` |
| **Shipped in app** | Planned |
| **Estimated release** | `TBD` |

### Overview
| **Title key** | `play.rules.halveIt.overview.title` |
| **Body key** | `play.rules.halveIt.overview.body` |

Pressure scoring: hit the round's target and add points; miss entirely and your total is cut in half. Six rounds in the default sequence, then highest score wins.

### Starting score
| **Title key** | `play.rules.halveIt.start.title` |
| **Body key** | `play.rules.halveIt.start.body` |

Default start is 301 on the running total (configurable). Solo players chase personal best; groups compare finals after the same six targets.

### Each round
| **Title key** | `play.rules.halveIt.round.title` |
| **Body key** | `play.rules.halveIt.round.body` |

Default targets: 20, 19, 18, 17, 16, 15 in order. Throw three darts. Any hit on the segment adds the visit's scored value to your total. No hit on that segment halves your total (rounded down).

### Winning
| **Title key** | `play.rules.halveIt.winning.title` |
| **Body key** | `play.rules.halveIt.winning.body` |

After the last round, highest total wins. One bad miss late can collapse a lead — that's the point.

---

## Localization

| **Exists** | `modes.catalog.practice.halveIt.name`, `.blurb` |

### New keys

**Setup:** `play.halveIt.setup.startingScore`; `play.halveIt.setup.targetSequence` (display curated list)

**Gameplay:** `play.halveIt.navTitle`, `roundTargetFormat`, `visitScoreFormat`, `totalHalved`, `totalAdded`, `runningTotalFormat`, `finalScoreFormat`, `solo.personalBestFormat`, `announce.roundComplete`

**How to play:** `play.rules.halveIt.overview|start|round|winning`

**History:** `history.timeline.halveItRoundFormat`, `history.detail.halveItSummaryFormat`

---

## 6. Data Capture
- `HalveItRoundEvent`: `target`, `visitScore`, `halved`, `totalAfter`

---

## 7. Testing
- Unit: halve rounding, add path, sequence completion
- Multiplayer ranking

---

## 8. Verification
| Field | Value |
|-------|-------|
| **Status** | Planned |
