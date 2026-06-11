# Nine Lives Game Specification

## 1. Purpose
Define Nine Lives — around-the-clock with lives lost on a scoreless visit — for future implementation.

**Status:** Planned (`practice.nineLives`).

References: [darts501.com — Nine Lives](https://darts501.com/Games.html), [Darts Corner](https://www.dartscorner.com/blogs/how-to/what-darts-games-can-you-play).

---

## 2. Catalog metadata
| Field | Value |
|-------|-------|
| **Section** | Practice |
| **UI template** | D — Lives elimination |
| **Stat kind** | Lives |
| **Ruleset (v1)** | `nine_lives_nine_lives` |

---

## Player count

| Question | Answer |
|----------|--------|
| **Solo?** | No — lives elimination around the clock needs rivals |
| **Minimum** | 2 participants (≥1 human) |
| **Recommended** | 3–6 |
| **App maximum** | 8 |

### Brainstorm
- ATC with lives lost on blank visits — meaningless without others to outlast.
- Source rules disagree on 3 vs 9 starting lives; multiplayer either way needs **2+**.
- Gets long with **8** players (everyone must progress 1–20) — spec allows it; recommend 3–6 in setup copy.
- Catalog `minimumPlayers: 2`.

---

## 3. MVP Scope
- Progress **1 → 20** in order (bull optional v2)
- Each player starts with **9 lives** (Darts Corner) — alt ruleset `three_lives` for 3 lives (darts501)
- 3 darts per turn; must advance at least once or lose **1 life**
- Last standing wins; or most lives when first player completes 20
- Lives + sequence UI; undo; local persistence

### Out of Scope (v1)
- Reset entire sequence on life loss

---

## 4. Rules Engine (`NineLivesEngine`)

### Config (`MatchConfigNineLives`, payload v1)
| Field | Default |
|-------|---------|
| `startingLives` | `9` |
| `winCondition` | `.lastStanding` |

### State
- `targetIndex[playerId]`, `lives[playerId]`, `eliminated`

### Turn flow
1. Player throws 3 darts at current target onward.
2. If index unchanged after visit, decrement life.
3. Eliminate at 0 lives; check win.

### Undo
Replay restores lives and indices.

---

## 5. UI Specification
- Template D + sequence strip (hybrid)
- Lives displayed as numeric + icon (not color-only)

---

## How to Play

| | |
|---|---|
| **Key prefix** | `play.rules.nineLives.` |
| **Shipped in app** | Planned |

### Overview
| **Title key** | `play.rules.nineLives.overview.title` |
| **Body key** | `play.rules.nineLives.overview.body` |

Around the clock with lives. Progress from 1 to 20 in order. Fail to advance on a visit and lose a life. Default nine lives; last standing or first to finish wins.

### Progress
| **Title key** | `play.rules.nineLives.progress.title` |
| **Body key** | `play.rules.nineLives.progress.body` |

Hit the current target (any single, double, or triple on that number) and move to the next. You must hit in sequence — 1, then 2, then 3, and so on.

### Losing lives
| **Title key** | `play.rules.nineLives.lives.title` |
| **Body key** | `play.rules.nineLives.lives.body` |

Throw three darts without advancing and you lose one life. At zero lives you're eliminated.

### Winning
| **Title key** | `play.rules.nineLives.winning.title` |
| **Body key** | `play.rules.nineLives.winning.body` |

Win by completing 20 while still alive, or by being the last player with lives when others are out.

---

## Localization

| **Exists** | `modes.catalog.practice.nineLives.name`, `.blurb` |

### New keys

**Setup:** `play.nineLives.setup.startingLives` (9 default); `play.nineLives.setup.winCondition`

**Gameplay:** `play.nineLives.navTitle`, `livesRemainingFormat`, `lifeLost`, `targetProgressFormat`, `playerEliminated`, `advancedToNext`, `announce.noAdvance`

**How to play:** `play.rules.nineLives.overview|progress|lives|winning`

**History:** `history.timeline.nineLivesVisitFormat`, `history.detail.nineLivesSummaryFormat`

**Validation:** `setup.validation.nineLivesMinimumPlayers` (min 2)

---

## 6. Data Capture
- `NineLivesVisitEvent`: `advanced`, `lifeLost`, `targetAfter`

---

## 7. Testing
- Unit: life loss on no advance, elimination, completion race

---

## 8. Verification
| Field | Value |
|-------|-------|
| **Status** | Planned |
