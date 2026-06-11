# Killer Game Specification

## 1. Purpose
Define Killer (party elimination mode) gameplay rules, play UI, input model, persistence, and history for the iPhone MVP.

Ruleset: `killer_double_standard` (see §3). External references: [GLD Killer darts](https://gldproducts.com/blogs/all/how-to-play-killer-darts), [Dart Scout](https://thedartscout.com/dart-rules-explained/).

---

## 2. MVP Scope
- `killer_double_standard` ruleset only
- 3..N players; preset difficulty bots supported (at least one human required)
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
- Training/custom bots, achievements, eliminated players as targets

---

## Player count

| Question | Answer |
|----------|--------|
| **Solo?** | No — elimination and number assignment need multiple targets |
| **Minimum** | 3 participants (≥1 human; preset bots fill seats) |
| **Recommended** | 4–6 (pub Killer is rarely 3) |
| **App maximum** | 8 |

### Brainstorm
- **3 is a hard floor**: with two players there are only two numbers/lives — rules collapse toward a duel, not pub Killer.
- Pick phase needs distinct numbers; at 8 players the pick grid is crowded but still workable.
- Cap at **8** for turn length (pick + play phases) and lives-board readability.

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
- Validation: min 3 players, at least 1 human, preset bots only

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

## How to Play

| | |
|---|---|
| **Key prefix** | `play.rules.killer.` |
| **Shipped in app** | Yes (`GameRulesCatalog.killer`) |

### Overview
| **Title key** | `play.rules.killer.overview.title` |
| **Body key** | `play.rules.killer.overview.body` |

Each player owns a target number (1–20). Start with lives, become a Killer by hitting your double, then remove opponents' lives by hitting their doubles. Last player with lives wins.

### Number pick
| **Title key** | `play.rules.killer.pick.title` |
| **Body key** | `play.rules.killer.pick.body` |

Each player throws one dart with their other hand. The segment hit becomes their number. Misses and taken numbers require a rethrow.

### Becoming Killer
| **Title key** | `play.rules.killer.killerStatus.title` |
| **Body key** | `play.rules.killer.killerStatus.body` |

Hit the double of your own number in any turn to become a Killer. Until then, hits on other players have no effect.

### Attacks
| **Title key** | `play.rules.killer.attacks.title` |
| **Body key** | `play.rules.killer.attacks.body` |

As a Killer, a double on an opponent's number removes one life. A double on your own number removes one life from you. Singles and triples do not count in the default rules.

---

## Localization

| Status | Meaning |
|--------|---------|
| **Exists** | In `en.lproj` today |
| **New** | Add when extending |

### Catalog & setup
| Key | Status |
|-----|--------|
| `modes.catalog.party.killer.name` / `.blurb` | Exists |
| `play.party.killer.title` / `.subtitle` | Exists |
| `play.killer.setup.lives` / `livesValueFormat` | Exists |
| `setup.validation.partyKillerMinimumPlayers` | Exists |
| `setup.validation.killerBotsPresetOnly` | Exists |

### Gameplay (`play.killer.*`)
| Key | Status |
|-----|--------|
| `play.killer.title` | Exists |
| `play.killer.header.pickFormat` / `throwFormat` / `killerThrowFormat` | Exists |
| `play.killer.pickHint` / `pickReminder` | Exists |
| `play.killer.yourNumberFormat` / `aimDoubles` | Exists |
| `play.killer.killerBadge` / `eliminated` | Exists |
| `play.killer.becameKiller` | Exists |
| `play.killer.submitPick` | Exists |
| `play.killer.livesAccessibilityFormat` | Exists |
| `play.killer.number*AccessibilityFormat` | Exists | open, taken, plain |
| `play.killer.pad.disabledWhileBot` | Exists |

### How to play (`play.rules.killer.*`)
| Key | Status |
|-----|--------|
| `overview`, `pick`, `killerStatus`, `attacks` | Exists |

### History
| Key | Status |
|-----|--------|
| `history.timeline.killerPickFormat` / `killerPickRetakeFormat` | Exists |
| `history.timeline.killerTurnFormat` | Exists |
| `history.detail.killerSummaryFormat` | Exists |

### Errors (`error.match.killer.*`)
| Key | Status |
|-----|--------|
| `notPickPhase`, `notPlayingPhase`, `pickComplete`, `playerMissing` | Exists |

---

## 5. Data Capture

### Events
- `KillerPickEvent` — pick phase dart and assigned number (if any)
- `KillerTurnEvent` — play phase darts with `KillerDartResolution` effects

Payload fields: see `KillerEngine.swift` and `SwiftData.md` when payload version is registered.

---

## 6. Testing
- Unit: pick collision, become killer, damage gates, elimination, undo (`KillerEngineTests.swift`, `MatchLifecycleService` replay)
- Setup: 3+ players, preset bot support, training/custom rejection (`MatchSetupViewModelTests.swift`)
