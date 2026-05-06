# Hotfix Decision Run Sheet

## Purpose
Operational decision sheet for `rollback` vs `hotfix` using `Rollback-and-Hotfix-Criteria.md`.

## Ownership
- Incident commander (release owner): `TBD`
- Engineering decision owner: `TBD`
- QA verification owner: `TBD`
- Communications owner: `TBD`

## Response SLA (1.0.x)
- P0 acknowledgment: <= 15 minutes from confirmation
- P0 action decision (rollback vs hotfix): <= 60 minutes from confirmation
- First user-facing update: <= 90 minutes from confirmation
- P1 triage decision: <= 1 business day

## Trigger Checklist
Mark all that apply.

### Rollback candidates
- [ ] Data migration failure without successful recovery path
- [ ] Reproducible crash in submit/undo/resume core gameplay loop
- [ ] Corruption or loss of local match history
- [ ] Critical accessibility regression blocking core flow completion

### Hotfix candidates
- [ ] High-impact scoring rule defect without crash
- [ ] Incorrect winner/completion metadata persistence
- [ ] Settings reset partial-failure behavior
- [ ] History rendering failure with valid data

## Decision Matrix
- P0 + broad impact -> rollback candidate
- P0 + narrow impact with guardrail -> hotfix candidate
- P1 -> schedule `1.0.x` patch unless it blocks release gates

## Incident Record
- Incident ID: `TBD`
- Detection timestamp: `TBD`
- Affected versions/builds: `TBD`
- Affected flow(s): `TBD`
- Reproduction status: `TBD`
- Blast radius estimate: `TBD`
- Data safety assessment: `TBD`
- Decision: `TBD`
- Decision timestamp: `TBD`

## Required Actions Before Ship Action
1. Freeze new changes on release branch.
2. Collect diagnostic logs for affected flow.
3. Verify migration/persistence safety for selected response.
4. Confirm QA reproduction and fix verification plan.
5. Publish status + remediation ETA.
