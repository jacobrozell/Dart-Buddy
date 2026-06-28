# Dart Buddy — Feature Inventory

Living register of every product feature: shipped, partial, and planned. Use this to answer “what exists?” and “what’s next?” without hunting through specs, code, and `FutureIdeas/`.

**Last reviewed:** 2026-06-13 (spec promotion, UI suite split, branch strategy doc)  
**App status:** **`dev` branch** — full catalog, no intentional gating (22 shipped modes, 5 tabs, all locales). **Release branches** (`release/1.0`, …) apply `ProductSurface` trimming per [`release/branch-strategy.md`](release/branch-strategy.md). Release train: [`release/ongoing-release-plan.md`](release/ongoing-release-plan.md).

---

## How to maintain

1. **When shipping a feature** — change its status here, update the linked spec, and (for game modes) promote `specs/game-modes/planned/` → `implemented/` plus `GameModeCatalog.swift`.
2. **When adding a planned feature** — add a spec under `specs/game-modes/planned/` and a row here (use `FutureIdeas/` only for pre-spec R&D).
3. **When something is behind a flag** — mark **Partial** and note the flag in the Notes column.
4. **Source of truth for mode list** — `GameModeCatalog.swift` (34 modes: 22 shipped, 12 planned). This doc mirrors it.
5. Do **not** duplicate release QA checklists here; track blockers in [`release/todo.md`](release/todo.md).
6. **Release sequencing** — store-facing dates live in [`release/estimated-releases.json`](release/estimated-releases.json) (**Estimated release** tags); train narrative in [`release/ongoing-release-plan.md`](release/ongoing-release-plan.md). **Lean 1.0 execution:** [`release/lean-1.0-implementation-plan.md`](release/lean-1.0-implementation-plan.md).
7. **PR rule** — when ship status changes, update this doc in the same PR as the feature spec (`SpecGovernance.md` §4.1 rule 6).

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
| Game modes (catalog) | 22 engines playable on `dev` | Achievement UI not wired | 12 catalog stubs |
| App shell & navigation | 5 tabs (full surface on `dev`) | WCAG manual evidence gaps | iPad two-pane IA |
| Localization | en/de/es/nl/fr bundled on `dev` | In-app picker | lean English-only on `release/1.0` |
| Shortcuts & deep links | Deep links | App Intents (flagged off) | Widgets, query intents |
| CI / release | GitHub Actions, Xcode Cloud | Slack notify, perf tests | — |
| Players & bots | CRUD + preset + custom + training bots | — | Game Center sync |
| Stats & activity | History + statistics (22 mode filters) | Per-mode reducers for newer kinds | — |
| Settings & a11y | Core prefs + TTS caller + visual dartboard | WCAG manual evidence, AXXXL layout | Talk mode |
| Firebase | Analytics + Crashlytics | — | Auth, Firestore, FCM |
| Platforms | iPhone, iPad universal | iPad layout polish | watchOS, macOS, visionOS |
| Gamification | — | Local achievements (domain + unit tests; summary/profile UI TBD) | Campaign, daily challenge, GC |

**Targets today:** `DartBuddy` (iOS, iPhone + iPad), `DartBuddyTests`, `DartBuddyPerformanceTests`, seven UI test targets (`DartBuddyUISmokeUITests`, …) — no Widget, Watch, or macOS extensions (`project.yml`).

---

## Game modes

Catalog source: [`Features/Modes/GameModeCatalog.swift`](../Features/Modes/GameModeCatalog.swift) · UI: [`ModesRootView`](../Features/Modes/ModesRootView.swift) · Spec: [`specs/ModesTabSpec.md`](../specs/ModesTabSpec.md)

### Shipped (22)

Reachable on **`dev`** with full product surface (all shipped modes in picker, resume, and Modes tab). **`release/*` branches** gate via `ProductSurface` — see [`branch-strategy.md`](release/branch-strategy.md).

