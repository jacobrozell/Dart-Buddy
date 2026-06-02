# Feature Flag and Configuration Specification

## 1. Purpose
Define how runtime feature flags and environment configuration are modeled so phased rollouts (Firebase, watch, vision, online) are safe and reversible.

---

## 2. Scope

## In Scope (1.0.0)
- Local compile-time/runtime flags
- Deterministic defaults per build configuration
- Centralized feature capability registry

## Future Scope
- Remote config-backed flags
- Staged rollout and kill-switch controls

---

## 3. Core Design Rules
- All feature checks route through one `FeatureFlags` interface.
- No hardcoded flag conditionals scattered across views.
- Defaults must be explicit and versioned.
- Flag names are stable and documented.
- Behavior must be deterministic when remote config is unavailable.

---

## 4. Flag Categories
- `release`: production-safe toggles
- `experiment`: short-lived evaluation toggles
- `developer`: debug-only controls
- `killSwitch`: immediate disable path for risky capabilities

---

## 5. Initial Flag Set (Starter)
- `enableFirebaseAnalytics` (Debug default `false`, Release default `true`; off for `-disable_firebase_analytics`, `-ui_test_reset`)
- `enableFirebaseCrashlytics` (same matrix as analytics; shares debug launch arg `-firebase_analytics_debug`)
- `enableAppleWatchCompanion` (default `false`)
- `enableVisionAutoScoring` (default `false`)
- `enableOnlinePlay` (default `false`)
- `enableAdvancedDiagnostics` (default `false`)

---

## 6. Architecture
- `FeatureFlagsProvider` protocol:
  - `isEnabled(_ flag: FeatureFlag) -> Bool`
- `LocalFeatureFlagsProvider` (MVP)
- `CompositeFeatureFlagsProvider` (future local+remote merge)

Usage rule:
- Feature layer asks provider.
- Domain logic should receive resolved capability values via config inputs (not read flags directly).

---

## 7. Environment Configuration
- Distinct config profiles:
  - `Debug`
  - `Staging`
  - `Release`
- Flag defaults can vary by profile, but must be documented in one matrix.
- Sensitive configuration values (future tokens/keys) must use secure storage patterns.

---

## 8. Rollout Rules (Future Remote Config)
- Roll out in small cohorts first.
- Always define rollback/kill-switch path before enabling.
- Log flag evaluation context for diagnostics (without sensitive data).

---

## 9. Testing
- Unit tests for flag provider behavior by environment.
- Integration tests proving disabled features are unreachable.
- Regression tests for kill-switch behavior.

---

## 10. Governance
- Every new flag requires:
  - purpose
  - owner
  - default values by environment
  - cleanup plan/date (for non-permanent flags)
