# Snooker Game Specification

## 1. Purpose
Define Snooker darts — reds and colours break-building on a standard board — for future implementation.

**Status:** Planned (`party.snooker`).
**Estimated release:** `TBD`

References: [darts501.com — Snooker](https://darts501.com/Games.html).

---

## 2. Catalog metadata
| Field | Value |
|-------|-------|
| **Section** | Party |
| **UI template** | I — Role split |
| **Stat kind** | Role score |
| **Ruleset (v1)** | `snooker_simplified_break` |

---

## Player count

| Question | Answer |
|----------|--------|
| **Solo?** | No — break-building alternates between opponents |
| **Minimum** | 2 participants (≥1 human) |
| **Recommended** | 2 exactly (v1 individual play) |
| **App maximum** | 2 (`maximumPlayers: 2` in catalog) |

### Brainstorm
- v1 simplified frame is **1v1** break alternation (like pub snooker darts).
- **2v2 teams** could share breaks but need team UX — post-v1; keep cap at 2 for v1.
- Bot opponent is sufficient for digital play.

---

## 3. MVP Scope
- **Reds:** segments 1–15 (1 point each); pocketed on hit (removed from table)
- **Colours:** 16=yellow(2), 17=green(3), 18=brown(4), 19=blue(5), 20=pink(6), bull=black(7)
- Break: hit red → nominate colour → hit colour → repeat until miss or no reds
- Simplified v1: single frame; highest break total wins (not full snooker frame count)
- One player breaks first (nearest bull); alternate breaks each frame
- Per-dart entry with nomination step; undo; local persistence

### Out of Scope (v1)
- Full 15-red multi-frame snooker, foul penalties

---

## 4. Rules Engine (`SnookerEngine`)

### Config (`MatchConfigSnooker`, payload v1)
| Field | Default |
|-------|---------|
| `frameCount` | `1` |
| `redsCount` | `15` |

### State
- `availableReds: Set<Int>`, `scores[playerId]`
- `breakState`: `awaitingRed | awaitingColour(nominated)`

### Turn flow
1. If reds remain, must hit red to continue break.
2. After red, player nominates colour; hit adds points and re-spots colour (colour returns).
3. Miss ends break; swap breaker.

### Undo
Replay restores table and scores.

---

## 5. UI Specification
- Template I: **table diagram** (reds remaining + colour nom)
- Break score vs frame score

---

## How to Play

| | |
|---|---|
| **Key prefix** | `play.rules.snooker.` |
| **Shipped in app** | Planned |
| **Estimated release** | `TBD` |

### Overview
| **Title key** | `play.rules.snooker.overview.title` |
| **Body key** | `play.rules.snooker.overview.body` |

Snooker on a dartboard: reds are segments 1–15, colours map to 16–20 and bull. Pot a red, nominate a colour, pot the colour, repeat. Highest break total wins the frame.

### Reds
| **Title key** | `play.rules.snooker.reds.title` |
| **Body key** | `play.rules.snooker.reds.body` |

Each number 1 through 15 is one red worth 1 point. Once potted, that red is gone for the rest of the frame. You must hit a red to start or continue a break.

### Colours
| **Title key** | `play.rules.snooker.colours.title` |
| **Body key** | `play.rules.snooker.colours.body` |

After a red, nominate a colour: 16 yellow (2), 17 green (3), 18 brown (4), 19 blue (5), 20 pink (6), bull black (7). Hit it to add points. Colours return to the table after being potted; reds do not.

### Breaks
| **Title key** | `play.rules.snooker.breaks.title` |
| **Body key** | `play.rules.snooker.breaks.body` |

Keep alternating red then colour until you miss or run out of reds. Your break ends on a miss; opponent's turn to break. Most points in the frame wins.

---

## Localization

| **Exists** | `modes.catalog.party.snooker.name`, `.blurb` |

### New keys

**Setup:** `play.party.snooker.title`, `.subtitle`

**Gameplay:** `play.snooker.navTitle`, `breakScoreFormat`, `redsRemainingFormat`, `nominateColour`, `colour.yellow` … `colour.black` (ball names), `redPocketed`, `breakEnded`, `frameScoreFormat`, `pad.nominationHint`

**How to play:** `play.rules.snooker.overview|reds|colours|breaks`

**History:** `history.timeline.snookerDartFormat`, `history.detail.snookerSummaryFormat`

**Validation:** `setup.validation.snookerExactTwoPlayers`

---

## 6. Data Capture
- `SnookerDartEvent`: `ballType`, `nominatedColour?`, `points`, `pocketedRed`

---

## 7. Testing
- Unit: red pocketing, colour nomination, break end on miss

---

## 8. Verification
| Field | Value |
|-------|-------|
| **Status** | Planned |
