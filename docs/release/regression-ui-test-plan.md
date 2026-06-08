# Regression UI test plan

Locks in UI coverage for bugs that have regressed multiple times in git history. Unit tests already guard much of the bot/undo lifecycle; this plan adds **end-to-end UI tests** for layout and match-screen behavior that only surface on simulators/devices.

**Related:** [`release_checklist.md`](release_checklist.md) §1 (manual undo smoke), [`.cursor/rules/gameplay-layout-size-classes.mdc`](../../.cursor/rules/gameplay-layout-size-classes.mdc), nightly UI workflow (Pro Max landscape).

**Implementation:** `Tests/UI/RegressionUITests.swift`, `Tests/UI/Support/UITestRegressionHelpers.swift`

---

## Regression catalog

| Area | Key commits | Unit coverage | UI before this plan |
|------|-------------|---------------|---------------------|
| Landscape X01/Cricket — phone treated as iPad side-by-side | `77a3d1b`, `cd9ca66`, `a777654`, `120f0b2` | `GameplayLayoutTests` | Cricket: strong. X01: partial |
| Bot stuck on “throwing” after exit → Stay | `baae976`, `4c93b54` | `DartBotIntegrationTests` | Pad-disable only |
| Undo breaks bot turns | `b53eaeb`, `c5cefd1` | `DartBotIntegrationTests` | Human undo only |
| X01 bust freezes match | `b1f0352` | `DartBotIntegrationTests` | None |
| Cricket ends too early | `72d7bd0` | Unit | `CricketMatchUITests` ✓ |
| 3+ player pinned active card | `32e712b` | Partial | X01 portrait/landscape pin |
| Setup clipping / sticky Start footer | `0b2519f`, `e7b86d1` | A11y layout tests | Swipe workarounds only |
| Undo from match summary → resume | `2e5b059` | Lifecycle | None |
| Consecutive bot visits | `30575cb` | Integration | None |

---

## Phase 1 — P0 (implemented)

| Test | File | Maps to |
|------|------|---------|
| `testX01BotVisitUndoStepsThroughRestoredDartsBeforePriorTurn` | `RegressionUITests` | `b53eaeb` |
| `testX01ExitAlertStayRecoversBotPlayback` | `RegressionUITests` | `baae976` |
| `testX01BustAdvancesToNextPlayer` | `RegressionUITests` | `b1f0352` |
| `testX01FullWidthPadKeysReachableInLandscape` | `RegressionUITests` | `77a3d1b`, `a777654` |
| `testX01LandscapeScoringRecordsDartFromWidePad` | `RegressionUITests` | `120f0b2` |
| `testCricketBotVisitUndoStepsThroughRestoredDarts` | `RegressionUITests` | `b53eaeb` (Cricket) |
| `testCricketExitAlertStayRecoversBotPlayback` | `RegressionUITests` | `baae976` (Cricket; interrupts bot chain via exit on third miss) |

**Launch args:** `-seed_players`, `-ui_test_disable_feedback` (haptics/sound off, fast bot stagger), `-ui_test_instant_bots` (zero bot/closure delays).

**Helpers:** `waitForBotVisitToComplete`, `dismissExitAlertStay`, `startAliceVersusEasyBotX01MatchForRegression`, `assertScoringKeysBelowPinnedArea`.

---

## Phase 2 — P1 (planned)

| Test | Notes |
|------|-------|
| `testX01UndoBackToBotTurnRestartsBotPlayback` | Multiple `pad_undo` taps until bot turn replays |
| `testThreePlayerCricketPinnedBoardVisibleInLandscape` | Pro Max nightly |
| `testThreePlayerX01AllPadKeysReachableInLandscape` | Extend existing pin test |

---

## Phase 3 — P2 (planned)

| Test | Notes |
|------|-------|
| `testFourPlayerTurnOrderRowsVisibleWithoutScrolling` | Compact simulator (`iPhone 17`) |
| `testX01UndoFromSummaryResumesPlay` | `2e5b059` |
| `testX01TwoBotsPlayConsecutivelyAfterHumanTurn` | Full product surface |

---

## Simulator matrix

| Bucket | Simulator | Workflow |
|--------|-----------|----------|
| Landscape layout | iPhone 17 Pro Max | Nightly UI (required for regular-width phone landscape) |
| Bot undo / exit / bust | iPhone 17 | CI + nightly |
| Setup clipping | iPhone 17 compact | CI |

---

## What stays unit-only

- Bot engine miss logic (`120f0b2`)
- Layout decision matrix (`GameplayLayoutTests`)
- Full 3-player Cricket completion sweep (slow; covered in unit tests)

---

## Running locally

```bash
xcodegen generate
# Phase 1 regression suite only:
xcodebuild test -project DartBuddy.xcodeproj -scheme DartBuddy \
  -destination 'platform=iOS Simulator,name=iPhone 17' \
  -only-testing:DartBuddyUITests/RegressionUITests

# Landscape tests (Pro Max):
xcodebuild test -project DartBuddy.xcodeproj -scheme DartBuddy \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -only-testing:DartBuddyUITests/RegressionUITests/testX01FullWidthPadKeysReachableInLandscape
```
