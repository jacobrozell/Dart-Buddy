# Phase 07 - Release Candidate, Launch, and Immediate Follow-Up

## Objective
Execute final release pipeline, publish with truthful App Store presentation, and run tight post-launch monitoring and patch readiness.

## Specs Anchored
- `specs/ReleaseOpsSpec.md`
- `specs/AppStoreConnectSpec.md`
- `specs/TestPlanSpec.md`
- `specs/AccessibilitySpec.md`
- `specs/LocalizationSpec.md`

## Batch Workstreams
- **RC lane**
  - Feature freeze and full release-candidate validation.
  - Manual exploratory pass on target devices across core flows.
  - Migration smoke from previous build/store snapshots.
- **App Store lane**
  - Finalize app name/subtitle/keywords/privacy metadata/screenshots.
  - Ensure listing truthfulness against shipped behavior.
  - Verify category/pricing/compliance metadata (`Sports`, `Free`, no ads, no IAP for `1.0.0`).
- **Launch lane**
  - Stage rollout decision and launch-day issue command path.
  - Daily crash/review monitoring and hotfix triage criteria.
- **Post-launch lane (first two weeks)**
  - Capture defect trends and top friction points.
  - Prioritize `1.0.x` patch list without widening scope.

## Deliverables
- Signed RC checklist and go/no-go decision.
- App Store listing assets + metadata package.
- Launch runbook and day-1/day-7 monitoring report template.

## Exit Criteria
- `1.0.0` submitted and approved for release.
- No launch-blocking accessibility, migration, or core-flow defects.
- First post-launch patch backlog triaged by severity and user impact.

## Deferred Backlog After 1.0.0
- Firebase runtime adoption phases (`specs/FirebaseBackendAnalyticsSpec.md`).
- Apple Watch companion (`specs/AppleWatchCompanionSpec.md`).
- Vision auto-scoring (`specs/AutoScoringVisionSpec.md`).
- Online play (`specs/OnlinePlaySpec.md`).
- UI automation expansion after UI lock and stabilization.
