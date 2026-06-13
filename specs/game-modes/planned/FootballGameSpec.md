# Football Game Specification

## 1. Purpose
Define Football — a two-player phase race to score goals on doubles after opening bull — for future implementation.

**Status:** Planned (`party.football`).

References: [darts501.com — Football](https://darts501.com/Games.html).

---

## 2. Catalog metadata
| Field | Value |
|-------|-------|
| **Section** | Party |
| **UI template** | G — Phase race |
| **Stat kind** | Goals |
| **Ruleset (v1)** | `football_ten_goals` |

---

## Player count

| Question | Answer |
|----------|--------|
| **Solo?** | No — kickoff then race to 10 goals is 1v1 |
| **Minimum** | 2 participants (≥1 human; bot as opponent OK) |
| **Recommended** | 2 exactly |
| **App maximum** | 2 (`maximumPlayers: 2` in catalog) |

### Brainstorm
- Pub Football is explicitly **two players** alternating kickoff and doubles-for-goals.
- A third player has no role without inventing keeper/team rules (out of scope).
- 1 human + 1 bot is the expected digital shape; enforce roster cap at 2 in setup.

---

## 3. MVP Scope
- **Phase 1 — Kickoff:** each player must hit **inner or outer bull** before scoring goals
- **Phase 2 — Scoring:** each double hit = **1 goal** (bull counts as double 25)
- First to **10 goals** wins
- Optional: two outer bulls = kickoff (setup chip)
- Phase-gated pad (bull-only until kickoff complete, then doubles)
- Undo; local persistence

### Out of Scope (v1)
- 3+ players, timed halves

---

## 4. Rules Engine (`FootballEngine`)

### Config (`MatchConfigFootball`, payload v1)
| Field | Default |
|-------|---------|
| `goalsToWin` | `10` |
| `kickoffMode` | `.singleBull` |

### State
- `kickoffComplete[playerId]`
- `goals[playerId]`

### Turn flow
1. If kickoff incomplete, only bull hits count toward kickoff.
2. Else doubles (and bull as double) add goals.
3. Check win at goalsToWin.

### Undo
Replay restores kickoff flags and goals.

---

## 5. UI Specification
- Template G: phase banner (Kickoff / Scoring) + goal tally
- Pitch-style timeline optional (goals markers)

---

## How to Play

| | |
|---|---|
| **Key prefix** | `play.rules.football.` |
| **Shipped in app** | Planned |

### Overview
| **Title key** | `play.rules.football.overview.title` |
| **Body key** | `play.rules.football.overview.body` |

A simple two-player race to ten goals. Both players must complete kickoff on the bull before doubles start counting as goals.

### Kickoff
| **Title key** | `play.rules.football.kickoff.title` |
| **Body key** | `play.rules.football.kickoff.body` |

Hit the inner or outer bull to complete kickoff. Until kickoff is done, only bull hits matter for you. Optional house rule: two outer bulls count as kickoff instead of one inner.

### Scoring goals
| **Title key** | `play.rules.football.goals.title` |
| **Body key** | `play.rules.football.goals.body` |

After kickoff, each double you hit scores one goal. The bull counts as a double 25 and can score again. Singles and triples do not score goals.

### Winning
| **Title key** | `play.rules.football.winning.title` |
| **Body key** | `play.rules.football.winning.body` |

First player to ten goals wins the match.

---

## Localization

| **Exists** | `modes.catalog.party.football.name`, `.blurb` |

### New keys

**Setup:** `play.party.football.title`, `.subtitle`; `play.football.setup.goalsToWin`; `play.football.setup.kickoffMode` (single bull / two outer)

**Gameplay:** `play.football.navTitle`, `phase.kickoff` / `phase.scoring`, `goalsFormat`, `kickoffComplete`, `goalScored`, `pad.bullOnlyHint`, `pad.doublesHint`, `announce.matchComplete`

**How to play:** `play.rules.football.overview|kickoff|goals|winning`

**History:** `history.timeline.footballVisitFormat`, `history.detail.footballSummaryFormat`

**Validation:** `setup.validation.footballExactTwoPlayers`

---

## 6. Data Capture
- `FootballVisitEvent`: `phase`, `goalsAdded`, `kickoffAchieved`

---

## 7. Testing
- Unit: kickoff gate, goal counting, bull-as-double
- UI: pad mode switches on kickoff

---

## 8. Verification
| Field | Value |
|-------|-------|
| **Status** | Planned |
