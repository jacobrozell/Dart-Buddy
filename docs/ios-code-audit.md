# iOS code audit (senior review)

**Last reviewed:** 2026-06-11  
**Scope:** SwiftUI app shell, features, design system, localization (`en`/`de`/`es`/`nl`), accessibility test harness, documentation hygiene, lean 1.0 release surface.

This is the engineering audit companion to the UX audit in [`todo.md`](release/todo.md) § UI/UX audit. It does not duplicate release QA checklists — use [`release/1.0.0-ship-checklist.md`](release/1.0.0-ship-checklist.md) for ship evidence.

---

## Executive summary

The codebase is production-shaped: clear one-directional layer boundaries
(`App` → `Features` → `Domain` / `Data`), MVVM in features, pure domain engines,
repository isolation behind protocols, and a layered automated test suite (unit,
accessibility, UI smoke, WCAG). There are no dead-code, force-try, force-cast,
or stray-`print` problems in app code.

Major structural refactors from the June 2026 pass are **done**: SwiftData
repositories split per model, shared turn-submit scaffolding in
`MatchTurnSupport`, and large SwiftUI files decomposed into extensions /
subviews.

Remaining engineering work before 1.0 ship is **evidence and review-facing
polish**, not architecture:

- Manual accessibility evidence (VoiceOver, AXXXL, nutrition labels) — tracked
  under `accessibility/`.
- App Review hardening — party-mode teasers in Play setup picker, active-match
  resume without `ProductSurface` gating (`docs/release/lean-1.0-app-review-hardening-plan.md`).
- Owner UX decisions (stats bot edge case, AXXXL trophy sizes) — optional for
  1.0.

Conventions are written down in [`CONTRIBUTING.md`](../CONTRIBUTING.md).

---

## What is working well

1. **Bootstrap & recovery** — `DartBuddyApp` gates on `AppBootstrapper`; migration failure routes to `MigrationRecoveryView` without silent data loss.
2. **Dependency injection** — `AppDependencies` wired once; features receive protocols, not concrete SwiftData types in views.
3. **Domain purity** — `X01Engine`, `CricketEngine`, `MatchLifecycleService` stay framework-agnostic; ViewModels orchestrate IO.
4. **Product surface gating** — `ProductSurface` centralizes lean 1.0 vs full catalog; `ProductSurfaceTests` + `Lean1_0SmokeUITests` guard the default build.
5. **Appearance policy** — `AppAppearancePolicy` + `SystemNavigationPolicy` (iOS 26 Liquid Glass nav); `BrandChrome` modifiers avoid copy-paste.
6. **Telemetry** — `AppLogger` → allowlisted Firebase Analytics + Crashlytics sinks; feature flags disable telemetry in Debug/CI/UI tests.
7. **Accessibility IDs** — Gameplay and settings flows expose stable identifiers consumed by `WCAGAccessibilityUITests` and the X01/Cricket UI test plan.
8. **Test layering** — Phase-tagged unit tests, bot simulations, lean smoke, regression UI, WCAG audits map to release gates.

---

## Findings & recommendations

### P1 — Ship-adjacent (product / evidence)

| ID | Finding | Recommendation |
|----|---------|----------------|
| A1 | Manual a11y evidence still open | Complete `accessibility/Manual_todo.md` + `accessibility/1.0-nutrition-label-checklist.md`; link in `QA-Signoff-RC1.md` |
| A2 | Hardcoded display sizes at AXXXL | `MatchSummaryScreen`, `X01MatchScreen` use `.font(.system(size:))`; prefer `relativeTo:` or cap scale with `@Environment(\.dynamicTypeSize)` |
| A3 | Statistics bot edge case | Product decision in `docs/release/todo.md` § Owner decisions |
| A4 | App Review surface leaks | Done — `isMatchTypeReachable`, lean mode picker, resume gating; metadata/screenshots still owner QA |
| A5 | TestFlight telemetry smoke | Verify `app_open` + match events in Firebase Console on internal Release build |

### P2 — Consistency (code health — mostly done)

| ID | Finding | Status |
|----|---------|--------|
| B1 | Dual token systems (`Brand` vs `DS`) | Documented in `DesignSystem/README.md`; enforce on new screens |
| B4 | Large SwiftUI files | Done — `SetupHomeView`, `PlayersRootView`, `X01MatchScreen` split |
| B7 | Duplicate turn-submit flows | Done — `MatchTurnSupport` + `MatchTurnSubmitter` |
| B8 | Monolithic repository | Done — `SwiftData*Repository` + `SwiftDataRepositorySupport` |
| B5 | Settings tab bar bleed | Verify on physical device; `.safeAreaPadding(.bottom)` already applied |
| B6 | Migration recovery styling | Done — `Brand` + `DS.Spacing` |

