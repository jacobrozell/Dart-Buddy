**Estimated release:** `1.0`

# Visual Dartboard Input Specification

## 1. Purpose
Define the optional **visual dartboard** dart-entry presentation: a circular, tappable
board where the player records each throw by tapping the zone the dart hit, as an
alternative to the number pads ([`ScoringInputSpec.md`](ScoringInputSpec.md)).

Promoted from [`FutureIdeas/visual-dartboard-input.md`](../FutureIdeas/visual-dartboard-input.md).
Distinct from the Cricket marks scoreboard (`CricketBoardView`), camera auto-scoring
([`AutoScoringVisionSpec.md`](AutoScoringVisionSpec.md)), and Talk Mode.

---

## 2. Terminology

| Term | Values | Notes |
|------|--------|-------|
| Dart entry mode | `totalEntry` \| `dartEntry` | X01 semantic (`ScoringInputMode`); unchanged |
| **Dart entry presentation** | `numberPad` \| `visualBoard` | `DartEntryPresentation` — how `enteredDarts` is built |

The presentation is a **view swap behind the same ViewModel bindings**
(`enteredDarts`, `selectedMultiplier`); no engine or scoring-pipeline changes.

---

## 3. Scope (v1)

| In | Out |
|----|-----|
| X01 + Cricket matches | Party modes (Baseball, Killer, Shanghai) — pad only |
| Settings default + in-match toggle | Per-match setup override |
| Ring-accurate tap entry | Two-step wedge-then-ring entry, zoom |
| | X01 `totalEntry` on the board |

---

## 4. Interaction Model

**Ring-accurate tapping:** the board renders all scoring zones and a tap commits the
dart for the exact zone hit — no sticky multiplier needed.

| Tap zone | `DartInput` |
|----------|-------------|
| Inner bull circle | Inner bull (50) — `single` + `.innerBull`, matching pad encoding |
| Outer bull band | Outer bull (25) |
| Inner/outer single areas | S{wedge} |
| Triple ring | T{wedge} |
| Double ring | D{wedge} |
| Outside the playable circle | Ignored (no dart) |
| **MISS** key (below board) | Miss dart |

- Double/triple rings and bull circles are drawn **wider than regulation** so they stay
  tappable (`BoardHitResolver.RingBounds`); the drawing and hit test share the same bounds.
- Each commit resets `selectedMultiplier` to `single` and shows a brief hit label at the
  tap point (respects Reduce Motion).
- Visit preview, max 3 darts, undo semantics, X01 auto-submit, and Cricket ENTER behave
  exactly as on the pads.
- **Cricket:** the full 1–20 clock renders; non-scoring wedges (1–14) are dimmed but
  remain tappable — the engine records the dart with zero marks, mirroring a real
  wasted throw. Bull stays active.

Wedge order is the regulation clock (`BoardHitResolver.segmentOrder`), 20 at 12 o'clock.

---

## 5. Settings & In-Match Control

### Global default

- `SettingsRecord.defaultDartEntryPresentationRaw` (optional column; `nil` → `numberPad`).
- Settings → **During Play** → "Scoring Input" picker (`settings_dartEntryPresentationPicker`).
- Applies to **new match screens**; it does not mutate a match already on screen.

### In-match toggle

- Match header button next to undo (`match_dartEntryPresentationToggle`) on X01 and
  Cricket; flips presentation immediately for the current screen only (not persisted).
- Darts already entered in the visit are kept — both presentations share `enteredDarts`.
- Resume uses the Settings default again (session-scoped override; see Future Work).

---

## 6. Layout

Board renders in the pad band of `MatchScoringBody`, square (aspect 1:1), capped at
`VisualDartboardMetrics.portraitBoardMaxHeight` / `landscapeBoardMaxHeight`, with the
MISS / UNDO (/ ENTER for Cricket) row below. iPad sidebar widths (420/300pt) constrain
the board via aspect fit.

---

## 7. Accessibility

The number pad stays **first-class**; the board is a sighted-ergonomics enhancement.

| Condition | Behavior |
|-----------|----------|
| Dynamic Type AX1–AX5 | Number pad forced, regardless of preference |
| VoiceOver running | Number pad forced (board zones are not yet individual elements) |
| Board root | Single element: label + hint pointing at the header toggle (`board_input_root`) |
| MISS / UNDO / ENTER keys | Standard `ScoringPadKey` labels and 44pt+ targets |

Per-wedge VoiceOver elements are future work; until then the forced-pad rule guarantees
non-visual users an equivalent flow.

---

## 8. UI Test Identifiers

| Element | Identifier |
|---------|------------|
| Board root | `board_input_root` |
| Visit preview | `board_visit_preview` |
| Miss / Undo / Enter | `board_miss`, `board_undo`, `board_enter` |
| In-match toggle | `match_dartEntryPresentationToggle` |
| Settings picker | `settings_dartEntryPresentationPicker` |

Existing `pad_*` / `cricket_*` identifiers are unchanged.

---

## 9. Components

| Piece | Responsibility |
|-------|----------------|
| `BoardHitResolver` (Domain) | Pure geometry: point + board frame → `DartInput?` |
| `DartEntryPresentation` (Domain) | Presentation enum + safe raw-value fallback |
| `VisualDartboardInput` | SwiftUI board + miss/undo/enter chrome; same bindings as pads |
| `DartEntryPresentationToggle` | Match-header switch |

---

## 10. Testing

| Layer | Coverage |
|-------|----------|
| Unit | `BoardHitResolverTests` (rings, wedge boundaries, bulls, outside taps), presentation fallback, settings persistence (`SettingsViewModelTests`), nil-column default (`SettingsRecordMigrationTests`) |
| Manual / UI | In-match toggle on both modes, landscape, AX-forces-pad — see §11 |

---

## 11. Accessibility verification
- Manual: extend [`x01-match.md`](../accessibility/wcag-2.1-aa/screens/x01-match.md) and
  [`cricket-match.md`](../accessibility/wcag-2.1-aa/screens/cricket-match.md) with the
  board presentation when capturing the next evidence pass.

## 12. Verification
| Field | Value |
|-------|--------|
| **Estimated release** | `1.0` |
| **Last verified** | 2026-06-12 |
| **Commit** | _initial implementation_ |
| **Code** | `VisualDartboardInput.swift`, `BoardHitResolver.swift`, `DartEntryPresentation.swift` |

---

## 13. Future Improvements
- Persist the in-match override in the match session/snapshot for resume.
- Killer, then segment-locked party modes (Baseball/Shanghai `lockedSegment` highlight).
- Per-wedge VoiceOver elements; per-match setup override (callout-voice pattern).