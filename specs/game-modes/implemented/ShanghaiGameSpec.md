**Estimated release:** `1.1`

# Shanghai Game Specification

## 1. Purpose
Define Shanghai (party mode) gameplay rules, play UI, input model, persistence, and history.

Authoritative rules reference: [GLD Shanghai darts](https://gldproducts.com/blogs/all/how-to-play-shanghai-darts), [darts501.com](https://darts501.com/Games.html).

---

## 2. MVP Scope
- Default **20 rounds** (targets 1→20); configurable 1–20
- 2..N players; preset difficulty bots supported
- Face-value scoring on the active round target only (single = N, double = 2N, triple = 3N)
- **Shanghai bonus** (single + double + triple on target in one visit): `+150` (default) or **instant win**
- Tie-breaker: **extra rounds** until a single leader emerges
- Per-dart entry via segment-locked scoring pad
- Undo last accepted turn
- Local-only persistence with turn + dart granularity
- Party setup category (`PlaySetupCategory.party` → `PartyGame.shanghai`)

### Out of Scope (v1)
- Training/custom bots, bull as final target round, achievements

---

## Player count

| Question | Answer |
|----------|--------|
| **Solo?** | No — round rotation compares cumulative totals across players |
| **Minimum** | 2 participants (≥1 human; preset bots OK) |
| **Recommended** | 2–4 |
| **App maximum** | 8 |

### Brainstorm
- Shanghai is head-to-head scoring per round; solo has no leaderboard within a match.
- Works well at 2–4; extra rounds tie-breaker gets long at 6–8 but rules still hold.
- **8** cap aligns with inning-style scoreboard (same template family as Baseball).

---

## 3. Rules Engine (`ShanghaiEngine`)

### Config (`MatchConfigShanghai`, payload v1)
| Field | Default |
|-------|---------|
| `roundCount` | `20` |
| `bonusRule` | `.bonus150` |
| `tieBreaker` | `.extraRounds` |

### Turn flow
1. All players throw three darts at `currentRound` target segment.
2. Advance to next player; after last player in round, increment round (or enter extra rounds on tie).
3. After `roundCount` complete rounds, highest cumulative points wins; ties use tie-breaker.

### Shanghai detection
Hit single, double, and triple on the active target within one visit.

### Undo
Replay from `ShanghaiTurnEvent` list restores round, scratch totals, cumulative points, and completion.

---

## 4. UI Specification

### Setup (`SetupHomeView` Shanghai chips)
- Rounds (1–20)
- Shanghai bonus rule
- Tie-breaker

### Play screen (`ShanghaiMatchScreen`)
| Region | Content |
|--------|---------|
| Header | Round + target; extra-round badge |
| Scoreboard | Cumulative points; optional this-round column |
| Round strip | Completed / current / upcoming — **not color-only** |
| Pad | Segment locked to `currentRound` |
| Actions | Submit, Undo |

### Match end
- Shared match summary; history shows round-by-round points.

---

## How to Play

| | |
|---|---|
| **Key prefix** | `play.rules.shanghai.` |
| **Shipped in app** | Yes (`GameRulesCatalog.shanghai`) |
| **Estimated release** | `1.1` |

### Overview
| **Title key** | `play.rules.shanghai.overview.title` |
| **Body key** | `play.rules.shanghai.overview.body` |

Players take turns throwing three darts at a rotating target number. Only hits on that round's segment score face value (single, double, or triple). Highest total after all rounds wins.

### Scoring
| **Title key** | `play.rules.shanghai.scoring.title` |
| **Body key** | `play.rules.shanghai.scoring.body` |

Round 1 targets 1, round 2 targets 2, and so on. A single scores the number, a double scores twice the number, and a triple scores three times the number. Off-target hits score zero.

### Shanghai bonus
| **Title key** | `play.rules.shanghai.bonus.title` |
| **Body key** | `play.rules.shanghai.bonus.body` |

Hit single, double, and triple on the active target in one turn for a Shanghai. Choose +150 bonus points or an instant win in setup.

### Tie-breakers
| **Title key** | `play.rules.shanghai.tieBreakers.title` *(add when shipping extra-round copy)* |
| **Body key** | `play.rules.shanghai.tieBreakers.body` |

If players tie after the final round, extra rounds continue with the next target number until one player leads on total points.

---

## Localization

| Status | Meaning |
|--------|---------|
| **Exists** | In `en.lproj` today |
| **New** | Add when extending |

### Catalog & setup
| Key | Status |
|-----|--------|
| `modes.catalog.party.shanghai.name` / `.blurb` | Exists |
| `play.party.shanghai.title` / `.subtitle` | Exists |
| `play.shanghai.setup.rounds` / `roundsValueFormat` | Exists |
| `play.shanghai.setup.bonusRule` | Exists |
| `play.shanghai.bonusRule.bonus150` / `instantWin` | Exists |
| `play.shanghai.tieBreaker.extraRounds` | Exists | setup chip |
| `setup.validation.shanghaiBotsPresetOnly` | Exists |
| `setup.validation.partyMinimumPlayers` | Exists |

### Gameplay (`play.shanghai.*`)
| Key | Status |
|-----|--------|
| `play.shanghai.title` | Exists |
| `play.shanghai.headerFormat` / `extraRound` / `leading` | Exists |
| `play.shanghai.thisRoundFormat` | Exists |
| `play.shanghai.achieved` | Exists |
| `play.shanghai.scoringHintFormat` / `goalReminder` | Exists |
| `play.shanghai.pad.lockedSegmentHint` / `disabledWhileBot` | Exists |
| `play.shanghai.roundStrip.accessibilityFormat` | Exists |
| `play.shanghai.announce.turnFormat` | Exists |

### How to play (`play.rules.shanghai.*`)
| Key | Status |
|-----|--------|
| `overview`, `scoring`, `bonus` | Exists |
| `tieBreakers.title` / `tieBreakers.body` | **New** | Copy in § How to Play; wire in `GameRulesCatalog` |

### History
| Key | Status |
|-----|--------|
| `history.timeline.shanghaiTurnFormat` | Exists |
| `history.detail.shanghaiSummaryFormat` | Exists |

### Errors
| Key | Status |
|-----|--------|
| `error.match.shanghai.invalidRoundCount` | Exists |

---

## 5. Data Capture

### Turn event (`ShanghaiTurnEvent`)
- `playerId`, `turnIndex`, `round`, `pointsThisVisit`, `cumulativePointsAfterTurn`
- `achievedShanghai`, `darts: [ShanghaiDartEvent]`

Authoritative payload fields: [`SwiftData.md`](../../SwiftData.md).

---

## 6. Accessibility
- Turn announcement (`play.shanghai.announce.turnFormat`)
- Round strip accessibility labels per dot
- Stable identifiers: `shanghai_match_header`, `shanghai_submit`, `shanghai_undo`, `shanghai_round_strip`
- Manual: [`shanghai-match.md`](../../../accessibility/wcag-2.1-aa/screens/shanghai-match.md)
- Shared pad: [`_shared-components.md`](../../../accessibility/wcag-2.1-aa/screens/_shared-components.md)

---

## 7. Testing
- Unit: scoring, Shanghai bonus paths, extra rounds, undo/replay (`ShanghaiEngineTests`)
- Setup: 2+ players, bot roster (`MatchSetupViewModelTests`)
- UI: segment lock, round strip states

---

## 8. Verification
| Field | Value |
|-------|-------|
| **Last verified** | 2026-06-11 |
| **Status** | Shipped |
| **Code** | `ShanghaiEngine.swift`, `Features/Play/Shanghai/` |
| **Catalog id** | `party.shanghai` |

---

## 9. References
- In-app rules: `GameRulesCatalog` → `play.rules.shanghai.*`
- Catalog: [`GameModeCatalog.swift`](../../../Features/Modes/GameModeCatalog.swift)
- UI template: **C — Inning points** ([`docs/full-game-catalog-ui.md`](../../../docs/full-game-catalog-ui.md))
