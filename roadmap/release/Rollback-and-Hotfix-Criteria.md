# Rollback and Hotfix Criteria

## Rollback Triggers (Immediate)
- Data migration failure without successful recovery path.
- Crash in core gameplay loop (submit/undo/resume) reproducible on release build.
- Corruption or loss of local match history.
- Critical accessibility regression blocking core flow completion.

## Hotfix Triggers (Patch Release)
- Non-crashing but high-impact scoring rule defects.
- Incorrect winner/completion metadata persistence.
- Settings reset partial-failure behavior.
- History rendering failures with valid data.

## Decision Matrix
- P0 + broad impact -> rollback candidate.
- P0 + narrow impact with safe guardrail -> hotfix.
- P1 -> schedule patch unless impacts release gates.

## Operational Steps
1. Freeze new changes on release branch.
2. Collect logs/diagnostics from affected flow.
3. Verify migration and persistence safety before any rollback/hotfix deployment.
4. Publish user-facing status and expected remediation timeline.
