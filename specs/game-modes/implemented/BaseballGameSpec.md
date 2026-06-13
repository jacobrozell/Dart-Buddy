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

## Player count

| Question | Answer |
|----------|--------|
| **Solo?** | No — innings rotate through a roster; need ≥2 scorers |
| **Minimum** | 2 participants (≥1 human; **preset bots only** in v1) |
| **Recommended** | 2–6 |
| **App maximum** | 8 (inning strip + scoreboard; optional per-inning column hidden at 6+) |

### Brainstorm
- Baseball is a rotation game: every inning visits each player. Solo has no comparative scoring.
- Bots are allowed to fill seats but not training/custom profiles (roster validation).
- **8** is acceptable with cumulative-only scoreboard; per-inning columns already drop at 6 players per spec UI notes.

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

Wireframe: [`UIBlueprintSpec.md`](../../UIBlueprintSpec.md) §4.4a.

### Match end
- Routes to shared match summary; history detail includes line-score grid (see [`HistorySpec.md`](../../HistorySpec.md)).

---

## 5. Data Capture

### Turn event (`BaseballTurnEvent`)
- `playerId`, `turnIndex`, `inning`, `phaseRaw`
- `runsThisVisit`, `cumulativeRunsAfterTurn`
- `darts: [BaseballDartEvent]` — segment, multiplier, `runsAwarded`, `wasMiss`, `openedStretchGate`

Authoritative payload fields: [`SwiftData.md`](../../SwiftData.md) § Payload versions.

### History line score
- Rows: players (throw order); columns: innings 1–9 (+ extra columns); cells: runs that inning; footer: totals
- Bull playoff turns omitted from grid (footnote when present)

---

## How to Play

| | |
|---|---|
| **Key prefix** | `play.rules.baseball.` |
| **Shipped in app** | Yes (`GameRulesCatalog.baseball`) |

### Overview
| **Title key** | `play.rules.baseball.overview.title` |
| **Body key** | `play.rules.baseball.overview.body` |

Each inning targets one segment (1 through 9). Singles, doubles, and triples on that segment score 1, 2, or 3 runs — not the segment face value.

### Innings
| **Title key** | `play.rules.baseball.innings.title` |
| **Body key** | `play.rules.baseball.innings.body` |

All players throw three darts per inning. After everyone completes the inning, move to the next target. Highest total runs wins.

### Tie-breakers
| **Title key** | `play.rules.baseball.tieBreakers.title` |
| **Body key** | `play.rules.baseball.tieBreakers.body` |

Extra innings continue with segment 10, 11, and so on until one leader remains. Bull playoff gives each tied player three darts at the bull.

### 7th-inning stretch
| **Title key** | `play.rules.baseball.stretch.title` |
| **Body key** | `play.rules.baseball.stretch.body` |

Optional house rule: in inning 7 only, each player must register a bull hit before runs on segment 7 count.

---

## Localization

| Status | Meaning |
|--------|---------|
| **Exists** | In `en.lproj` today |
| **New** | Add when extending |

### Catalog & setup
| Key | Status |
|-----|--------|
| `modes.catalog.party.baseball.name` / `.blurb` | Exists |
| `play.party.baseball.title` / `.subtitle` | Exists |
| `play.baseball.setup.innings` / `tieBreaker` / `stretch` | Exists |
| `play.baseball.tieBreaker.extraInnings` / `bullPlayoff` | Exists |
| `play.baseball.stretch.on` / `.off` | Exists |
| `setup.validation.baseballBotsPresetOnly` | Exists |
| `setup.validation.partyMinimumPlayers` | Exists |

### Gameplay (`play.baseball.*`)
| Key | Status |
|-----|--------|
| `play.baseball.title` | Exists |
| `play.baseball.headerFormat` | Exists |
| `play.baseball.extraInning` / `header.bullPlayoff` | Exists |
| `play.baseball.leading` / `thisInningFormat` | Exists |
| `play.baseball.stretchGateHint` / `stretchGateOpened` | Exists |
| `play.baseball.perfectInning` | Exists |
| `play.baseball.pad.lockedSegmentHint` / `lockedBullHint` | Exists |
| `play.baseball.inningStrip.*` | Exists | accessibility + completed/current/upcoming |
| `play.baseball.announce.turnFormat` | Exists |

### How to play (`play.rules.baseball.*`)
| Key | Status |
|-----|--------|
| `overview`, `innings`, `tieBreakers`, `stretch` | Exists |

### History & line score
| Key | Status |
|-----|--------|
| `history.timeline.baseballTurnFormat` | Exists |
| `history.detail.baseballSummaryFormat` | Exists |
| `history.lineScore.*` | Exists | See `BaseballGameSpec` §5 / `LocalizationSpec.md` |

### Errors
| Key | Status |
|-----|--------|
| `error.match.baseball.invalidInningCount` | Exists |

---

## 6. Accessibility
- Cumulative runs announced on submit (`play.baseball.announce.turnFormat`)
- Inning strip labels per dot (`play.baseball.inningStrip.*`)
- Scoreboard rows expose spoken name + runs (not color-only leading indicator)
- Screen tracker: [`accessibility/wcag-2.1-aa/screens/baseball-match.md`](../../../accessibility/wcag-2.1-aa/screens/baseball-match.md)

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
Keys under `play.baseball.*`, `history.detail.baseballSummaryFormat`, `history.timeline.baseballTurnFormat`. See [`LocalizationSpec.md`](../../LocalizationSpec.md).

---

## 9. Verification
| Field | Value |
|-------|--------|
| **Last verified** | 2026-06-04 |
| **Code** | `BaseballEngine.swift`, `BaseballMatchScreen.swift`, `MatchLifecycleService.swift` |
