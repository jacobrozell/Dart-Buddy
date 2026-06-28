# X01 & Cricket UI test phased plan

End-to-end UI coverage for locked-in X01 and Cricket gameplay, organized so tests stay maintainable as layout scales.

**Companion docs**

- Cursor rules: [`.cursor/rules/ui-test-writing.mdc`](../../.cursor/rules/ui-test-writing.mdc), [`.cursor/rules/gameplay-ui-test-identifiers.mdc`](../../.cursor/rules/gameplay-ui-test-identifiers.mdc)
- Layout: [`.cursor/rules/gameplay-layout-size-classes.mdc`](../../.cursor/rules/gameplay-layout-size-classes.mdc), [`docs/gameplay-layout-modes.md`](../gameplay-layout-modes.md)
- Manual undo smoke: [`docs/release/release_checklist.md`](../release/release_checklist.md) §1

**Existing suites (baseline)**

| File | Tests | Role |
|------|-------|------|
| `X01MatchUITests.swift` | 8 | Scoring, checkout, undo, landscape, inactive card |
| `CricketMatchUITests.swift` | 11 | Marks, continuation, setup chips, landscape, MPR |
| `PartyPack1_1SmokeUITests.swift` | 3 | Party Pack Play → X01 / Cricket / party / Raid / Around the Clock start |
| `RegressionUITests.swift` | 7+ | Bot undo, exit Stay, bust, landscape pad keys |
| `WCAGAccessibilityUITests.swift` | 40 | A11y audits + pad identifier contracts |
| `MatchSetupUITests.swift` | partial | Roster, bots, solo practice |

---

## Principles (read first)

### What UI tests own

- User can score, undo, exit, finish, and rematch through the real pad and navigation stack.
- Layout contracts: pinned active player, pad reachable, keys not collapsed in landscape.
- Accessibility identifiers and combined labels match product intent.

### What UI tests do **not** own

- Checkout route math, bust rules, cut-throat scoring, leg/set logic → **unit / integration**.
- Full 3-player Cricket synchronized completion → **unit** (`cricketUIEquivalentThreePlayerSynchronizedSweepCompletesMatch`).
- Every setup chip permutation → **ViewModel / chip enablement unit tests**.
- Pixel-perfect visual design → manual evidence (`accessibility/wcag-2.1-aa/evidence/`).

### Maintainability tactics

1. **Identifier-first queries** — never assert on marketing copy when an ID exists.
2. **Fat helpers, thin tests** — `UITestMenuSupport`, `WCAGAccessibilitySupport`, `UITestRegressionHelpers`.
3. **Fast presets** — 101 / 1-leg X01; 2-player Cricket; `-seed_players`.
4. **Combined-label assertions** — `scoreCard_active.label`, `cricket_column_active.label`.
5. **Tiered CI** — smoke + WCAG on PR; full match + landscape on nightly Pro Max.
6. **One layout assertion per regression** — frame checks only when a specific bug recurred.

---

## Regression catalog (git-history bugs)

Locks in UI coverage for bugs that regressed multiple times. Unit tests guard much of the bot/undo lifecycle; UI tests catch layout and match-screen behavior that only surface on simulators/devices.

**Implementation:** `Tests/UI/RegressionUITests.swift`, `Tests/UI/Support/UITestRegressionHelpers.swift`

| Area | Key commits | Unit coverage | UI status |
|------|-------------|---------------|-----------|
| Landscape X01/Cricket — phone treated as iPad side-by-side | `77a3d1b`, `cd9ca66`, `a777654`, `120f0b2` | `GameplayLayoutTests` | Phase 5 ✓ (X01 landscape) |
| Bot stuck on “throwing” after exit → Stay | `baae976`, `4c93b54` | `DartBotIntegrationTests` | Phase 5 ✓ |
| Undo breaks bot turns | `b53eaeb`, `c5cefd1` | `DartBotIntegrationTests` | Phase 5 ✓ |
| X01 bust freezes match | `b1f0352` | `DartBotIntegrationTests` | Phase 5 ✓ |
| Cricket ends too early | `72d7bd0` | Unit | `CricketMatchUITests` ✓ |
| 3+ player pinned active card | `32e712b` | Partial | Phase 4 (planned) |
| Setup clipping / sticky Start footer | `0b2519f`, `e7b86d1` | A11y layout tests | Phase 6 (planned) |
| Undo from match summary → resume | `2e5b059` | Lifecycle | Phase 5.3 (planned) |
| Consecutive bot visits | `30575cb` | Integration | Phase 5.2 (planned) |

