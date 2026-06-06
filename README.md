# Dart Buddy

<img src="Resources/Media.xcassets/AppIcon.appiconset/AppIcon.png" alt="Dart Buddy app icon" width="120" />

**Dart Buddy** is a local-first iOS scorekeeper for X01 and Cricket darts. The Xcode target and Swift module are named **DartBuddy** (`import DartBuddy`).

Product behavior and UX contracts live under [`specs/`](specs/README.md). A cross-cutting **feature inventory** (shipped vs planned) lives at [`docs/feature-inventory.md`](docs/feature-inventory.md). This file is the repo entry point — not a second spec.

## Status (1.0 RC — lean core)

- **Product:** Lean 1.0 — X01 + Cricket (Normal + Cut Throat), preset bots, Play · Players · Activity · Settings. Party modes, Modes tab, Training/Custom bots, and export are **hidden** until 1.1+ ([`docs/release/lean-1.0-implementation-plan.md`](docs/release/lean-1.0-implementation-plan.md)).
- **Localization:** **English only** in the 1.0 app bundle (`de` / `es` / `nl` files remain in repo for a future release).
- **Telemetry:** Firebase Analytics + Crashlytics in Release builds with a real plist.
- **Remaining for App Store:** Device QA on lean matrix, accessibility evidence, migration recovery smoke, English listing assets — [`docs/release/todo.md`](docs/release/todo.md).

## Getting started

