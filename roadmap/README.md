# 1.0.0 Delivery Roadmap

This roadmap translates the current specs into an ordered, batch-based plan to reach a production-ready `1.0.0`.

## Scope Boundary
- **In scope for `1.0.0`:** local-first iPhone app, X01 + Cricket, players, history, settings, accessibility, release ops, App Store launch readiness.
- **Explicitly deferred post-`1.0.0`:** online play, Apple Watch companion, vision auto-scoring, Firebase runtime SDK adoption, UI automation beyond locked MVP baseline.

## UI Guidance Inputs
- Figma documentation and mockup/handoff assets are guidance inputs for UI fidelity, not a standalone source of truth.
- `FigmaBuildPlan`, `UIBlueprintSpec`, and `UIImplementationSpec` are used together; written specs and product behavior contracts are authoritative.
- Because Figma is currently incomplete, teams should use it where accurate and rely on authoritative specs where Figma is missing or incorrect.
- Conflict rule: if Figma and authoritative written specs diverge, authoritative specs in `specs/SpecGovernance.md` win, then Figma can be reconciled.

## Working Model for This Release
- UI quality is verified continuously during Phases 03-05 via manual checks against specs and Figma (not only at final UI lock).
- XCTest UI automation is explicitly deferred to a future phase.
- CI/CD automation is out of scope for this roadmap execution; verification is run manually for now.

## Run Order
1. `roadmap/00-scope-and-governance.md`
2. `roadmap/AGENT-KICKOFF-BRIEF.md` (mandatory pre-implementation read)
3. `roadmap/01-foundation-architecture-and-data.md`
4. `roadmap/02-core-engines-and-match-lifecycle.md`
5. `roadmap/03-app-shell-navigation-and-setup.md`
6. `roadmap/04-feature-batches-gameplay-players-history-settings.md`
7. `roadmap/05-ui-system-and-fidelity-lock.md`
8. `roadmap/06-quality-hardening-and-release-operations.md`
9. `roadmap/07-rc-launch-and-post-launch.md`

## Verification Artifact
- `roadmap/SECOND-PASS-COVERAGE-AUDIT.md` is a coverage readout, not an execution phase.

## Authoritative Sources Used
- Product/system: `AppShellSpec`, `ArchitectureSpec`, `NavigationSpec`, `TechStackSpec`, `SwiftData`, `DataSchemaSpec`, `RepositorySpec`, `DesignSystemSpec`, `UIBlueprintSpec`, `UIImplementationSpec`, `UIReviewChecklist`, `AccessibilitySpec`, `TestPlanSpec`, `ReleaseOpsSpec`, `SecurityPrivacySpec`, `PerformanceSpec`, `LocalizationSpec`, `LoggingSpec`, `FeatureFlagConfigSpec`, `ErrorModelSpec`, `AppStoreConnectSpec`, `SpecGovernance`.
- Feature: `SetupFlowSpec`, `MatchSpec`, `X01GameSpec`, `CricketSpec`, `ScoringInputSpec`, `PlayerSpec`, `HistorySpec`, `StatsSpec`, `SettingsSpec`.
- Mockup/handoff references available in repo: `FigmaBuildPlan`, `UIBlueprintSpec`, `UIImplementationSpec`.

## Definition of Roadmap Completion
- All phase exit criteria pass in sequence.
- Every MVP requirement in the listed specs is implemented or documented as accepted deferment.
- Release gates in accessibility, quality, migration safety, and operations are signed off for App Store submission.