**What stays unit-only:** bot engine miss logic (`120f0b2`), layout decision matrix (`GameplayLayoutTests`), full 3-player Cricket completion sweep.

**Regression launch args:** `-seed_players`, `-ui_test_disable_feedback`, `-ui_test_instant_bots`.

**Regression helpers:** `waitForBotVisitToComplete`, `dismissExitAlertStay`, `startAliceVersusEasyBotX01MatchForRegression`, `assertScoringKeysBelowPinnedArea`.

---

## Phase 0 — Foundation & contracts

**Goal:** Stable hooks and helper APIs so later phases touch one file per flow change.

**Duration:** 1 PR

### 0.1 Identifier gaps (app code)

| Task | File(s) | Identifier | Notes |
|------|---------|------------|-------|
| Header undo | `PlayViewHelpers.swift` | `match_undo` | Mirror `pad_undo`; WCAG label already exists |
| Checkout cycle | `CheckoutSuggestionBanner.swift` | ✓ `checkoutCycleButton` | Add UI test in Phase 2 only if needed |
| Cricket visit preview | `CricketTapPad` | `cricket_visit_preview` (optional) | Hidden from a11y tree; tests use pad + column label today |
| Closed mark | `CricketMarkCell` | defer | Label fragment `Closed` is enough for smoke |

### 0.2 Helper consolidation

| Helper | Location | Purpose |
|--------|----------|---------|
| `startTwoPlayerX01Match(from:)` | unify `WCAGAccessibilitySupport` + inline duplicates | Single entry for X01 match screen |
| `tapX01Segment(_:multiplier:)` | `UITestMenuSupport` | `pad_triple` + `pad_20` wrapper |
| `tapCricketSegment(_:multiplier:)` | `UITestMenuSupport` | DBL/TPL + segment |
| `submitX01Visit(segments:multipliers:)` | `UITestMenuSupport` | `[20,20,20]` style |
| `assertMatchSummaryVisible(winner:)` | already `assertMatchSummaryShowsWinner` | use everywhere |
| `tapRematch(in:)` | `UITestMenuSupport` | `matchSummaryRematch` + wait for pad |
| `tapSummaryDone(in:)` | `UITestMenuSupport` | returns to Play home |

### 0.3 Documentation & rules

- [x] `.cursor/rules/ui-test-writing.mdc`
- [x] `.cursor/rules/gameplay-ui-test-identifiers.mdc`
- [x] This plan

### 0.4 Optional: identifier contract unit test

`Tests/Unit/AccessibilityIdentifierContractTests.swift` — static list of required pad IDs (no UI launch). Catches accidental renames in refactors.

**Exit criteria:** Helpers documented; `match_undo` shipped; no duplicate `startTwoPlayer*` paths.

---

## Phase 1 — X01 core gameplay (P0)

**Goal:** Cover primary scoring paths not yet explicit in `X01MatchUITests`.

**Duration:** 1–2 PRs | **CI:** iPhone 17 | **File:** `X01MatchUITests.swift`

| # | Test method | Behavior | Assert via |
|---|-------------|----------|------------|
| 1.1 | `testX01TripleScoringUpdatesRemaining` | T20 on 101 → 41 | `scoreCard_active` label `41` |
| 1.2 | `testX01DoubleScoringUpdatesRemaining` | D20 on 101 → 61 | label |
| 1.3 | `testX01MissRecordsInVisit` | `pad_0` ×1 | `Visit total 0` or visit darts fragment |
| 1.4 | `testX01ThreeDartVisitAutoSubmits` | 20+20+20 | turn advances; Bob active |
| 1.5 | `testX01RematchFromSummary` | finish checkout → Rematch | `pad_20` + Alice active |
| 1.6 | `testX01SetupChipGridVisible` | expand options | `setup_startScoreChip`, `setup_checkoutChip`, `setup_legsChip` |
| 1.7 | `testX01HeaderUndoRemovesDart` | `match_undo` after one dart | remaining 101 (needs Phase 0.1) |

