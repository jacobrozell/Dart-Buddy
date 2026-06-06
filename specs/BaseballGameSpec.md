# Baseball Game Specification

## 1. Purpose
Define Baseball (party mode) gameplay rules, play UI, input model, persistence, and history for the iPhone MVP.

Authoritative rules reference: [GLD Baseball darts](https://gldproducts.com/blogs/all/how-to-play-baseball-darts).

---

## 2. MVP Scope
- Nine-inning default (`inningCount: 9`); segment *n* scores in inning *n*
- Runs: single = 1, double = 2, triple = 3 on the active segment only (not face value)
- 2..N human players; **preset difficulty bots only** (no training/custom bots in v1)
- Tie-breakers: `extraInnings` (default) or `bullPlayoff`
- Optional **7th-inning stretch**: bull hit required before segment 7 runs count in inning 7
- Per-dart entry via segment-locked scoring pad
- Undo last accepted turn (same guarantees as X01/Cricket)
- Local-only persistence with turn + dart granularity
- Party setup category (`PlaySetupCategory.party` → `PartyGame.baseball`)

### Out of Scope (v1)
- Training Partner and custom bots in baseball roster
- Team baseball, 10-inning board variant, achievements

---

## 3. Rules Engine (`BaseballEngine`)

### Config (`MatchConfigBaseball`, payload v1)
| Field | Default |
|-------|---------|
| `inningCount` | `9` |
| `tieBreaker` | `.extraInnings` |
| `seventhInningStretch` | `false` |

### Turn flow
1. All players throw three darts for the current inning target.
2. Advance inning when the last player completes the inning.
3. After `inningCount` innings, highest cumulative runs wins.
4. Tie → extra innings (segment 10, 11, …) or bull playoff per config.

### Undo
Replay from events restores cumulative runs, inning-local runs, `currentInning`, turn index, stretch gate, and playoff state exactly.

---

## 4. UI Specification

### Setup (`SetupHomeView+BaseballOptionChips`)
- Party category → Baseball game picker
- Chips: innings (9), tie-breaker, 7th-inning stretch
- Validation: `setup.validation.baseballBotsPresetOnly` when roster includes training/custom bots

### Play screen (`BaseballMatchScreen`)
| Region | Content |
|--------|---------|
| Header | Inning + target text; extra-inning badge when applicable |
| Scoreboard | Cumulative runs; optional “this inning” column when &lt; 6 players |
| Inning strip | Dots 1–9 (+ extras); completed/current/upcoming — **not color-only** |
| Pad | Segment locked to `currentInning` (or bull in stretch/playoff) |
| Actions | Submit, Undo |

Wireframe: [`UIBlueprintSpec.md`](UIBlueprintSpec.md) §4.4a.

### Match end
- Routes to shared match summary; history detail includes line-score grid (see [`HistorySpec.md`](HistorySpec.md)).

---

## 5. Data Capture

### Turn event (`BaseballTurnEvent`)
- `playerId`, `turnIndex`, `inning`, `phaseRaw`
- `runsThisVisit`, `cumulativeRunsAfterTurn`
- `darts: [BaseballDartEvent]` — segment, multiplier, `runsAwarded`, `wasMiss`, `openedStretchGate`

Authoritative payload fields: [`SwiftData.md`](SwiftData.md) § Payload versions.

### History line score
- Rows: players (throw order); columns: innings 1–9 (+ extra columns); cells: runs that inning; footer: totals
- Bull playoff turns omitted from grid (footnote when present)

---

## 6. Accessibility
- Cumulative runs announced on submit (`play.baseball.announce.turnFormat`)
- Inning strip labels per dot (`play.baseball.inningStrip.*`)
- Scoreboard rows expose spoken name + runs (not color-only leading indicator)
- Screen tracker: [`accessibility/wcag-2.1-aa/screens/baseball-match.md`](../accessibility/wcag-2.1-aa/screens/baseball-match.md)

Stable identifiers: `baseball_match_header`, `baseball_submit`, `baseball_undo`, `baseball_inning_strip`, `baseball_scoreboard_row_*`.

---

## 7. Testing

### Unit
- `BaseballEngineTests` — scoring, rotation, tie-breakers, stretch, undo/replay
- `BaseballLineScoreBuilderTests` — grid from turn events
- `MatchLifecycleServiceBaseballTests` — create → submit → snapshot → undo
- `BaseballMatchViewModelTests` — rehydrate, submit, completion

### UI
- `WCAGAccessibilityUITests` — party → baseball setup → match smoke
- Manual VoiceOver pass logged in `accessibility/Manual_todo.md` before release

---

## 8. Localization
Keys under `play.baseball.*`, `history.detail.baseballSummaryFormat`, `history.timeline.baseballTurnFormat`. See [`LocalizationSpec.md`](LocalizationSpec.md).

---

## 9. Verification
| Field | Value |
|-------|--------|
| **Last verified** | 2026-06-04 |
| **Code** | `BaseballEngine.swift`, `BaseballMatchScreen.swift`, `MatchLifecycleService.swift` |
