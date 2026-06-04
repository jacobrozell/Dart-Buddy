# App Shell Specification

## 1. Purpose
Define root app composition: launch behavior, tab structure, routing entry points, and app-wide environment setup.

---

## 2. Root Structure
- `DartBuddyApp` initializes dependency container and model container.
- Root view is `MainTabView`.
- Tabs (order in `MainTabView`):
  - `Play`
  - `Players`
  - `Statistics`
  - `History`
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
- Migration failure routes to recovery screen — see [`MigrationRecoverySpec.md`](MigrationRecoverySpec.md):
  - Retry
  - Export diagnostics
  - Reset local data (last resort)
- App never silently wipes data.

---

## 6. App Store Update Prompt
When a **newer App Store version** is available than the installed build, `MainTabView` may show a single system alert after the tab shell loads.

### Behavior
- **Trigger:** iTunes Lookup API (`bundleId=com.jacobrozell.DartBuddy`) compares store `version` to `CFBundleShortVersionString`.
- **Presentation:** Non-blocking `.alert` with **Update** and **Not Now** (`app.update.*` strings in all shipped locales).
- **Update:** Opens App Store via lookup `trackViewUrl`, or fallback `AppLinks.appStore` (App Store Connect app ID `6775713346`).
- **Not Now:** Persists dismissed store version in `UserDefaults` (`app_store_update_dismissed_version`); no re-prompt until a newer store version appears.
- **Failure / no network:** Silent — app continues normally.

### Disabled when
- Debug builds
- UI tests (`-ui_test_reset`)
- Store version ≤ installed version
- User dismissed the current store version

### Implementation
- `Support/AppStore/AppStoreUpdateChecker.swift`
- `Support/AppStore/AppVersionComparator.swift`
- Unit tests: `Tests/Unit/AppStoreUpdateCheckerTests.swift`

Store listing metadata and app ID: [`AppStoreConnectSpec.md`](AppStoreConnectSpec.md) §5.

---

## 7. Future Improvements
- Deep links into active match/history detail
- Background restoration hints
- In-app diagnostics panel for beta builds
