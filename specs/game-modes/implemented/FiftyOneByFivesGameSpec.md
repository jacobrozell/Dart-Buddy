# 51 By 5's Game Specification

## 1. Purpose
Define 51 By 5's (All Fives) — a divisibility-scoring race to 51 points — for future implementation.

**Status:** Shipped (`party.fiftyOneByFives`).
**Estimated release:** `1.3`

References: [Darts Corner — 51 By 5's](https://www.dartscorner.com/blogs/how-to/what-darts-games-can-you-play), [darts501.com — Fives](https://darts501.com/Games.html).

---

## 2. Catalog metadata
| Field | Value |
|-------|-------|
| **Section** | Party |
| **UI template** | A — Checkout score |
| **Stat kind** | Checkout |
| **Ruleset (v1)** | `fifty_one_by_fives_exact` |

---

## Player count

| Question | Answer |
|----------|--------|
| **Solo?** | No — race to 51 points against others |
| **Minimum** | 2 participants (≥1 human) |
| **Recommended** | 2–6 |
| **App maximum** | 8 |

### Brainstorm
- Solo could chase personal best to 51 but v1 is multiplayer race (All Fives pub game).
- Large groups (6–8) work because turns are one visit + divisibility check — no complex board state.
- Divisibility-by-5 teaching game: pairs and trios are most common.

---

## 3. MVP Scope
- Target score: **51 points** (race; not exact finish)
- Each visit: 3-dart total must be **divisible by 5** to score; round points = total ÷ 5
- Non-divisible visit scores **0**
- First player to reach **≥ 51** wins
- Optional: **exact 51** required (bust over 51 resets visit only — config `mustFinishExact`, default `false`)
- Total-entry; undo; local persistence

### Out of Scope (v1)
- Alternate targets (50, 100)

---

## 4. Rules Engine (`FiftyOneByFivesEngine`)

### Config (`MatchConfigFiftyOneByFives`, payload v1)
| Field | Default |
|-------|---------|
| `targetPoints` | `51` |
| `divisor` | `5` |
| `mustFinishExact` | `false` |

### State
- `points[playerId]`, `turnIndex`

### Turn flow
1. Compute visit total.
2. If total % 5 == 0, add total / 5 to player points.
3. Check win at ≥ target (or exact if configured).

### Undo
Replay restores point totals.

---

## 5. UI Specification
- Template A with **points** column and divisibility hint (“Total must divide by 5”)
- Show computed round points on submit

---

## How to Play

| | |
|---|---|
| **Key prefix** | `play.rules.fiftyOneByFives.` |
| **Shipped in app** | Yes |
| **Estimated release** | `1.3` |

### Overview
| **Title key** | `play.rules.fiftyOneByFives.overview.title` |
| **Body key** | `play.rules.fiftyOneByFives.overview.body` |

Also called All Fives. Throw three darts, add the total, and earn points only when that total divides evenly by five. First player to 51 points wins.

### Scoring visits
| **Title key** | `play.rules.fiftyOneByFives.scoring.title` |
| **Body key** | `play.rules.fiftyOneByFives.scoring.body` |

If your three-dart total is divisible by five, divide by five and add that to your score. Example: 60 points = 12 scored. If the total is not divisible by five, you score zero for that turn.

### Examples
| **Title key** | `play.rules.fiftyOneByFives.examples.title` |
| **Body key** | `play.rules.fiftyOneByFives.examples.body` |

45 → 9 points. 55 → 11 points. 58 → 0 points. Plan finishes that land on multiples of five.

### Winning
| **Title key** | `play.rules.fiftyOneByFives.winning.title` |
| **Body key** | `play.rules.fiftyOneByFives.winning.body` |

The first player to reach at least 51 points wins the game.

---

## Localization

| **Exists** | `modes.catalog.party.fiftyOneByFives.name`, `.blurb` |

### New keys

**Setup:** `play.party.fiftyOneByFives.title`, `.subtitle`; `play.fiftyOneByFives.setup.targetPoints` (default 51)

**Gameplay:** `play.fiftyOneByFives.navTitle`, `visitTotalFormat`, `pointsAwardedFormat`, `noPointsDivisibleHint`, `runningScoreFormat`, `targetReached`, `divisibleByFiveReminder`

**How to play:** `play.rules.fiftyOneByFives.overview|scoring|examples|winning`

**History:** `history.timeline.fiftyOneByFivesVisitFormat`, `history.detail.fiftyOneByFivesSummaryFormat`

**Validation:** `setup.validation.fiftyOneByFivesMinimumPlayers` (min 2)

---

## 6. Data Capture
- `FiftyOneByFivesVisitEvent`: `rawTotal`, `pointsAwarded`, `cumulativeAfter`

---

## 7. Testing
- Unit: divisibility gate, win detection, exact-finish variant
- Edge: 0 visit, 180 visit (36 points)

---

## 8. Verification
| Field | Value |
|-------|-------|
| **Status** | Planned |
