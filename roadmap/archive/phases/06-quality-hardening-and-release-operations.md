# Phase 06 - Quality Hardening and Release Operations

## Objective
Stabilize behavior, prove performance/migration/reliability targets, and produce operational artifacts needed for a safe `1.0.0` cut.

## Specs Anchored
- `specs/TestPlanSpec.md`
- `specs/SwiftTestingTagsSpec.md`
- `specs/PerformanceSpec.md`
- `specs/ReleaseOpsSpec.md`
- `specs/SecurityPrivacySpec.md`
- `specs/LoggingSpec.md`

## Batch Workstreams
- **Test hardening lane**
  - Complete unit + integration suites for all core domains/features.
  - Enforce canonical Swift Testing tags for consistent manual/local test selection.
  - Validate MVP regression matrix end to end.
  - Enforce `1.0.0` test policy: UI automation remains deferred; manual UI/accessibility/orientation checks are mandatory release evidence.
- **Performance lane**
  - Instrument `submitTurn`, `resumeMatch`, `completeMatch`, `historyLoad`.
  - Validate launch, scoring responsiveness, resume, and history first-paint targets.
  - Validate against MVP targets: launch < 2s, submit perceived < 100ms, resume < 500ms, history first paint < 400ms.
- **Operational readiness lane**
  - Finalize release notes template, QA sign-off template, migration report.
  - Validate logging categories and production-safe verbosity behavior.
- **Security/privacy lane**
  - Verify local-first baseline, privacy disclosures, no forbidden tracking/SDKs.

## Deliverables
- Green manual/local test runs on required unit/integration lanes.
- Performance report with pass/fail against MVP targets.
- Migration safety report and rollback/hotfix criteria.
- Security/privacy release checklist pass.
- RC evidence bundle including manual accessibility, dark mode, and landscape verification artifacts.

## Exit Criteria
- No unresolved critical defects or failing critical/regression/migration suites.
- Performance targets met or accepted with explicit signed mitigations.
- Release artifacts ready for candidate build.
