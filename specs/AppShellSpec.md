# App Shell Specification

## 1. Purpose
Define root app composition: launch behavior, tab structure, routing entry points, and app-wide environment setup.

---

## 2. Root Structure
- `DartsScoreboardApp` initializes dependency container and model container.
- Root view is `MainTabView`.
- Tabs:
  - `Play`
  - `History`
  - `Players`
  - `Settings`

---

## 3. Launch Behavior
- Build persistence container with migration plan.
- Seed default settings if missing.
- Resolve theme/haptics/sound preferences.
- If one active in-progress match exists, Play tab shows resume card.

---

## 4. Global Environment
- Dependency injection via environment/container
- Shared services:
  - `PlayerRepository`
  - `MatchRepository`
  - `StatsRepository`
  - `SettingsRepository`
  - `HapticsService`
  - `AudioFeedbackService`

---

## 5. Global Error/Recovery
- Migration failure routes to recovery screen:
  - Retry
  - Export diagnostics
  - Reset local data (last resort)
- App never silently wipes data.

---

## 6. Future Improvements
- Deep links into active match/history detail
- Background restoration hints
- In-app diagnostics panel for beta builds
