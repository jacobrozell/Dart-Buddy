# Grand National Game Specification

## 1. Purpose
Define Grand National — a sequence race around the board with hurdle elimination — for future implementation.

**Status:** Shipped (`party.grandNational`).
**Estimated release:** `1.3`

**In-visit progression:** **Excluded** — one course position per visit regardless of hit count ([`InVisitSequenceProgressionSupplement.md`](../InVisitSequenceProgressionSupplement.md) §2).

References: [darts501.com — Grand National](https://darts501.com/Games.html).

---

## 2. Catalog metadata
| Field | Value |
|-------|-------|
| **Section** | Party |
| **UI template** | E — Sequence progress |
| **Stat kind** | Sequence |
| **Ruleset (v1)** | `grand_national_novice` |

---

## Player count

| Question | Answer |
|----------|--------|
| **Solo?** | Not in v1 — elimination race needs rivals |
| **Minimum** | 2 participants (≥1 human) |
| **Recommended** | 4–8 (designed for pub crowd on Grand National day) |
| **App maximum** | 8 |

### Brainstorm
- Source game targets “more the better” novice punters; elimination on missed hurdle shrinks the field.
- **2** works but loses elimination drama; still valid for testing.
- Solo time-trial (furthest around course) is a sensible practice variant — post-v1.
- **8** cap keeps hurdle-race UI legible (one token per player on course strip).

---

## 3. MVP Scope
- **Novice ruleset (v1):** anticlockwise from **20**, hit each segment at least once per visit (3 darts); miss all → **fall** (eliminated)
- First to complete **two laps** and return to 20 wins
- Sequence strip UI showing fence positions
- Per-dart or visit confirmation; undo; local persistence

### Post-v1 ruleset
- `grand_national_expert` — large segments 5→9→11… then small segments second lap + bull finish; 3 lives per player

---

## 4. Rules Engine (`GrandNationalEngine`)

### Config (`MatchConfigGrandNational`, payload v1)
| Field | Default |
|-------|---------|
| `ruleset` | `grand_national_novice` |
| `laps` | `2` |

### State
- `segmentIndex` per player along fixed anticlockwise course
- `eliminated`, `lapsCompleted`

### Turn flow
1. Player has 3 darts to hit **current hurdle segment** at least once.
2. **Any** qualifying hit advances **one** position (additional hits on the same hurdle do not advance further).
3. No hit in visit → elimination (novice).

### Undo
Replay restores positions and elimination.

---

## 5. UI Specification
- Template E: **course map** with player tokens
- Elimination state announced accessibly
- Scoring pad: `lockedSegment` stays on the **visit hurdle** for all three darts (supplement §2 exclusion)

---

## How to Play

| | |
|---|---|
| **Key prefix** | `play.rules.grandNational.` |
| **Shipped in app** | Yes |
| **Estimated release** | `1.3` |

### Overview
| **Title key** | `play.rules.grandNational.overview.title` |
| **Body key** | `play.rules.grandNational.overview.body` |

Based on the horse race: travel anticlockwise around the board, jumping each hurdle segment in order. Miss a hurdle with all three darts and you're out. First to finish two laps wins.

### Novice course
| **Title key** | `play.rules.grandNational.course.title` |
| **Body key** | `play.rules.grandNational.course.body` |

Start at 20 and follow the board anticlockwise (20 → 5 → 12 → …). Each turn you have three darts to hit the current hurdle at least once. One successful hit moves you forward one hurdle for the turn; extra hits on the same hurdle do not skip ahead. Miss entirely and you're eliminated.

### Two laps
| **Title key** | `play.rules.grandNational.laps.title` |
| **Body key** | `play.rules.grandNational.laps.body` |

Complete the full circuit twice and return to 20 to win. If several players remain, the furthest around the course can win if others fall at hurdles.

### Expert mode
| **Title key** | `play.rules.grandNational.expert.title` |
| **Body key** | `play.rules.grandNational.expert.body` |

*(Post-v1)* Alternate large and small segments with lives instead of instant elimination. Document here when the expert ruleset ships.

---

## Localization

| **Exists** | `modes.catalog.party.grandNational.name`, `.blurb` |

### New keys

**Setup:** `play.party.grandNational.title`, `.subtitle`; `play.grandNational.setup.ruleset` (novice / expert when shipped)

**Gameplay:** `play.grandNational.navTitle`, `hurdleFormat`, `lapFormat`, `fellAtHurdle`, `playerEliminated`, `coursePositionAccessibilityFormat`, `announce.finished`

**How to play:** `play.rules.grandNational.overview|course|laps|expert`

**History:** `history.timeline.grandNationalVisitFormat`, `history.detail.grandNationalSummaryFormat`

**Validation:** `setup.validation.grandNationalMinimumPlayers` (min 2)

---

## 6. Data Capture
- `GrandNationalVisitEvent`: `segmentBefore`, `segmentAfter`, `eliminated`

---

## 7. Testing
- Unit: course order, lap counting, elimination
- Expert ruleset tests deferred

---

## 8. Verification
| Field | Value |
|-------|-------|
| **Status** | Shipped |
