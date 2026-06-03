# iOS code audit (senior review)

**Date:** 2026-06-02  
**Scope:** SwiftUI app shell, features, design system, accessibility test harness, documentation hygiene.

This is the engineering audit companion to the UX audit in [`todo.md`](../todo.md) § UI/UX audit. It does not duplicate release QA checklists — use [`release_checklist.md`](../release_checklist.md) for ship evidence.

---

## Executive summary

The codebase is **production-shaped**: clear layer boundaries (`App` → `Features` → `Domain` / `Data`), MVVM in features, pure domain engines, repository isolation, and a strong automated WCAG UI test suite. Remaining work is mostly **consistency** (tokens, typography at AXXXL), **evidence** (manual VoiceOver / device matrix), and **doc placement** — not architectural rewrites.

| Area | Grade | Notes |
|------|-------|-------|
| Architecture & boundaries | A | Matches [`specs/ArchitectureSpec.md`](../specs/ArchitectureSpec.md) |
| Domain / testability | A | Engines and lifecycle tested by phase |
| SwiftUI / MVVM | A− | ViewModels own state; a few large views (setup, X01) |
| Design system | B+ | `Brand` + `DS` split is intentional but needs discipline |
| Accessibility (automated) | A | 40/40 `WCAGAccessibilityUITests` |
| Accessibility (manual) | Incomplete | AXXXL evidence, VO spot-checks in `accessibility/` |
| Documentation | B+ | Good spec governance; trackers were scattered (now consolidated) |

---

## What is working well

1. **Bootstrap & recovery** — `DartsScoreboardApp` gates on `AppBootstrapper`; migration failure routes to `MigrationRecoveryView` without silent data loss.
2. **Dependency injection** — `AppDependencies` wired once; features receive protocols, not concrete SwiftData types in views.
3. **Domain purity** — `X01Engine`, `CricketEngine`, `MatchLifecycleService` stay framework-agnostic; ViewModels orchestrate IO.
4. **Appearance policy** — `AppAppearancePolicy` centralizes light/dark/system vs Settings chrome; `BrandChrome` modifiers avoid copy-paste.
5. **Accessibility IDs** — Gameplay and settings flows expose stable `accessibilityIdentifier`s consumed by `WCAGAccessibilityUITests`.
6. **Test layering** — Phase-tagged unit tests, long-term bot simulations, UI smoke + WCAG suites map to release gates.

---

## Findings & recommendations

### P1 — Ship-adjacent (product / evidence)

| ID | Finding | Recommendation |
|----|---------|----------------|
| A1 | Manual a11y evidence still open | Complete `accessibility/Manual_todo.md` + link in `QA-Signoff-RC1.md` |
| A2 | Hardcoded display sizes at AXXXL | `MatchSummaryScreen`, `X01MatchScreen` use `.font(.system(size:))`; prefer `relativeTo:` or cap scale with `@Environment(\.dynamicTypeSize)` |
| A3 | Statistics bot edge case | Product decision in `todo.md` § Owner decisions |

### P2 — Consistency (code health)

| ID | Finding | Recommendation |
|----|---------|----------------|
| B1 | **Dual token systems** | **`Brand`** = scoreboard palette (light/dark). **`DS`** = spacing/radius + semantic colors for native surfaces. Do not mix `DS.ColorRole` on brand screens — use `Brand.textSecondary` (see `DesignSystem/README.md`). |
| B2 | **`ThemeTokens` unused** | Removed; was dead code. |
| B3 | **`ScoringPadLabels` in DesignSystem** | Acceptable for now; if Play grows, move to `Features/Play/`. |
| B4 | **Large SwiftUI files** | `SetupHomeView`, `PlayersRootView`, `X01MatchScreen` — consider extracting subviews (setup sections, player row, score column) when touching those files next. |
| B5 | **Settings tab bar bleed** | Verify on device; `SettingsRootView` already uses `.safeAreaPadding(.bottom)`. If bleed persists, add tab-bar-aware inset via `safeAreaInset(edge: .bottom)` on the `Form`. |
| B6 | **Migration recovery styling** | Migrated to `Brand` + `DS.Spacing` for consistency with recovery UX on brand shell. |

### P3 — Housekeeping (post-1.0)

| ID | Finding | Recommendation |
|----|---------|----------------|
| C1 | `inputMode: .totalEntry` in X01 VM but 1.0 is per-dart only | Keep enum for future toggle; document in `MatchSpec` |
| C2 | Per-call `ModelContext` profiling | Only if RC performance report fails |
| C3 | Snapshot tests | After UI lock |

---

## Module map (actual vs spec names)

| Spec name | Repo path | Notes |
|-----------|-----------|-------|
| PlayFeature | `Features/Play/` | Setup, X01, Cricket, summary, play home |
| HistoryFeature | `Features/History/` | List + detail |
| PlayersFeature | `Features/Players/` | List, detail, edit, visuals |
| SettingsFeature | `Features/Settings/` | Form + `SettingsViewModel` |
| Statistics | `Features/Statistics/` | Tab (not renamed in spec) |
| DesignSystem | `DesignSystem/` | Tokens, components, `GameplayLayout` |
| Support | `Support/` | L10n, logging, preferences, flags |

Tab order in `MainTabView` matches [`specs/AppShellSpec.md`](../specs/AppShellSpec.md): Play → Players → Statistics → History → Settings.

---

## Design system rules (enforced by convention)

```
Scoreboard tabs (Play, Players, Stats, History)
  → Brand.* colors
  → DS.Spacing / DS.Radius
  → .brandScoreboardChrome(appearanceModeRaw:)

Settings (theme = Light)
  → Native Form, DS.ColorRole for secondary text

Settings (theme = Dark / System)
  → Brand dark chrome via .brandSettings* modifiers

Recovery / rare native-only surfaces
  → Brand background + DS spacing (MigrationRecoveryView)
```

Dark/light progress tracker: [`accessibility/dark-light-mode.md`](../accessibility/dark-light-mode.md).

---

## Testing posture

| Layer | Location | Role |
|-------|----------|------|
| Domain | `Tests/Phase02Tests/` | Engines, scoring, lifecycle |
| ViewModels | `Tests/Phase03Tests/` | Feature VM behavior |
| Long-run | `Tests/Phase04Tests/` | Bots, statistics flows |
| Foundation | `Tests/FoundationTests/` | Policy, prefs, a11y labels |
| UI smoke | `UITests/DartsScoreboardUITests.swift` | Core journeys |
| WCAG | `UITests/WCAGAccessibilityUITests.swift` | Automated audits + ID contracts |

---

## Changelog

| Date | Change |
|------|--------|
| 2026-06-02 | Initial audit; consolidated dark/light tracker; DesignSystem README; removed `ThemeTokens`; aligned `MigrationRecoveryView` styling |