### P3 — Housekeeping (post-1.0)

| ID | Finding | Recommendation |
|----|---------|----------------|
| C1 | `inputMode: .totalEntry` in X01 VM but 1.0 is per-dart only | Keep enum for future toggle; documented in `MatchSpec` |
| C2 | Per-call `ModelContext` profiling | Only if RC performance report fails |
| C3 | Snapshot tests | After UI lock |

---

## Module map (actual vs spec names)

| Spec name | Repo path | Notes |
|-----------|-----------|-------|
| PlayFeature | `Features/Play/{Setup,X01,Cricket,Shared}/` | Setup, X01, Cricket, summary, play home |
| ActivityFeature | `Features/Activity/` | History + Statistics segments |
| HistoryFeature | `Features/History/` | List + detail (embedded in Activity) |
| PlayersFeature | `Features/Players/` | List, detail, edit, visuals |
| SettingsFeature | `Features/Settings/` | Form + `SettingsViewModel` |
| Statistics | `Features/Statistics/` | Segment inside Activity |
| DesignSystem | `DesignSystem/` | Tokens, components, `GameplayLayout` |
| Support | `Support/` | L10n, logging, preferences, flags, `ProductSurface` |

Lean 1.0 tab order in `MainTabView`: **Play → Players → Activity → Settings** (Modes hidden). Full product surface adds Modes between Play and Players. See [`specs/AppShellSpec.md`](../specs/AppShellSpec.md).

---

## Design system rules (enforced by convention)

```
Scoreboard tabs (Play, Players, Activity)
  → Brand.* colors
  → DS.Spacing / DS.Radius
  → .brandScoreboardChrome(appearanceModeRaw:)

Settings
  → .brandSettings* modifiers (native Form in Light; brand chrome in Dark)

System navigation (iOS 26+)
  → SystemNavigationPolicy — do not override tab/nav materials

Recovery / rare native-only surfaces
  → Brand background + DS spacing (MigrationRecoveryView)
```

Dark/light progress tracker: [`accessibility/dark-light-mode.md`](../accessibility/dark-light-mode.md).

---

## Testing posture

| Layer | Location | Role |
|-------|----------|------|
| Unit | `Tests/Unit/` | Engines, VMs, repos, policy, simulations, identifier contracts |
| Accessibility | `Tests/Accessibility/` | WCAG contrast + label contracts |
| Lean smoke | `Tests/UI/Lean1_0SmokeUITests.swift` | 4-tab shell, X01/Cricket start, reset, resume |
| Mode UI | `Tests/UI/X01MatchUITests.swift`, `CricketMatchUITests.swift` | Gameplay pad flows |
| Regression UI | `Tests/UI/RegressionUITests.swift` | Bot undo, exit Stay, bust, landscape |
| WCAG UI | `Tests/UI/WCAGAccessibilityUITests.swift` | Automated audits + ID contracts |
| Backlog | [`docs/testing/x01-cricket-ui-test-phased-plan.md`](testing/x01-cricket-ui-test-phased-plan.md) | Phased X01/Cricket + regression catalog |

**CI:** `DartBuddyCI` (unit + WCAG on PR); full `DartBuddy` scheme + nightly Pro Max landscape.

---

## Changelog

| Date | Change |
|------|--------|
| 2026-06-02 | Initial audit; consolidated dark/light tracker; DesignSystem README; removed `ThemeTokens`; aligned `MigrationRecoveryView` styling |
| 2026-06-03 | Refinement pass: `CONTRIBUTING.md`; removed force-unwrap in `SettingsViewModel`; split `SetupHomeView`, `PlayersRootView`, `X01MatchScreen` |
| 2026-06-03 | B7/B8 done: `MatchTurnSupport` + per-model SwiftData repositories |
| 2026-06-06 | One-type-per-file pass on History/Players view models |
| 2026-06-11 | App Review hardening: `isMatchTypeReachable`, lean mode picker, resume/deep-link gating |
| 2026-06-11 | Refresh for lean 1.0 RC: updated executive summary (B7/B8 closed), Activity tab map, testing posture, App Review hardening (A4), telemetry smoke (A5); merged UI test docs into phased plan |
