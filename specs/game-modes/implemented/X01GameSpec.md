**Estimated release:** `1.0`

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

## Player count

| Question | Answer |
|----------|--------|
| **Solo?** | Yes — 1 human vs bots, or solo practice with no opponent |
| **Minimum** | 1 participant (≥1 human) |
| **Recommended** | 1–4 (pub legs are usually 2–4 on one board) |
| **App maximum** | 8 (`GameModeCatalog` default; iPad layout tested at 8) |

### Brainstorm
- X01 is the most solo-friendly competitive mode: bots fill any empty seat and check-in/out rules still apply.
- Multiplayer needs no special minimum beyond “someone to beat”; 2 is the common pub default.
- Cap at **8** because scoreboard + visit slots scale with scroll on iPad; beyond 8, turn latency and readability degrade faster than rules break.
- Not `isSolo` in catalog (`minimumPlayers: 1` but `maximumPlayers: 8`) — setup still shows roster; one human + bots is valid.

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

## How to Play

Source copy for the in-app **How to play** sheet (`GameRulesGuideView` → `GameRulesCatalog`). Edit here first; mirror into `Resources/*/Localizable.strings` when copy changes.

| | |
|---|---|
| **Key prefix** | `play.rules.x01.` |
| **Shipped in app** | Yes (`GameRulesCatalog.x01`) |
| **Estimated release** | `1.0` |

### The game
| **Title key** | `play.rules.x01.overview.title` |
| **Body key** | `play.rules.x01.overview.body` |

Each player starts at the starting score you pick (101, 201, 301, 401, 501, or 601) and throws three darts per turn. Subtract your turn total from your remaining score. The first player to reach exactly zero wins the leg under your leg and set settings.

### Busts
| **Title key** | `play.rules.x01.bust.title` |
| **Body key** | `play.rules.x01.bust.body` |

If a turn would take you below zero, leave 1 on double-out or master-out, or break the check-in or check-out rule, the turn busts: your score returns to what it was at the start of the turn and play passes to the next player.

### Check-in
| **Title key** | `play.rules.x01.checkIn.title` |
| **Body key** | `play.rules.x01.checkIn.body` |

**Straight In:** every dart in your visit counts from your first scoring throw.

**Double In:** you must hit a double (or inner bull when your league counts it) before any other darts in the visit count.

**Master In:** you must hit a double or triple (or inner bull when your league counts it) before earlier singles in the visit count.

### Check-out
| **Title key** | `play.rules.x01.checkOut.title` |
| **Body key** | `play.rules.x01.checkOut.body` |

**Straight Out:** you may finish on any dart that reaches exactly zero.

**Double Out:** you must reach exactly zero on a double (or inner bull when your league counts it as a double).

**Master Out:** you must reach exactly zero on a double or triple (or inner bull when your league counts it as a double).

### Legs and sets
| **Title key** | `play.rules.x01.format.title` |
| **Body key** | `play.rules.x01.format.body` |

Use the setup chips for starting score, check-in, check-out, legs to win, optional sets, and first-to or best-of leg format.

---

## Localization

Per [`LocalizationSpec.md`](../../LocalizationSpec.md): ship **en + de + es + nl** together; `LocalizationParityTests` enforces key parity.

| Status | Meaning |
|--------|---------|
| **Exists** | In `Resources/en.lproj/Localizable.strings` today |
| **New** | Add when extending this mode |

### Catalog & setup
| Key | Status | Notes |
|-----|--------|-------|
| `modes.catalog.standard.x01.name` | Exists | |
| `modes.catalog.standard.x01.blurb` | Exists | |
| `play.x01.title` | Exists | Setup / mode label |
| `setup.validation.minimumPlayers` | Exists | Min 1 allowed; message still says “two” for empty-roster UX — verify copy if solo+bot ships widely |
| `setup.validation.invalidStartScore` | Exists | |
| `setup.validation.invalidLegs` / `invalidSets` | Exists | |
| `setup.validation.requiresHuman` | Exists | |

### Gameplay (`play.x01.*`)
| Key | Status |
|-----|--------|
| `play.x01.navTitle` | Exists |
| `play.x01.turnLegSet` | Exists |
| `play.x01.setsLegsFormat` / `setsCountFormat` / `legsCountFormat` | Exists |
| `play.x01.bustFeedback` | Exists |
| `play.x01.legWon.banner` | Exists |
| `play.x01.checkout.*` | Exists | title, cycle, setupDartFormat, finishDartFormat, accessibility |
| `play.x01.turn.active` | Exists |
| `play.x01.pad.disabledWhileBot` | Exists |
| `play.x01.announce.legWon` / `announce.matchComplete` | Exists |
| `play.x01.scoreCard.*` | Exists | summary, visit darts/total, average |
| `play.x01.leaveMatch.accessibility` | Exists |

### How to play (`play.rules.x01.*`)
| Key | Status |
|-----|--------|
| `overview`, `bust`, `checkIn`, `checkOut`, `format` (`.title` + `.body` each) | Exists |

### History & summary
| Key | Status |
|-----|--------|
| `history.timeline.x01TurnFormat` | Exists |
| `history.detail.x01SummaryFormat` | Exists |

### Errors (`error.match.x01.*`)
| Key | Status |
|-----|--------|
| `invalidStartScore`, `invalidLegCount`, `invalidSetCount` | Exists |

### Shared (reuse)
`play.rules.learnButton`, `play.rules.sheet.title`, `play.rules.sheet.done`; shared scoring pad keys in `ScoringInputSpec.md`.

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
- Manual: [`x01-match.md`](../../../accessibility/wcag-2.1-aa/screens/x01-match.md)
- Shared pad: [`_shared-components.md`](../../../accessibility/wcag-2.1-aa/screens/_shared-components.md)

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