#### Standard (3)

| Mode | Engine / UI | Spec |
|------|-------------|------|
| X01 (301 / 501) | `X01Engine`, `Features/Play/X01/` | [`X01GameSpec.md`](../specs/game-modes/implemented/X01GameSpec.md) |
| Cricket (Normal + Cut Throat) | `CricketEngine`, `Features/Play/Cricket/` | [`CricketSpec.md`](../specs/game-modes/implemented/CricketSpec.md) |
| American Cricket | `AmericanCricketEngine`, `Features/Play/AmericanCricket/` | [`AmericanCricketGameSpec.md`](../specs/game-modes/implemented/AmericanCricketGameSpec.md) |

#### Party (14)

| Mode | Engine / UI | Spec |
|------|-------------|------|
| Baseball | `BaseballEngine`, `Features/Play/Baseball/` | [`BaseballGameSpec.md`](../specs/game-modes/implemented/BaseballGameSpec.md) |
| Killer | `KillerEngine`, `Features/Play/Killer/` | [`KillerGameSpec.md`](../specs/game-modes/implemented/KillerGameSpec.md) |
| Shanghai | `ShanghaiEngine`, `Features/Play/Shanghai/` | [`ShanghaiGameSpec.md`](../specs/game-modes/implemented/ShanghaiGameSpec.md) |
| Mickey Mouse | `MickeyMouseEngine`, `Features/Play/MickeyMouse/` | [`MickeyMouseGameSpec.md`](../specs/game-modes/implemented/MickeyMouseGameSpec.md) |
| Mulligan | `MulliganEngine`, `Features/Play/Mulligan/` | [`MulliganGameSpec.md`](../specs/game-modes/implemented/MulliganGameSpec.md) |
| English Cricket | `EnglishCricketEngine`, `Features/Play/EnglishCricket/` | [`EnglishCricketGameSpec.md`](../specs/game-modes/implemented/EnglishCricketGameSpec.md) |
| Knockout | `KnockoutEngine`, `Features/Play/Knockout/` | [`KnockoutGameSpec.md`](../specs/game-modes/implemented/KnockoutGameSpec.md) |
| Sudden Death | `SuddenDeathEngine`, `Features/Play/SuddenDeath/` | [`SuddenDeathGameSpec.md`](../specs/game-modes/implemented/SuddenDeathGameSpec.md) |
| 51 By 5's | `FiftyOneByFivesEngine`, `Features/Play/FiftyOneByFives/` | [`FiftyOneByFivesGameSpec.md`](../specs/game-modes/implemented/FiftyOneByFivesGameSpec.md) |
| Golf | `GolfEngine`, `Features/Play/Golf/` | [`GolfGameSpec.md`](../specs/game-modes/implemented/GolfGameSpec.md) |
| Football | `FootballEngine`, `Features/Play/Football/` | [`FootballGameSpec.md`](../specs/game-modes/implemented/FootballGameSpec.md) |
| Grand National | `GrandNationalEngine`, `Features/Play/GrandNational/` | [`GrandNationalGameSpec.md`](../specs/game-modes/implemented/GrandNationalGameSpec.md) |
| Hare and Hounds | `HareAndHoundsEngine`, `Features/Play/HareAndHounds/` | [`HareAndHoundsGameSpec.md`](../specs/game-modes/implemented/HareAndHoundsGameSpec.md) |
| Fleet | `FleetEngine`, `Features/Play/Fleet/` | [`FleetGameSpec.md`](../specs/game-modes/implemented/FleetGameSpec.md) |

#### Co-op (1)

| Mode | Engine / UI | Spec |
|------|-------------|------|
| Raid | `RaidEngine`, `Features/Play/Raid/`, `CoopBossChromeView` | [`RaidGameSpec.md`](../specs/game-modes/implemented/RaidGameSpec.md) · platform [`CoopPvEModesSpec.md`](../specs/CoopPvEModesSpec.md) |

