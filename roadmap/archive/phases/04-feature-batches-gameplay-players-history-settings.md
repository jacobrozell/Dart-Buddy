# Phase 04 - Feature Batches: Gameplay, Players, History, Settings

## Objective
Complete all MVP feature surfaces and their data contracts so the app is functionally complete before UI fidelity lock and hardening.

## Specs Anchored
- `specs/UIBlueprintSpec.md` (screen behavior)
- `specs/UIImplementationSpec.md` (screen contracts)
- `specs/PlayerSpec.md`
- `specs/HistorySpec.md`
- `specs/SettingsSpec.md`
- `specs/ScoringInputSpec.md`

## Parallel Batches
- **Batch A - X01 Gameplay UI**
  - Build X01 active match screen states, scoring input, bust/checkout feedback, undo, completion route.
- **Batch B - Cricket Gameplay UI**
  - Build cricket board rendering, non-color closure indicators, overflow visibility, undo.
- **Batch C - Players Domain UI**
  - Players list/detail/edit flows, archive/unarchive, guarded delete, duplicate-name validation.
- **Batch D - History UI**
  - History list filters (mode/date/player), detail timeline, missing-reference fallback.
- **Batch E - Settings + Recovery UI**
  - Preferences, defaults propagation to setup, destructive reset flow, migration recovery screen actions.

## Deliverables
- All 12 MVP screens implemented with required states and ViewModel events.
- Turn-by-turn event timeline visible in history detail.
- Player/history integrity behavior preserved after edits/archives/deletes.
- Reset-all-data flow fully transactional and recoverable.

## Exit Criteria
- Every screen contract in `UIImplementationSpec` is represented in code.
- Feature-level integration tests pass for player/history/settings/match continuity.
- No open P0/P1 functional defects in core user journeys.
