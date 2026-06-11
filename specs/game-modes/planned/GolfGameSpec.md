# Golf Game Specification

## 1. Purpose
Define Golf (darts) — stroke-play across 9 or 18 holes — for future implementation.

**Status:** Planned (`party.golf`). R&D: [`FutureIdeas/party-practice-modes.md`](../../../FutureIdeas/party-practice-modes.md).

References: [GLD Golf darts](https://gldproducts.com/blogs/all/how-to-play-golf-darts), [darts501.com](https://darts501.com/Games.html).

---

## 2. Catalog metadata
| Field | Value |
|-------|-------|
| **Section** | Party |
| **UI template** | C — Inning points (stroke scorecard) |
| **Stat kind** | Innings |
| **Ruleset (v1)** | `golf_gld_last_dart` |

---

## Player count

| Question | Answer |
|----------|--------|
| **Solo?** | Not in v1 — stroke play compares totals across a roster |
| **Minimum** | 2 participants (≥1 human) |
| **Recommended** | 2–4 (scorecard width); up to 6 comfortable |
| **App maximum** | 8 |

### Brainstorm
- Golf is lowest-strokes-wins; solo vs par is a natural practice variant but deferred (post-v1 `soloVsPar`).
- **2** is the real multiplayer floor; foursome golf maps to 4 players well.
- **8** stretches the hole×player grid — use scroll + running totals only at 6+ (same pattern as Baseball).
- Bots need “stop early on double” behavior — feasible at any count 2–8.

---

## 3. MVP Scope
- Course: **9 or 18 holes** (segments 1→9 or 1→18)
- Up to 3 darts per hole; player may **end turn early** after 1–2 darts
- **Last dart thrown counts** for the hole (GLD ruleset)
- Strokes per dart on target segment: **double = 1**, **triple = 2**, **single = 3**, **miss = 5**
- **Lowest total strokes wins**
- Segment-locked pad per hole; undo last hole resolution
- Local persistence; preset bots in v1

### Out of Scope (v1)
- A1 wedge 1–5 ring scoring, handicap/par adjustment (v2 `golf_a1_wedge`)

---

## 4. Rules Engine (`GolfEngine`)

### Config (`MatchConfigGolf`, payload v1)
| Field | Default |
|-------|---------|
| `courseLength` | `9` |
| `ruleset` | `golf_gld_last_dart` |
| `lastDartOnly` | `true` |

### State
- `currentHole` (1…courseLength)
- `strokes[playerId][hole]`, `runningTotal[playerId]`
- `dartsThrownThisHole`, `lastDartResolution?`

### Turn flow
1. Player throws 1–3 darts at current hole segment.
2. On early end or 3rd dart, record **last dart** stroke value for hole.
3. Advance hole when all players complete; lowest total wins at end.

### Undo
Replay restores hole index and stroke grid.

---

## 5. UI Specification
- Template C: **scorecard** (holes × players) + current hole target
- Actions: Submit, End turn early, Undo
- Accessibility: stroke values not color-only on scorecard

---

## How to Play

| | |
|---|---|
| **Key prefix** | `play.rules.golf.` |
| **Shipped in app** | Planned |

### Overview
| **Title key** | `play.rules.golf.overview.title` |
| **Body key** | `play.rules.golf.overview.body` |

Golf darts is stroke play on the board. Each hole is a segment in order (1 through 9 or 18). Lowest total strokes after the course wins — like real golf.

### Per hole
| **Title key** | `play.rules.golf.perHole.title` |
| **Body key** | `play.rules.golf.perHole.body` |

You may throw up to three darts at the current hole's segment. You can stop after one or two darts if you like your result. Only the last dart you throw counts for that hole.

### Strokes
| **Title key** | `play.rules.golf.strokes.title` |
| **Body key** | `play.rules.golf.strokes.body` |

On the target segment: double = 1 stroke, triple = 2 strokes, single = 3 strokes, miss = 5 strokes. Lower is better.

### Winning
| **Title key** | `play.rules.golf.winning.title` |
| **Body key** | `play.rules.golf.winning.body` |

After everyone completes every hole, add strokes. The player with the lowest total wins. Ties can play extra holes (future setup option).

---

## Localization

| **Exists** | `modes.catalog.party.golf.name`, `.blurb` |

### New keys

**Setup:** `play.party.golf.title`, `.subtitle`; `play.golf.setup.courseLength` (9/18); `play.golf.setup.ruleset.gldLastDart`

**Gameplay:** `play.golf.navTitle`, `header.holeFormat`, `strokesThisHoleFormat`, `runningTotalFormat`, `lastDartCountsHint`, `endTurnEarly`, `stroke.double` / `stroke.triple` / `stroke.single` / `stroke.miss` (labels), `scorecard.holeHeader`, `scorecard.totalFormat`, `pad.lockedHoleHint`, `pad.disabledWhileBot`, `announce.holeComplete`

**How to play:** `play.rules.golf.overview|perHole|strokes|winning`

**History:** `history.timeline.golfHoleFormat`, `history.detail.golfSummaryFormat`, `history.lineScore.golf*` (hole grid — mirror baseball line score keys)

**Validation:** `setup.validation.golfMinimumPlayers` (min 2)

---

## 6. Data Capture
- `GolfHoleEvent`: `hole`, `darts[]`, `strokesRecorded`, `lastDartOrder`

---

## 7. Testing
- Unit: last-dart resolution, early end, 9/18 course, win by lowest
- UI: early-end affordance

---

## 8. Verification
| Field | Value |
|-------|-------|
| **Status** | Planned |