#### Practice (4)

| Mode | Engine / UI | Spec |
|------|-------------|------|
| Around the Clock | `AroundTheClockEngine`, `Features/Play/AroundTheClock/` | [`AroundTheClockGameSpec.md`](../specs/game-modes/implemented/AroundTheClockGameSpec.md) |
| 180 Around the Clock | `AroundTheClock180Engine`, `Features/Play/AroundTheClock180/` | [`AroundTheClock180GameSpec.md`](../specs/game-modes/implemented/AroundTheClock180GameSpec.md) |
| Chase the Dragon | `ChaseTheDragonEngine`, `Features/Play/ChaseTheDragon/` | [`ChaseTheDragonGameSpec.md`](../specs/game-modes/implemented/ChaseTheDragonGameSpec.md) |
| Nine Lives | `NineLivesEngine`, `Features/Play/NineLives/` | [`NineLivesGameSpec.md`](../specs/game-modes/implemented/NineLivesGameSpec.md) |

**Doc debt:** promoted 2026-06-13 — 17 specs moved to `specs/game-modes/implemented/`. Custom/R&D specs remain under `planned/` without catalog ids.

### Planned — catalog stubs (12)

Shown in Modes tab as “coming soon”; no `MatchType`, Start disabled.

| Mode | Section | UI template | Spec |
|------|---------|-------------|------|
| Blind Killer | Party | Lives elimination | [`BlindKillerGameSpec.md`](../specs/game-modes/planned/BlindKillerGameSpec.md) |
| Follow the Leader | Party | Lives elimination | [`FollowTheLeaderGameSpec.md`](../specs/game-modes/planned/FollowTheLeaderGameSpec.md) |
| Loop | Party | Lives elimination | [`LoopGameSpec.md`](../specs/game-modes/planned/LoopGameSpec.md) |
| Prisoner | Party | Board state | [`PrisonerGameSpec.md`](../specs/game-modes/planned/PrisonerGameSpec.md) |
| Scam | Party | Role split | [`ScamGameSpec.md`](../specs/game-modes/planned/ScamGameSpec.md) |
| Snooker | Party | Role split | [`SnookerGameSpec.md`](../specs/game-modes/planned/SnookerGameSpec.md) |
| Tic-Tac-Toe | Party | Board state | [`TicTacToeGameSpec.md`](../specs/game-modes/planned/TicTacToeGameSpec.md) |
| Cerberus | Co-op | Role split | [`CerberusGameSpec.md`](../specs/game-modes/planned/CerberusGameSpec.md) |
| The Vault | Co-op | Phase race | [`TheVaultGameSpec.md`](../specs/game-modes/planned/TheVaultGameSpec.md) |
| Clear the Board | Co-op | Board state | [`ClearTheBoardGameSpec.md`](../specs/game-modes/planned/ClearTheBoardGameSpec.md) |
| Bob's 27 | Practice | Solo challenge | [`Bobs27GameSpec.md`](../specs/game-modes/planned/Bobs27GameSpec.md) |
| Halve-It | Practice | Solo challenge | [`HalveItGameSpec.md`](../specs/game-modes/planned/HalveItGameSpec.md) |

### Game mode infrastructure

