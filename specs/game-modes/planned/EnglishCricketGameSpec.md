# English Cricket Game Specification

## 1. Purpose
Define English Cricket — a two-role party game (Batter vs Bowler) inspired by bat-and-ball cricket — for future implementation.

**Status:** Planned (`party.englishCricket`).

References: [DolfDarts — English Cricket](https://dolfdarts.com/games/english-cricket), [darts501.com](https://darts501.com/Games.html).

---

## 2. Catalog metadata
| Field | Value |
|-------|-------|
| **Section** | Party |
| **UI template** | A — Checkout score (dual score columns) |
| **Stat kind** | Checkout (runs / wickets) |
| **Ruleset (v1)** | `english_cricket_ten_wickets` |

---

## Player count

| Question | Answer |
|----------|--------|
| **Solo?** | No — fixed Batter vs Bowler roles each innings |
| **Minimum** | 2 participants (1 Batter + 1 Bowler; ≥1 human) |
| **Recommended** | 2 exactly |
| **App maximum** | 2 (`maximumPlayers: 2` in catalog) |

### Brainstorm
- Rules are explicitly two-role: one scores runs, one takes wickets on bull. A third player has no seat.
- **Teams (2v2)** could alternate batters within a side but v1 is **1v1 only**; team play is out of scope.
- Setup should skip adding a 3rd roster slot (enforce `maximumPlayers: 2`).

---

## 3. MVP Scope
- Fixed roles per innings: **Batter** scores runs; **Bowler** takes wickets on bull
- Batter: 3-dart visit total; **runs = max(0, total − 40)** (standard pub rule)
- Bowler: each bull hit (inner or outer) = 1 wicket; **10 wickets** ends innings
- Two innings — players swap roles; **higher run total wins**
- If second batter passes first batter's total before 10 wickets, innings may end early (config: `endWhenTargetPassed`, default `true`)
- Total-entry or dart-by-dart for Batter; bull-only pad for Bowler turn
- Undo last accepted visit; local persistence

### Out of Scope (v1)
- 3+ players, limited-overs variants, full-board batter scoring without the −40 rule

---

## 4. Rules Engine (`EnglishCricketEngine`)

### Config (`MatchConfigEnglishCricket`, payload v1)
| Field | Default |
|-------|---------|
| `wicketsPerInnings` | `10` |
| `runsThreshold` | `40` |
| `endWhenTargetPassed` | `true` |

### State
- `inningsIndex` (0/1), `phase` (batting / bowling)
- `runs[playerId]`, `wicketsFallen`, `opponentRunTarget?`

### Turn flow
1. Batter throws 3 darts (any scoring segment); compute runs.
2. Bowler throws 3 darts at bull only; count wickets.
3. Swap roles after innings end condition.

### Undo
Replay restores runs, wickets, phase, and innings.

---

## 5. UI Specification
- Template A variant: split header **Runs** vs **Wickets** with role badge
- Phase-specific pad (full board vs bull-only)
- Scoreboard: runs this innings + wickets remaining

---

## How to Play

| | |
|---|---|
| **Key prefix** | `play.rules.englishCricket.` |
| **Shipped in app** | Planned |

### Overview
| **Title key** | `play.rules.englishCricket.overview.title` |
| **Body key** | `play.rules.englishCricket.overview.body` |

English Cricket is a two-player game inspired by bat-and-ball cricket. One player bats for runs on the full board; the other bowls at the bull to take wickets. After ten wickets the roles swap. Most runs across both innings wins.

### Batting
| **Title key** | `play.rules.englishCricket.batting.title` |
| **Body key** | `play.rules.englishCricket.batting.body` |

The batter throws three darts at any scoring segment. Add the visit total, then subtract 40. Whatever remains (if positive) is runs scored that visit. Example: 85 points = 45 runs.

### Bowling
| **Title key** | `play.rules.englishCricket.bowling.title` |
| **Body key** | `play.rules.englishCricket.bowling.body` |

The bowler throws three darts at the bull only. Each bull hit (inner or outer) is one wicket. Ten wickets ends the batting innings.

### Innings and winning
| **Title key** | `play.rules.englishCricket.innings.title` |
| **Body key** | `play.rules.englishCricket.innings.body` |

Players swap batter and bowler after each innings. If the second batter passes the first batter's run total before all wickets fall, the innings may end. Highest combined batting runs after both innings wins.

---

## Localization

| **Exists** | `modes.catalog.party.englishCricket.name`, `.blurb` |

### New keys

**Setup:** `play.party.englishCricket.title`, `.subtitle`; `play.englishCricket.setup.wicketsPerInnings`, `setup.endWhenTargetPassed` (chip labels)

**Gameplay:** `play.englishCricket.navTitle`, `role.batter` / `role.bowler`, `header.inningsFormat`, `runsFormat`, `wicketsRemainingFormat`, `visitRunsFormat` (runs above 40), `wicketTaken`, `pad.bullOnlyHint`, `pad.fullBoardHint`, `announce.inningsComplete`

**How to play:** `play.rules.englishCricket.overview|batting|bowling|innings`

**History:** `history.timeline.englishCricketVisitFormat`, `history.detail.englishCricketSummaryFormat`

**Validation:** `setup.validation.englishCricketExactTwoPlayers` (max 2 roster)

**Errors:** `error.match.englishCricket.wrongPhase`

---

## 6. Data Capture
- `EnglishCricketVisitEvent`: `role`, `rawTotal`, `runsAdded`, `wicketsAdded`, `darts[]`

---

## 7. Testing
- Unit: runs formula, wicket cap, chase logic, innings swap
- UI: role-appropriate input surfaces

---

## 8. Verification
| Field | Value |
|-------|-------|
| **Status** | Planned |
