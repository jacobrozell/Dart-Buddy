# Dart Buddy — Feature Inventory

Living register of every product feature: shipped, partial, and planned. Use this to answer “what exists?” and “what’s next?” without hunting through specs, code, and `FutureIdeas/`.

**Last reviewed:** 2026-06-06  
**App status:** 1.0 RC — MVP scope complete; App Store evidence + ops remain ([`release/todo.md`](release/todo.md))

---

## How to maintain

1. **When shipping a feature** — change its status here, update the linked spec, and (for game modes) promote the row in `Features/Modes/GameModeCatalog.swift`.
2. **When adding a planned feature** — add a row with status **Planned** and link the spec or `FutureIdeas/` brief.
3. **When something is behind a flag** — mark **Partial** and note the flag in the Notes column.
4. **Source of truth for mode list** — `GameModeCatalog.swift` (29 modes). This doc mirrors it.
5. Do **not** duplicate release QA checklists here; track blockers in [`release/todo.md`](release/todo.md).
6. **Release sequencing** — what ships in 1.0 vs 1.1+ lives in [`release/ongoing-release-plan.md`](release/ongoing-release-plan.md). **Lean 1.0 execution:** [`release/lean-1.0-implementation-plan.md`](release/lean-1.0-implementation-plan.md).

---

## Status legend

| Status | Meaning |
|--------|---------|
| **Shipped** | Built, reachable in a Release build (may still need QA evidence). |
| **Partial** | Exists but incomplete, gated, or missing polish/evidence. |
| **Planned** | Spec or catalog stub; no playable implementation. |
| **Assessed** | Research / brief only; no spec implementation yet. |

---

## Summary

| Area | Shipped | Partial | Planned / assessed |
|------|---------|---------|-------------------|
| Game modes (catalog) | 5 | 0 | 24 |
| App shell & navigation | 5 tabs | iPad two-pane IA | — |
| Localization | 4 locales | — | 3 items |
| Shortcuts & deep links | Deep links | App Intents (flagged off) | Widgets, query intents |
| CI / release | GitHub Actions, Xcode Cloud | Slack notify, perf tests | — |
| Players & bots | Full CRUD + 3 bot types | — | — |
| Stats & activity | History + statistics | Per-mode stats (5 of 29) | — |
| Settings & a11y | Core prefs + TTS caller | WCAG evidence, AXXXL layout | Talk mode |
| Firebase | Analytics + Crashlytics | — | Auth, Firestore, FCM |
| Platforms | iPhone, iPad universal | iPad layout polish | watchOS, macOS, visionOS |
| Post-1.0 product | — | — | Achievements, campaign, online, vision scoring, reminders |

**Targets today:** `DartBuddy` (iOS, iPhone + iPad), `DartBuddyTests`, `DartBuddyPerformanceTests`, `DartBuddyUITests` — no Widget, Watch, or macOS extensions (`project.yml`).

---

## Game modes

Catalog source: [`Features/Modes/GameModeCatalog.swift`](../Features/Modes/GameModeCatalog.swift) · UI: [`ModesRootView`](../Features/Modes/ModesRootView.swift) · Spec: [`specs/ModesTabSpec.md`](../specs/ModesTabSpec.md)

### Shipped (5)

| Mode | Section | Engine / UI | Spec |
|------|---------|-------------|------|
| X01 (301 / 501) | Standard | `X01Engine`, `Features/Play/X01/` | [`X01GameSpec.md`](../specs/X01GameSpec.md) |
| Cricket (Normal + Cut Throat) | Standard | `CricketEngine`, `Features/Play/Cricket/` | [`CricketSpec.md`](../specs/CricketSpec.md) |
| Baseball | Party | `BaseballEngine`, `Features/Play/Baseball/` | [`BaseballGameSpec.md`](../specs/BaseballGameSpec.md) |
| Killer | Party | `KillerEngine`, `Features/Play/Killer/` | [`KillerGameSpec.md`](../specs/KillerGameSpec.md) |
| Shanghai | Party | `ShanghaiEngine`, `Features/Play/Shanghai/` | — |

### Planned — catalog stubs (24)

