# Scam Game Specification

## 1. Purpose
Define Scam — alternating Stopper and Scorer roles across the full board — for future implementation.

**Status:** Planned (`party.scam`).
**Estimated release:** `TBD`

References: [darts501.com — Scam](https://darts501.com/Games.html).

---

## 2. Catalog metadata
| Field | Value |
|-------|-------|
| **Section** | Party |
| **UI template** | I — Role split |
| **Stat kind** | Role score |
| **Ruleset (v1)** | `scam_stopper_first` |

---

## Player count

| Question | Answer |
|----------|--------|
| **Solo?** | No — Stopper vs Scorer are opposing roles |
| **Minimum** | 2 participants (≥1 human) |
| **Recommended** | 2 exactly |
| **App maximum** | 2 (`maximumPlayers: 2` in catalog) |

### Brainstorm
- Each half is one Stopper blocking 20→1 while one Scorer accumulates — no third role.
- Brag/wager variant stays 2-player.
- Bot can play either role; roster capped at 2.

---

## 3. MVP Scope
- **Half 1:** Player A = Stopper, B = Scorer
- Stopper throws first each turn; marks segments **out of play** for Scorer (one mark per hit on 20→1)
- Scorer aims at **highest available** segment; adds face value to score
- After Stopper closes all segments 20→1, swap roles for **half 2**
- **Higher total after both halves wins**
- Bull not used
- Role-specific UI; undo; local persistence

### Out of Scope (v1)
- Brag wagering variant

---

## 4. Rules Engine (`ScamEngine`)

### Config (`MatchConfigScam`, payload v1)
| Field | Default |
|-------|---------|
| `segmentsDescending` | `true` |

### State
- `halfIndex` (0/1), `roles`, `closedSegments`
- `scores[playerId]`

### Turn flow
1. Stopper throws 3 darts — mark any hit segments closed.
2. Scorer throws 3 darts — score on highest open segment hit (or 0).
3. End half when all segments closed; swap roles.

### Undo
Replay restores closed set and scores.

---

## 5. UI Specification
- Template I: split view — closed segment list + role banner
- Scorer sees available segments highlighted

---

## How to Play

| | |
|---|---|
| **Key prefix** | `play.rules.scam.` |
| **Shipped in app** | Planned |
| **Estimated release** | `TBD` |

### Overview
| **Title key** | `play.rules.scam.overview.title` |
| **Body key** | `play.rules.scam.overview.body` |

Two roles: Stopper and Scorer. The Stopper closes segments; the Scorer points on what's still open. Play two halves, swap roles, highest total wins. Bull is not used.

### Stopper's turn
| **Title key** | `play.rules.scam.stopper.title` |
| **Body key** | `play.rules.scam.stopper.body` |

The Stopper throws first each visit and tries to hit high numbers (20 down to 1). Each segment hit is closed — the Scorer cannot score on it for the rest of that half.

### Scorer's turn
| **Title key** | `play.rules.scam.scorer.title` |
| **Body key** | `play.rules.scam.scorer.body` |

The Scorer throws at the highest segment still open and adds its face value to their total. If the best open number is 17, only hits on 17 count for points that visit.

### Halves
| **Title key** | `play.rules.scam.halves.title` |
| **Body key** | `play.rules.scam.halves.body` |

When every segment 20–1 is closed, the half ends. Swap roles and play again. Combined score from both halves decides the winner.

---

## Localization

| **Exists** | `modes.catalog.party.scam.name`, `.blurb` |

### New keys

**Setup:** `play.party.scam.title`, `.subtitle`

**Gameplay:** `play.scam.navTitle`, `role.stopper` / `role.scorer`, `halfFormat`, `segmentClosedFormat`, `highestOpenSegmentFormat`, `pointsThisVisitFormat`, `halfComplete`, `rolesSwap`, `closedSegmentsAccessibilityFormat`

**How to play:** `play.rules.scam.overview|stopper|scorer|halves`

**History:** `history.timeline.scamVisitFormat`, `history.detail.scamSummaryFormat`

**Validation:** `setup.validation.scamExactTwoPlayers`

---

## 6. Data Capture
- `ScamTurnEvent`: `role`, `segmentsClosed`, `pointsAdded`

---

## 7. Testing
- Unit: closure order, scorer picks highest open, half swap

---

## 8. Verification
| Field | Value |
|-------|-------|
| **Status** | Planned |
