# Hare and Hounds Game Specification

## 1. Purpose
Define Hare and Hounds — a two-player chase around the clock-wise board — for future implementation.

**Status:** Planned (`party.hareAndHounds`).

References: [darts501.com — Hare and Hounds](https://darts501.com/Games.html).

---

## 2. Catalog metadata
| Field | Value |
|-------|-------|
| **Section** | Party |
| **UI template** | E — Sequence progress (dual track) |
| **Stat kind** | Sequence |
| **Ruleset (v1)** | `hare_and_hounds_classic` |

---

## Player count

| Question | Answer |
|----------|--------|
| **Solo?** | No — Hare and Hound are opposing roles on one track |
| **Minimum** | 2 participants (≥1 human; bot fills other role) |
| **Recommended** | 2 exactly |
| **App maximum** | 2 (`maximumPlayers: 2` in catalog) |

### Brainstorm
- Asymmetric chase: one player leads from 20, one pursues from 5 or 12. No third seat in rules.
- Rematch with swapped roles could be a match format (best of 2 innings) but still 2 seats per leg.
- Setup must hard-cap roster at 2.

---

## 3. MVP Scope
- **Hare** starts at 20; **Hound** starts at 5 or 12 (setup chip)
- Both advance **clockwise** following board order (20→1→18→…), hitting current segment to advance
- 3 darts per turn; first hit on target advances one segment
- **Hare wins** by completing circuit back to 20 before hound catches up
- **Hound wins** by passing hare on the track
- Dual-track progress UI; undo; local persistence

### Out of Scope (v1)
- Distance scoring for role reversal rematch

---

## 4. Rules Engine (`HareAndHoundsEngine`)

### Config (`MatchConfigHareAndHounds`, payload v1)
| Field | Default |
|-------|---------|
| `houndStart` | `.segment5` |
| `course` | `clockwiseStandard` |

### State
- `hareIndex`, `houndIndex` on shared course array
- `roles: [playerId: Role]`

### Turn flow
1. Active player throws at their current segment.
2. Advance on hit; check catch/overtake win conditions.

### Undo
Replay restores both positions.

---

## 5. UI Specification
- Template E with **two markers** on shared segment strip
- Role badges (Hare / Hound)

---

## How to Play

| | |
|---|---|
| **Key prefix** | `play.rules.hareAndHounds.` |
| **Shipped in app** | Planned |

### Overview
| **Title key** | `play.rules.hareAndHounds.overview.title` |
| **Body key** | `play.rules.hareAndHounds.overview.body` |

A two-player chase around the board. The Hare leads from 20; the Hound pursues from segment 5 or 12. Follow clockwise board order — hit your current segment to advance.

### Hare
| **Title key** | `play.rules.hareAndHounds.hare.title` |
| **Body key** | `play.rules.hareAndHounds.hare.body` |

The Hare must complete a full circuit back to 20 before the Hound catches up. Three darts per turn; any hit on the active segment moves you one step clockwise.

### Hound
| **Title key** | `play.rules.hareAndHounds.hound.title` |
| **Body key** | `play.rules.hareAndHounds.hound.body` |

The Hound chases on the same path. If you pass the Hare's position, you win immediately.

### Winning
| **Title key** | `play.rules.hareAndHounds.winning.title` |
| **Body key** | `play.rules.hareAndHounds.winning.body` |

Hare wins by reaching 20 first after a full lap. Hound wins by overtaking the Hare on the track.

---

## Localization

| **Exists** | `modes.catalog.party.hareAndHounds.name`, `.blurb` |

### New keys

**Setup:** `play.party.hareAndHounds.title`, `.subtitle`; `play.hareAndHounds.setup.houndStart` (segment 5 / 12)

**Gameplay:** `play.hareAndHounds.navTitle`, `role.hare` / `role.hound`, `trackPositionFormat`, `hareWins` / `houndWins`, `overtake`, `segmentAdvance`, `dualTrackAccessibilityFormat`

**How to play:** `play.rules.hareAndHounds.overview|hare|hound|winning`

**History:** `history.timeline.hareAndHoundsVisitFormat`, `history.detail.hareAndHoundsSummaryFormat`

**Validation:** `setup.validation.hareAndHoundsExactTwoPlayers`

---

## 6. Data Capture
- `HareAndHoundsVisitEvent`: `role`, `positionBefore`, `positionAfter`, `winReason?`

---

## 7. Testing
- Unit: catch detection, hare completion win, start positions

---

## 8. Verification
| Field | Value |
|-------|-------|
| **Status** | Planned |
