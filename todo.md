# Dart Buddy — TODO

Goal: match the reference *Darts Scoreboard: Scorekeeper* app's functionality and feel — ad-free.

Status legend: `[x]` done · `[ ]` todo · `[~]` partial

---

## Full code review audit (2026-06-01)

Senior iOS / feature-set review. Items are ranked **impact → effort** unless noted.

### P0 — User-visible bugs / broken settings

- [x] **Honor appearance setting** — `MainTabView` reads `UserPreferencesStore.preferredColorScheme` from settings; theme picker applies live via `SettingsViewModel`.
- [x] **Honor haptics & sound toggles** — `GatedHapticsService` / `GatedAudioFeedbackService` wrap real services and respect `FeedbackPreferences` synced from settings.
- [x] **Settings defaults ↔ setup round-trip** — `MatchSetupViewModel` restores all checkout/check-in/leg-format modes from settings and persists last-used setup on match start.
- [x] **Unify X01 exit copy / localization** — `X01MatchScreen` uses `play.match.exit.*` / `common.stay` keys like Cricket.

### P1 — Architecture & maintainability

- [x] **Split `PlayRootView.swift` (~800 lines)** — Shell in `PlayRootView`; extracted `SetupHomeView`, `QuickAddPlayerScreen`, `CricketMatchScreen`, `MatchSummaryScreen`.
- [x] **Remove or wire dead UI: `ScoringInputPad.swift`** — Deleted; `ScoringInputMode` enum lives in `X01MatchViewModel`.
- [x] **Remove dead code: `isSnapshotPreviewMode`** — Removed from `CricketMatchScreen`.
- [x] **Document active-match contract** — Doc comment on `ActiveMatchStore` clarifies DB resume vs in-memory cache.

### P2 — Data model & bots

- [x] Persist `botDifficultyRaw` on match participants — `SchemaV1.MatchParticipantRecord` + repository mapping; written on match create.
- [x] **Bot identity in stats** — Bots are `PlayerRecord` rows with stable UUIDs (`isBot` + `botDifficultyRaw`); listed under Bots in Players and selectable on setup.
- [x] **Replace-active-match deletes DB row** — `confirmReplaceActiveMatch` now abandons via `MatchLifecycleService` instead of `deleteMatch`.

### P3 — History & statistics

- [x] **Wire or remove `HistoryListViewModel` filters** — Date filter wired in `HistoryRootView`; player filter matches any participant, not just winner.
- [ ] **Statistics load performance** — `StatisticsViewModel`, `PlayerDetailViewModel`, and similar paths fetch up to **1000** history rows + per-match `fetchEvents`. Add pagination or repository-level aggregates before large histories.
- [x] **Statistics loading UI** — Spinner shown while `isLoading && rows.isEmpty`.
- [x] **Cricket MPR in Statistics** — `marksPerRound` tracked in `StatsService`; MPR table in Cricket mode.

### P4 — UI / UX / accessibility

- [ ] **iPad / landscape layouts** — X01 board portrait-tuned; Cricket has `contentMaxWidth` on regular size class only.
- [ ] **Accessibility pass** — Sparse VoiceOver on score cards; X01 header back/undo buttons bumped to **44×44**; Cricket grid cells need labels.
- [ ] **Localize hardcoded strings** — Home, History, Statistics, Match Summary, X01 exit, game detail delete copy still English inline (Players/Settings use `L10n` / keys).
- [ ] **Settings gameplay defaults UI** — Schema stores checkout/legs/sets/start score; Settings UI only exposes default **mode** (X01 vs Cricket). Expose or stop persisting unused fields.

### P5 — Testing gaps

- [ ] **`StatisticsViewModel` unit tests** — Aggregation, period cutoff, mode filter, empty state.
- [ ] **`HistoryListViewModel` tests** — Date filter, player filter (once fixed), error/empty, config line decoding.
- [x] **`SettingsViewModel` tests** — Load/save, reset, appearance/feedback mutations, error keys.
- [ ] **`MatchSummaryViewModel` tests** — Winner rows, stats labels; store-only data path (no repository fallback).
- [ ] **`MigrationRecoveryViewModel` tests** — Retry/reset flows.
- [x] **Abandon + resume integration** — `playHomeDoesNotOfferAbandonedMatch` VM test added.
- [ ] **UI tests** — Checkout banner, Cricket tap grid, match summary, settings feedback toggles, abandon vs save & exit.
- [ ] **Repository contract tests** — `specs/RepositorySpec.md` calls for per-repo contract tests; only in-memory fakes in feature tests today.

