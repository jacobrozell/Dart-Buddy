# Bob's 27 Game Specification

## 1. Purpose
Define Bob's 27 — solo doubles practice from 27 points — for future implementation.

**Status:** Planned (`practice.bobs27`). R&D: [`FutureIdeas/party-practice-modes.md`](../../../FutureIdeas/party-practice-modes.md).

References: [Target Darts — Bob's 27](https://www.target-darts.co.uk/dart-games), [darts501.com](https://darts501.com/Games.html).

---

## 2. Catalog metadata
| Field | Value |
|-------|-------|
| **Section** | Practice |
| **UI template** | F — Solo challenge |
| **Stat kind** | Solo score |
| **Ruleset (v1)** | `bobs27_standard` |

---

## Player count

| Question | Answer |
|----------|--------|
| **Solo?** | Yes — **only** supported shape |
| **Minimum** | 1 human |
| **Recommended** | 1 exactly |
| **App maximum** | 1 (`maximumPlayers: 1`; `isSolo: true`) |

### Brainstorm
- Bob's 27 is a doubles trainer: one score track, no opponent logic.
- Setup **skips roster** (`GameModeCatalogEntry.isSolo`) — auto-select single human or prompt pick one profile.
- Multiplayer “race the same doubles” is a different mode (out of scope); do not raise max above 1.

---

## 3. MVP Scope
- Start at **27 points**
- 21 rounds: **D1, D2, … D20, bull** (one target double per round)
- Hit intended double in 3 darts → **add** face value (D2 = +4)
- Miss all three → **subtract** that double's value
- Score ≤ 0 → game over
- Perfect score: **1437**
- Bull on miss: subtract **27** (confirm in implementation; document in rules sheet)
- Solo challenge layout; local best score; undo last round

### Out of Scope (v1)
- Multiplayer race variant

---

## 4. Rules Engine (`Bobs27Engine`)

### Config (`MatchConfigBobs27`, payload v1)
| Field | Default |
|-------|---------|
| `bullSubtract` | `27` |
| `gameOverAtZero` | `true` |

### State
- `roundIndex` (0…20), `score`, `isComplete`, `gameOver`

### Turn flow
1. Player throws 3 darts at current double (or bull).
2. Any hit on target → add value; else subtract.
3. Advance round; check game over.

### Undo
Replay restores round and score.

---

## 5. UI Specification
- Template F: large score + **"Double N"** round label
- Personal best on completion

---

## How to Play

| | |
|---|---|
| **Key prefix** | `play.rules.bobs27.` |
| **Shipped in app** | Planned |

### Overview
| **Title key** | `play.rules.bobs27.overview.title` |
| **Body key** | `play.rules.bobs27.overview.body` |

A solo doubles drill. Start at 27 points. Twenty-one rounds: double 1, double 2, … double 20, then bull. Perfect game scores 1,437.

### Hitting the target
| **Title key** | `play.rules.bobs27.hit.title` |
| **Body key** | `play.rules.bobs27.hit.body` |

Each round you throw three darts at the required double (or bull on the last round). Hit it at least once and add its face value — double 8 adds 16, and so on.

### Missing
| **Title key** | `play.rules.bobs27.miss.title` |
| **Body key** | `play.rules.bobs27.miss.body` |

Miss all three darts and subtract that double's value from your score. On bull round, subtract 27 if you miss entirely.

### Game over
| **Title key** | `play.rules.bobs27.gameOver.title` |
| **Body key** | `play.rules.bobs27.gameOver.body` |

If your score drops to zero or below, the game ends. Otherwise finish all rounds and keep your final score to compare against personal best.

---

## Localization

| **Exists** | `modes.catalog.practice.bobs27.name`, `.blurb` |

### New keys

**Setup:** `play.bobs27.title` (solo — no party picker); `modes.playerCount.solo` (Exists) for catalog card

**Gameplay:** `play.bobs27.navTitle`, `round.doubleFormat` / `round.bull`, `scoreFormat`, `pointsAddedFormat`, `pointsSubtractedFormat`, `gameOver`, `personalBestFormat`, `perfectGame` (1437), `announce.roundComplete`

**How to play:** `play.rules.bobs27.overview|hit|miss|gameOver`

**History:** `history.timeline.bobs27RoundFormat`, `history.detail.bobs27SummaryFormat`

**Errors:** `error.match.bobs27.gameOver` (submit after end)

---

## 6. Data Capture
- `Bobs27RoundEvent`: `target`, `hit`, `delta`, `scoreAfter`

---

## 7. Testing
- Unit: add/subtract paths, game over, perfect game math
- Bull subtract value

---

## 8. Verification
| Field | Value |
|-------|-------|
| **Status** | Planned |
