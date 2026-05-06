# Phase 02 - Core Engines and Match Lifecycle

## Objective
Ship deterministic domain behavior first: setup payload handling, turn processing, undo, completion, resume, and stats reducers independent of final UI polish.

## Specs Anchored
- `specs/MatchSpec.md`
- `specs/SetupFlowSpec.md`
- `specs/X01GameSpec.md`
- `specs/CricketSpec.md`
- `specs/ScoringInputSpec.md`
- `specs/StatsSpec.md`

## Batch Workstreams
- **Domain lane**
  - Implement `X01Engine` and `CricketEngine` with full MVP rules.
  - Implement `MatchLifecycleService` transitions (create/progress/complete/resume).
  - Implement undo semantics across leg/set/closure boundaries.
- **Eventing lane**
  - Implement turn + dart event payloads with versioning and replay determinism.
  - Add snapshot checkpoint strategy for fast resume.
- **Stats lane**
  - Implement baseline metrics and deterministic formulae.
  - Implement aggregate cache recompute + rebuild-from-events utility.

## Deliverables
- Engine contract tests for X01 single/double-out, bust paths, and cricket closure/overflow.
- End-to-end lifecycle integration (setup -> play -> complete -> history-ready summary).
- Resume determinism tests from snapshots + tail events.

## Exit Criteria
- Core regression matrix passes for match lifecycle and scoring rules.
- Resume after relaunch works for both X01 and Cricket.
- Winner and completion metadata are persisted correctly.
- Undo is safe and deterministic in both game modes.
