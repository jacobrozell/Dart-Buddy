# Match Specification

## 1. Purpose
Define match lifecycle behavior shared by X01, Cricket, and Baseball: setup, active play state, completion, persistence, resume, and history integrity.

---

## 2. MVP Scope

### In Scope (1.0.0)
- Create match from setup flow
- Support X01, Cricket, and Baseball match types
- Persist in-progress and completed matches locally
- Resume one in-progress match from Play tab
- Complete match and write summary data

### Out of Scope
- Online matches
- Cloud sync
- Multi-device live continuity

---

## 3. Tech Stack and Architecture
- `SwiftUI` feature module under `Features/Play`
- `MatchDomain` service for generic lifecycle state
- Mode-specific engines (`X01Engine`, `CricketEngine`, `BaseballEngine`)
- `MatchRepository` protocol + SwiftData implementation
- Event-sourced scoring timeline with snapshot checkpoints for fast resume

---

## 4. Match Data Model

Authoritative persistence field definitions live in:
- `specs/SwiftData.md` (versioned schema details)
- `specs/DataSchemaSpec.md` (cross-entity invariants)

This section is conceptual and must not diverge from those sources.

## Core Entities
- `MatchRecord`
  - `id: UUID`
  - `type: MatchType` (`x01`, `cricket`, `baseball`)
  - `status: MatchStatus` (`notStarted`, `inProgress`, `completed`, `abandoned`)
  - `startedAt: Date`
  - `endedAt: Date?`
  - `winnerPlayerId: UUID?`
  - `configPayload: Data` (versioned mode config)
  - `currentTurnPlayerId: UUID?`
  - `currentLegIndex: Int`
  - `currentSetIndex: Int`
  - `eventCount: Int`

- `MatchParticipantRecord`
  - `id: UUID`
  - `matchId: UUID`
  - `playerId: UUID?` (nullable for historical safety if player record is removed)
  - `turnOrder: Int`
  - `displayNameAtMatchStart: String`
  - `avatarStyleAtMatchStart: String?`

- `MatchSnapshotRecord`
  - `matchId: UUID`
  - `snapshotVersion: Int`
  - `snapshotPayload: Data`
  - `updatedAt: Date`

---

## 5. Match Lifecycle

## Create
1. Validate setup input.
2. Materialize `MatchRecord` and participants.
3. Initialize mode engine state.
4. Save initial snapshot.

## Progress
- Each accepted turn generates immutable events.
- Engine computes derived state (scores/marks/leg progress).
- Repository updates match head fields (`currentTurnPlayerId`, indices, eventCount).

## Complete
1. Engine returns `isMatchComplete = true`.
2. Persist `endedAt`, `winnerPlayerId`, `status = completed`.
3. Compute and cache summary metrics for history list cards.

## Resume
- Load `MatchRecord` + latest snapshot + events after snapshot.
- Rehydrate state deterministically.

## Abandon (1.0 policy)
- Triggered when the player exits an in-progress match without completing it, or confirms **Abandon & Start** on setup when another match is already active.
- Sets `status = abandoned`, `endedAt`, clears `currentTurnPlayerId`; snapshot is persisted for diagnostics only.
- **Not shown** in History, Statistics, or Play home “recent games” (queries use `status = completed` only).
- **Does not count** toward games, wins, trends, or any player aggregate in 1.0.
- Rows may remain in local storage until **Reset All Local Data**; no abandoned-match list or purge UI in 1.0.

## Active match constraint (1.0)
- At most one `inProgress` match at a time (`fetchActiveMatch`).
- Play tab resume banner and setup conflict flow target that record only.

---

## 6. UI Expectations

## Setup to Start
- Match setup is a guided form with sticky `Start Match`.
- Validation blocks invalid states.

## Active Match Shell
- Top region: participants, turn indicator, legs/sets (or cricket board header)
- Middle region: mode-specific board/score
- Bottom region: input controls + `Undo`

## End Summary
See [`MatchSummarySpec.md`](MatchSummarySpec.md) for the dedicated post-match screen (winner card, stats chips, undo last throw, navigation).

---

## 7. Data Management Rules
- Match/event history is immutable after completion.
- Abandoned matches are write-once audit rows, excluded from user-visible history and stats (see **Abandon** above).
- Profile edits never rewrite participant snapshots.
- Hard delete of match is disallowed in MVP UI (future admin option only).
- If a player is archived/deleted later, completed match remains readable.

---

## 8. Error/Edge Case Handling
- App termination mid-turn -> recover to last committed event
- Corrupt snapshot -> rebuild state from full event stream
- Missing player reference -> fallback to `displayNameAtMatchStart`
- Resume conflict (multiple in-progress records) -> show selector (future), for MVP prefer single active constraint

---

## 9. Testing

## Unit
- Use `Swift Testing` (`Testing` module).
- Lifecycle transitions by status
- Resume rehydration determinism
- Winner assignment correctness

## Integration
- Use `Swift Testing` (`Testing` module).
- Setup -> play -> complete -> history render
- Setup -> partial play -> app relaunch -> resume

## UI
- Out of scope for 1.0.0.
- Future UI automation tasks (post-UI-lock):
  - Start match validation
  - End summary CTA flow

---

## 10. Accessibility verification
- In-match: [`x01-match.md`](../accessibility/wcag-2.1-aa/screens/x01-match.md), [`cricket-match.md`](../accessibility/wcag-2.1-aa/screens/cricket-match.md), [`baseball-match.md`](../accessibility/wcag-2.1-aa/screens/baseball-match.md)

## 11. Analytics
§12 — `match_started`, `match_completed`, `match_abandoned`, `turn_submitted`, `turn_persist_failed`, undo events.

## 12. Verification
| Field | Value |
|-------|--------|
| **Last verified** | 2026-06-04 |
| **Commit** | `0c25396` |
| **Code** | `MatchLifecycleService.swift`, `MatchTurnSupport.swift` |

---

## 13. Future Improvements
- Multiple active matches with explicit queue
- Match tags/notes/location metadata
- Export/import single match bundles
- Cloud conflict resolution for in-progress matches
- Vision-assisted auto-scoring session support (`specs/AutoScoringVisionSpec.md`)
- Future verified online match mode using signed scoring events and confidence metadata
