# American Cricket Game Specification

## 1. Purpose
Define American Cricket (standard section) — a segment-sequential Cricket variant starting at 20 and descending to 15, then bull — for future implementation.

**Status:** Planned (`standard.americanCricket`). Not routable until `MatchType` and engine ship.

References: [Darts.org — American Cricket](https://www.darts.org/rules/american-cricket.html), [Darts Corner](https://www.dartscorner.com/blogs/how-to/what-darts-games-can-you-play).

---

## 2. Catalog metadata
| Field | Value |
|-------|-------|
| **Section** | Standard |
| **UI template** | B — Mark board |
| **Stat kind** | Marks |
| **Ruleset (v1)** | `american_cricket_sequential` |

---

## Player count

| Question | Answer |
|----------|--------|
| **Solo?** | No — sequential closure and point scoring require an opponent |
| **Minimum** | 2 participants (≥1 human; preset bots OK) |
| **Recommended** | 2–4 |
| **App maximum** | 8 |

### Brainstorm
- Same rationale as standard Cricket: marks and points are relative to who has not closed the active segment.
- Sequential target order (20→15→bull) does not change the need for ≥2 sides.
- **8** cap for mark-board density; Darts.org notes 2–4 as common but pub play can go higher.

---

## 3. MVP Scope
- Targets visited **in order**: 20 → 19 → 18 → 17 → 16 → 15 → bull
- Close current target with 3 marks (S=1, D=2, T=3); outer bull = 1, inner bull = 2
- Once a player closes the active target, score face-value points on that segment until all opponents also close it
- Game ends when bull is closed by the trailing player; **highest total wins**
- Mark-board UI reusing Cricket template with **sequential target highlight** (only active segment scores)
- Per-dart entry, undo last turn, local persistence
- Preset bots only in v1

### Out of Scope (v1)
- Team play, simultaneous all-target Cricket board, Cut Throat variant

---

## 4. Rules Engine (`AmericanCricketEngine`)

### Config (`MatchConfigAmericanCricket`, payload v1)
| Field | Default |
|-------|---------|
| `ruleset` | `american_cricket_sequential` |
| `pointsEnabled` | `true` |

### State
- `activeTargetIndex` (0…6 for 20…15, bull)
- Per-player marks on active target + cumulative points
- `currentPlayerIndex`, `turnIndex`

### Turn flow
1. Player throws up to 3 darts at **active target only** (pad locked).
2. Apply marks; award overflow points per Cricket rules on active segment.
3. When any player reaches 3 marks on active target, advance `activeTargetIndex` for all (unclosed scoring stops on prior segments).
4. Match complete after bull closure sequence resolves; rank by points.

### Undo
Event replay restores marks, points, active target, and turn order.

---

## 5. UI Specification
- **Template B** — Cricket mark board with single highlighted row (active target)
- Setup: points on/off (default on), player count validation (≥2)
- History: marks per target + running points total

---

## How to Play

| | |
|---|---|
| **Key prefix** | `play.rules.americanCricket.` |
| **Shipped in app** | Planned — register in `GameRulesCatalog` when mode ships |

### Overview
| **Title key** | `play.rules.americanCricket.overview.title` |
| **Body key** | `play.rules.americanCricket.overview.body` |

American Cricket plays the board in order: 20, then 19, 18, 17, 16, 15, and finally the bull. Everyone throws at the same active number until it is closed, then play moves to the next.

### Closing and marks
| **Title key** | `play.rules.americanCricket.marks.title` |
| **Body key** | `play.rules.americanCricket.marks.body` |

Singles, doubles, and triples count as 1, 2, or 3 marks on the active segment. Three marks closes that number for the player who finished it. On the bull, outer bull is one mark and inner bull is two.

### Scoring points
| **Title key** | `play.rules.americanCricket.scoring.title` |
| **Body key** | `play.rules.americanCricket.scoring.body` |

After you close the active number, you may keep scoring on it while any opponent has not closed it yet. Points equal the segment value (20 for 20s, 25/50 for bulls per hit type). When everyone has closed that number, scoring on it stops and the game advances.

### Winning
| **Title key** | `play.rules.americanCricket.winning.title` |
| **Body key** | `play.rules.americanCricket.winning.body` |

The game ends once the bull sequence is resolved. The player with the highest total points wins.

---

## Localization

Per [`LocalizationSpec.md`](../../LocalizationSpec.md): add **en + de + es + nl** in one PR; run `LocalizationParityTests`.

| Status | Meaning |
|--------|---------|
| **Exists** | Catalog strings already shipped |
| **New** | Required for gameplay implementation |

### Catalog (Exists)
`modes.catalog.standard.americanCricket.name`, `modes.catalog.standard.americanCricket.blurb`

### Setup (New)
| Key | Purpose |
|-----|---------|
| `play.americanCricket.title` | Mode / nav label |
| `play.americanCricket.setup.points` | Points on/off chip label |
| `play.americanCricket.setup.pointsOn` / `.pointsOff` | Chip values |
| `setup.validation.americanCricketMinimumPlayers` | Min 2 (or reuse `setup.validation.minimumPlayers`) |
| `setup.validation.americanCricketBotsPresetOnly` | If bots gated like Cricket |

### Gameplay (New)
| Key | Purpose |
|-----|---------|
| `play.americanCricket.navTitle` | Navigation title |
| `play.americanCricket.header.activeTargetFormat` | e.g. “Target 20 · Segment 1 of 7” |
| `play.americanCricket.activeTargetHint` | Pad locked to active segment |
| `play.americanCricket.pad.disabledWhileBot` | Bot turn |
| `play.americanCricket.pointsFormat` | Running points column |
| `play.americanCricket.marksOnTargetFormat` | Marks toward close on active row |
| `play.americanCricket.segmentAdvanced` | Toast when target moves |
| `play.americanCricket.announce.turnFormat` | VoiceOver turn summary |

### How to play (New) — `play.rules.americanCricket.*`
`overview`, `marks`, `scoring`, `winning` (`.title` + `.body` each) — see § How to Play

### History (New)
| Key | Purpose |
|-----|---------|
| `history.timeline.americanCricketTurnFormat` | Turn line |
| `history.detail.americanCricketSummaryFormat` | Detail header stats |

### Errors (New)
`error.match.americanCricket.invalidConfig` (if needed)

### Shared (reuse)
`play.rules.learnButton`, `play.rules.sheet.title`, `play.rules.sheet.done`; Cricket mark-board strings where identical (`play.cricket.column.*` — evaluate reuse vs duplicate)

---

## 6. Data Capture
- `AmericanCricketTurnEvent` with `activeTarget`, `marksAdded`, `pointsAdded`, `darts[]`
- Board snapshot payloads for replay (link [`SwiftData.md`](../../SwiftData.md) when registered)

---

## 7. Testing
- Unit: sequential advance, scoring while target open, bull marks, tie on points
- Integration: full 2-player match + undo
- UI: only active target accepts input

---

## 8. Verification
| Field | Value |
|-------|-------|
| **Status** | Planned |
| **Last verified** | — |
