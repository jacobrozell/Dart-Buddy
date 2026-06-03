# Cricket Game Specification

## 1. Purpose
Define Cricket gameplay rules, board UI, input model, and persistence for the iPhone MVP.

---

## 2. MVP Scope
- Standard Cricket targets: `20,19,18,17,16,15,bull`
- 2..N players
- Mark-based input
- Point overflow scoring when opponents have not closed target
- Undo last accepted turn
- Local-only persistence with turn + dart granularity
- Shared input component: see `specs/ScoringInputSpec.md`

---

## 3. Rules Engine

## Match Completion Rule
The match ends when every player has closed all Cricket targets (`20` through `15` and `bull`).
The winner is the player with the highest score at that moment.
If multiple players tie for the highest score, the earliest seat in turn order wins.

## Mark Processing
- Single/Double/Triple contribute 1/2/3 marks on target
- A target closes at 3 marks for a player
- Marks beyond closure are overflow marks
- Overflow converts to points only while at least one opponent has not closed that target

## Bull Handling
- Outer bull = single bull mark
- Inner bull = double bull marks

---

## 4. UI Specification

## Board Layout
- Rows: `20..15` + `Bull`
- Columns: one per player
- Cell state visual:
  - open marks (0..2)
  - closed state (3+)
  - should include color + iconography (not color-only)

## Input Panel
- Shared `ScoringInputPad` in dart-entry mode
- Target selector row
- Multiplier controls: `S`, `D`, `T` (+ bull-specific constraints)
- Submit turn action
- Undo action

## Readability
- Large marks/closures for distance readability
- Sticky player turn indicator
- Per-player points always visible

---

## 5. Data Capture Requirements

## Turn Event (`CricketTurnEvent`)
- `matchId`
- `playerId`
- `turnIndex`
- `roundIndex`
- `totalPointsAdded`
- `targetsTouched: [CricketDartTouch]`
- `boardBeforePayload`
- `boardAfterPayload`
- `timestamp`

## Dart Event (`CricketDartEvent`)
- `turnEventId`
- `dartOrder`
- `targetNumber` (`15...20` or `bull`)
- `multiplier`
- `marksAdded`
- `overflowMarks`
- `pointsAdded`
- `wasMiss`

---

## 6. Edge Cases
- Triple on already-closed target may score up to 3x target value if opponents still open
- Bull overflow should use bull value policy consistently (define in constants)
- Undo across closing transitions must restore marks and points exactly
- Large player counts must remain performant and readable

---

## 7. Testing

## Unit
- Closure logic by target
- Overflow scoring when mixed opponent closure states
- Bull-specific scoring and mark behavior
- Match completion tie/lead conditions

## Integration
- Complete match with 3+ players
- Resume from mid-board state

## UI
- Board state rendering correctness
- Accessibility labels per target cell

---

## 8. Future Improvements
- Fast batch entry for full turn (3 darts at once)
- Cricket variants (cut-throat, no-score variants)
- Live throw quality metrics and closure-speed charts
