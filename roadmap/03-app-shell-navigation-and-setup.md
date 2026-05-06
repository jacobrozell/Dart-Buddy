# Phase 03 - App Shell, Navigation, and Setup Flow

## Objective
Connect core services into end-user app flow: tab shell, typed routes, launch behavior, play-home resume logic, and validated match setup path.

## Specs Anchored
- `specs/AppShellSpec.md`
- `specs/NavigationSpec.md`
- `specs/UIBlueprintSpec.md` (global flow contracts)
- `specs/UIImplementationSpec.md` (Play Home + Match Setup contracts)

## Batch Workstreams
- **Navigation lane**
  - Implement root tabs and per-tab typed route stacks.
  - Enforce stable ID route params only.
- **Play entry lane**
  - Implement Play Home states: loading, with/without active match, no players, error.
  - Implement resume card logic for single active in-progress match.
- **Setup lane**
  - Implement full setup form sections with sticky `Start Match`.
  - Add validation matrix and quick-add player route hook.
  - Persist last-used defaults and consume settings defaults.

## Deliverables
- Navigation contracts for Play/History/Players/Settings roots.
- Setup-to-match transition for both modes.
- Confirmation guard behavior for destructive exits from active play routes.

## Exit Criteria
- New-match and resume-match flows are deterministic and spec-aligned.
- Invalid setup states cannot start a match and always show inline guidance.
- No mutable model blobs passed through route payloads.