Shown in Modes tab as “coming soon”; no `MatchType`, Start disabled.

| Mode | Section | UI template | R&D |
|------|---------|-------------|-----|
| American Cricket | Standard | Mark board | [`additional-game-modes.md`](../FutureIdeas/additional-game-modes.md) |
| Mickey Mouse | Party | Mark board | same |
| Mulligan | Party | Mark board | same |
| English Cricket | Party | Checkout score | same |
| Blind Killer | Party | Lives elimination | same |
| Knockout | Party | Checkout score | same |
| Sudden Death | Party | Checkout score | same |
| 51 By 5's | Party | Checkout score | same |
| Golf | Party | Inning points | [`party-practice-modes.md`](../FutureIdeas/party-practice-modes.md) |
| Football | Party | Phase race | same |
| Grand National | Party | Sequence progress | same |
| Hare and Hounds | Party | Sequence progress | same |
| Follow the Leader | Party | Lives elimination | same |
| Loop | Party | Lives elimination | same |
| Prisoner | Party | Board state | same |
| Scam | Party | Role split | same |
| Snooker | Party | Role split | same |
| Tic-Tac-Toe | Party | Board state | same |
| Around the Clock | Practice | Sequence progress | [`party-practice-modes.md`](../FutureIdeas/party-practice-modes.md) |
| 180 Around the Clock | Practice | Sequence progress | same |
| Chase the Dragon | Practice | Sequence progress | same |
| Nine Lives | Practice | Lives elimination | same |
| Bob's 27 | Practice | Solo challenge | same |
| Halve-It | Practice | Solo challenge | same |

### Game mode infrastructure

| Feature | Status | Notes | Reference |
|---------|--------|-------|-----------|
| Modes tab (browse, search, quick-start) | Shipped | Standard / Party / Practice sections; iPad 2-col grid | [`ModesTabSpec.md`](../specs/ModesTabSpec.md) |
| Game rules guide (in-app) | Shipped | Shipped modes only | `Features/Play/Rules/GameRulesGuideView.swift` |
| 8 gameplay UI templates | Partial | Enum defined; 5 modes mapped | [`full-game-catalog-ui.md`](full-game-catalog-ui.md) |
| Per-mode stat kinds (29 declared) | Partial | Data only for 5 shipped modes | `ModeStatKind` in `GameModeCatalog.swift` |
| Campaign mode | Assessed | Single-player ladder / bosses | [`campaign-mode.md`](../FutureIdeas/campaign-mode.md) |
| Online multiplayer | Planned | Firestore sync | [`OnlinePlaySpec.md`](../specs/OnlinePlaySpec.md) |
| Vision auto-scoring | Planned | Camera dart detection | [`AutoScoringVisionSpec.md`](../specs/AutoScoringVisionSpec.md) · flag `enableVisionAutoScoring` |

---

## App shell & navigation

| Feature | Status | Notes | Reference |
|---------|--------|-------|-----------|
| Tab bar: Play · Modes · Players · Activity · Settings | Shipped | History + Statistics merged into Activity | [`AppShellSpec.md`](../specs/AppShellSpec.md), `MainTabView.swift` |
| Activity segment picker (History / Statistics) | Shipped | Shared filters | `ActivityRootView.swift` |
| Play home (resume banner, recent games) | Shipped | | [`PlayHomeSpec.md`](../specs/PlayHomeSpec.md) |
| Match setup flow | Shipped | Roster, turn order, mode options | [`SetupFlowSpec.md`](../specs/SetupFlowSpec.md) |
| Quick-add player from setup | Shipped | | [`QuickAddPlayerSpec.md`](../specs/QuickAddPlayerSpec.md) |
| Match lifecycle (start / resume / abandon) | Shipped | SwiftData persistence | [`MatchSpec.md`](../specs/MatchSpec.md) |
| Match summary screen | Shipped | Post-match stats, undo last throw | [`MatchSummarySpec.md`](../specs/MatchSummarySpec.md) |
| Shared scoring input pad | Shipped | Undo, submit | [`ScoringInputSpec.md`](../specs/ScoringInputSpec.md) |
| Checkout suggester (X01) | Shipped | | `Domain/Engines/CheckoutSuggester.swift` |
| Onboarding (first launch + replay) | Shipped | Experience branching | `Features/Onboarding/` |
| Migration recovery UI | Shipped | Retry, export, reset on schema failure | [`MigrationRecoverySpec.md`](../specs/MigrationRecoverySpec.md) |
| App Store update checker | Shipped | Prompt when newer store version | `AppStoreUpdateChecker.swift` |
| iPad two-pane master-detail | Planned | Post-1.0 IA | [`ux-design-review.md`](ux-design-review.md) |
| External display / AirPlay | Planned | Post-1.0 | [`release/todo.md`](release/todo.md) |

