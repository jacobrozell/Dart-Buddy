# Prisoner Game Specification

## 1. Purpose
Define Prisoner — around-the-clock with captive darts in the inner board — for future implementation.

**Status:** Planned (`party.prisoner`).

References: [darts501.com — Prisoner](https://darts501.com/Games.html), [Darts Corner](https://www.dartscorner.com/blogs/how-to/what-darts-games-can-you-play).

---

## 2. Catalog metadata
| Field | Value |
|-------|-------|
| **Section** | Party |
| **UI template** | H — Board state |
| **Stat kind** | Board claim |
| **Ruleset (v1)** | `prisoner_clockwise_triple_to_double` |

---

## Player count

| Question | Answer |
|----------|--------|
| **Solo?** | No — prisoner capture and dart pools need rivals |
| **Minimum** | 2 participants (≥1 human); rules allow 2 but feel thin |
| **Recommended** | 5–8 (source: “best with 5 people plus”) |
| **App maximum** | 8 |

### Brainstorm
- **2** is legal but prisoner mechanics need others to capture darts — game improves sharply at 4+.
- At **8**, dart-pool counts (up to 7 darts per player late game) need clear pool UI — still in spec scope.
- Long turns at high count: clockwise progress is one segment per successful visit per player.

---

## 3. MVP Scope
- Objective: first to hit segments **1→20 clockwise** in the **playable ring** (triple ring through double ring, inclusive)
- After segment 1, follow clock order: 18, 4, 13, … (standard board layout)
- **Bounce-out / outside double:** dart left on board one turn; player throws 2 darts next visit
- **Inner board hit** (bull through triple ring): dart becomes **prisoner** until any player hits playable area of same number (bull captures bull prisoners)
- Captured prisoner dart joins thrower's pool for rest of game
- Per-dart entry with board-state tracking; undo; local persistence

### Out of Scope (v1)
- Physical dart count > 3 UI (show pool size badge)

---

## 4. Rules Engine (`PrisonerEngine`)

### Config (`MatchConfigPrisoner`, payload v1)
| Field | Default |
|-------|---------|
| `playableRing` | `.tripleToDouble` |

### State
- `progressIndex` per player on clockwise course
- `prisoners: [DartRef]` on board (segment, owner, location)
- `dartPool[playerId]` count (default 3)

### Turn flow
1. Player throws up to `dartPool` darts at current target segment in playable ring.
2. Resolve miss types → prisoner / lost turn dart.
3. On segment hit, advance; check win at 20.

### Undo
Replay restores progress, prisoners, pools.

---

## 5. UI Specification
- Template H: board overlay showing prisoners + current target
- Dart pool indicator per player

---

## How to Play

| | |
|---|---|
| **Key prefix** | `play.rules.prisoner.` |
| **Shipped in app** | Planned |

### Overview
| **Title key** | `play.rules.prisoner.overview.title` |
| **Body key** | `play.rules.prisoner.overview.body` |

Race clockwise from 1 to 20 through the outer scoring ring (triples through doubles). First to hit every number in that ring wins — but missed darts can become prisoners other players capture.

### Progress
| **Title key** | `play.rules.prisoner.progress.title` |
| **Body key** | `play.rules.prisoner.progress.body` |

After 1 comes 18, then 4, 13, and so on clockwise. Only hits in the playable ring count. Three darts per turn.

### Lost darts
| **Title key** | `play.rules.prisoner.lost.title` |
| **Body key** | `play.rules.prisoner.lost.body` |

Miss the board outside the doubles ring or bounce out and the dart stays in the board one turn — you throw only two darts next visit, then recover it.

### Prisoners
| **Title key** | `play.rules.prisoner.capture.title` |
| **Body key** | `play.rules.prisoner.capture.body` |

Hit the inner board (bull through triple ring) and the dart becomes a prisoner. Anyone who later hits the playable area of that same number captures it and adds it to their dart pool. You might finish throwing seven darts none of which started as yours.

---

## Localization

| **Exists** | `modes.catalog.party.prisoner.name`, `.blurb` |

### New keys

**Setup:** `play.party.prisoner.title`, `.subtitle`

**Gameplay:** `play.prisoner.navTitle`, `progressSegmentFormat`, `dartPoolFormat`, `prisonerCaptured`, `prisonerOnBoard`, `dartLostOneTurn`, `playableRingHint`, `boardOverlayAccessibilityFormat`

**How to play:** `play.rules.prisoner.overview|progress|lost|capture`

**History:** `history.timeline.prisonerVisitFormat`, `history.detail.prisonerSummaryFormat`

**Validation:** `setup.validation.prisonerMinimumPlayers` (min 2; recommend copy for 4+)

---

## 6. Data Capture
- `PrisonerDartEvent`: location, capture events, progress delta

---

## 7. Testing
- Unit: prisoner capture, pool growth, clockwise order
- Edge: multiple prisoners same segment (one at a time capture)

---

## 8. Verification
| Field | Value |
|-------|-------|
| **Status** | Planned |
