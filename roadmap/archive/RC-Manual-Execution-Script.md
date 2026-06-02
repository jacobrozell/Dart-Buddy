# RC Manual Execution Script (Strict)

## Session Setup
1. Open `roadmap/release/QA-Signoff-RC1.md`.
2. Set candidate metadata:
   - version
   - build
   - device(s)
   - iOS version(s)
3. Start a timestamped note block for this run:
   - tester
   - start time
   - environment (simulator/device)

## Build and Launch
1. Build release candidate.
2. Install/run on:
   - one physical iPhone
   - one simulator profile
3. If build/launch fails:
   - mark impacted checks as `Blocked`
   - log exact error and unblock step in `Phase07-RC-Launch-Readiness-Report.md`
   - stop pass/fail claims for blocked items

## Core Flow Checks (must execute in order)
For each scenario, record `Pass/Fail`, short notes, and defects (if any).

1. Setup -> X01 -> Summary
   - create match with valid players
   - submit turns to completion
   - verify summary renders winner and stats coherently
2. Setup -> Cricket -> Summary
   - create cricket match
   - close numbers and complete match
   - verify summary consistency
3. Resume Active Match
   - leave mid-match
   - relaunch app
   - verify active match resumes without corruption
4. Undo Paths (X01 + Cricket)
   - submit turn
   - undo once and verify previous state restoration
5. Players Archive/Delete Guard
   - archive player
   - verify guarded delete behavior for referenced entities
6. History List/Detail
   - verify list rendering
   - open detail and confirm integrity of displayed result data
7. Settings Reset Flow
   - execute reset with confirmation
   - verify expected data wipe behavior and app recovery state

## Appearance + Accessibility Matrix
Record each row in QA sign-off file.

1. Portrait + Light
2. Portrait + Dark
3. Landscape + Light
4. Landscape + Dark
5. VoiceOver smoke:
   - setup, gameplay scoring controls, history, settings
6. Dynamic Type:
   - verify critical controls/labels remain readable and actionable
7. Non-color meaning:
   - cricket state and critical status cues remain understandable without color

## Migration and Recovery Smoke
1. Validate migration path from previous persisted state/build.
2. Validate recovery-path readiness:
   - retry
   - export diagnostics
   - reset flow
3. Record results in `roadmap/reports/Phase06-Migration-Safety-Report.md`.

## Performance Capture (release build)
Record observed values in `roadmap/reports/Phase06-Performance-Report.md`.

Required measurements:
- launch to usable UI
- submitTurn perceived latency
- resumeMatch latency
- history first paint

## Security and Privacy Final Check
Update `roadmap/reports/Phase06-Security-Privacy-Checklist.md`:
- transactional wipe verified on device
- release verbosity behavior validated
- privacy disclosure alignment checked against current app behavior

## App Store Truthfulness Check
Use `roadmap/reports/Phase07-AppStore-Metadata-Validation.md`:
- confirm category/pricing/compliance values
- confirm screenshots reflect current shipped UI
- confirm privacy/compliance text truthfulness

## Exit Rule
Mark go/no-go in `QA-Signoff-RC1.md` only when:
- no open P0 blockers
- all required gates are executed (or explicitly blocked with owner and unblock path)
- no unverified checks are represented as pass