**Already covered (do not duplicate):** start + score, live average, undo via pad, checkout summary, inactive card visit, landscape exit/pad, 3-player pin.

**Exit criteria:** Phase 1 tests green on `DartBuddyCI`; no new frame assertions.

---

## Phase 2 — Cricket core gameplay (P0)

**Goal:** Pad-specific Cricket flows (Enter, points mode, rematch).

**Duration:** 1–2 PRs | **CI:** iPhone 17 | **File:** `CricketMatchUITests.swift`

| # | Test method | Behavior | Assert via |
|---|-------------|----------|------------|
| 2.1 | `testCricketEnterSubmitsPartialVisit` | 1× `cricket_bull` + `cricket_enter` | Bob active |
| 2.2 | `testCricketMissVisitAdvancesTurn` | 3× `cricket_miss` | opponent column active |
| 2.3 | `testCricketScoringModeShowsPoints` | points ON, hit opponent's open 20 | column label score fragment |
| 2.4 | `testCricketRematchFromSummary` | 2p quick win path or seeded | `cricket_20` after rematch |
| 2.5 | `testCricketUndoRemovesLastDart` | 2× 20, undo, 20 again | mark count via label |
| 2.6 | `testCricketDoubleSingleMark` | `cricket_double` + `cricket_19` | board label / column |

**Already covered:** triple-close, continuation 2p/3p, setup chips, cut-throat subtitle, bot throw, MPR/darts, landscape board + pad.

**Exit criteria:** Enter and rematch covered; no full-match-to-summary UI unless fast seeded path exists.

---

## Phase 3 — Shared match chrome (P1)

**Goal:** Exit, save, summary, and cross-mode consistency.

**Duration:** 1 PR | **Files:** `X01MatchUITests.swift`, `CricketMatchUITests.swift`, helpers

| # | Test method | Mode | Behavior |
|---|-------------|------|----------|
| 3.1 | `testX01ExitSaveAndResume` | X01 | Exit → Save & Exit → `resumeMatchButton` → same remaining |
| 3.2 | `testX01ExitAbandonReturnsHome` | X01 | Exit → Abandon → Play home |
| 3.3 | `testCricketExitSaveAndResume` | Cricket | same pattern |
| 3.4 | `testCricketExitAbandonReturnsHome` | Cricket | same |
| 3.5 | `testSummaryDoneReturnsToPlayHome` | both | `matchSummaryDone` |
| 3.6 | `testSummaryViewStatsOpensDetail` | X01 | existing post-match stats test pattern for Cricket |

**Partial coverage today:** `RegressionUITests` (Stay + bot), `testPostMatchStatsDeleteReturnsToPlayHome` (X01).

**Exit criteria:** Human exit paths for both modes; alert button queries use identifiers if added (`match_exit_stay`, etc.) or stable alert button titles documented in helpers.

---

## Phase 4 — Multi-player & scroll layout (P1)

**Goal:** 3–4 players without asserting game completion.

**Duration:** 1 PR | **CI:** iPhone 17 + **nightly Pro Max** for landscape

| # | Test method | Mode | Behavior |
|---|-------------|------|----------|
| 4.1 | `testThreePlayerX01AllPadKeysReachableInLandscape` | X01 | extend pin test; all `pad_*` hittable |
| 4.2 | `testThreePlayerCricketPinnedBoardVisibleInLandscape` | Cricket | `cricket_column_active` + pad (Pro Max) |
| 4.3 | `testFourPlayerX01ActiveCardVisible` | X01 | scroll scoreboard; `scoreCard_active` exists |
| 4.4 | `testFourPlayerCricketHorizontalScroll` | Cricket | swipe board; second column reachable |
| 4.5 | `testThreePlayerX01TurnRotation` | X01 | Alice → Bob → Carol via miss visits | label `BEGINSWITH` |

**Defer:** 4-player match completion, iPad side-by-side matrix (add when iPad layout locked).

