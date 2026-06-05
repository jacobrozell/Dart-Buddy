# Killer Game Specification

## 1. Purpose
Define Killer (party elimination mode) gameplay rules, play UI, input model, persistence, and history for the iPhone MVP.

Authoritative rules reference: [`FutureIdeas/killer-darts.md`](../FutureIdeas/killer-darts.md) (`killer_double_standard`).

---

## 2. MVP Scope
- `killer_double_standard` ruleset only
- 3..N human players (no bots in v1)
- Number-pick phase (one dart per player, non-dominant hand — honor system + copy)
- Starting lives: 3–5 (default 3)
- Become Killer on own double; damage opponents with doubles only
- Self-double penalty while Killer
- Per-dart entry via full-board scoring pad
- Undo last accepted pick/turn
- Local-only persistence with event granularity
- Party setup category (`PlaySetupCategory.party` → `PartyGame.killer`)

### Out of Scope (v1)
- `killer_marks_progression` variant
- Bots, achievements, eliminated players as targets

---

## 3. Rules Engine (`KillerEngine`)

### Config (`MatchConfigKiller`, payload v1)
| Field | Default |
|-------|---------|
| `startingLives` | `3` |
| `bullAllowedOnPick` | `false` |

### Phases
1. **Number pick** — each player throws one dart; segment 1–20 becomes their number; miss or taken number → rethrow.
2. **Playing** — 3 darts per turn; skip eliminated players; last player with lives wins.

### Undo
Replay from events restores assigned numbers, lives, killer flags, elimination, phase, and turn order exactly.

---

## 4. UI Specification

### Setup (`SetupHomeView+KillerOptionChips`)
- Party category → Killer game picker
- Chip: starting lives (3/4/5)
- Validation: min 3 players, humans only

### Play screen (`KillerMatchScreen`)
| Region | Content |
|--------|---------|
| Header | Current thrower; pick vs play hint |
| Board | Number chip, lives pips, killer badge per player |
| Pick grid | Taken numbers 1–20 with player initials |
| Pad | Full board; 1 dart in pick phase, 3 in play |
| Actions | Submit, Undo |

### Match end
- Routes to shared match summary; history shows lives standings and turn timeline.

---

## 5. Data Capture

### Events
- `KillerPickEvent` — pick phase dart and assigned number (if any)
- `KillerTurnEvent` — play phase darts with `KillerDartResolution` effects

Payload fields: see `KillerEngine.swift` and `SwiftData.md` when payload version is registered.

---

## 6. Testing
- Unit: pick collision, become killer, damage gates, elimination, undo (`KillerEngineTests.swift`, `MatchLifecycleService` replay)
- Setup: 3+ humans, bot rejection (`MatchSetupViewModelTests.swift`)