### P6 — Polish / performance

- [x] **Retain UIKit haptic generators** — `SystemHapticsService` retains and re-prepares generators per tap.
- [ ] **SwiftData: new `ModelContext` per repository call** — Works via actor isolation; profile under heavy scoring if writes feel sluggish.
- [ ] **`MatchSummaryViewModel` repository fallback** — Summary reads `ActiveMatchStore` only; deep link / cold path to summary route may show empty without store session.

---

## Auth / login (deferred by design)

- [x] **No login in 1.0** — Local-first SwiftData; bootstrap has no auth (`AppBootstrapper`, `DartsScoreboardApp`).
- [ ] **Firebase Auth (Phase 2+)** — Per `specs/FirebaseBackendAnalyticsSpec.md`: anonymous first, behind repository interfaces; engines stay Firebase-agnostic.

---

## Code-review improvements (prioritized 2026-06) — shipped

1. [x] **Cricket tap-to-mark grid board** — `CricketBoardView` + `CricketTapPad`; `-snapshot_match_cricket` route.
2. [x] **Mid-match exit → `abandoned`** — `MatchLifecycleService.abandon`; Save & Exit vs Abandon; unit tests.
3. [x] **X01 checkout suggestions** — `CheckoutSuggester` + board banner; unit tests incl. 2–170 sweep.
4. [x] **Win celebration + richer Match Summary** — Trophy, stat cards, `-snapshot_match_summary`.
5. [x] **Setup chips** — Master Out/In, First to / Best of; engine + tests.
6. [x] **Real haptics/audio** — `SystemHapticsService` + `BundledAudioFeedbackService` (see P0: settings toggles not honored yet).

---

## Done so far

- [x] Dark brand theme (black surfaces, green/red/amber accents)
- [x] Home/setup board: X01/Cricket pill, config chips, red START, player list, random order, Add Bot menu
- [x] X01 match board: player cards, per-dart pad, auto-submit, checkout banner
- [x] Cricket marks grid + tap-to-mark pad
- [x] X01 start scores 301 / 401 / 501 / 601 (+ 101 / 201 in engine list)
- [x] Statistics tab (X01/Cricket + period filters, tables + charts)
- [x] All Games list + Game Statistics detail + **delete match** (detail screen)
- [x] Players list + detail + edit
- [x] 5-tab shell (Home / Players / Statistics / All Games / Settings)
- [x] XCUITest target (tabs, start+score, resume, undo, bots, delete game, player detail)
- [x] DartBot engine + difficulties + integration / long-term simulation tests
- [x] Local MCP config (XcodeBuildMCP + ios-simulator)
- [x] Migration recovery path

---

## High priority — core parity (reference app)

### Cricket

- [x] Cricket match board (marks grid 15–20 + Bull)
- [x] Tap-to-mark input
- [ ] Cricket-specific setup (e.g. Cut Throat)
- [ ] Cricket stats: MPR, cricket-specific wins column in Statistics

### Game flow polish

- [x] Checkout suggestion on board
- [x] Win / match summary celebration
- [x] Exit mid-match → `abandoned`
- [ ] Per-dart bust feedback animation + leg/set transition animations

### Statistics & history depth

- [~] Statistics tables (Games, Avg, Legs/Checkout, Points, Throws, sector chart) — present; legs win% / player filter missing
- [ ] Statistics: filter by individual player
- [~] Game detail hit-distribution charts — sector chart exists; per-player bars like reference TBD
- [x] All Games: delete a game (`deleteMatch` + detail confirm)
- [x] All Games: config summary includes check-in/out, best-of/first-to (via snapshot decode in `HistoryListViewModel`)

---