**Exit criteria:** Pro Max nightly runs Phase 4.2 + 4.1; compact iPhone runs 4.3–4.5.

---

## Phase 5 — Bot & regression extension (P1)

**Goal:** Extend `RegressionUITests.swift` for bot/undo/landscape bugs from the regression catalog above.

**Duration:** 1 PR | **File:** `RegressionUITests.swift`

### Implemented (Phase 5a)

| Test | Maps to commit |
|------|----------------|
| `testX01BotVisitUndoStepsThroughRestoredDartsBeforePriorTurn` | `b53eaeb` |
| `testX01ExitAlertStayRecoversBotPlayback` | `baae976` |
| `testX01BustAdvancesToNextPlayer` | `b1f0352` |
| `testX01FullWidthPadKeysReachableInLandscape` | `77a3d1b`, `a777654` |
| `testX01LandscapeScoringRecordsDartFromWidePad` | `120f0b2` |
| `testCricketBotVisitUndoStepsThroughRestoredDarts` | `b53eaeb` (Cricket) |
| `testCricketExitAlertStayRecoversBotPlayback` | `baae976` (Cricket) |

### Planned (Phase 5b)

| # | Test method | Notes |
|---|-------------|-------|
| 5.1 | `testX01UndoBackToBotTurnRestartsBotPlayback` | Multiple `pad_undo` taps until bot turn replays |
| 5.2 | `testX01TwoBotsPlayConsecutivelyAfterHumanTurn` | `-enable_full_product_surface` |
| 5.3 | `testX01UndoFromSummaryResumesPlay` | `2e5b059` |
| 5.4 | `testCricketCutThroatBotFullVisit` | instant bots; pad re-enabled after |
| 5.5 | `testX01BotBustDoesNotFreezeMatch` | extends bust coverage with bot |

**Launch args:** `-seed_players`, `-ui_test_instant_bots`, `-ui_test_disable_feedback`.

**Exit criteria:** All regression catalog rows implemented or explicitly waived with unit-test link.

---

## Phase 6 — Setup & Play home flows (P2)

**Goal:** Match setup edge cases without chip combinatorics explosion.

**Duration:** 1 PR | **File:** `MatchSetupUITests.swift` + small smoke additions

| # | Test method | Behavior |
|---|-------------|----------|
| 6.1 | `testStartDisabledUntilTwoPlayers` | `startMatchButton` disabled with 0–1 players |
| 6.2 | `testX01ModeSwitchPreservesRoster` | X01 → Cricket → X01; Alice/Bob still selected |
| 6.3 | `testCricketNormalModeChipEnabledWhenPointsOn` | inverse of points-off test |
| 6.4 | `testResumeMatchPreservesMode` | `-seed_demo` resume → correct pad IDs |
| 6.5 | `testSoloCricketPracticeOneHuman` | mirror solo X01 test |

**Rule:** One test per *enablement rule*, not per chip value.

---

## Phase 7 — WCAG & identifier contracts (P2)

**Goal:** Prevent identifier drift; extend audits for new controls.

**Duration:** ongoing | **File:** `WCAGAccessibilityUITests.swift`

| # | Task | Trigger |
|---|------|---------|
| 7.1 | Pad key contract tests for any new pad layout variant | Pad refactor |
| 7.2 | `match_undo` reachability audit | Phase 0.1 |
| 7.3 | Summary rematch/done `assertInteractiveElement` | Phase 1.5 / 2.4 |
| 7.4 | iOS 26 Liquid Glass tab bar — keep audit filters updated | Chrome changes |
| 7.5 | AXXXL usability smoke for X01 + Cricket start | Dynamic Type |

**Exit criteria:** New gameplay control without WCAG coverage = incomplete PR.

---

## Phase 8 — CI matrix & ownership (P2)

**Goal:** Fast PR feedback; deep coverage nightly.

### PR gate (`DartBuddyCI` — iPhone 17)

- `PartyPack1_1SmokeUITests` (all) — on `release/*` via `DartBuddyUILean`; not in PR `DartBuddyCI`
- `WCAGAccessibilityUITests` (all)
- **Optional add after Phase 1:** `X01MatchUITests/testX01TripleScoringUpdatesRemaining`, `CricketMatchUITests/testCricketEnterSubmitsPartialVisit`

