# X01 Game Specification

## 1. Purpose
Define X01 gameplay, rule variants, UI behavior, and persistence for MVP with both Single-Out and Double-Out from day one.

---

## 2. MVP Scope
- Modes: 301 and 501
- Supports 2..N players
- Legs and optional sets
- Checkout modes:
  - `singleOut` (finish on exact zero)
  - `doubleOut` (finish on exact zero on a double)
- Undo last accepted turn
- Local persistence with turn and dart event capture
- Shared input component: see `specs/ScoringInputSpec.md`

---

## 3. Rules Engine

## Inputs
- `MatchConfigX01`:
  - `startScore` (301 or 501)
  - `legsToWin`
  - `setsEnabled`
  - `setsToWin?`
  - `checkoutMode` (`singleOut`, `doubleOut`)

## Commands
- `submitTurn(totalPoints: Int, darts: [DartInput]?)`
- `undoLastTurn()`
- `advanceLegIfComplete()`

## Validation
- Reject totals outside `0...180`
- Reject invalid dart composition if provided
- Prevent score from going below zero
- For checkout:
  - Single-Out: exact zero required
  - Double-Out: exact zero and final dart is double
- Bust behavior:
  - Bust resets turn effect (score returns to turn start)
  - Turn passes to next player

---

## 4. UI Specification

## Main Screen Regions
- Header:
  - Current player highlight
  - Leg/set counters
  - Checkout mode badge (`Single-Out` / `Double-Out`)
- Scoreboard:
  - Remaining score per player, large typography
- Input panel:
  - Shared `ScoringInputPad`
  - Total entry (`0...180`) for speed
  - Dart-by-dart entry with `S/D/T` + segment (`T20`, `D16`, etc.)
  - `Submit`
  - `Undo`

## Interaction Notes
- `Submit` disabled on invalid total
- Successful submit triggers subtle haptic
- Bust shows short transient message
- When checkout is possible, show non-blocking checkout suggestion from `CheckoutSuggester` (fewest-dart valid route for current remaining score and mode)
- Each player score card shows the current visit's dart slots for every player who has thrown in the current scoring round (one full rotation through all players). When the turn wraps back to player 1, all visit slots clear. A new leg clears all visit slots.

---

## 5. Data Capture Requirements

## Turn Event (`X01TurnEvent`)
- `matchId`
- `playerId`
- `turnIndex`
- `legIndex`
- `setIndex`
- `startRemaining`
- `enteredTotal`
- `appliedTotal`
- `endRemaining`
- `isBust`
- `didCheckout`
- `checkoutMode`
- `checkoutDartCount?`
- `timestamp`

## Dart Event (`X01DartEvent`)
- `turnEventId`
- `dartOrder` (1..3)
- `multiplier` (`single`,`double`,`triple`)
- `segmentValue`
- `points`
- `wasMiss`

This schema enables future checkout heatmaps and progression charts.

---

## 6. Edge Cases
- Entering `0` is valid (no score turn)
- Entering total that causes bust applies no score delta
- Double-Out with zero reached on non-double is bust
- Last-turn undo after leg win should rollback leg transition safely

---

## 7. Testing

## Unit
- Single-Out exact finish scenarios
- Double-Out finish validity
- Bust permutations near zero
- Leg/set transition logic
- Undo across leg boundary

## Integration
- Full 501 match with sets enabled
- Mid-match persistence + resume

## UI
- Input panel validation states
- Checkout mode label accuracy
- Completed visit darts persist on score cards until the scoring round advances

---

## 8. Accessibility verification
- Manual: [`x01-match.md`](../accessibility/wcag-2.1-aa/screens/x01-match.md)
- Shared pad: [`_shared-components.md`](../accessibility/wcag-2.1-aa/screens/_shared-components.md)

## 9. Analytics
§12 — `match_completed`, `turn_submitted`, `turn_undone`, `dart_undone`, `turn_bust` (log), `bot_turn_started` (log).

## 10. Verification
| Field | Value |
|-------|--------|
| **Last verified** | 2026-06-04 |
| **Commit** | `0c25396` |
| **Code** | `X01Engine.swift`, `X01MatchViewModel.swift`, `CheckoutSuggester.swift` |

---

## 11. Future Improvements
- Multi-route checkout picker when several equally short routes exist
- Voice scoring entry
- AI opponent (deferred by product decision)
