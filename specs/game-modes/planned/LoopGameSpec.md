# Loop Game Specification

## 1. Purpose
Define Loop (Loopy) — Follow the Leader with wire loops and split segments — for future implementation.

**Status:** Planned (`party.loop`).
**Estimated release:** `TBD`

References: [darts501.com — Loop](https://darts501.com/Games.html).

---

## 2. Catalog metadata
| Field | Value |
|-------|-------|
| **Section** | Party |
| **UI template** | D — Lives elimination |
| **Stat kind** | Lives |
| **Ruleset (v1)** | `loop_wire_targets` |

---

## Player count

| Question | Answer |
|----------|--------|
| **Solo?** | No — wire-target matching game for a group |
| **Minimum** | 2 participants (≥1 human) |
| **Recommended** | 4–8 |
| **App maximum** | 8 |

### Brainstorm
- Same social dynamics as Follow the Leader; Loop adds wire/split targets — still needs followers.
- **2** is minimum for rules; **4+** recommended for variety in target setting.
- UI complexity (wire targets) is per-turn, not per-player — 8 remains OK.

---

## 3. MVP Scope
- Extends Follow the Leader: valid targets include **wire loops**, **split numbers**, and standard scoring areas
- First dart establishes target area; followers must hit same **wire target** or lose a life (3 lives default)
- Loop segments: 4, 6, 8, 10, 14, 16, 18, 20 (upper/lower loop variants)
- Split segments: e.g. between the two digits of 11
- Requires extended `TargetArea` model beyond ring enum
- Undo; local persistence

### Out of Scope (v1)
- Full wire geometry auto-detection from board photo

---

## 4. Rules Engine (`LoopEngine`)

### Config (`MatchConfigLoop`, payload v1)
| Field | Default |
|-------|---------|
| `startingLives` | `3` |

### State
- `target: WireTargetArea?` — superset of Follow the Leader target
- `lives[playerId]`

### Turn flow
Same as Follow the Leader but `WireTargetArea` equality includes loop id and split id.

### Undo
Event replay.

---

## 5. UI Specification
- Template D + wire-target picker overlay on board diagram (accessibility: spoken target name e.g. "lower loop 6")
- May share components with Follow the Leader when target is standard ring

---

## How to Play

| | |
|---|---|
| **Key prefix** | `play.rules.loop.` |
| **Shipped in app** | Planned |
| **Estimated release** | `TBD` |

### Overview
| **Title key** | `play.rules.loop.overview.title` |
| **Body key** | `play.rules.loop.overview.body` |

Loop is Follow the Leader on the wiring of the board. Match the leader's target — including wire loops and splits between digits — or lose a life. Three lives each; last player standing wins.

### Valid targets
| **Title key** | `play.rules.loop.targets.title` |
| **Body key** | `play.rules.loop.targets.body` |

A target can be a normal scoring wedge, a wire loop (on numbers like 6, 8, 16, 20), or a split between the two digits of a number (e.g. between the ones of 11). The app names the target clearly when it is set.

### Play
| **Title key** | `play.rules.loop.play.title` |
| **Body key** | `play.rules.loop.play.body` |

The first dart establishes the target. Followers must hit that exact wire area in three darts or lose a life. Hit early and you may set a new target with remaining darts, same as Follow the Leader.

### Loops and splits
| **Title key** | `play.rules.loop.wires.title` |
| **Body key** | `play.rules.loop.wires.body` |

Upper and lower loops on the same number are different targets. A dart in the loop of 6 is not the same as the large single 6.

---

## Localization

| **Exists** | `modes.catalog.party.loop.name`, `.blurb` |

### New keys

**Setup:** `play.party.loop.title`, `.subtitle`; reuse `play.followTheLeader.setup.startingLives` or `play.loop.setup.startingLives`

**Gameplay:** `play.loop.navTitle`, `wireTarget.loopFormat`, `wireTarget.splitFormat`, `wireTarget.lowerLoop` / `upperLoop`, `currentWireTargetAccessibilityFormat`, `lifeLost`, `livesRemainingFormat` — extend Follow the Leader keys where possible

**How to play:** `play.rules.loop.overview|targets|play|wires`

**History:** `history.timeline.loopVisitFormat`, `history.detail.loopSummaryFormat`

**Validation:** `setup.validation.loopMinimumPlayers` (min 2)

---

## 6. Data Capture
- `LoopVisitEvent`: `wireTargetRaw`, `matched`, `lifeLost`

---

## 7. Testing
- Unit: wire target equality, loop vs segment distinction
- UI: target callout for loop targets

---

## 8. Verification
| Field | Value |
|-------|-------|
| **Status** | Planned |
