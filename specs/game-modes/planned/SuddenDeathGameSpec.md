# Sudden Death Game Specification

## 1. Purpose
Define Sudden Death — lowest-score elimination each round until one player remains — for future implementation.

**Status:** Planned (`party.suddenDeath`).

References: [darts501.com — Sudden Death](https://darts501.com/Games.html).

---

## 2. Catalog metadata
| Field | Value |
|-------|-------|
| **Section** | Party |
| **UI template** | A — Checkout score |
| **Stat kind** | Checkout |
| **Ruleset (v1)** | `sudden_death_lowest_out` |

---

## Player count

| Question | Answer |
|----------|--------|
| **Solo?** | No — eliminates lowest scorer each round |
| **Minimum** | 3 participants (≥1 human) |
| **Recommended** | 4–8 |
| **App maximum** | 8 |

### Brainstorm
- **3 is the hard floor**: with 2 players every round eliminates someone immediately (1-round match). Still playable but not “sudden death circle.”
- Catalog `minimumPlayers: 3` matches pub rules (multiplayer warm-up).
- At **8**, one elimination per round → 7 rounds max; acceptable for a short party opener.

---

## 3. MVP Scope
- Each round: all active players throw 3 darts; **lowest visit total eliminated**
- Ties for lowest: eliminate all tied players (config `eliminateAllTied`, default `true`) or sudden-death throw-off (v2)
- Continue until one player remains
- Optional setup: **two visits per round** before elimination (small groups)
- Total-entry; undo last visit; local persistence

### Out of Scope (v1)
- Three-lives variant (document as `sudden_death_three_lives` ruleset for v2)

---

## 4. Rules Engine (`SuddenDeathEngine`)

### Config (`MatchConfigSuddenDeath`, payload v1)
| Field | Default |
|-------|---------|
| `visitsPerRound` | `1` |
| `eliminateAllTied` | `true` |

### State
- `activePlayers`, `roundIndex`, `visitTotalsThisRound`

### Turn flow
1. Collect visit total from each active player.
2. Determine minimum; eliminate loser(s).
3. If one remains, match complete.

### Undo
Replay restores active set and round index.

---

## 5. UI Specification
- Template A with round counter and elimination banner
- Highlight players at risk when totals submitted

---

## How to Play

| | |
|---|---|
| **Key prefix** | `play.rules.suddenDeath.` |
| **Shipped in app** | Planned |

### Overview
| **Title key** | `play.rules.suddenDeath.overview.title` |
| **Body key** | `play.rules.suddenDeath.overview.body` |

Sudden Death is a quick elimination warm-up. Every round each player throws three darts. Whoever scores the lowest visit total is eliminated. Repeat until one player remains.

### Each round
| **Title key** | `play.rules.suddenDeath.round.title` |
| **Body key** | `play.rules.suddenDeath.round.body` |

All active players throw a full visit. Totals are compared when everyone has thrown. The lowest score (or all players tied for lowest) leaves the game.

### Ties
| **Title key** | `play.rules.suddenDeath.ties.title` |
| **Body key** | `play.rules.suddenDeath.ties.body` |

If two or more players share the lowest total, all of them are eliminated in the same round unless your group prefers a throw-off (house rule — not in v1).

### Winning
| **Title key** | `play.rules.suddenDeath.winning.title` |
| **Body key** | `play.rules.suddenDeath.winning.body` |

The last player standing wins. With three players the game can end in two rounds; larger groups take longer.

---

## Localization

| **Exists** | `modes.catalog.party.suddenDeath.name`, `.blurb` |

### New keys

**Setup:** `play.party.suddenDeath.title`, `.subtitle`; `play.suddenDeath.setup.eliminateAllTied`

**Gameplay:** `play.suddenDeath.navTitle`, `roundFormat`, `lowestScoreEliminatedFormat`, `playersRemainingFormat`, `eliminatedThisRound`, `announce.roundResults`

**How to play:** `play.rules.suddenDeath.overview|round|ties|winning`

**History:** `history.timeline.suddenDeathRoundFormat`, `history.detail.suddenDeathSummaryFormat`

**Validation:** `setup.validation.suddenDeathMinimumPlayers` (min 3)

---

## 6. Data Capture
- `SuddenDeathRoundEvent`: per-player totals, eliminated ids

---

## 7. Testing
- Unit: elimination order, tie handling, 2-player remainder
- Edge: all players tie (rethrow rule)

---

## 8. Verification
| Field | Value |
|-------|-------|
| **Status** | Planned |