---

## Localization

| Feature | Status | Notes | Reference |
|---------|--------|-------|-----------|
| English (`en`) | Shipped | Source locale | `Resources/en.lproj/Localizable.strings` |
| German (`de`) | Shipped | Wave 1 | `Resources/de.lproj/Localizable.strings` |
| Spanish (`es`) | Shipped | Wave 2 | `Resources/es.lproj/Localizable.strings` |
| Dutch (`nl`) | Shipped | Wave 3 | `Resources/nl.lproj/Localizable.strings` |
| `L10n` helper + namespaced keys | Shipped | No hardcoded UI strings policy | `Support/Localization/L10n.swift` |
| Mode catalog strings (all 29 modes) | Shipped | `modes.catalog.*` keys | [`LocalizationSpec.md`](../specs/LocalizationSpec.md) |
| Locale generator script | Shipped | Key parity helper | `Scripts/generate_localizable.py` |
| Localization parity unit tests | Shipped | en/de/es/nl | `Tests/Unit/LocalizationParityTests.swift` |
| Localized smoke UI tests | Shipped | de / es / nl tab smoke | `Tests/UI/*LocalizationSmokeUITests.swift` |
| In-app language picker | Planned | Settings locale override | [`LocalizationSpec.md`](../specs/LocalizationSpec.md) §6 |
| Pseudo-localization / RTL CI | Planned | Truncation stress, RTL readiness | [`LocalizationSpec.md`](../specs/LocalizationSpec.md) |
| App Store localized listings | Partial | Captures planned for de/es/nl | [`release/todo.md`](release/todo.md) |

---

## App Intents, Shortcuts & deep links

| Feature | Status | Notes | Reference |
|---------|--------|-------|-----------|
| Deep links (`dartbuddy://v1/...`) | Shipped | play, resume, tab routes | [`DeepLinkSpec.md`](../specs/DeepLinkSpec.md), `DartBuddyURL.swift` |
| Intent routing bridge | Shipped | Routes to `AppRouteRouter` | `IntentRoutingBridge.swift` |
| Open Play intent | Partial | Siri → Play tab | `OpenPlayIntent.swift` |
| Resume Active Match intent | Partial | Resume or “no active match” dialog | `ResumeActiveMatchIntent.swift` |
| Shortcuts provider | Partial | Returns `[]` when flag off | `DartBuddyShortcutsProvider.swift` |
| **`enableAppIntents` flag** | Shipped | **Default off**; `-enable_app_intents` to enable | [`FeatureFlagConfigSpec.md`](../specs/FeatureFlagConfigSpec.md) |
| Query intents (stats, player, match status) | Planned | Phase 2 | [`AppIntentsSpec.md`](../specs/AppIntentsSpec.md) §11 |
| Start Quick / Start Mode intents | Planned | Blocked on Deep Link Phase 2 | same |
| Home Screen widgets | Planned | Resume / status tap targets | [`AppIntentsSpec.md`](../specs/AppIntentsSpec.md) |
| Control Center control (iOS 18+) | Planned | One-tap Resume | `.cursor/plans/app_intents_brainstorm_174c8c15.plan.md` |
| Spotlight indexing | Planned | Tied to resume/status intents | same |

---

## CI, testing & release

