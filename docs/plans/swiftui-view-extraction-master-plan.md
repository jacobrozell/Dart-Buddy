# SwiftUI view extraction — master plan

**Status:** In progress (Phases 0–7 done; 8–10 open)  
**Created:** 2026-07-01  
**Last updated:** 2026-10-27  
**Supersedes / extends:** [`release-build-view-decomposition-plan.md`](release-build-view-decomposition-plan.md) Phase 5

Pure refactor. No behavior, copy, or `accessibilityIdentifier` changes.

---

## Why

SwiftUI re-evaluates a whole `View` when any of its inputs change. Computed `private var section: some View` properties share the parent's invalidation boundary. Separate `struct` types get their own.

**Goal:** thin shell views that compose named child structs, each in its own file when non-trivial.

| Signal | Target |
|--------|--------|
| Shell views | `body` ~30–50 lines; delegates immediately |
| Subviews | No computed `some View` property over ~40 lines |
| Presentation | One `.sheet(item:)` enum per host layer |
| Contracts | All `accessibilityIdentifier` values unchanged |
| Files | No SwiftUI view file over ~450 lines |

Not in scope: view model / domain refactors ([`tier-1-scalability-refactor-plan.md`](tier-1-scalability-refactor-plan.md)), visual redesign, Android.

---

## Rules

Extract to its own file + struct when the subview is over ~40–60 lines, owns `@State` / `@Binding`, is reused, carries its own identifiers, or the parent is over ~400 lines.

Keep computed properties only for 2–10 lines of layout glue.

1. Split types, not extensions.
2. Push state down, callbacks up. Shell owns sheets, alerts, and `Task`s.
3. One presentation surface per layer.
4. Never rename identifiers ([`Tests/UI/Support/UITestMenuSupport.swift`](../../Tests/UI/Support/UITestMenuSupport.swift)).
5. Run `xcodegen generate` after adding files.

---

## Phases

| Phase | Scope | Status |
|-------|-------|--------|
| 0 | This doc, index rows, supersede note | Done |
| 1 | `PlayMatchRouteView` | Done — [`Scripts/generate_play_match_route_view.py`](../../Scripts/generate_play_match_route_view.py) emits a thin dispatcher, one `Features/Play/Setup/Routes/{Mode}MatchRouteView.swift` per mode, and `Features/Play/Shared/MatchRouteScreen.swift`. The generator now covers all 31 modes (it was missing the 1.2 modes) |
| 2 | Activity tab | Done — `ActivitySegmentChrome`, `ActivityHistoryContent`, `ActivityStatisticsContent`, `StatisticsTablesContent` own files; root keeps view models, filters, and tasks |
| 3 | Match summary | Done — `MatchSummaryCelebrationHeader`, `MatchSummaryPlayerCard`, `MatchSummaryAchievementsSection`, `MatchSummaryActions`; screen is the layout router |
| 4 | Setup roster | Done — `SetupSelectedRosterContent` + `SetupRosterTurnOrderList`, `SetupAvailablePlayersContent`, `SetupRosterActionButtons`; section is a ~40 line shell |
| 5 | Players tab | Done — single `PlayersSheet` enum (`customBot`, `player`, `export`) and `PlayersListRow` |
| 6 | Players files | Done — `CustomBotViews.swift` and `PlayerVisualViews.swift` split by component |
| 7 | Settings | Done — `SettingsDuringPlaySection`, `SettingsBotOpponentsSection`, `SettingsDataSection`, `SettingsHelpAndFeedbackSection`, `SettingsAboutSection`, `SettingsSectionFooter`. Gameplay-default pickers stay in the root (they share `queueGameplayDefaults`) |
| 8 | Match screens batch | Open — shared `MatchStatusBannersView`, X01/Cricket first, then per-mode shells; `ForfeitSheetHost` in `MatchLifecycleChrome` |
| 9 | History / stats / design system | Open — `MatchHistoryDetailScreen`, `MatchHistoryCard`, `StatsChartViews`, `StatTable` |
| 10 | Setup chips | Opportunistic — refactor `Setup*OptionChips` when that mode is touched |

### Phase 8 notes

Most `{Mode}MatchScreen` files have 1–3 banner computed properties (`statusBanners`, `botTurnBanner`, `checkoutBanner`). Build `MatchStatusBannersView` from a small config struct, prove it on X01 and Cricket, then batch by family. Prioritize Killer, Golf, English Cricket, Cricket, Fleet. Also: `PlayerScoreCard` sub-structs, `DartNumberPad` / `CricketTapPad` regions, `VisualDartboardInput` overlays.

---

## Per-PR workflow

1. List computed subviews + line counts in the parent.
2. Create child struct file(s); copy body verbatim.
3. Replace the computed property with `ChildView(…)`.
4. Move `@State` down only if the child is the sole consumer.
5. Debug build, then the targeted UI test.
6. Release build if the file was over 400 lines.
7. One screen family per PR.

## Testing

- `DartBuddyCI` unit tests (Debug)
- `MatchSetupUITests`, `PartyPack1_1SmokeUITests` after setup / players phases
- Release whole-module build
- Manual: iPhone + iPad + landscape tab roots; AXXXL primary flows; VoiceOver focus order on extracted sections; setup → match → summary → history detail
