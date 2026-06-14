# Mickey Mouse Game Specification

## 1. Purpose
Define Mickey Mouse — a descending mark-closure party game (20 down through 12, then bull) — for future implementation.

**Status:** Shipped (`party.mickeyMouse`).
**Estimated release:** `1.3`

References: [darts501.com — Mickey Mouse](https://darts501.com/Games.html), [Darts Corner](https://www.dartscorner.com/blogs/how-to/what-darts-games-can-you-play).

---

## 2. Catalog metadata
| Field | Value |
|-------|-------|
| **Section** | Party |
| **UI template** | B — Mark board |
| **Stat kind** | Marks |
| **Ruleset (v1)** | `mickey_mouse_race` |

---

## Player count

| Question | Answer |
|----------|--------|
| **Solo?** | No — race to close all targets; first finisher wins |
| **Minimum** | 2 participants (≥1 human) |
| **Recommended** | 2–4 |
| **App maximum** | 8 |

### Brainstorm
- v1 race mode needs someone to beat to the bull finish.
- Scoring variant (post-v1) still needs opponents to close against.
- Longer target ladder (20→12) means more turns at 6–8 players — acceptable but 2–4 is snappier.

---

## 3. MVP Scope
- Targets in order: **20, 19, 18, 17, 16, 15, 14, 13, 12, bull**
- Close each with 3 marks (S/D/T = 1/2/3); outer bull = 1, inner bull = 2
- **Race mode (v1):** first player to close all targets wins (no point scoring)
- Optional setup chip (post-v1): `mickey_mouse_scoring` — American Cricket-style points after closure
- Mark-board UI; per-dart entry; undo; local persistence

### Out of Scope (v1)
- Random target order, triples-only Mickey variants

---

## 4. Rules Engine (`MickeyMouseEngine`)

### Config (`MatchConfigMickeyMouse`, payload v1)
| Field | Default |
|-------|---------|
| `ruleset` | `mickey_mouse_race` |
| `scoringEnabled` | `false` |

### State
- `currentTargetIndex`, per-player marks on current target, per-player closed targets bitmask
- `winnerPlayerId?`

### Turn flow
1. Throws apply only to **current target** segment.
2. On 3 marks by any player on current target, advance target index globally.
3. First to close bull wins.

### Undo
Replay restores target index and all mark counts.

---

## 5. UI Specification
- Template B with descending target strip (20→12 + bull)
- Highlight current target; closed targets show player identity (not color-only)

---

## How to Play

| | |
|---|---|
| **Key prefix** | `play.rules.mickeyMouse.` |
| **Shipped in app** | Yes |
| **Estimated release** | `1.3` |

### Overview
| **Title key** | `play.rules.mickeyMouse.overview.title` |
| **Body key** | `play.rules.mickeyMouse.overview.body` |

Mickey Mouse is a race down the board. Close each number in order from 20 through 12, then the bull. First player to close everything wins.

### Closing numbers
| **Title key** | `play.rules.mickeyMouse.closing.title` |
| **Body key** | `play.rules.mickeyMouse.closing.body` |

You may only score marks on the current target. Singles, doubles, and triples add 1, 2, or 3 marks. Three marks closes that number for you. Outer bull counts as one mark; inner bull as two on the final target.

### Turn order
| **Title key** | `play.rules.mickeyMouse.turns.title` |
| **Body key** | `play.rules.mickeyMouse.turns.body` |

Each player throws three darts per turn. When anyone closes the active number, the next target opens for everyone. You cannot skip ahead — the group moves together from 20 down to 12, then bull.

### Winning
| **Title key** | `play.rules.mickeyMouse.winning.title` |
| **Body key** | `play.rules.mickeyMouse.winning.body` |

The first player to close the bull wins the game. If several players close the bull on the same round, the earliest finisher in throw order wins.

---

## Localization

| **Exists** | `modes.catalog.party.mickeyMouse.name`, `.blurb` |

### New keys

**Setup:** `play.party.mickeyMouse.title`, `.subtitle`; `play.mickeyMouse.title`

**Gameplay:** `play.mickeyMouse.navTitle`, `header.currentTargetFormat` (e.g. “Close 20”), `targetStrip.*` (20→12 + bull), `marksToCloseFormat`, `pad.lockedTargetHint`, `pad.disabledWhileBot`, `playerClosedTargetFormat`, `announce.matchComplete`

**How to play:** `play.rules.mickeyMouse.overview|closing|turns|winning` (`.title` / `.body`)

**History:** `history.timeline.mickeyMouseTurnFormat`, `history.detail.mickeyMouseSummaryFormat`

**Validation:** `setup.validation.mickeyMouseMinimumPlayers` (min 2) or reuse party minimum

---

## 6. Data Capture
- `MickeyMouseTurnEvent`: `target`, marks per dart, `advancedTarget` flag

---

## 7. Testing
- Unit: mark math, target advance, race win on bull
- UI: pad locked to current target

---

## 8. Verification
| Field | Value |
|-------|-------|
| **Status** | Planned |
