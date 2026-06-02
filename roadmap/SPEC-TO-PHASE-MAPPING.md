# Spec to Phase Mapping (1.0.0)

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
- `SetupFlowSpec` -> Phase 03
- `MatchSpec` -> Phases 02, 04
- `X01GameSpec` + `CricketSpec` + `ScoringInputSpec` -> Phases 02, 04
- `PlayerSpec` + `HistorySpec` + `StatsSpec` + `SettingsSpec` -> Phase 04 (with test hardening in Phase 06)

## Future / Explicitly Deferred Specs
- `FirebaseBackendAnalyticsSpec` -> post-1.0 phases only
- `AppleWatchCompanionSpec` -> post-1.0 phases only
- `AutoScoringVisionSpec` -> post-1.0 phases only
- `OnlinePlaySpec` -> post-1.0 phases only

## Governance Rule
If implementation conflicts with any authoritative spec, resolve the spec conflict first, then continue phase execution.