| Feature | Status | Notes | Reference |
|---------|--------|-------|-----------|
| GitHub Actions CI (push / PR) | Shipped | XcodeGen, build-for-testing, `DartBuddyCI` | `.github/workflows/ci.yml` |
| Nightly UI tests | Shipped | Full `DartBuddy` scheme smoke | `.github/workflows/nightly-ui.yml` |
| Xcode Cloud → TestFlight | Shipped | Manual / API trigger only | [`release/xcode-cloud.md`](release/xcode-cloud.md) |
| Trigger TestFlight workflow | Shipped | GHA → App Store Connect API | `.github/workflows/trigger-testflight.yml` |
| XcodeGen project generation | Shipped | `.xcodeproj` not committed | `project.yml` |
| Firebase plist in CI | Shipped | Example in GHA; secret in Xcode Cloud | `ci_scripts/ci_post_clone.sh` |
| Slack `/dart-buddy release` | Partial | Cloudflare worker → GHA | [`workers/dart-buddy-slack/README.md`](../workers/dart-buddy-slack/README.md) |
| Slack CI pass/fail notifications | Partial | Composite action | `.github/actions/slack-ci-notify/` |
| Performance test target | Partial | Exists; not in `DartBuddyCI` scheme | `DartBuddyPerformanceTests` |
| WCAG accessibility UI tests (40) | Shipped | In CI | `Tests/UI/WCAGAccessibilityUITests.swift` |
| Snapshot tests | Planned | Post UI lock | [`release/todo.md`](release/todo.md) |
| Demo seed (`-seed_demo`) | Shipped | UI test fixtures | UI test launch args |
| Marketing screenshot pipelines | Shipped | iPhone + iPad capture scripts | `marketing-screenshots/`, `Scripts/` |
| Release checklist & runbooks | Shipped | QA, Connect, launch week | [`release/release_checklist.md`](release/release_checklist.md) |
| GitHub Pages (privacy / support) | Shipped | Hosted legal pages | `docs/privacy.html`, `docs/support.html` |

---

## Players, bots & profiles

| Feature | Status | Notes | Reference |
|---------|--------|-------|-----------|
| Player CRUD | Shipped | Create, edit, archive, delete with guards | [`PlayerSpec.md`](../specs/PlayerSpec.md) |
| Player detail + per-player stats | Shipped | | `PlayerDetailView.swift` |
| Avatar colors + symbols | Shipped | 16 colors / 18 symbols | `PlayerVisualStyle.swift` |
| Player export (DBPE bundle) | Shipped | Human player match history | `PlayerExportBundle.swift` |
| Preset difficulty bots | Shipped | Very Easy → Pro via `DartBotEngine` | [`BotOpponentSpec.md`](../specs/BotOpponentSpec.md) |
| Training Partner bots | Shipped | Progress-gated custom opponents | [`TrainingBotSpec.md`](../specs/TrainingBotSpec.md) |
| Custom bots (user metrics) | Shipped | Skill profile interpolation | `CustomBotMetrics.swift` |
| Game Center achievements (~62 catalog) | Assessed | No GameKit code | [`achievements.md`](../FutureIdeas/achievements.md) |
| Leaderboards | Assessed | Separate from achievements MVP | same |

---

## History, statistics & activity

| Feature | Status | Notes | Reference |
|---------|--------|-------|-----------|
| Match history list + detail | Shipped | Filters, timeline, mode badges | [`HistorySpec.md`](../specs/HistorySpec.md) |
| Baseball line score in history | Shipped | | `BaseballLineScoreView.swift` |
| Statistics aggregates + charts | Shipped | Per-player breakdowns, filters | [`StatsSpec.md`](../specs/StatsSpec.md) |
| Statistics tab UI | Shipped | Now Activity segment | [`StatisticsTabSpec.md`](../specs/StatisticsTabSpec.md) |
| Per-mode statistics (29 kinds declared) | Partial | Live data for 5 shipped modes only | `ModeStatKind` in catalog |
| CSV export on recovery | Planned | Recovery Required affordance | [`backlog.md`](../FutureIdeas/backlog.md) |

---

## Settings, themes & feedback