| Feature | Status | Notes | Reference |
|---------|--------|-------|-----------|
| Modes tab (browse, search, quick-start) | Shipped | Standard / Party / **Co-op** / Practice sections; iPad 2-col grid | [`ModesTabSpec.md`](../specs/ModesTabSpec.md) |
| Game rules guide (in-app) | Shipped | Shipped modes only | `Features/Play/Rules/GameRulesGuideView.swift` |
| 8 gameplay UI templates | Partial | Enum A–I defined; **J (voice drill)** spec'd for Call & Hit | [`VoiceDrillUITemplateSpec.md`](../specs/game-modes/planned/VoiceDrillUITemplateSpec.md) |
| Per-mode stat kinds (34 declared) | Partial | Live reducers vary by mode; all shipped modes have history/activity filters | `ModeStatKind` in `GameModeCatalog.swift` |
| Campaign mode (Journey tab) | **Planned** | Spec’d; no implementation; flag `enableCampaign` | [`CampaignSpec.md`](../specs/CampaignSpec.md) |
| Solo practice platform | **Partial** | Four practice engines shipped; Bob's 27 / Halve-It / Call & Hit still planned | [`SoloPracticeModesSpec.md`](../specs/SoloPracticeModesSpec.md) |
| Co-op platform | **Partial** | Raid shipped; shared `BossParticipant` type + Cerberus/Vault/Clear the Board still planned | [`CoopPvEModesSpec.md`](../specs/CoopPvEModesSpec.md) §13 |
| Guided Play (blind/low-vision) | **Assessed (R&D)** | WIP — camera + mic + talk-back; see FutureIdeas brief | [`FutureIdeas/guided-play-blind-darts.md`](../FutureIdeas/guided-play-blind-darts.md) |
| Online multiplayer | Planned | Firestore sync | [`OnlinePlaySpec.md`](../specs/OnlinePlaySpec.md) |
| Vision auto-scoring | Partial | Phase A (guided calibration + assistive detection) behind flag; X01 only | [`AutoScoringVisionSpec.md`](../specs/AutoScoringVisionSpec.md) · flag `enableVisionAutoScoring` |

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
| Visual dartboard input (X01 + Cricket) | Shipped | Settings default + in-match toggle | [`VisualDartboardInputSpec.md`](../specs/VisualDartboardInputSpec.md) |
| Checkout suggester (X01) | Shipped | | `Domain/Engines/CheckoutSuggester.swift` |
| Onboarding (first launch + replay) | Shipped | Experience branching | `Features/Onboarding/` |
| Bootstrap store recovery | Shipped | Auto-repair/recreate on open failure | [`SwiftData.md`](../specs/SwiftData.md) §9, `BootstrapStoreRecovery.swift` |
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
| French (`fr`) | Shipped | Wave 4 | `Resources/fr.lproj/Localizable.strings` |
| `L10n` helper + namespaced keys | Shipped | No hardcoded UI strings policy | `Support/Localization/L10n.swift` |
| Mode catalog strings (all 34 modes) | Shipped | `modes.catalog.*` keys | [`LocalizationSpec.md`](../specs/LocalizationSpec.md) |
| Locale generator script | Shipped | Key parity helper | `Scripts/l10n.py` |
| Localization parity unit tests | Shipped | en/de/es/nl/fr | `Tests/Unit/LocalizationParityTests.swift` |
| Localized smoke UI tests | Shipped | de / es / nl / fr tab smoke | `Tests/UI/*LocalizationSmokeUITests.swift` |
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
| App entities (`Player`, `Match`, `GameMode`) | Planned | Phase 1b–2; wraps existing domain models | [`AppIntentsSpec.md`](../specs/AppIntentsSpec.md) §4.5 |
| `IndexedEntity` / semantic history search | Planned | Phase 2 | [`AppIntentsSpec.md`](../specs/AppIntentsSpec.md) §4.6 |
| Query intents (stats, player, match status) | Planned | Phase 2; Siri answers without opening app | [`AppIntentsSpec.md`](../specs/AppIntentsSpec.md) §4.3, §13 |
| On-screen entity annotations | Planned | Phase 2b; “this game” on gameplay / history | [`AppIntentsSpec.md`](../specs/AppIntentsSpec.md) §4.7 |
| `AppIntentsTesting` in CI | Planned | Phase 2 query/entity tests | [`AppIntentsSpec.md`](../specs/AppIntentsSpec.md) §10 |
| Start Quick / Start Mode intents | Planned | Blocked on Deep Link Phase 2 | [`AppIntentsSpec.md`](../specs/AppIntentsSpec.md) §4.2 |
| Home Screen widgets | Planned | Resume / status tap targets | [`AppIntentsSpec.md`](../specs/AppIntentsSpec.md) §11 |
| Control Center control (iOS 18+) | Planned | One-tap Resume | [`AppIntentsSpec.md`](../specs/AppIntentsSpec.md) §11 |
| Cross-app `Transferable` export | Planned | Low priority | [`AppIntentsSpec.md`](../specs/AppIntentsSpec.md) §4.8 |
| Custom intents (no App Schema domains) | Policy | Sports scoring has no Apple schema domain | [`AppIntentsSpec.md`](../specs/AppIntentsSpec.md) §4.9, §13 |

