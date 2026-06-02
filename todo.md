# Dart Buddy — TODO

Goal: match the reference *Darts Scoreboard: Scorekeeper* app's functionality and feel — ad-free.

Status legend: `[ ]` todo · `[~]` partial

---

## User feedback

* What if we had a watch app? SO you could enter your throws on the watch and it connect back to the main app
* Speak mode while playing

- [x] **Turn total caller (optional)** — After human submits a visit, speak/play visit total; Settings toggle, default off; respect sound gate.
- [x] **Leg vs match finish SFX** — `legFinishSoundToken` uses `playMatchFinished()` today; add leg-specific sound; reserve `game_finished` for match end.
- [x] **Bot zero visits** — `veryEasy` tier, `offBoardMissChance`, unit + mirror sim caps (in `477a2c5`).
- [x] **X01 live darts + avg** — VM has preview stats; verify UI updates per dart in simulator; fix binding or add UI test if not.

---

## Core product gaps

### History & statistics

- [x] **Statistics: in-progress / partial stats** — Active match darts/points merge into Statistics; games/wins unchanged until complete.
- [x] **History: player filter UI** — VM + tests exist; wire menu in `HistoryRootView` (mirror Statistics).
- [x] **History: push filters to SwiftData** — Map mode/date (and player) into `MatchHistoryFilter` instead of fetch-500-then-filter.
- [x] **History: pagination** — Load more / proper `emptyFiltered` when filters match nothing.
- [x] **All Games: in-progress row** — Resume section + optional tab badge when `fetchActiveMatch` non-nil.
- [ ] **Abandoned matches** — Optional list or purge policy (rows exist in DB, invisible in UI).
- [x] **Home: recent completed mini-list** — Optional `UIBlueprint` entry on setup home.
- [x] **Game detail per-player hit bars** — Per-player sector charts on game detail.

### Match setup & play

- [ ] **X01 total-score entry toggle** — Deferred; keep current per-dart entry.
- [ ] **Setup: reorder + remove roster** — Drag reorder; swipe remove; keep random order.
- [ ] **Settings: default X01/Cricket options** — Expose checkout, check-in, legs/sets, start score in Settings, or stop persisting unused fields.
- [x] **Bot-vs-bot guard** — Warn or block START when no human selected.
- [x] **Match Summary cold path** — Reload from `matchRepository` when `ActiveMatchStore` has no session.
- [ ] **Cricket setup variants** — e.g. Cut Throat (`CricketSpec`).
- [ ] **Bust / leg / set animations** — Bust is text banner only today.

### UI / UX / accessibility

- [ ] **iPad / landscape layouts**
- [ ] **Accessibility pass** — Follow `accessibility/accessibility_todo.md` (Phase 0–2); status in `accessibility/wcag-2.1-aa/`.
- [x] **Localize remaining English** — Home, History, Statistics, Match Summary, setup, game detail delete copy.
- [x] **Cricket nav title contrast** — dark toolbar on `CricketMatchScreen` (verify in Inspector / `Manual_todo.md`)
- [ ] **X01 layout dead space** — Gap between cards and pad on phone.
- [ ] **Setup flow** — Roster below START / tab bar; Add Bot vs START proximity; red START semantics.
- [ ] **Unify match exit chrome** — X01 chevron vs Cricket Cancel.
- [ ] **Match Summary stat parity** — Align winner/loser stat columns (e.g. Best Out).
- [x] **Empty-state CTAs** — History/Statistics “no games” → jump to Play.
- [ ] **Cricket one-screen fit (phone)** — Pin active row + pad; scroll grid only.
- [ ] **X01 player card legibility** — Tiny sets/legs/darts/avg on right.
- [ ] **Theme cohesion** — Settings light vs Play dark when preference is dark.
- [ ] **App icon finalization** — `Media.xcassets` / `assets/app-icons/`
- [ ] **Reduce Motion on summary celebration**
- [ ] **Cricket closure highlight** — Beyond `boardUpdated` text on `closureTransition`
- [ ] **Bot turn pacing** — Optional stagger + per-dart haptic (settings).
- [ ] **DesignSystem primitives** — `PrimaryActionButton`, `StatChip`, `ErrorBanner` (Phase 05 P1).

### Copy / quick fixes

- [x] **“Delete & Start” → abandon wording** — Behavior abandons; update `play.setup.activeConflict.*` + UITest.
- [x] **Bust banner** — Use `L10n.bustFeedback` instead of hardcoded `"BUST"`.
- [x] **`PlayHomeViewModel.emptyNoPlayers`** — Removed; setup roster empty state covers the UI.
- [x] **Tab labels vs spec** — “Play” / “History” tab items; History screen title aligned with blueprint.

---

## Testing

- [x] **`StatisticsViewModel`** — Breakdown, player/mode/period filters, partial active match, empty state.
- [x] **`HistoryListViewModel`** — Mode/date/player filters, pagination, DB filter mapping, empty/error states.
- [x] **`MatchSummaryViewModel` tests** — Cold-load, missing snapshot.
- [x] **`MigrationRecoveryViewModel` tests**
- [x] **UI: checkout → winner → summary**
- [x] **UI: Cricket grid scoring**
- [x] **UI: settings sound/haptics persistence**
- [x] **Repository contract tests** — SwiftData player/match/settings/stats contracts covered; expand as RepositorySpec evolves.
- [ ] **Snapshot tests** — Optional post UI lock

---

## Performance & data

- [ ] **Profile SwiftData per-call `ModelContext`** — If scoring feels sluggish under load.
- [ ] **Performance baselines** — `PerformanceMonitor` on history load + submit turn; fill Phase 06 report.
- [ ] **Stats aggregate rebuild utility** — Optional dev tool if cache drift matters (no `PlayerDailyAggregate` tables in 1.0).

---

## Release readiness (1.0)

- [ ] **RC smoke pass** — `specs/ReleaseGateChecklist.md` + `SmokeTestChecklist.md` on device.
- [ ] **Manual evidence** — `SmokeTestEvidenceTemplate.md` screenshots.
- [ ] **App Store metadata** — Icon, name, privacy disclosure (`AppStoreConnectSpec`, Phase 06 privacy checklist).
- [ ] **On-device reset wipe verification**
- [ ] **Commit bot tuning + Very Easy** — Done in `477a2c5`.

---

## Post-1.0 / deferred

- [ ] **Firebase Auth** — `specs/FirebaseBackendAnalyticsSpec.md`
- [ ] **Online play / Firebase SDKs** — `specs/OnlinePlaySpec.md`
- [ ] **AI camera auto-scoring** — `AutoScoringVisionSpec`
- [ ] **External display / AirPlay**
- [ ] **Voice caller (“180!”)** — Beyond turn-total optional caller above
- [ ] **Apple Watch / widgets / cloud sync** — Roadmap

---

## Housekeeping

- [ ] **Debug launch args policy** — `-seed_demo`, `-snapshot_*`, `-ui_test_reset` (debug vs Release).
- [ ] **XcodeGen team note** — `DartsScoreboard.xcodeproj/` gitignored; no `xcuserstate` in git.
- [ ] **Document in-progress + abandoned match rules** — Single active `inProgress`; abandoned rows accumulate.

---

## Sprint order

| Sprint | Focus |
|--------|--------|
| **A** | User feedback + commit bot tuning |
| **B** | History discoverability (player filter, in-progress, DB filters) |
| **C** | P4 layout + copy quick fixes |
| **D** | Release gate + testing gaps |
| **E** | Copy + history perf + ops evidence |
