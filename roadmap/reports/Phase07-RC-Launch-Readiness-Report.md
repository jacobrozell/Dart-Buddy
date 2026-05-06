# Phase 07 RC and Launch Readiness Report

## Decision
- **Go/No-Go:** **NO-GO (current state)**
- **Rationale:** Required manual/device evidence for release gates is still pending, and migration recovery actions are scaffold-level placeholders rather than fully executed recovery handlers.

## Gate Status
- RC checklist execution: **In progress / not complete**
- Core-flow exploratory verification on local/device: **Pending**
- Migration smoke + recovery readiness validation: **Partial**
- Performance target validation on device: **Pending**
- App Store metadata/compliance truthfulness check: **Ready for submission review, pending final App Store Connect entry verification**
- Launch runbook + hotfix triage flow: **Completed (docs finalized)**

## Blockers (P0/P1), Owners, and Next Actions

### P0 (launch blocking)
- **P0-01: Core-flow manual evidence missing**
  - Owner: QA + iOS Eng
  - Next actions:
    1. Execute and record pass/fail for:
       - setup -> X01 -> summary
       - setup -> cricket -> summary
       - resume active match
       - undo paths
       - players archive/delete guard
       - history list/detail
       - settings reset flow
    2. Fill all statuses in `roadmap/release/QA-Signoff-RC1.md`.
- **P0-02: Migration recovery handlers not fully operationally validated**
  - Owner: iOS Eng
  - Next actions:
    1. Complete concrete execution handlers for retry/export/reset where placeholders remain.
    2. Run migration smoke from previous build data and log evidence in migration report.

### P1 (must close for strong 1.0 confidence)
- **P1-01: Accessibility and orientation matrix evidence not captured**
  - Owner: QA
  - Next actions:
    1. Run VoiceOver smoke on setup/gameplay/history/settings.
    2. Run Dynamic Type checks on critical screens.
    3. Capture portrait/light, portrait/dark, landscape/light, landscape/dark results.
- **P1-02: Performance measurements against MVP targets not recorded**
  - Owner: iOS Eng
  - Next actions:
    1. Run release build instrumentation on target device(s).
    2. Record launch, submitTurn, resumeMatch, history first paint in report.

## Exact Unblock Steps (Environment/Tooling)
- Use a local Xcode/iOS runtime where app builds and runs.
- Build release candidate:
  - `xcodebuild -scheme DartsScoreboard -configuration Release -destination "platform=iOS Simulator,name=iPhone 15" build`
- Run validation on at least one physical device + one simulator configuration.
- Capture evidence directly in:
  - `roadmap/release/QA-Signoff-RC1.md`
  - `roadmap/reports/Phase06-Performance-Report.md`
  - `roadmap/reports/Phase06-Migration-Safety-Report.md`
  - `roadmap/reports/Phase06-Security-Privacy-Checklist.md`

## Launch-Day Action List
1. Confirm freeze and candidate build identifiers (version/build/schema).
2. Confirm QA sign-off doc has no unresolved P0.
3. Confirm migration smoke and recovery assessment completed.
4. Confirm performance targets are measured and within threshold or have accepted mitigation.
5. Confirm App Store metadata values:
   - Category `Sports`
   - Pricing `Free`
   - Ads `None`
   - IAP `None`
6. Submit with release notes and keep rollback/hotfix command path active for launch day.

## First Post-Launch Patch Priorities (Proposed 1.0.x)
1. Finalize migration recovery handler robustness and user-facing recovery UX.
2. Close remaining UI token consistency gaps and shared design-system primitive usage.
3. Address highest-frequency friction from launch-week feedback (history readability, setup friction, undo clarity).
4. Add stronger guardrails around settings reset transactional behavior verification.
5. Expand manual accessibility evidence into repeatable smoke protocol.

## Completed Evidence Index
- Query 07 decision package:
  - `roadmap/reports/Phase07-RC-Launch-Readiness-Report.md` (this file)
- RC checklist execution status:
  - `roadmap/release/QA-Signoff-RC1.md`
- Launch and hotfix operations:
  - `roadmap/release/Launch-Day-Runbook.md`
  - `roadmap/release/Rollback-and-Hotfix-Criteria.md`
- UI fidelity baseline:
  - `roadmap/reports/Phase05-UI-Fidelity-Report.md`
- Manual quality baseline:
  - `roadmap/reports/Phase06-Manual-Test-Report.md`
- Performance baseline and instrumentation:
  - `roadmap/reports/Phase06-Performance-Report.md`
- Migration safety baseline:
  - `roadmap/reports/Phase06-Migration-Safety-Report.md`
- Security/privacy baseline:
  - `roadmap/reports/Phase06-Security-Privacy-Checklist.md`
- App Store truth-source:
  - `specs/AppStoreConnectSpec.md`
