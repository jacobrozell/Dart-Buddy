# App Shell Specification

## 1. Purpose
Define root app composition: launch behavior, tab structure, routing entry points, and app-wide environment setup.

---

## 2. Root Structure
- `DartBuddyApp` initializes dependency container and model container.
- Root view is `MainTabView`.
- Tabs (order in `MainTabView`):
  - `Play`
  - `Modes`
  - `Players`
  - `Activity` (History | Statistics segment)
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

## 6. First-Launch Onboarding

A branching **onboarding flow** on first launch asks whether the user knows how to play darts, then routes to either a curated preferences step or the Learn to play rules content.

### Flow

```text
Welcome → Experience question → Preferences (experienced) or Learn to play (beginner)
       → App tour → Support & feedback → Ready → Play tab
Welcome → Skip → Ready → Play tab
```

### Behavior
- **Trigger:** `UserDefaults` key `onboarding_completed` is unset and onboarding is enabled.
- **Presentation:** `fullScreenCover` on `MainTabView` after bootstrap (before the App Store update check).
- **Welcome:** One-screen 1.0 intro with **Skip** (escape hatch) and **Next**.
- **Experience question:** Two choice buttons — experienced path continues to preferences; beginner path continues to rules content (X01 + Cricket only via `ProductSurface`).
- **Preferences (experienced path):** Curated subset of Settings (appearance, gameplay defaults, X01 defaults, feedback toggles). Changes persist immediately via `SettingsViewModel`.
- **Learn to play (beginner path):** Reuses `GameRulesGuideContent` with onboarding **Continue** footer.
- **App tour:** Four cards for Play, Players, Activity, and Settings tabs plus a short roadmap note.
- **Support & feedback:** Links to hosted support FAQ, feedback mailto, and privacy policy (same destinations as Settings → Help & Feedback).
- **Ready:** Shared finale with **Start a Match** and a Settings replay hint.
- **Skip / Start a Match:** Sets `onboarding_completed`; first launch selects the Play tab. **Start a Match** also persists `onboarding_darts_experience` (`experienced` | `beginner`) when the user completed a branch. Skip from Welcome lands on Ready without persisting experience. First launch cannot be swipe-dismissed (must use Skip or Start a Match).
- **Replay:** Settings → About → **View onboarding** presents the same flow in `.replay` mode without changing completion state or saved experience.
- **Reset all data:** Clears `onboarding_completed` and `onboarding_darts_experience` with all other auxiliary `UserDefaults`; onboarding can present again immediately after reset (see `LocalAppStateReset`).

### Disabled when
- Launch argument `-skip_onboarding`
- UI tests (`-ui_test_reset`, same gate as App Store update checker)
- Opt in during UI tests with `-ui_test_onboarding` (still uses `-ui_test_reset` store reset)

### Implementation
- `Support/Onboarding/OnboardingStore.swift`
- `Features/Onboarding/OnboardingFlowView.swift` (+ step views)
- `Features/Play/Rules/GameRulesGuideContent.swift` (shared rules content)
- Unit tests: `Tests/Unit/OnboardingStoreTests.swift`

---

## 7. App Store Update Prompt
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

## 8. Navigation chrome (iOS 26 Liquid Glass)

- **Deployment target:** iOS 17+. On iOS 26+, system tab bars and `NavigationStack` toolbars use Liquid Glass automatically.
- **Policy:** `SystemNavigationPolicy` in DesignSystem — do not override nav/tab chrome with opaque `.toolbarBackground` on iOS 26+. Scoreboard tab content stays opaque (`brandScoreboardChrome`).
- **Accessibility:** Reduce Transparency uses system opaque fallbacks for glass chrome; content-layer contrast remains on `Brand` tokens. See `DesignSystem/README.md` § Navigation vs content layer.

---

## 9. Future Improvements
- ~~Deep links into active match/history detail~~ — **partial:** Play/tab/resume shipped ([`DeepLinkSpec.md`](DeepLinkSpec.md)); history/player paths planned
- App Intents (Siri/Shortcuts/Apple Intelligence) — **Phase 1 shipped:** Open Play + Resume ([`AppIntentsSpec.md`](AppIntentsSpec.md)); entities, query intents, indexing, on-screen context, widgets, and voice scoring planned (§4.5–4.9, §11, §13)
- Background restoration hints
- In-app diagnostics panel for beta builds
