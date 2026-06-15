**Estimated release:** `1.0`

# Scoring Input Specification

## 1. Purpose
Define a reusable custom scoring input system for X01 and Cricket, including `Single/Double/Triple` dart entry such as `T20`.

---

## 1a. Entry Presentation
The pad is the default **dart entry presentation**. An optional tappable visual
dartboard presentation shares the same bindings and visit rules — see
[`VisualDartboardInputSpec.md`](VisualDartboardInputSpec.md).

---

## 2. MVP Goals
- Fast one-hand input
- Large touch targets for standing play
- Low input error rate with clear undo path
- Shared component across game modes

---

## 3. Component Model

## Shared Component
- **Scoring input pad** (concept) — implemented as `DartNumberPad` (SwiftUI reusable component)

Modes:
1. `totalEntry`
   - User enters aggregate turn total (primarily X01 fast mode)
2. `dartEntry`
   - User enters each dart as `multiplier + segment` (X01 precision mode, Cricket required)

## Supporting State
- `multiplierSelection: single|double|triple`
- `segmentSelection: Int?` (1...20, plus bull options where relevant)
- `enteredDarts: [DartInput]` (max 3)
- `computedTurnTotal: Int`

---

## 4. UI Specification

## Layout Regions
- Multiplier row: `S`, `D`, `T`
- Segment grid: `1...20`, plus `Outer Bull`, `Inner Bull`
- Active entry preview (e.g., `T20`, `D16`)
- Current turn list (dart 1-3)
- Actions:
  - `Submit Turn`
  - `Backspace`
  - `Clear Turn`
  - `Undo Last Turn`

## Interaction Rules
- Tapping multiplier sets current modifier.
- Tapping segment commits one dart with selected modifier.
- Auto-reset multiplier behavior:
  - Option A (recommended): persist last multiplier until changed
  - Option B: reset to `S` after each dart
- Cap at 3 darts per turn.

Recommended MVP behavior: persist selected multiplier until changed for speed.

---

## 5. Domain Mapping

`DartInput` model:
- `multiplier: single|double|triple`
- `segment: oneToTwenty|outerBull|innerBull`
- `points: Int` (derived)
- `isMiss: Bool` (optional v1.1)

Examples:
- `T20` -> 60
- `D20` -> 40
- `S5` -> 5
- `Outer Bull` -> 25
- `Inner Bull` -> 50

Turn submission:
- `enteredDarts` -> calculate `turnTotal`
- pass to mode engine for validation and application
- persist turn event + dart events

---

## 6. X01-Specific Behavior
- Allow both input modes:
  - total quick entry
  - dart-by-dart entry
- In `doubleOut`, only a final double can legally checkout.
- If user enters 3 darts that violate checkout constraints, engine returns bust and UI surfaces it clearly.

---

## 7. Cricket-Specific Behavior
- Use dart-by-dart entry only in MVP.
- Multiplier maps to mark count (S=1, D=2, T=3).
- For closed targets, overflow marks become points when opponents still open.
- Bulls use Cricket-specific mark and scoring rules.

## 7a. Baseball-Specific Behavior
- Dart-by-dart entry only; pad segment locked to `currentInning` (see [`BaseballGameSpec.md`](game-modes/implemented/BaseballGameSpec.md)).
- Multiplier maps to runs on active segment (S=1, D=2, T=3); off-segment = 0.
- Bull appears on pad only during 7th-inning stretch (inning 7) or bull playoff phase.
- See [`BaseballGameSpec.md`](game-modes/implemented/BaseballGameSpec.md) for stretch gate and tie-breaker input rules.

---

## 8. Accessibility
- 52x52 minimum target size for scoring buttons
- VoiceOver labels:
  - `Single 20`, `Double 20`, `Triple 20`
  - `Outer Bull`, `Inner Bull`
- Haptic on commit (respect setting)
- Avoid color-only multiplier state; use strong text + selected outline

---

## 9. Error Prevention
- Disable impossible combinations where applicable
- Show live computed total before submit
- Require confirmation only for destructive actions, not normal scoring
- Always provide `Undo Last Turn`

---

## 10. Testing

## Unit
- Multiplier/segment -> points mapping
- Turn total composition from darts
- Bull mapping correctness

## Integration
- X01: `T20,T20,D20` scoring and checkout validation
- Cricket: triple mark closure and overflow scoring

## UI
- Multiplier state transitions
- VoiceOver labels and focus order
- Large text and dark mode legibility

---

## 11. Accessibility verification
- Manual: [`x01-match.md`](../accessibility/wcag-2.1-aa/screens/x01-match.md), [`cricket-match.md`](../accessibility/wcag-2.1-aa/screens/cricket-match.md), [`_shared-components.md`](../accessibility/wcag-2.1-aa/screens/_shared-components.md)

## 12. Verification
| Field | Value |
|-------|--------|
| **Estimated release** | `1.0` |
| **Last verified** | 2026-06-11 |
| **Commit** | `340f788` |
| **Code** | `DartNumberPad.swift` (X01/Cricket/party match screens) |

---

## 13. Future Improvements
- Gesture shortcuts for common darts
- Optional manual correction/edit for current turn before submit