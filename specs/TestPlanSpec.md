# Test Plan Specification

## 1. Purpose
Define test strategy, ownership, and quality gates for MVP release confidence.

Test-first policy for this project:
- Core logic in every production file should be covered by tests as it is introduced.
- Unit/integration coverage is mandatory in MVP delivery scope.
- Unit/integration + accessibility run in CI (`DartBuddyCI`); UI smoke runs locally or in pre-release QA.

---

## 2. Test Layers

## Unit Tests (`Tests/Unit/`)
- Domain engines (`X01Engine`, `CricketEngine`, `StatsService`)
- Validation utilities
- Repository mapping/parsing logic
- View models and long-run simulations

## Accessibility Tests (`Tests/Accessibility/`)
- WCAG contrast ratios for design tokens and gameplay chrome
- Accessibility label contracts for core controls

## Integration Tests
- End-to-end feature flows with persistence:
  - setup -> play -> complete -> history
  - app relaunch -> resume match
  - archive player -> setup/history behavior

## UI Tests (`Tests/UI/`)

UI tests are split into **seven Xcode targets** (shared helpers in `Tests/UI/Support/`) so suites can run in parallel locally without multi-hour monolithic runs. See [`docs/release/branch-strategy.md`](../docs/release/branch-strategy.md).

| Scheme | Target | Classes | When to run |
|--------|--------|---------|-------------|
| `DartBuddyUISmoke` | `DartBuddyUISmokeUITests` | `MatchSetupUITests`, `ModesAndActivityUITests`, `MatchChromeUITests` | Pre-release / local |
| `DartBuddyUIGameplay` | `DartBuddyUIGameplayUITests` | `X01MatchUITests`, `CricketMatchUITests` | Pre-release / local |
| `DartBuddyUIAccessibility` | `DartBuddyUIAccessibilityUITests` | `WCAGAccessibilityUITests` (~48 tests) | Pre-release / local |
| `DartBuddyUILocalization` | `DartBuddyUILocalizationUITests` | `FrenchLocalizationSmokeUITests`, `GermanLocalizationSmokeUITests`, `SpanishLocalizationSmokeUITests`, `DutchLocalizationSmokeUITests`, `ChineseLocalizationSmokeUITests`, `ItalianLocalizationSmokeUITests` | Pre-release / local |
| `DartBuddyUILandscape` | `DartBuddyUILandscapeUITests` | `RegressionUITests` (landscape + bot regressions; **iPhone 17 Pro Max**) | Pre-release / local |
| `DartBuddyUIChrome` | `DartBuddyUIChromeUITests` | `SettingsUITests`, `OnboardingUITests`, `PlayerDetailUITests`, `BotDetailUITests`, `HistoryDetailUITests` | Pre-release / local |
| `DartBuddyUILean` | `DartBuddyUILeanUITests` | `Smart1_2SmokeUITests` (1.2) · `Lean1_0SmokeUITests` (1.0/1.1) | `release/*` branches (local) |

`DartBuddyUI` scheme runs all targets **except** `DartBuddyUILean` (full local UI pass). `DartBuddy` scheme runs unit + all UI targets for a complete local run.

Other UI coverage:
- Marketing screenshot harness (`-snapshot_*`, `-seed_demo` launch args)
- Localization uses `AppleLanguages` / `AppleLocale` via `DartBuddyUITestCase.launchApp(localeLanguage:localeIdentifier:)`

UI test execution policy:
- **PR / `dev`:** `DartBuddyCI` (unit + `Tests/Accessibility/` only).
- **Pre-release / local:** run `DartBuddyUI` or individual `DartBuddyUI*` schemes; use iPhone 17 Pro Max for landscape suite.
- **Release branches:** run `DartBuddyUILean` locally for `ProductSurface` regressions.
- Prioritize robust unit + integration coverage first; UI suites stay thin (observable UI state, not game rules).

---

## 3. Quality Gates
- All domain unit tests pass
- No migration invariant failures
- No crash on active-match resume path
- Core integration suites pass for match lifecycle, persistence, and player/history integrity
- New/changed files include tests for their core functions before merge

---

## 4. Regression Matrix (MVP)
- X01 single-out checkout
- X01 double-out checkout
- X01 bust near finish
- Cricket closure and overflow scoring (Normal and Cut Throat)
- Cut Throat Cricket + preset bot match (`CricketMatchUITests`)
- Undo turn on both modes
- Player archive/delete guard behavior
- History rendering after player edits
- Settings defaults applied to setup
- Training Partner: eligibility UI + add to setup (`PlayerDetailUITests`, setup helpers)
- Quick add player from empty roster → auto-selected in setup
- Statistics partial-match banner when active match matches filters
- Migration recovery: retry / export / reset (manual RC — [`MigrationRecoverySpec.md`](MigrationRecoverySpec.md))
- Localization: `LocalizationParityTests` + `de`/`es`/`nl`/`fr`/`zh-Hans`/`it` smoke UI tests (`DartBuddyUILocalization` scheme)

---

## 5. CI Recommendations
- Run unit + accessibility on PR via `DartBuddyCI` scheme (see `.github/workflows/ci.yml`)
- Run `DartBuddyUI` (or per-suite `DartBuddyUI*` schemes) locally before release
- Run `DartBuddyUILean` on `release/*` branches before shipping
- `DartBuddyPerformanceTests` (long-run bot simulations) is excluded from CI schemes; run locally
- Track coverage trend for domain and repository layers

---

## 6. Starter Tag Matrix (Swift Testing)
Use canonical tags from `specs/SwiftTestingTagsSpec.md`.

- `X01Engine` suite:
  - `unit`, `x01`, `critical`, `offline`, `regression`
- `CricketEngine` suite:
  - `unit`, `cricket`, `critical`, `offline`, `regression`
- `MatchLifecycleService` suite:
  - `unit`, `match`, `critical`, `regression`
- `StatsService` suite:
  - `unit`, `stats`, `regression`, `offline`
- `PlayerRepository` suite:
  - `integration`, `player`, `swiftdata`, `regression`
- `MatchRepository` suite:
  - `integration`, `match`, `swiftdata`, `critical`, `regression`
- `HistoryFeature` integration suite:
  - `integration`, `history`, `swiftdata`, `regression`
- `SettingsRepository` suite:
  - `integration`, `settings`, `swiftdata`, `regression`
- `Migration` suite:
  - `migration`, `swiftdata`, `critical`, `regression`
- `Navigation` smoke suite:
  - `integration`, `navigation`, `smoke`
- `ScoringInput` suite:
  - `unit`, `scoringInput`, `critical`
- `Accessibility` smoke suite (`WCAGAccessibilityUITests`, `WCAGAccessibilityLabelTests`):
  - `ui`, `accessibility`, `smoke`
- `LocalizationParityTests` (`Tests/Unit/`):
  - `unit`, `localization`, `critical`
- `GermanLocalizationSmokeUITests` / `SpanishLocalizationSmokeUITests` / `DutchLocalizationSmokeUITests` / `FrenchLocalizationSmokeUITests` / `ChineseLocalizationSmokeUITests` / `ItalianLocalizationSmokeUITests`:
  - `ui`, `localization`, `smoke`
- `Lean1_0SmokeUITests` / `Smart1_2SmokeUITests`:
  - `ui`, `smoke`, `releaseGate`

---

## 7. Release Readiness Checklist
- Manual exploratory pass on iPhone target device
- WCAG 2.1 AA accessibility pass on core flows
- Dark mode + Dynamic Type validation
- Landscape orientation validation on core flows
- Persistence migration smoke test from previous build
- App reset flow verified
