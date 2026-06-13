# 180 Around the Clock Game Specification

## 1. Purpose
Define 180 Around the Clock — treble-focused scoring around 1–20 — for future implementation.

**Status:** Shipped (`practice.aroundTheClock180`).
**Estimated release:** `1.4`

References: [darts501.com — 180 Around the Clock](https://darts501.com/Games.html).

---

## 2. Catalog metadata
| Field | Value |
|-------|-------|
| **Section** | Practice |
| **UI template** | E — Sequence progress |
| **Stat kind** | Sequence |
| **Ruleset (v1)** | `atc180_treble_scoring` |

---

## Player count

| Question | Answer |
|----------|--------|
| **Solo?** | Yes — beat par / personal best (primary design intent) |
| **Minimum** | 1 participant |
| **Recommended** | 1 solo; 2–4 for highest-total competition |
| **App maximum** | 8 |

### Brainstorm
- Source material emphasizes solo improvement bands (60–180 point scale).
- Multiplayer is “highest total after 20 numbers” — works 2–8 but is a side mode.
- Solo uses Template F-style challenge layout when `playerCount == 1`.

---

## 3. MVP Scope
- For each number 1→20: throw 3 darts aiming **treble**
- Scoring per dart on current number: **treble = 3**, **single = 1**, **double = 1** (poor throw), miss = 0
- After 3 darts, advance to next number regardless
- **Solo:** maximize total (perfect = 180); optional par target (60/75/80)
- **Multiplayer:** highest total after 20 numbers wins
- Sequence strip + running score; undo; local persistence

### Out of Scope (v1)
- Stay-on-number-until-hit variant

---

## 4. Rules Engine (`AroundTheClock180Engine`)

### Config (`MatchConfigAroundTheClock180`, payload v1)
| Field | Default |
|-------|---------|
| `parScore` | `nil` (solo challenge optional) |

### State
- `numberIndex` (1…20), `totalScore[playerId]`

### Turn flow
1. Score 3 darts on current number using scoring table.
2. Advance number; after 20, match complete.

### Undo
Replay restores index and totals.

---

## 5. UI Specification
- Template E + large **running total** (solo challenge layout when 1 player)
- Performance band hints optional (informational only)

---

## How to Play

| | |
|---|---|
| **Key prefix** | `play.rules.aroundTheClock180.` |
| **Shipped in app** | Yes |
| **Estimated release** | `1.4` |

### Overview
| **Title key** | `play.rules.aroundTheClock180.overview.title` |
| **Body key** | `play.rules.aroundTheClock180.overview.body` |

Not about scoring a 180 checkout — it's treble practice around the board. For each number 1–20 you throw three darts aiming at the treble, score points, then move on.

### Scoring each number
| **Title key** | `play.rules.aroundTheClock180.scoring.title` |
| **Body key** | `play.rules.aroundTheClock180.scoring.body` |

Treble = 3 points. Single = 1 point. Double = 1 point (considered a poor throw). Miss = 0. After three darts you always advance to the next number.

### Solo challenge
| **Title key** | `play.rules.aroundTheClock180.solo.title` |
| **Body key** | `play.rules.aroundTheClock180.solo.body` |

Maximum score is 180 (three trebles on every number). Set a personal par — 60 is beginner-friendly, 80+ is strong club level — and try to beat it each session.

### Head-to-head
| **Title key** | `play.rules.aroundTheClock180.headToHead.title` |
| **Body key** | `play.rules.aroundTheClock180.headToHead.body` |

After all twenty numbers, highest total wins. Ties can share the win or play a bull tie-break (future option).

---

## Localization

| **Exists** | `modes.catalog.practice.aroundTheClock180.name`, `.blurb` |

### New keys

**Setup:** `play.aroundTheClock180.setup.parScore` (optional solo target)

**Gameplay:** `play.aroundTheClock180.navTitle`, `numberIndexFormat`, `visitPointsFormat`, `treblePoints` / `singlePoints` / `doublePoorThrow`, `runningTotalFormat`, `personalBestFormat`, `performanceBand.*` (optional info labels), `announce.numberComplete`

**How to play:** `play.rules.aroundTheClock180.overview|scoring|solo|headToHead`

**History:** `history.timeline.atc180NumberFormat`, `history.detail.atc180SummaryFormat`

---

## 6. Data Capture
- `ATC180NumberEvent`: `number`, `dartScores[3]`, `visitTotal`

---

## 7. Testing
- Unit: scoring table, 180 max, multiplayer compare

---

## 8. Verification
| Field | Value |
|-------|-------|
| **Status** | Planned |
