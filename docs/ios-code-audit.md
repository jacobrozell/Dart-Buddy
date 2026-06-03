# iOS code audit (senior review)

**Last reviewed:** 2026-06-03  
**Scope:** SwiftUI app shell, features, design system, accessibility test harness, documentation hygiene.

This is the engineering audit companion to the UX audit in [`todo.md`](../todo.md) § UI/UX audit. It does not duplicate release QA checklists — use [`release_checklist.md`](../release_checklist.md) for ship evidence.

---

## Executive summary

The codebase is production-shaped: clear one-directional layer boundaries
(`App` → `Features` → `Domain` / `Data`), MVVM in features, pure domain engines,
repository isolation behind protocols, and an automated WCAG UI test suite.
There are no dead-code, force-try, force-cast, or stray-`print` problems. The
remaining engineering work is **consistency and decomposition**, not
architectural rewrites:

- A few files carry too much: the monolithic `SwiftDataRepositories` and the
  near-duplicate turn-submit flows in the X01 / Cricket view models are the main
  structural smells (see P2 below).
- A handful of feature views are long; they are already decomposed into focused
  subviews, so the win is file-splitting for readability, not restructuring.
- Manual accessibility evidence (VoiceOver, AXXXL, device matrix) is still open
  and tracked under `accessibility/`.

Conventions are now written down in [`CONTRIBUTING.md`](../CONTRIBUTING.md) so
new code has a standard to match.

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
| B4 | **Large SwiftUI files** | Done. Split via extension / dedicated files: `SetupHomeView` → `SetupHomeView+OptionChips.swift` (614→445); `PlayersRootView` → `PlayerDetailView.swift` (558→331); `X01MatchScreen` → `PlayerScoreCard.swift` (443→282). |
| B7 | **Duplicate turn-submit flows** | Done (branch `claude/b7-turn-submit-helper`). Shared scaffolding extracted to `Features/Play/MatchTurnSupport.swift`: `MatchTurnSubmitter` runs engine-submit → persist → save → log and returns an `Outcome`; each view model maps the outcome to its own state (bust vs. closure, caller tokens, completion). Pure helpers (`matchSummary`, `matchProgressMetadata`, `appErrorMetadata`, `errorMessageKey`) moved to the `MatchTurnSupport` namespace. Removed ~180 lines of duplication (X01 VM 599→509, Cricket VM 476→386). Behavior-preserving; verify with the unit suite. |
| B8 | **Monolithic repository** | Done. `SwiftDataRepositories.swift` (~798 lines) split into `SwiftDataPlayerRepository`, `SwiftDataMatchRepository`, `SwiftDataStatsRepository`, `SwiftDataSettingsRepository`, and a shared `SwiftDataRepositorySupport.swift` (mappers + `dataCall`). |
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
| 2026-06-03 | Refinement pass: added `CONTRIBUTING.md` (codified house style); removed a force-unwrap in `SettingsViewModel`; named the Cricket closure-transition delay in `BotTurnPacing`; split `SetupHomeView` option chips into an extension file; slimmed the README documentation map and fixed its broken banner image; removed the `darkmodelightmode.md` redirect stub. |
| 2026-06-03 | Decomposition pass: split `PlayersRootView` (→ `PlayerDetailView.swift`) and `X01MatchScreen` (→ `PlayerScoreCard.swift`); split the monolithic `SwiftDataRepositories.swift` into per-model repository files plus `SwiftDataRepositorySupport.swift` (B4, B8 done). B7 (shared turn-submit helper) left open pending a green test run. |
| 2026-06-03 | B7 done on `claude/b7-turn-submit-helper`: extracted `MatchTurnSubmitter` + `MatchTurnSupport` and de-duplicated the X01 / Cricket turn-submit flows (~180 lines removed). Behavior-preserving refactor; pending verification against the unit suite. |