## Medium priority — setup & options

- [x] Check-In modes (Straight / Double / Master In)
- [x] Master Out checkout
- [x] First to vs Best of sets/legs
- [x] Persist last-used setup ↔ Settings — round-trip for mode, start score, checkout, check-in, leg format, legs, sets-enabled
- [ ] Player reordering on setup roster + remove-from-match
- [ ] Player avatars / colors (bot vs human)

---

## Larger features (reference / post-1.0)

- [x] Bot opponent (DartBot + Easy/Medium/Hard/Pro)
- [ ] AI camera auto-scoring (Vision pipeline)
- [ ] External display / AirPlay scoreboard
- [ ] Voice caller (“One hundred and eighty!”) beyond current SFX

---

## Quality & polish

- [ ] Localize remaining English strings (`Localizable.strings`)
- [ ] VoiceOver + Dynamic Type on board, setup, stats
- [ ] iPad / landscape (see P4)
- [ ] App icon finalization (`Media.xcassets` / `assets/app-icons/`)
- [x] Apply appearance preference — `UserPreferencesStore` at app root

---

## Testing

- [x] Unit: engines, lifecycle, checkout, DartBot, core ViewModels (Play home, setup, X01, Cricket)
- [x] UI: tab navigation, start/score, resume, undo, bots, delete game
- [ ] UI: full checkout → winner → summary
- [ ] UI: Cricket grid scoring path
- [x] Unit: `SettingsViewModel`
- [ ] Unit: `StatisticsViewModel`, `HistoryListViewModel`, `MatchSummaryViewModel`
- [ ] Snapshot tests (light/dark, iPhone/iPad) — optional post UI lock

---

## Housekeeping

- [ ] Reconcile `todo.md` with git status when editing (avoid stale “not done” items)
- [ ] Decide long-term fate of `-seed_demo` / `-seed_players` / `-snapshot_*` launch arguments (debug vs release)
- [x] `tmp/` in `.gitignore` (MCP screenshots)
- [ ] `DartsScoreboard.xcodeproj/` is gitignored (XcodeGen); ensure team uses `xcodegen generate` — do not commit user state (`xcuserstate`)
- [ ] Online play / Firebase runtime SDKs — deferred per roadmap (`specs/OnlinePlaySpec.md`, `FirebaseBackendAnalyticsSpec.md`)

---

## Second-pass findings (2026-06-01 scan)

Issues found on re-scan beyond the first audit:

- [x] **`ScoringInputPad.swift` is orphaned** — Deleted; enum moved to `X01MatchViewModel`.
- [x] **`botDifficultyRaw` not in SwiftData participant schema** — Column added to `MatchParticipantRecord`.
- [ ] **Settings UI vs schema mismatch** — Checkout/legs/start score defaults stored but not editable in Settings (only match type).
- [ ] **`HistoryListViewModel.dateFilter` / `playerFilter` dead** — Implemented, not bound to UI; player filter logic incorrect for future use.
- [ ] **`MatchSummaryViewModel` store-only** — No reload from `matchRepository` if `ActiveMatchStore` cleared.
- [x] **`confirmReplaceActiveMatch` uses `deleteMatch`** — Now abandons in place.
- [x] **Bot ephemeral UUIDs in stats** — Bots persist as player records with stable IDs.
- [ ] **No `SettingsViewModel` / `MigrationRecoveryViewModel` tests** — `SettingsViewModel` covered; `MigrationRecoveryViewModel` still open.
- [ ] **Repository contract tests missing** — Per `RepositorySpec.md`
- [ ] **`try!` in test helpers only** — Acceptable in tests; avoid in app code (currently clean)
- [ ] **Forced dark mode duplicates “done” and open work** — Resolved: appearance setting is honored at app root.

---

## What’s in good shape (no action required)

- Clean layering: engines → `MatchLifecycleService` → repositories
- Abandoned matches excluded from history (`fetchHistory` = completed only)
- Resume via snapshots + tail events; `PlayHome` uses DB active match
- Strong engine + bot test coverage including long-term simulations
- Migration recovery + bootstrap error handling
- UI test baseline for primary flows