---

## CI, testing & release

| Feature | Status | Notes | Reference |
|---------|--------|-------|-----------|
| GitHub Actions CI (push / PR) | Shipped | XcodeGen, build-for-testing, `DartBuddyCI` | `.github/workflows/ci.yml` |
| Nightly UI tests | Shipped | Parallel matrix: smoke, gameplay, a11y, l10n, landscape, chrome | `.github/workflows/nightly-ui.yml` |
| Lean UI tests (`DartBuddyUILean`) | Shipped | `release/*` branches only | `PartyPack1_1SmokeUITests` (7-mode Party Pack + Raid) |
| Xcode Cloud → TestFlight | Shipped | Manual / API trigger only | [`release/xcode-cloud.md`](release/xcode-cloud.md) |
| Trigger TestFlight workflow | Shipped | GHA → App Store Connect API | `.github/workflows/trigger-testflight.yml` |
| XcodeGen project generation | Shipped | `.xcodeproj` not committed | `project.yml` |
| Firebase plist in CI | Shipped | Example in GHA; secret in Xcode Cloud | `ci_scripts/ci_post_clone.sh` |
| Slack `/dart-buddy release` | Post-1.0 | Worker code in repo; not deployed — see [`release/slack-integration.md`](release/slack-integration.md) | [`workers/dart-buddy-slack/`](../workers/dart-buddy-slack/) |
| Slack CI pass/fail notifications | Post-1.0 | Composite action; needs webhook secret | [`.github/actions/slack-ci-notify/`](../.github/actions/slack-ci-notify/) · [`release/slack-integration.md`](release/slack-integration.md) |
| Performance test target | Partial | Exists; not in `DartBuddyCI` scheme | `DartBuddyPerformanceTests` |
| WCAG accessibility UI tests (48) | Shipped | Nightly `DartBuddyUIAccessibility` | `Tests/UI/WCAGAccessibilityUITests.swift` |
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
| Custom bots (user metrics) | Shipped (simple UI); Advanced phased | Template-aware resolution; facet editors planned | [`CustomBotSpec.md`](../specs/CustomBotSpec.md) · [`plans/custom-bot-architecture-ui-plan.md`](plans/custom-bot-architecture-ui-plan.md) |
| Local achievements (profile) | **Partial** | `AchievementEvaluator`, `DefaultAchievementService`, `SwiftDataAchievementRepository`, unit tests; flag `enableAchievements`; summary/profile UI not wired | [`AchievementsSpec.md`](../specs/AchievementsSpec.md) |
| Achievement badges UI (profile gallery) | **Partial** | `BadgeMedal` / `AchievementUnlockRow` exist; gated behind achievements flag | [`BadgesSpec.md`](../specs/BadgesSpec.md) |
| Game Center sync | **Planned** | Add-on on local achievements; sync reads local stats → updates GC | [`AchievementsSpec.md`](../specs/AchievementsSpec.md) §10 |
| Leaderboards | **Planned** | Not in achievements v1 | [`achievements.md`](../FutureIdeas/achievements.md) |

---

## History, statistics & activity

