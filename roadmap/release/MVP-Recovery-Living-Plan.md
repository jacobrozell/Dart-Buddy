# MVP Recovery Living Plan

Purpose: track ongoing execution from "scaffolded/no-go" to "working MVP candidate" to "release-ready" with evidence.

Status legend:
- `[ ]` not started
- `[-]` in progress
- `[x]` done
- `[!]` blocked

## Outcomes
- Restore functional MVP behavior backed by real persistence.
- Eliminate placeholder-critical paths in core flows.
- Complete all pending RC evidence and close launch blockers.

## Track A - Functional Core (P0)
- [x] A1. Replace runtime stubs with SwiftData-backed repositories.
- [x] A2. Persist match lifecycle end-to-end (create, event append, snapshots, complete, resume).
- [x] A3. Implement quick-add player path from setup with return-and-refresh behavior.
- [x] A4. Implement active-match destructive exit confirmation.
- [x] A5. Wire Match Summary CTAs to real routes.
- [x] A6. Implement migration recovery handlers (retry, export diagnostics, reset).

## Track B - Contract/Spec Closure (P0/P1)
- [x] B1. Replace guarded-delete placeholder with real reference checks.
- [x] B2. Complete History list/detail contract fields and fallback identity rendering.
- [x] B3. Close settings reset transactional behavior gaps.
- [x] B4. Remove remaining placeholder texts from user-visible flows.

## Track C - Release Evidence (P0)
- [-] C1. Execute RC manual core-flow checks and record results.
- [-] C2. Capture accessibility evidence (VoiceOver, Dynamic Type, non-color cues).
- [-] C3. Capture appearance/orientation matrix evidence.
- [-] C4. Record performance measurements against MVP targets.
- [ ] C5. Final App Store metadata/assets truthfulness verification.

## Working Cadence
- One iteration should end with:
  - code landed,
  - plan updated,
  - risks updated,
  - next iteration explicitly queued.

## Iteration Log

### Iteration 1 (active)
Scope:
- Ship SwiftData-backed repository implementations.
- Switch bootstrap from stubs to real repositories.
- Wire setup quick-add player flow.
- Replace guarded-delete placeholder behavior.

Progress:
- [x] Implement `PlayerRepository` via SwiftData.
- [x] Implement `MatchRepository` via SwiftData.
- [x] Implement `StatsRepository` via SwiftData.
- [x] Implement `SettingsRepository` via SwiftData.
- [x] Wire repositories into `AppBootstrapper`.
- [x] Run lint pass and fix introduced issues.

Risks:
- Match lifecycle still uses in-memory `ActiveMatchStore` for active runtime session; persistence integration in view-model path remains to be fully completed in A2.

Next iteration (queued):
- A2 persist gameplay submit/undo/complete through repositories and resume from snapshot + tail events.

### Iteration 2 (active)
Scope:
- Connect gameplay/match lifecycle paths to repositories (not just in-memory store).

Planned:
- [x] Route setup-created sessions through `MatchRepository` create + initial snapshot persistence.
- [x] Persist turn events and periodic snapshots on submit/undo/complete.
- [-] Make PlayHome and History read from repository-backed state as source of truth.
- [x] Add destructive-exit confirmation for active-match routes.
- [x] Wire Match Summary CTAs to actionable routes.
- [x] Replace migration recovery placeholders with concrete retry/export/reset behavior.

Completed in this pass:
- Match view-model rehydration from persisted snapshot + tail events when in-memory state is missing.

### Iteration 3 (queued)
Scope:
- Close remaining contract gaps in History and Settings, then remove remaining user-visible placeholders.

Planned:
- [x] Expand History list/detail rendering toward full spec contract (participants/date/mode-specific summary/fallback identity).
- [x] Ensure settings reset is fully transactional across repositories and in-memory state.
- [x] Remove leftover placeholder copy/keys in user-visible flows.

Completed in this pass:
- History list rows now include participant snapshots, winner identity text, and event count metadata.
- History detail now renders mode/date/duration/participants/mode-specific summary and timeline names resolved through participant snapshots.
- Repository boundary expanded for history detail/list enrichment (`fetchMatch`, `fetchParticipants`) with SwiftData implementation.
- Reduced remaining user-visible placeholders in quick-add and migration recovery copy paths.

### Iteration 4 (active)
Scope:
- Convert release evidence docs into executable run templates and align reports with current implementation state.

Planned:
- [x] Add execution/evidence templates to `QA-Signoff-RC1.md`.
- [x] Add manual run capture template blocks to `Phase06-Manual-Test-Report.md`.
- [x] Add performance metric capture template to `Phase06-Performance-Report.md`.
- [x] Update migration safety report to reflect implemented recovery handlers and remaining manual validation gap.
- [ ] Execute device/manual runs and replace `Pending` values with observed outcomes.
