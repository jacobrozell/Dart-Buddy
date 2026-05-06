# Launch Day Runbook (1.0.0 RC -> GA)

## Command Structure
- Release owner: coordinates go/no-go, submission, and incident routing.
- QA owner: owns final evidence integrity in `QA-Signoff-RC1.md`.
- iOS engineering owner: owns migration/performance/security technical checks.

## Pre-Launch Gate Checklist
1. Confirm `QA-Signoff-RC1.md` has no open P0 items.
2. Confirm migration smoke run completed and recovery paths validated.
3. Confirm performance metrics captured against MVP targets:
   - launch < 2s
   - submitTurn < 100ms
   - resumeMatch < 500ms
   - history first paint < 400ms
4. Confirm security/privacy checklist has no release-blocking gaps.
5. Confirm App Store metadata truthfulness:
   - Category: `Sports`
   - Price: `Free`
   - Ads: `None`
   - IAP: `None`
   - Privacy labels consistent with local-first behavior and current diagnostics.

## Submission Checklist
1. Verify app name/subtitle/keywords match approved metadata set.
2. Verify screenshots reflect real current app UI and key MVP flows.
3. Attach final release notes from `Release-Notes-Template.md` adaptation.
4. Submit build and capture submission timestamp and build identifier.

## Live Monitoring Cadence (Day 0 to Day 7)
- Day 0:
  - Hourly checks for crash signals and severe reviews.
  - Validate no widespread failures in setup, submit turn, resume, history, reset.
- Day 1-7:
  - Daily review triage and defect trend summary.
  - Re-rank patch backlog by severity and user impact.

## Incident Triage Flow (Hotfix vs Rollback)
Use `Rollback-and-Hotfix-Criteria.md` as source of truth.

1. Triage severity and blast radius:
   - P0 broad impact -> rollback candidate.
   - P0 narrow with guardrail -> hotfix candidate.
   - P1 -> schedule 1.0.x patch unless gating.
2. Freeze new release-branch changes.
3. Collect diagnostics for affected flow.
4. Validate persistence/migration safety before deployment action.
5. Publish user-facing status and ETA.

## First Post-Launch Patch Queue (1.0.x)
- Priority 1: Migration recovery execution hardening and UX clarity.
- Priority 2: High-impact scoring/input friction surfaced from live feedback.
- Priority 3: History and player flow polish issues with measurable user impact.
- Priority 4: Accessibility and orientation evidence gaps converted into repeatable checklist process.

## Rollback Readiness Confirmation
- Rollback owner designated: `TBD`
- Last rollback criteria review: `TBD`
- Last dry-run verification of decision matrix: `TBD`
