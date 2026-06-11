# Cricket Game Specification

## 1. Purpose
Define Cricket gameplay rules, board UI, input model, and persistence for the iPhone MVP.

---

## 2. MVP Scope
- Standard Cricket targets: `20,19,18,17,16,15,bull`
- **Cut Throat** scoring mode (lowest total wins when points on)
- 2..N players
- Mark-based input
- Point overflow scoring when opponents have not closed target
- Undo last accepted turn
- Local-only persistence with turn + dart granularity
- Shared input component: see `specs/ScoringInputSpec.md`
- Setup chips: Points On/Off, Normal/Cut Throat, Set/Leg format, Sets, Legs (`MatchConfigCricket` payload v2)
- Bot matches: Points On required; scoring modes Normal and Cut Throat supported (Points Off bots deferred) — see [`BotOpponentSpec.md`](../../BotOpponentSpec.md)

---

## Player count

| Question | Answer |
|----------|--------|
| **Solo?** | No — needs at least one opponent for marks, closure, and scoring |
| **Minimum** | 2 participants (≥1 human; bots OK on Points On) |
| **Recommended** | 2–4 |
| **App maximum** | 8 (Cricket board scrolls horizontally at 3+ players) |

### Brainstorm
- Cricket without an opponent is undefined: overflow points and leg completion require multiple player columns.
- Points-off “close all on your turn” could technically be solo practice but is not a supported product shape.
- **2** is the real floor; catalog `minimumPlayers: 2`.
- **8** cap matches mark-board UI (`CricketBoardView` scroll threshold) and keeps leg length reasonable.

---

## 3. Rules Engine

## Match Completion Rule (Points On)
When points are enabled, a leg ends when every player has closed all targets. The leg winner is the highest score (Normal) or lowest score (Cut Throat); ties go to the earliest seat. Multi-leg/set targets use the same leg-format math as X01.

## Match Completion Rule (Points Off)
When points are disabled, a leg ends when the acting player closes all targets on their turn. That player wins the leg. Scores remain zero.

## Match Completion Rule (legacy default)
Single-leg Normal + Points On: same as “Points On” with one leg — match completes when the board is fully closed.

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
  - closed state (3+): per-player identity color (from roster `PlayerColorToken`), not a global green
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

## How to Play

| | |
|---|---|
| **Key prefix** | `play.rules.cricket.` |
| **Shipped in app** | Yes (`GameRulesCatalog.cricket`) |

### Cricket basics
| **Title key** | `play.rules.cricket.basics.title` |
| **Body key** | `play.rules.cricket.basics.body` |

Close targets 20 through 15 and the bull by landing marks. Singles, doubles, and triples add 1, 2, or 3 marks. A target closes at three marks. Outer bull counts as one mark; inner bull counts as two.

### Normal · Points on
| **Title key** | `play.rules.cricket.normalScore.title` |
| **Body key** | `play.rules.cricket.normalScore.body` |

While at least one opponent has not closed a target, extra marks on a closed target become points on that number.

When everyone has closed all targets, the leg ends. Highest total score wins the leg.

### Cut Throat · Points on
| **Title key** | `play.rules.cricket.cutThroatScore.title` |
| **Body key** | `play.rules.cricket.cutThroatScore.body` |

Overflow points are credited to opponents who have not closed that target—the more marks you add, the more points they receive.

When the board is fully closed, the leg ends. Lowest total score wins the leg.

### No score (points off)
| **Title key** | `play.rules.cricket.noScore.title` |
| **Body key** | `play.rules.cricket.noScore.body` |

Marks still close targets, but no points are scored. The leg ends when you close all targets on your turn—you win that leg immediately.

---

## Localization

| Status | Meaning |
|--------|---------|
| **Exists** | In `en.lproj` today |
| **New** | Add when extending |

### Catalog & setup
| Key | Status |
|-----|--------|
| `modes.catalog.standard.cricket.name` / `.blurb` | Exists |
| `play.cricket.title` | Exists |
| `play.cricket.points.on` / `.off` | Exists |
| `play.cricket.mode.normal` / `.cutThroat` | Exists |
| `play.cricket.subtitle.*` | Exists | normal, cutThroat, noScore variants |
| `setup.validation.cricketBotUnsupported` | Exists |
| `setup.validation.minimumPlayers` | Exists | Min 2 players |

### Gameplay (`play.cricket.*`)
| Key | Status |
|-----|--------|
| `play.cricket.navTitle` | Exists |
| `play.cricket.roundTurn` / `round` / `turn` | Exists |
| `play.cricket.pointsFormat` | Exists |
| `play.cricket.boardUpdated` | Exists |
| `play.cricket.targetClosed` | Exists |
| `play.cricket.pad.disabledWhileBot` | Exists |
| `play.cricket.column.footer.*` | Exists | darts, mpr, legs, sets |
| `play.cricket.column.accessibilityFormat` | Exists |

### How to play (`play.rules.cricket.*`)
| Key | Status |
|-----|--------|
| `basics`, `normalScore`, `cutThroatScore`, `noScore` (`.title` + `.body`) | Exists |

### History
| Key | Status |
|-----|--------|
| `history.timeline.cricketTurnFormat` | Exists |
| `history.detail.cricketSummaryFormat` | Exists |

### Shared
`play.rules.learnButton`, `play.rules.sheet.*`; mark-board accessibility per `CricketSpec` §8.

---

## 7. Testing

## Unit
- Closure logic by target
- Overflow scoring when mixed opponent closure states
- Bull-specific scoring and mark behavior
- Match completion tie/lead conditions

## Integration
- Complete match with 3+ players — `CricketEngineProgressionTests` (`cricketCompletesWhenAllThreePlayersCloseAllTargets`, `cricketRotatesTurnOrderThroughThreePlayers`, …), `CricketMatchViewModelTests` (`cricketViewModelCompletesWhenAllThreePlayersCloseAllTargets`), `CricketMatchUITests` (`testThreePlayerCricketMatchEndsWhenAllPlayersCloseAllTargets`)
- Resume from mid-board state — `MatchLifecycleServiceTests` (`lifecycleResumeThreePlayerCricketMidBoard`)

## UI
- Board state rendering correctness
- Accessibility labels per target cell

---

## 8. Accessibility verification
- Manual: [`cricket-match.md`](../../../accessibility/wcag-2.1-aa/screens/cricket-match.md)

## 9. Analytics
§12 — same match/turn events as X01; `cricket_abandon_failed` on Crashlytics.

## 10. Verification
| Field | Value |
|-------|--------|
| **Last verified** | 2026-06-04 |
| **Commit** | `0c25396` |
| **Code** | `CricketEngine.swift`, `CricketMatchViewModel.swift` |

---

## 11. Future Improvements
- Fast batch entry for full turn (3 darts at once)
- Additional Cricket variants (no-score formats, Points Off bot matches)
- Live throw quality metrics and closure-speed charts