### Nightly (iPhone 17 Pro Max + iPhone 17)

| Bucket | Simulator | Suites |
|--------|-----------|--------|
| Landscape layout | iPhone 17 Pro Max | `RegressionUITests` landscape, `CricketMatchUITests` landscape, Phase 4 |
| Bot undo / exit / bust | iPhone 17 | `RegressionUITests` |
| Setup clipping | iPhone 17 compact | Phase 6 |
| Full match | iPhone 17 | `X01MatchUITests`, `CricketMatchUITests` |

### Pre-release manual (checklist only)

- Real device rotation during active match
- VoiceOver once per mode on production build
- Reduce Transparency / Increase Contrast spot check

---

## View → test matrix (quick reference)

### Setup (`SetupHomeView`)

| Screen | Phase | Key IDs |
|--------|-------|---------|
| Mode picker | smoke ✓ | `setup_changeModeButton` |
| Roster | smoke ✓ | `select_*`, `setup_selected_*` |
| X01 chips | 1.6 | `setup_startScoreChip`, … |
| Cricket chips | ✓ | `setup_cricket*Chip` |
| Start / Resume | 6.x | `startMatchButton`, `resumeMatchButton` |

### X01 match (`X01MatchScreen`)

| Zone | Phase | Key IDs |
|------|-------|---------|
| Header | 1.7, 3.x | `match_exit`, `match_undo` |
| Scoreboard | 1.x, 4.x | `scoreCard_active` |
| Banners | 5.x (regression) | bust hidden; checkout optional |
| Pad | 1.x | `pad_*` |
| Summary | 1.5, 3.5 | `matchSummary*` |

### Cricket match (`CricketMatchScreen`)

| Zone | Phase | Key IDs |
|------|-------|---------|
| Subtitle | ✓ | `cricket_match_subtitle` |
| Board | 2.x, 4.x | `cricket_column_active` |
| Pad | 2.x | `cricket_*` |
| Summary | 2.4, 3.x | `matchSummary*` |

### Shared summary (`MatchSummaryScreen`)

| Control | Phase | ID |
|---------|-------|-----|
| Winner | ✓ | `matchSummaryHeader` |
| Rematch | 1.5, 2.4 | `matchSummaryRematch` |
| Done | 3.5 | `matchSummaryDone` |
| Stats | 3.6 | button label (consider ID) |

---

## Implementation order (recommended)

```
Phase 0  ──► Phase 1 (X01) ──► Phase 2 (Cricket)     [ship first — highest value]
                │                    │
                └────────┬───────────┘
                         ▼
              Phase 3 (chrome) ──► Phase 5 (bots/regression)
                         │
                         ▼
              Phase 4 (multi-player, nightly)
                         │
                         ▼
              Phase 6 (setup) + Phase 7 (WCAG) + Phase 8 (CI tuning)
```

**Estimated new tests:** ~35–40 methods across Phases 1–6 (many helpers shared).

**Estimated maintenance cost:** Low if Phases 0–1 land first — later tests reuse `submitX01Visit`, `tapRematch`, exit helpers.

---

## Running locally

```bash
xcodegen generate

# Phase 1 slice
xcodebuild test -project DartBuddy.xcodeproj -scheme DartBuddy \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:DartBuddyUITests/X01MatchUITests

# Landscape / Phase 4 (Pro Max)
xcodebuild test -project DartBuddy.xcodeproj -scheme DartBuddy \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -only-testing:DartBuddyUITests/CricketMatchUITests/testCricketBoardVisibleInLandscape

# Regression suite only
xcodebuild test -project DartBuddy.xcodeproj -scheme DartBuddy \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:DartBuddyUITests/RegressionUITests

# Full UI suite
xcodebuild test -project DartBuddy.xcodeproj -scheme DartBuddy \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:DartBuddyUITests
```

---

## Changelog

| Date | Change |
|------|--------|
| 2026-06-11 | Merged regression catalog + Phase 5a/5b from former `regression-ui-test-plan.md` |
| 2026-06-11 | Initial phased plan; Cursor rules added |
