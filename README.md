# Dart Buddy

![App Icon Concept](assets/app-icons/appstore-icon-concept-4.png)

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

Run tests: **Product → Test** (`⌘U`), or:

```bash
xcodebuild test -scheme DartsScoreboard \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

> `DartsScoreboard.xcodeproj` is generated locally and not committed. Regenerate after pulling `project.yml` changes.

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
| `Tests/` | Unit and integration tests by phase |
| `specs/` | Product and system specifications |
| `roadmap/` | Phase delivery plan and release artifacts |
| `accessibility/` | WCAG 2.1 AA tracker and manual verification |

## App flow

1. `App/DartsScoreboardApp.swift` bootstraps dependencies.
2. `App/MainTabView.swift` presents Play, Players, Statistics, History, and Settings tabs.
3. Feature root views own their view models and navigation.

## Documentation map

Use **one primary doc per concern**. Link instead of copying checklists or backlogs.

| Concern | Authoritative | Do not duplicate in |
|---------|---------------|---------------------|
| Active release work | [`todo.md`](todo.md) | README, roadmap phase files |
| Product/system requirements | [`specs/SpecGovernance.md`](specs/SpecGovernance.md) → individual specs | README feature lists, `todo.md` completed items |
| Spec index | [`specs/README.md`](specs/README.md) | README |
| Phase delivery history | [`roadmap/README.md`](roadmap/README.md) | `todo.md` (roadmap is historical; todo is current) |
| Pre-coding agent brief | [`roadmap/AGENT-KICKOFF-BRIEF.md`](roadmap/AGENT-KICKOFF-BRIEF.md) | — |
| Accessibility requirements | [`specs/AccessibilitySpec.md`](specs/AccessibilitySpec.md) | WCAG screen files (link only) |
| Accessibility status roll-up | [`accessibility/wcag-2.1-aa/SUMMARY.md`](accessibility/wcag-2.1-aa/SUMMARY.md) | `todo.md`, README |
| Accessibility manual checks | [`accessibility/Manual_todo.md`](accessibility/Manual_todo.md) | `SUMMARY.md` evidence detail |
| Accessibility engineering plan | [`accessibility/accessibility_todo.md`](accessibility/accessibility_todo.md) | `Manual_todo.md` (manual vs engineering) |
| Fast QA gate | [`specs/ReleaseGateChecklist.md`](specs/ReleaseGateChecklist.md) | `SmokeTestChecklist.md` |
| Full smoke test | [`specs/SmokeTestChecklist.md`](specs/SmokeTestChecklist.md) | `ReleaseGateChecklist.md` |
| RC sign-off evidence | [`roadmap/release/QA-Signoff-RC1.md`](roadmap/release/QA-Signoff-RC1.md) | `todo.md` (todo links here; matrix lives here) |
| PR smoke evidence template | [`specs/SmokeTestEvidenceTemplate.md`](specs/SmokeTestEvidenceTemplate.md) | sign-off doc |
| Game Center (post-1.0) | [`achievements.md`](achievements.md) | `todo.md` (todo links; assessment detail here) |
| Post-1.0 features | [`todo.md`](todo.md) § Post-1.0 + feature specs | README (removed) |

### Duplication audit (2026-06)

Changes applied in this pass:

- **README** — Dropped near/mid/long-term roadmap (duplicated `todo.md` and future specs). Added doc-role table above.
- **`specs/README.md`** — Removed stale “Next Optional Specs” entries for docs that already exist.
- **Accessibility cross-refs** — Fixed links that pointed at a removed `todo.md` section.
- **`specs/SpecGovernance.md`** — Added repo-level doc ownership alongside existing spec-to-spec rules.

When adding documentation, extend the table above rather than restating content in multiple places.
