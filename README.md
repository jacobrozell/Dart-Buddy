# Dart Buddy

<img src="Media.xcassets/AppIcon.appiconset/AppIcon.png" alt="Dart Buddy app icon" width="120" />

**Dart Buddy** is a local-first iOS scorekeeper for X01 and Cricket darts. The Xcode target and Swift module are named **DartsScoreboard** (`import DartsScoreboard`).

Product behavior and UX contracts live under [`specs/`](specs/README.md). This file is the repo entry point — not a second spec.

## Status (1.0 RC)

- **Product:** MVP scope complete — play, players, history, statistics, settings.
- **Remaining for App Store:** QA sign-off, accessibility evidence, migration recovery smoke, listing assets — tracked in [`todo.md`](todo.md).

## Getting started

Requirements: Xcode 16+, iOS 17+, [XcodeGen](https://github.com/yonaskolb/XcodeGen) 2.44+.

```bash
brew install xcodegen   # if needed
xcodegen generate
open DartsScoreboard.xcodeproj
```

Copy `GoogleService-Info.plist.example` to `GoogleService-Info.plist` and replace placeholders with values from the [Firebase Console](https://console.firebase.google.com/) (Project settings → Your apps → iOS).

**Analytics (1.0):** Release builds with a real `GoogleService-Info.plist` send a small allowlist of product-health events (`app_open`, `match_started`, `match_completed`, `turn_submitted`, `undo_used`, etc.) via the existing `AppLogger` → Firebase Analytics sink. Debug builds stay off unless you add the launch argument `-firebase_analytics_debug`. UI tests pass `-disable_firebase_analytics`.

**Crashlytics (1.0):** Release builds with a real plist also enable Firebase Crashlytics (native crashes + allowlisted non-fatal `error`/`fault` logger events). A **Firebase Crashlytics** run script uploads dSYMs on **Release** archives only (skipped for placeholder plist / CI). Debug stays off unless `-firebase_analytics_debug` (shared switch with analytics). Disable telemetry for local runs with `-disable_firebase_analytics` or UI tests with `-ui_test_reset`. To verify a test crash in Debug: add launch argument `-crashlytics_test_crash` (fatal; sends on next launch).

Run tests: **Product → Test** (`⌘U`), or:

```bash
xcodebuild test -scheme DartsScoreboard \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

> `DartsScoreboard.xcodeproj` is generated locally and not committed. Regenerate after pulling `project.yml` changes.

### CI

GitHub Actions (`.github/workflows/ci.yml`) runs on every push and pull request to `master`/`main`: installs XcodeGen, regenerates the project, then `xcodebuild test` on the `DartsScoreboard` scheme (unit + UI tests) using an available iPhone simulator on the macOS runner.

## What the app does

High-level summary only — authoritative rules are in feature specs:

- X01 and Cricket matches with guided scoring, undo, and bot opponents
- Match setup with roster selection, turn order, and mode-specific options
- Resume in-progress matches; match summary on completion
- Player management (create, edit, archive, delete)
- Match history with filtering and detail views; dedicated statistics tab
- Settings: appearance, default game options, haptics, sound, bot pacing

## Project layout

| Path | Role |
|------|------|
| `App/` | Entry point, dependency wiring, tab shell, navigation |
| `Features/` | Play, History, Players, Statistics, Settings screens |
| `Domain/` | Rules engines, entities, business logic |
| `Data/` | Repository protocols and SwiftData implementations |
| `Persistence/` | Schema, migrations, container factory |
| `DesignSystem/` | Tokens, shared components, gameplay layout |
| `Support/` | Localization, logging, preferences, utilities |
| `Tests/` | `Unit/`, `Accessibility/`, and `UI/` test sources (three Xcode targets) |
| `specs/` | Product and system specifications |
| `roadmap/` | Phase delivery plan and release artifacts |
| `accessibility/` | WCAG 2.1 AA tracker and manual verification |

## App flow

1. `App/DartsScoreboardApp.swift` bootstraps dependencies.
2. `App/MainTabView.swift` presents Play, Players, Statistics, History, and Settings tabs.
3. Feature root views own their view models and navigation.

## Documentation map

Each concern has one authoritative doc. Link to it rather than restating its content elsewhere.

| Concern | Start here |
|---------|------------|
| Product & system requirements | [`specs/README.md`](specs/README.md) (governed by [`SpecGovernance.md`](specs/SpecGovernance.md)) |
| Active release work | [`todo.md`](todo.md) |
| Device + App Store runbook | [`release_checklist.md`](release_checklist.md) |
| Contributing & code style | [`CONTRIBUTING.md`](CONTRIBUTING.md) |
| iOS code audit | [`docs/ios-code-audit.md`](docs/ios-code-audit.md) |
| Design system tokens | [`DesignSystem/README.md`](DesignSystem/README.md) |
| Accessibility (requirements / status / manual) | [`specs/AccessibilitySpec.md`](specs/AccessibilitySpec.md) · [`accessibility/wcag-2.1-aa/SUMMARY.md`](accessibility/wcag-2.1-aa/SUMMARY.md) · [`accessibility/Manual_todo.md`](accessibility/Manual_todo.md) |
| Phase delivery history | [`roadmap/README.md`](roadmap/README.md) |
| Post-1.0 ideas | [`FutureIdeas/`](FutureIdeas/) |