Requirements: Xcode 16+, iOS 17+, [XcodeGen](https://github.com/yonaskolb/XcodeGen) 2.44+.

```bash
brew install xcodegen   # if needed
xcodegen generate
open DartBuddy.xcodeproj
```

Copy `Resources/GoogleService-Info.plist.example` to `Resources/GoogleService-Info.plist` and replace placeholders with values from the [Firebase Console](https://console.firebase.google.com/) (Project settings → Your apps → iOS). The example uses bundle ID `com.jacobrozell.DartBuddy` — add or update the iOS app in Firebase to match before shipping.

> **App Store continuity:** Changing the bundle ID from `com.jacobrozell.DartsScoreboard` means a new App Store listing (not an in-place update). To keep the existing listing, set `PRODUCT_BUNDLE_IDENTIFIER` back to the old value in `project.yml` and regenerate.

**Analytics (1.0):** Release builds with a real `GoogleService-Info.plist` send a small allowlist of product-health events (`app_open`, `match_started`, `match_completed`, `turn_submitted`, `undo_used`, etc.) via the existing `AppLogger` → Firebase Analytics sink. Debug builds stay off unless you add the launch argument `-firebase_analytics_debug`. UI tests pass `-disable_firebase_analytics`.

**Crashlytics (1.0):** Release builds with a real plist also enable Firebase Crashlytics (native crashes + allowlisted non-fatal `error`/`fault` logger events). A **Firebase Crashlytics** run script uploads dSYMs on **Release** archives only (skipped for placeholder plist / CI). Debug stays off unless `-firebase_analytics_debug` (shared switch with analytics). Disable telemetry for local runs with `-disable_firebase_analytics` or UI tests with `-ui_test_reset`. To verify a test crash in Debug: add launch argument `-crashlytics_test_crash` (fatal; sends on next launch).

Run tests: **Product → Test** (`⌘U`), or:

```bash
xcodebuild test -scheme DartBuddy \
  -destination 'platform=iOS Simulator,name=iPhone 17'
```

> `DartBuddy.xcodeproj` is generated locally and not committed. Regenerate after pulling `project.yml` changes.

### CI

GitHub Actions (`.github/workflows/ci.yml`) runs on every push and pull request to `master`/`main`: Xcode 26.2, XcodeGen, `build-for-testing` then `test-without-building` on the `DartBuddyCI` scheme (unit + accessibility only) on an iPhone 17 simulator (`macos-26` runner). Full UI smoke runs nightly via `.github/workflows/nightly-ui.yml` (`DartBuddy` scheme) and locally with `xcodebuild test -scheme DartBuddy`.

**Release builds** use Xcode Cloud (archive → TestFlight internal), triggered on demand via Slack `/dart-buddy release` or `.github/workflows/trigger-testflight.yml` — not on every push. Setup: [`docs/release/xcode-cloud.md`](docs/release/xcode-cloud.md).

## What the app does

High-level summary only — authoritative rules are in feature specs:

- **X01** and **Cricket** (Normal + Cut Throat) with guided scoring, undo, and **preset difficulty** bots
- Match setup with roster selection, turn order, and mode-specific options (X01/Cricket chips on Play home)
- Resume in-progress matches; match summary on completion
- Player management (create, edit, archive, delete)
- **Activity** tab: match history + statistics with shared filters
- Settings: appearance, default game options, haptics, sound, bot pacing
- **English UI** in 1.0 (additional locales ship in a later release)

Post-1.0 (implemented but hidden in lean 1.0): Modes catalog tab, party modes, Training Partner / custom bots, player export — see [`docs/feature-inventory.md`](docs/feature-inventory.md).

## Project layout

| Path | Role |
|------|------|
| `App/` | Entry point, dependency wiring, tab shell, navigation |
| `Features/` | Play, Activity, Players, Settings screens |
| `Domain/` | Rules engines, entities, business logic |
| `Data/` | Repository protocols and SwiftData implementations |
| `Persistence/` | Schema, migrations, container factory |
| `DesignSystem/` | Tokens, shared components, gameplay layout |
| `Resources/` | Asset catalog, `en.lproj/Localizable.strings` (1.0 bundle); `de`/`es`/`nl` in repo for future releases, Firebase plist template |
| `Scripts/` | CI helpers, locale generator (`generate_localizable.py`) |
| `Support/` | Localization, logging, preferences, utilities |
| `Tests/` | `Unit/`, `Accessibility/`, and `UI/` test sources (three Xcode targets) |
| `docs/release/` | Active backlog (`todo.md`) and App Store runbook (`release_checklist.md`) |
| `specs/` | Product and system specifications |
| `roadmap/` | Phase delivery plan and release artifacts |
| `accessibility/` | WCAG 2.1 AA tracker and manual verification |

## App flow

1. `App/DartBuddyApp.swift` bootstraps dependencies.
2. `App/MainTabView.swift` presents Play, Players, Activity, and Settings tabs (lean 1.0).
3. Feature root views own their view models and navigation.

## Documentation map

Each concern has one authoritative doc. Link to it rather than restating its content elsewhere.

| Concern | Start here |
|---------|------------|
| Product & system requirements | [`specs/README.md`](specs/README.md) (governed by [`SpecGovernance.md`](specs/SpecGovernance.md) — coverage checklist §5, PR rules §4.1) |
| Localization | [`specs/LocalizationSpec.md`](specs/LocalizationSpec.md) |
| Feature specs (full index) | [`specs/README.md`](specs/README.md) § Feature Specs |
| Active release work | [`docs/release/todo.md`](docs/release/todo.md) |
| Lean 1.0 scope & tasks | [`docs/release/lean-1.0-implementation-plan.md`](docs/release/lean-1.0-implementation-plan.md) |
| Device + App Store runbook | [`docs/release/release_checklist.md`](docs/release/release_checklist.md) |
| Contributing & code style | [`CONTRIBUTING.md`](CONTRIBUTING.md) |
| iOS code audit | [`docs/ios-code-audit.md`](docs/ios-code-audit.md) |
| Design system tokens | [`DesignSystem/README.md`](DesignSystem/README.md) |
| UI/UX design review | [`docs/ux-design-review.md`](docs/ux-design-review.md) |
| Accessibility (requirements / status / manual) | [`specs/AccessibilitySpec.md`](specs/AccessibilitySpec.md) · [`accessibility/wcag-2.1-aa/SUMMARY.md`](accessibility/wcag-2.1-aa/SUMMARY.md) · [`accessibility/Manual_todo.md`](accessibility/Manual_todo.md) |
| Phase delivery history | [`roadmap/README.md`](roadmap/README.md) |
| Post-1.0 ideas | [`FutureIdeas/`](FutureIdeas/) |
