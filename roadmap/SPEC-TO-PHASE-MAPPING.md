# Spec to Phase Mapping (1.0.0)

> **Superseded for day-to-day work.** Current product behavior and spec ownership live in [`specs/README.md`](../specs/README.md) (Feature Specs) and [`specs/SpecGovernance.md`](../specs/SpecGovernance.md) §5 coverage checklist. Keep this file for historical phase traceability only.

Use this file to verify every spec is either implemented in `1.0.0` phases or explicitly deferred.

## Core Implementation Specs
- `AppShellSpec` -> Phases 01, 03
- `ArchitectureSpec` -> Phases 00, 01
- `NavigationSpec` -> Phase 03
- `TechStackSpec` -> Phases 00, 01, 06
- `SwiftData` + `DataSchemaSpec` + `RepositorySpec` -> Phases 01, 02, 06
- `DesignSystemSpec` + `specs/archive/FigmaBuildPlan.md` + `UIBlueprintSpec` + `UIImplementationSpec` + `UIReviewChecklist` -> Phases 03, 04, 05 (historical; see `roadmap/archive/phases/`)
- `AccessibilitySpec` + `LocalizationSpec` -> Phases 05, 06, 07
- `TestPlanSpec` + `SwiftTestingTagsSpec` -> Phases 02, 04, 06
- `ReleaseOpsSpec` + `AppStoreConnectSpec` -> Phases 06, 07
- `LoggingSpec` + `ErrorModelSpec` + `FeatureFlagConfigSpec` + `SecurityPrivacySpec` -> Phases 00, 01, 06

## Feature Specs (MVP)
- See [`specs/README.md`](../specs/README.md) § Feature Specs for the current list (`PlayHomeSpec`, `BotOpponentSpec`, `TrainingBotSpec`, `StatisticsTabSpec`, `MigrationRecoverySpec`, `QuickAddPlayerSpec`, etc.)
- Historical phase mapping: `SetupFlowSpec` -> Phase 03; `MatchSpec` -> Phases 02, 04; gameplay specs -> Phases 02, 04; players/history/stats/settings -> Phase 04

## Future / Explicitly Deferred Specs
- `FirebaseBackendAnalyticsSpec` -> Phase 1 Analytics/Crashlytics shipped in 1.0; Auth/Firestore still post-1.0
- `AppleWatchCompanionSpec` -> post-1.0 phases only
- `AutoScoringVisionSpec` -> post-1.0 phases only
- `OnlinePlaySpec` -> post-1.0 phases only

## Governance Rule
If implementation conflicts with any authoritative spec, resolve the spec conflict first, then continue phase execution.
