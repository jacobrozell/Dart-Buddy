# Chase the Dragon Game Specification

## 1. Purpose
Define Chase the Dragon — hit trebles 10 through 20 then outer and inner bull in order — for future implementation.

**Status:** Shipped (`practice.chaseTheDragon`).
**Estimated release:** `1.4`

**In-visit progression:** [`InVisitSequenceProgressionSupplement.md`](../InVisitSequenceProgressionSupplement.md) — qualifying treble/bull per step; pad uses modifiers (no segment lock).

References: [darts501.com — Chase the Dragon](https://darts501.com/Games.html).

---

## 2. Catalog metadata
| Field | Value |
|-------|-------|
| **Section** | Practice |
| **UI template** | E — Sequence progress |
| **Stat kind** | Sequence |
| **Ruleset (v1)** | `chase_the_dragon_standard` |

---

## Player count

| Question | Answer |
|----------|--------|
| **Solo?** | Yes — accuracy drill (trebles 10–20 + bulls) |
| **Minimum** | 1 participant |
| **Recommended** | 1 solo; 2–4 race |
| **App maximum** | 8 |

### Brainstorm
- Fast solo drill for out-shot trebles; multiplayer is first-through-sequence wins.
- Three-headed dragon (3 laps) lengthens solo sessions — player count agnostic.
- **8** players racing the same 13-step dragon is busy but turns are single-target checks.

---

## 3. MVP Scope
- Sequence: **T10, T11, … T20, outer bull, inner bull** (treble segments only for 10–20)
- 3 darts per turn; **each qualifying hit** advances to the next dragon step for the rest of the visit
- First to complete sequence wins (multiplayer) or best time/dart count (solo)
- Optional: **three-headed dragon** — complete full sequence 3 times (setup chip)
- Sequence strip with treble+bull icons; per-dart entry; undo

### Out of Scope (v1)
- Singles count on dragon segments

---

## 4. Rules Engine (`ChaseTheDragonEngine`)

### Config (`MatchConfigChaseTheDragon`, payload v1)
| Field | Default |
|-------|---------|
| `laps` | `1` |

### State
- `stepIndex[playerId]` on fixed 13-step course

### Turn flow
1. Process darts in order; validate each dart against the **current** step (treble N or bull type).
2. Each qualifying hit advances one step; lap wrap per config (supplement §3).

### Undo
Replay restores step indices.

---

## 5. UI Specification
- Template E emphasizing **treble** targets in strip
- Header shows effective dragon step during entry (supplement §4); pad arms double/triple — segment keys stay enabled but only the current step's treble/bull counts
- Solo: timer + darts-to-complete

---

## How to Play

| | |
|---|---|
| **Key prefix** | `play.rules.chaseTheDragon.` |
| **Shipped in app** | Yes |
| **Estimated release** | `1.4` |

### Overview
| **Title key** | `play.rules.chaseTheDragon.overview.title` |
| **Body key** | `play.rules.chaseTheDragon.overview.body` |

Chase the trebles from 10 through 20, then outer bull, then inner bull — in that order. Fast training for common out-shot trebles.

### Sequence
| **Title key** | `play.rules.chaseTheDragon.sequence.title` |
| **Body key** | `play.rules.chaseTheDragon.sequence.body` |

You must hit the treble of the current number to advance (T10, T11, … T20). Then hit outer bull, then inner bull to finish. Singles and doubles on the number do not advance you.

### Turns
| **Title key** | `play.rules.chaseTheDragon.turns.title` |
| **Body key** | `play.rules.chaseTheDragon.turns.body` |

Three darts per turn. Each qualifying hit moves you one step for the rest of the visit. Multiplayer: first to finish the full dragon wins.

### Three-headed dragon
| **Title key** | `play.rules.chaseTheDragon.laps.title` |
| **Body key** | `play.rules.chaseTheDragon.laps.body` |

Optional setup: complete the full sequence three times to win. Extends the game for groups or endurance practice.

---

## Localization

| **Exists** | `modes.catalog.practice.chaseTheDragon.name`, `.blurb` |

### New keys

**Setup:** `play.chaseTheDragon.setup.laps` (1 vs 3-headed dragon)

**Gameplay:** `play.chaseTheDragon.navTitle`, `step.trebleFormat`, `step.outerBull` / `step.innerBull`, `sequenceProgressFormat`, `lapFormat`, `dragonComplete`, `solo.timeToCompleteFormat`

**How to play:** `play.rules.chaseTheDragon.overview|sequence|turns|laps`

**History:** `history.timeline.chaseTheDragonStepFormat`, `history.detail.chaseTheDragonSummaryFormat`

---

## 6. Data Capture
- `ChaseTheDragonVisitEvent`: `stepBefore`, `stepAfter`, `lap`

---

## 7. Testing
- Unit: treble-only validation, bull order, multi-lap, **multi-step visit**
- View model: effective dragon step during entry

---

## 8. Verification
| Field | Value |
|-------|-------|
| **Status** | Shipped |