| Feature | Status | Notes | Reference |
|---------|--------|-------|-----------|
| Appearance (system / light / dark) | Shipped | Brand scoreboard chrome | [`SettingsSpec.md`](../specs/SettingsSpec.md) |
| Default starting mode (X01 / Cricket) | Shipped | Until Modes pick overrides | `SettingsRootView.swift` |
| Match defaults (legs, sets, format) | Shipped | Persisted gameplay defaults | same |
| X01 defaults (score, check-in/out) | Shipped | 301/501, checkout modes | same |
| Haptics + sound | Shipped | During-play feedback | same |
| Turn total caller (TTS) | Shipped | Speaks visit total after submit | `FeedbackServices.swift` |
| Bot pacing (stagger + dart haptics) | Shipped | Bot opponent UX tuning | same |
| Reset all data | Shipped | Destructive local wipe | same |
| Replay onboarding | Shipped | From Settings | same |
| Buy Developer a Coffee link | Shipped | External link | `AppLinks.swift` |
| Brand design system | Shipped | Tokens, scoreboard chrome | [`DesignSystemSpec.md`](../specs/DesignSystemSpec.md) |
| Per-mode accent identity | Shipped | Badge + color per catalog id | `GameModeAccent.swift` |
| Full voice caller (“180!”) | Planned | Beyond turn-total TTS | [`talk-mode.md`](../FutureIdeas/talk-mode.md) |

---

## Accessibility

| Feature | Status | Notes | Reference |
|---------|--------|-------|-----------|
| WCAG 2.1 AA target | Partial | 40/40 automated tests pass; manual evidence pending | [`AccessibilitySpec.md`](../specs/AccessibilitySpec.md) |
| VoiceOver spot checks | Partial | Evidence in `accessibility/wcag-2.1-aa/evidence/` | [`accessibility_todo.md`](../accessibility/accessibility_todo.md) |
| Dynamic Type at AXXXL | Partial | Manual evidence + hardcoded sizes remain | [`release/todo.md`](release/todo.md) |
| Dedicated a11y gameplay layout at AXXXL | Planned | Score + pad visible together | [`backlog.md`](../FutureIdeas/backlog.md) |
| Talk mode (voice input at oche) | Assessed | Hands-free dart parsing | [`talk-mode.md`](../FutureIdeas/talk-mode.md) |
| iPad layout polish | Partial | Max-width column, side-by-side match | `GameplayLayout.swift` |

---

## Firebase & backend

| Feature | Status | Notes | Reference |
|---------|--------|-------|-----------|
| Firebase Core bootstrap | Shipped | Release-only with real plist | `FirebaseBootstrap.swift` |
| Firebase Analytics (allowlisted events) | Shipped | `AppLogger` → Analytics sink | [`FirebaseBackendAnalyticsSpec.md`](../specs/FirebaseBackendAnalyticsSpec.md) |
| Firebase Crashlytics | Shipped | Crashes + allowlisted non-fatals; dSYM upload | `FirebaseCrashlyticsLogSink.swift` |
| Intent + deep-link analytics events | Shipped | `intent_*`, `deep_link_*` allowlisted | same |
| Analytics / Crashlytics feature flags | Shipped | Off in Debug/CI; `-disable_firebase_analytics` | `FeatureFlag.swift` |
| Firebase Auth | Planned | Phase 2 post-1.0 | [`FirebaseBackendAnalyticsSpec.md`](../specs/FirebaseBackendAnalyticsSpec.md) |
| Firestore / Cloud Functions | Planned | Online play backend | [`OnlinePlaySpec.md`](../specs/OnlinePlaySpec.md) |
| FCM push messaging | Planned | Optional for play reminders | [`play-reminders.md`](../FutureIdeas/play-reminders.md) |
| `GoogleService-Info.plist.example` | Shipped | Real plist gitignored | `Resources/` |

---

## Platform targets & extensions

