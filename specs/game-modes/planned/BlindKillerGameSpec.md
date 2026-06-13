# Blind Killer Game Specification

## 1. Purpose
Define Blind Killer — a hidden-number elimination party game — for future implementation.

**Status:** Planned (`party.blindKiller`).
**Estimated release:** `TBD`

References: [darts501.com — Blind Killer](https://darts501.com/Games.html), [`KillerGameSpec.md`](../implemented/KillerGameSpec.md).

---

## 2. Catalog metadata
| Field | Value |
|-------|-------|
| **Section** | Party |
| **UI template** | D — Lives elimination |
| **Stat kind** | Lives |
| **Ruleset (v1)** | `blind_killer_double_elimination` |

---

## Player count

| Question | Answer |
|----------|--------|
| **Solo?** | No — hidden assignments and elimination need a group |
| **Minimum** | 3 participants (≥1 human; same floor as Killer) |
| **Recommended** | 5–8 (source material: “good player” dynamics need a crowd) |
| **App maximum** | 8 |

### Brainstorm
- Same **3-player floor** as Killer: fewer players means trivial secret-number deduction.
- Blind Killer shines at 5+ where anonymous segment tallies create paranoia.
- Do not allow 2 — degenerates into known mapping after one double.

---

## 3. MVP Scope
- Each player assigned a secret number 1–20 (visible only to that player on device)
- **Pick phase:** each player throws at any double; hits record a tally on that number (hidden assignment mapping stored in events)
- When a number accumulates **3 double hits**, the player holding that number is **eliminated**
- Last player remaining wins
- Lives UI shows elimination state, not opponent numbers
- Per-dart full-board entry; undo; local persistence

### Out of Scope (v1)
- Killer-style killer status, self-double penalties, marks progression variant

---

## 4. Rules Engine (`BlindKillerEngine`)

### Config (`MatchConfigBlindKiller`, payload v1)
| Field | Default |
|-------|---------|
| `hitsToEliminate` | `3` |
| `assignmentSeed` | stored for replay |

### State
- `secretNumbers: [playerId: Int]` (not exposed to opponents in UI state)
- `hitCounts: [segment: Int]`
- `eliminated: Set<playerId>`

### Turn flow
1. Active player throws 3 darts (any doubles count toward segment tallies).
2. After each double hit, check if segment tally ≥ threshold → eliminate holder.
3. Skip eliminated players.

### Undo
Replay restores tallies and elimination set; assignments fixed from config seed.

---

## 5. UI Specification
- Template D with **masked number chips** (own number revealed; others show "?")
- Public board: segments 1–20 with anonymous hit pips (not color-only)
- Accessibility: private number announced only to owning player via accessibility hint

---

## How to Play

| | |
|---|---|
| **Key prefix** | `play.rules.blindKiller.` |
| **Shipped in app** | Planned |
| **Estimated release** | `TBD` |

### Overview
| **Title key** | `play.rules.blindKiller.overview.title` |
| **Body key** | `play.rules.blindKiller.overview.body` |

Everyone is assigned a secret number from 1 to 20. Throw at doubles — each double hit is recorded on that segment. When a segment reaches three double hits, whoever holds that number is out. Last player standing wins.

### Your secret number
| **Title key** | `play.rules.blindKiller.secret.title` |
| **Body key** | `play.rules.blindKiller.secret.body` |

Only you see your number on your device. Opponents see which segments have hits, not who owns them. Plan your throws without revealing your identity.

### Throwing
| **Title key** | `play.rules.blindKiller.throwing.title` |
| **Body key** | `play.rules.blindKiller.throwing.body` |

Each turn you throw three darts. Any double adds a hit to that segment's tally. Singles and triples do not count. Misses have no effect.

### Elimination
| **Title key** | `play.rules.blindKiller.elimination.title` |
| **Body key** | `play.rules.blindKiller.elimination.body` |

When a segment's double-hit tally reaches three, the player with that secret number is eliminated immediately. Play continues until one player remains.

---

## Localization

| **Exists** | `modes.catalog.party.blindKiller.name`, `.blurb` |

### New keys

**Setup:** `play.party.blindKiller.title`, `.subtitle`; `play.blindKiller.setup.hitsToEliminate`

**Gameplay:** `play.blindKiller.navTitle`, `yourSecretNumberFormat` (private), `segmentHitCountFormat`, `segmentHiddenLabel`, `eliminatedPlayerFormat`, `doubleHitRecorded`, `pad.disabledWhileBot`, `anonymousTallyAccessibilityFormat`

**How to play:** `play.rules.blindKiller.overview|secret|throwing|elimination`

**History:** `history.timeline.blindKillerTurnFormat` (no secret leak in shared history copy)

**Validation:** `setup.validation.blindKillerMinimumPlayers` (min 3)

**Errors:** `error.match.blindKiller.alreadyEliminated`

---

## 6. Data Capture
- `BlindKillerTurnEvent`: darts, segment hit counts delta, elimination events
- Assignments in `MatchConfigBlindKiller` encrypted payload or seeded shuffle

---

## 7. Testing
- Unit: elimination on 3rd hit, assignment uniqueness, undo
- Multiplayer UI: opponent numbers never leak in view model

---

## 8. Verification
| Field | Value |
|-------|-------|
| **Status** | Planned |
