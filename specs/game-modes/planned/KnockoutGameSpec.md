# Knockout Game Specification

## 1. Purpose
Define Knockout — a beat-the-leader scoring elimination party game — for future implementation.

**Status:** Planned (`party.knockout`).

References: [darts501.com — Knockout](https://darts501.com/Games.html).

---

## 2. Catalog metadata
| Field | Value |
|-------|-------|
| **Section** | Party |
| **UI template** | A — Checkout score |
| **Stat kind** | Checkout |
| **Ruleset (v1)** | `knockout_three_strikes` |

---

## Player count

| Question | Answer |
|----------|--------|
| **Solo?** | No — must beat another player’s visit total |
| **Minimum** | 2 participants (≥1 human) |
| **Recommended** | 3–6 |
| **App maximum** | 8 |

### Brainstorm
- Works at **2** (alternating beat-the-high) but pub Knockout is a warm-up circle — 3–8 is the intended feel.
- **8** is fine: each visit is fast (one total), strikes are per-player state.
- Bots can set or chase highs like humans.

---

## 3. MVP Scope
- Each player throws 3 darts; **visit total** (0–180) recorded
- First player sets benchmark; each following player must **beat the current high** visit total
- Failing to beat high → **strike** (ring); **3 strikes** eliminates player
- After each full rotation, high score resets to 0 for next round (pub standard)
- Total-entry primary; dart-by-dart optional
- Undo last visit; local persistence

### Out of Scope (v1)
- Cumulative multi-round totals without reset (variant)

---

## 4. Rules Engine (`KnockoutEngine`)

### Config (`MatchConfigKnockout`, payload v1)
| Field | Default |
|-------|---------|
| `strikesToEliminate` | `3` |
| `resetHighEachRound` | `true` |

### State
- `currentHigh`, `strikes[playerId]`, `eliminated`
- `roundLeaderPlayerId?`

### Turn flow
1. Player submits visit total.
2. If total ≤ currentHigh (and not first thrower of round), add strike.
3. Else update currentHigh.
4. Advance; when rotation completes, reset high.

### Undo
Replay restores high, strikes, elimination.

---

## 5. UI Specification
- Template A: large **current high** banner + strike indicators per player
- Submit validation 0–180

---

## How to Play

| | |
|---|---|
| **Key prefix** | `play.rules.knockout.` |
| **Shipped in app** | Planned |

### Overview
| **Title key** | `play.rules.knockout.overview.title` |
| **Body key** | `play.rules.knockout.overview.body` |

Knockout is a scoring challenge. Each player throws three darts for a visit total. You must beat the current high score or earn a strike. Three strikes and you're out. Last player left wins.

### Setting the score
| **Title key** | `play.rules.knockout.highScore.title` |
| **Body key** | `play.rules.knockout.highScore.body` |

The first player in a round sets the benchmark with their visit total. Each following player must throw higher than the current best. Beat it and you become the new high score to beat.

### Strikes
| **Title key** | `play.rules.knockout.strikes.title` |
| **Body key** | `play.rules.knockout.strikes.body` |

Fail to beat the high score and you receive a strike. Three strikes eliminates you from the game. Strikes stay with you across rounds until you're out.

### Rounds
| **Title key** | `play.rules.knockout.rounds.title` |
| **Body key** | `play.rules.knockout.rounds.body` |

After everyone has thrown once, the high score resets and a new round begins among surviving players. Continue until one player remains.

---

## Localization

| **Exists** | `modes.catalog.party.knockout.name`, `.blurb` |

### New keys

**Setup:** `play.party.knockout.title`, `.subtitle`; `play.knockout.setup.strikesToEliminate`

**Gameplay:** `play.knockout.navTitle`, `currentHighFormat`, `visitTotalFormat`, `strikeAwarded`, `strikesRemainingFormat`, `playerEliminated`, `roundComplete`, `announce.beatHigh` / `announce.missedHigh`

**How to play:** `play.rules.knockout.overview|highScore|strikes|rounds`

**History:** `history.timeline.knockoutVisitFormat`, `history.detail.knockoutSummaryFormat`

**Validation:** `setup.validation.knockoutMinimumPlayers` (min 2)

---

## 6. Data Capture
- `KnockoutVisitEvent`: `visitTotal`, `beatHigh`, `strikeAwarded`, `highAfter`

---

## 7. Testing
- Unit: strike accumulation, elimination, round reset
- Edge: tied high does not beat

---

## 8. Verification
| Field | Value |
|-------|-------|
| **Status** | Planned |
