# Follow the Leader Game Specification

## 1. Purpose
Define Follow the Leader — match the leader's exact hit or lose a life — for future implementation.

**Status:** Planned (`party.followTheLeader`).

References: [darts501.com — Follow the Leader](https://darts501.com/Games.html).

---

## 2. Catalog metadata
| Field | Value |
|-------|-------|
| **Section** | Party |
| **UI template** | D — Lives elimination |
| **Stat kind** | Lives |
| **Ruleset (v1)** | `follow_the_leader_three_lives` |

---

## Player count

| Question | Answer |
|----------|--------|
| **Solo?** | No — must match another player’s target area |
| **Minimum** | 2 participants (≥1 human) |
| **Recommended** | 4–8 (pub party; “more the better” in source rules) |
| **App maximum** | 8 |

### Brainstorm
- Playable at **2** but thin — leader/follower with one follower.
- Sweet spot is **4+**: target setting and life loss create a social circle.
- **8** cap before turn length explodes (each miss costs a life, rounds continue).

---

## 3. MVP Scope
- Opening: non-dominant hand throw sets first **target area** (segment + ring: e.g. small 16)
- Each player must **match exact area** within 3 darts or lose 1 life (default **3 lives**)
- On match with darts remaining, player may set new target with remaining dart(s); **last dart** establishes target if thrown
- If all miss, turn returns to target setter who may pass or rethrow
- Last player with lives wins
- Full-board per-dart entry with ring resolution; undo; local persistence

### Out of Scope (v1)
- Wire-loop targets (see Loop)

---

## 4. Rules Engine (`FollowTheLeaderEngine`)

### Config (`MatchConfigFollowTheLeader`, payload v1)
| Field | Default |
|-------|---------|
| `startingLives` | `3` |
| `ringPrecision` | `.full` (small/large single, double, triple) |

### State
- `target: TargetArea?` (segment + ring enum)
- `lives[playerId]`, `eliminated`

### Turn flow
1. Validate each dart against `target` ring rules.
2. On success with spare darts, accept optional new target from remaining throws.
3. On complete miss, decrement life; rotate per rules.

### Undo
Replay restores target, lives, elimination.

---

## 5. UI Specification
- Template D + **target callout** card (segment + ring diagram)
- Lives pips per player

---

## How to Play

| | |
|---|---|
| **Key prefix** | `play.rules.followTheLeader.` |
| **Shipped in app** | Planned |

### Overview
| **Title key** | `play.rules.followTheLeader.overview.title` |
| **Body key** | `play.rules.followTheLeader.overview.body` |

Match the exact area the leader set — or lose a life. Everyone starts with three lives. Last player with lives wins.

### Setting the target
| **Title key** | `play.rules.followTheLeader.target.title` |
| **Body key** | `play.rules.followTheLeader.target.body` |

The first player throws one dart with their non-dominant hand to set the opening target (segment and ring, e.g. small 16). Later players must hit that exact area within three darts.

### Matching and setting
| **Title key** | `play.rules.followTheLeader.match.title` |
| **Body key** | `play.rules.followTheLeader.match.body` |

Hit the target with your first or second dart and you may use remaining darts to set a new target. The last dart you choose to throw sets the new target if it lands in a scoring area. Miss the target entirely and lose one life.

### When everyone misses
| **Title key** | `play.rules.followTheLeader.pass.title` |
| **Body key** | `play.rules.followTheLeader.pass.body` |

If every player misses, the turn returns to whoever set the target. They may pass (keep the same target) or try to hit it and set something harder.

---

## Localization

| **Exists** | `modes.catalog.party.followTheLeader.name`, `.blurb` |

### New keys

**Setup:** `play.party.followTheLeader.title`, `.subtitle`; `play.followTheLeader.setup.startingLives`

**Gameplay:** `play.followTheLeader.navTitle`, `currentTargetFormat`, `targetArea.small` / `.large` / `.double` / `.triple` (ring names), `lifeLost`, `livesRemainingFormat`, `setNewTarget`, `passTurn`, `nonDominantPickReminder`, `announce.targetMatched`

**How to play:** `play.rules.followTheLeader.overview|target|match|pass`

**History:** `history.timeline.followTheLeaderVisitFormat`, `history.detail.followTheLeaderSummaryFormat`

**Validation:** `setup.validation.followTheLeaderMinimumPlayers` (min 2)

---

## 6. Data Capture
- `FollowTheLeaderVisitEvent`: `targetBefore`, `targetAfter`, `matched`, `lifeLost`

---

## 7. Testing
- Unit: ring matching, target setting with 1–2 darts, pass behavior

---

## 8. Verification
| Field | Value |
|-------|-------|
| **Status** | Planned |