| Feature | Status | Notes | Reference |
|---------|--------|-------|-----------|
| Match history list + detail | Shipped | Filters, timeline, mode badges | [`HistorySpec.md`](../specs/HistorySpec.md) |
| Baseball line score in history | Shipped | | `BaseballLineScoreView.swift` |
| Statistics aggregates + charts | Shipped | Per-player breakdowns, filters | [`StatsSpec.md`](../specs/StatsSpec.md) |
| Statistics tab UI | Shipped | Now Activity segment | [`StatisticsTabSpec.md`](../specs/StatisticsTabSpec.md) |
| Per-mode statistics (34 kinds declared) | Partial | All shipped modes filter in Activity; aggregate depth varies by `ModeStatKind` | `ModeStatKind` in catalog |
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
| Instant bot turns (app-wide) | Shipped | Settings → During Play; all modes & bot kinds | [`InstantBotTurnsSpec.md`](../specs/InstantBotTurnsSpec.md) |
| Reset all data | Shipped | Destructive local wipe | same |
| Replay onboarding | Shipped | From Settings | same |
| Tip jar (StoreKit consumables) | Planned | Optional IAP in Settings → About; replaces external coffee link (3.1.1) | [`storekit-tip-jar-plan.md`](plans/storekit-tip-jar-plan.md) |
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
| iPhone (iOS 18+) | Shipped | Primary target | `project.yml` |
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
| `enableVisionAutoScoring` | Off | Camera auto-scoring Phase A (enable locally with `-enable_vision_scoring`) |
| `enableOnlinePlay` | Off | Online multiplayer (not built) |
| `enableAdvancedDiagnostics` | Off | Extra diagnostics |
| `enableAchievements` | **Off** | Local profile achievements (domain layer only; `-enable_achievements` in Debug) | [`AchievementsSpec.md`](../specs/AchievementsSpec.md) |
| `enableCampaign` | **Off** | Journey / campaign tab (**not built**) | [`CampaignSpec.md`](../specs/CampaignSpec.md) |
| `enableDailyChallenge` | **Off** | Daily challenge card + push (**not built**) | [`DailyChallengeSpec.md`](../specs/DailyChallengeSpec.md) |

---

## Gamification (post-1.0 — partial / planned)

| Feature | Status | Brief | Reference |
|---------|--------|-------|-----------|
| Local achievements | **Partial** | Evaluator + repository landed; lifecycle hooks, summary reveal, and unit tests still open | [`AchievementsSpec.md`](../specs/AchievementsSpec.md) |
| Profile badge gallery | **Partial** | UI components exist; not reachable without flag + wiring | [`BadgesSpec.md`](../specs/BadgesSpec.md) |
| Campaign / Journey tab | **Planned** | Scripted stages, bundled JSON, primary player, separate stats | [`CampaignSpec.md`](../specs/CampaignSpec.md) |
| Daily challenge | **Planned** | Once-per-day goal; ties to local push work | [`DailyChallengeSpec.md`](../specs/DailyChallengeSpec.md) |
| Game Center reporting | **Planned** | Layer on local achievements; local is source of truth, GC mirrors on sign-in + unlock | [`AchievementsSpec.md`](../specs/AchievementsSpec.md) §10 |
| Gamification reset on delete-all | **Planned** | Inventory when models ship | [`DeleteAllDataSpec.md`](../specs/DeleteAllDataSpec.md) §6.6 |

**Ship order (product):** wire local achievements → evaluator tests → summary reveal → Journey shell → daily challenge → Game Center bridge.

R&D catalog (IDs, GC estimates): [`FutureIdeas/achievements.md`](../FutureIdeas/achievements.md) · campaign brainstorm: [`FutureIdeas/campaign-mode.md`](../FutureIdeas/campaign-mode.md).

---

## Post-1.0 product ideas (assessed / planned)

| Feature | Status | Brief | Reference |
|---------|--------|-------|-----------|
| Play reminders (local notifications) | Assessed | MVP local; FCM optional Phase 2 | [`play-reminders.md`](../FutureIdeas/play-reminders.md) |
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