| Feature | Status | Notes | Reference |
|---------|--------|-------|-----------|
| iPhone (iOS 17+) | Shipped | Primary target | `project.yml` |
| iPad universal (`TARGETED_DEVICE_FAMILY: 1,2`) | Partial | Supported; full two-pane IA not done | `project.yml`, `GameplayLayout.swift` |
| Apple Watch companion | Planned | Active-match scoring via WatchConnectivity | [`AppleWatchCompanionSpec.md`](../specs/AppleWatchCompanionSpec.md) · flag `enableAppleWatchCompanion` |
| macOS target | Planned | Not in project | — |
| visionOS target | Planned | Auto-scoring spec only | [`AutoScoringVisionSpec.md`](../specs/AutoScoringVisionSpec.md) |
| WidgetKit extension | Planned | No target yet | [`AppIntentsSpec.md`](../specs/AppIntentsSpec.md) |

---

## Feature flags

All flags: `Support/FeatureFlags/FeatureFlag.swift` · config: [`FeatureFlagConfigSpec.md`](../specs/FeatureFlagConfigSpec.md)

| Flag | Default | Gated feature |
|------|---------|---------------|
| `enableFirebaseAnalytics` | On (Release + real plist) | Firebase Analytics sink |
| `enableFirebaseCrashlytics` | On (Release + real plist) | Crashlytics |
| `enableAppIntents` | **Off** | Siri / Shortcuts |
| `enableAppleWatchCompanion` | Off | Watch companion (not built) |
| `enableVisionAutoScoring` | Off | Camera auto-scoring (not built) |
| `enableOnlinePlay` | Off | Online multiplayer (not built) |
| `enableAdvancedDiagnostics` | Off | Extra diagnostics |

---

## Post-1.0 product ideas (assessed / planned)

| Feature | Status | Brief | Reference |
|---------|--------|-------|-----------|
| Game Center achievements | Assessed | ~62-achievement catalog, MVP estimate | [`achievements.md`](../FutureIdeas/achievements.md) |
| Play reminders (local notifications) | Assessed | MVP local; FCM optional Phase 2 | [`play-reminders.md`](../FutureIdeas/play-reminders.md) |
| Campaign mode | Assessed | Progression ladder | [`campaign-mode.md`](../FutureIdeas/campaign-mode.md) |
| Talk mode | Assessed | Voice scoring input | [`talk-mode.md`](../FutureIdeas/talk-mode.md) |
| Additional game modes R&D | Assessed | Target Darts–style index | [`additional-game-modes.md`](../FutureIdeas/additional-game-modes.md) |
| General post-1.0 backlog | Planned | CSV export, bot names, a11y layout, etc. | [`backlog.md`](../FutureIdeas/backlog.md) |

---

## Core infrastructure (non-UI)

| Feature | Status | Reference |
|---------|--------|-----------|
| SwiftData persistence + SchemaV2 | Shipped | [`SwiftData.md`](../specs/SwiftData.md) |
| Repository layer | Shipped | [`RepositorySpec.md`](../specs/RepositorySpec.md) |
| Structured logging (`AppLogger`) | Shipped | [`LoggingSpec.md`](../specs/LoggingSpec.md) |
| Feature flags system | Shipped | [`FeatureFlagConfigSpec.md`](../specs/FeatureFlagConfigSpec.md) |
| Error model | Shipped | [`ErrorModelSpec.md`](../specs/ErrorModelSpec.md) |
| Security & privacy baseline | Shipped | [`SecurityPrivacySpec.md`](../specs/SecurityPrivacySpec.md) |
| Performance monitoring | Shipped | [`PerformanceSpec.md`](../specs/PerformanceSpec.md) |

---

## Related indexes

| Doc | Purpose |
|-----|---------|
| [`specs/README.md`](../specs/README.md) | Governed feature specs (40+) |
| [`docs/release/todo.md`](release/todo.md) | 1.0 ship blockers & UX audit |
| [`docs/release/ongoing-release-plan.md`](release/ongoing-release-plan.md) | Versioned release train (scope by test confidence) |
| [`docs/release/lean-1.0-implementation-plan.md`](release/lean-1.0-implementation-plan.md) | Lean 1.0 implementation tasks (approved) |
| [`FutureIdeas/`](../FutureIdeas/) | Post-1.0 briefs |
| [`roadmap/README.md`](../roadmap/README.md) | Phase delivery history |
| [`specs/SpecGovernance.md`](../specs/SpecGovernance.md) | How specs relate to code |
