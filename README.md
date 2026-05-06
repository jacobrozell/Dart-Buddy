# Darts Scoreboard App

![App Icon Concept](assets/app-icons/appstore-icon-concept-4.png)

## What This App Does

Darts Scoreboard is an iOS SwiftUI app for running and tracking darts matches.

## Current Functions

- Play a match of darts in `X01` or `Cricket`
- Set up a match with player selection and mode-specific options
- Enter turn scores with guided scoring input and undo support
- Resume an active match and view a match summary when complete
- Manage players (create, edit, archive, delete with safeguards)
- Browse match history with mode/date filtering
- Configure settings for appearance, default game options, haptics, and sound

## Future Potential Improvements

### Near-term

- Match export/sharing (CSV, PDF, or image summary)
- Advanced player stats and trend dashboards
- Expanded game modes and richer match setup options

### Mid-term

- Tournament and league tracking workflows
- Optional user accounts and multiplayer player profiles
- Cloud backup/sync across devices

### Long-term

- Apple Watch companion scoring controls
- Home/Lock Screen widgets and Live Activities for quick score updates
- Cross-platform companion experiences (iPad/macOS/web)

## Key Paths and Responsibilities

- `App/` - app entry, bootstrap, dependency wiring, tab shell, navigation routes
- `Features/Play/` - match setup, scoring input, live X01/Cricket gameplay, summary flow
- `Features/History/` - match history list, filtering, and detail screens
- `Features/Players/` - player list, details, and edit/archive/delete actions
- `Features/Settings/` - app settings, defaults, reset flow
- `Data/` - repository protocols and SwiftData-backed repository implementations
- `Domain/` - domain entities, rules, and core business logic
- `Persistence/` - local storage setup and persistence concerns
- `DesignSystem/` - shared theme tokens, spacing, color roles, and reusable UI styling
- `assets/app-icons/` - app icon concepts and variants
- `Tests/` - unit and feature-level test coverage

## Main App Flow

1. `App/DartsScoreboardApp.swift` bootstraps dependencies.
2. `App/MainTabView.swift` presents `Play`, `History`, `Players`, `Settings`.
3. Each feature root view initializes its view model(s) and coordinates navigation + async tasks.

## QA and Smoke Testing

- Full manual smoke pass: `specs/SmokeTestChecklist.md`
- Fast pre-release gate (5-10 min): `specs/ReleaseGateChecklist.md`
- PR/CI evidence template: `specs/SmokeTestEvidenceTemplate.md`

