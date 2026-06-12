import XCTest

/// UI regression tests for bugs that have recurred in git history.
/// See `docs/testing/x01-cricket-ui-test-phased-plan.md` (Regression catalog + Phase 5).
final class RegressionUITests: DartBuddyUITestCase {
    // MARK: - Bot + undo (b53eaeb)

    func testX01BotVisitUndoStepsThroughRestoredDartsBeforePriorTurn() {
        let app = launchForRegression()
        startAliceVersusEasyBotX01MatchForRegression(from: app, timeout: timeout)

        submitMissVisit(on: app, timeout: timeout)
        waitForBotVisitToComplete(in: app, timeout: timeout)

        let undo = app.buttons["match_undo"]
        XCTAssertTrue(undo.waitForExistence(timeout: timeout))
        undo.tap()
        waitForBotVisitToComplete(in: app, timeout: timeout)

        assertActiveScoreCardNamesAlice(in: app, timeout: timeout)
    }

    func testCricketBotVisitUndoStepsThroughRestoredDarts() {
        let app = launchForRegression()
        ensurePlayTab(app, timeout: timeout)
        selectCricketMode(in: app, timeout: timeout)
        selectPlayerFromRoster("Alice", in: app, timeout: timeout)
        addEasyBot(from: app, timeout: timeout)
        tapStartMatch(in: app, timeout: timeout + 10)
        waitForRegressionCricketPadReady(app, timeout: timeout + 10)

        submitCricketMissVisit(in: app, timeout: timeout)
        waitForBotVisitToComplete(in: app, padKeyIdentifier: "cricket_20", timeout: timeout)

        let undo = app.buttons["match_undo"]
        XCTAssertTrue(undo.waitForExistence(timeout: timeout))
        undo.tap()
        waitForBotVisitToComplete(in: app, padKeyIdentifier: "cricket_20", timeout: timeout)

        waitForActiveCricketPlayer("Alice", in: app, timeout: timeout + 10)
    }

    // MARK: - Exit alert + Stay (baae976)

    func testX01ExitAlertStayRecoversBotPlayback() {
        let app = launchApp([
            "-seed_players",
            Self.disableFeedbackLaunchArgument,
        ])
        startAliceVersusEasyBotX01MatchForRegression(from: app, timeout: timeout)

        scoreSingleVisit(app, segments: [20, 20, 20], timeout: timeout)
        waitForBotVisitToComplete(in: app, timeout: timeout)

        dismissMatchExitStay(in: app, timeout: timeout)
        _ = waitForPadReady(app, timeout: timeout + 10)

        XCTAssertFalse(
            botThrowingBanner(in: app).waitForExistence(timeout: 2),
            "Stay should return to a stable human turn without a stuck bot banner"
        )
    }

    func testCricketExitAlertStayRecoversBotPlayback() {
        let app = launchForRegression()
        startAliceVersusEasyBotCricketMatchForRegression(from: app, timeout: timeout)

        submitCricketMissVisitAndInterruptWithExitStay(in: app, timeout: timeout)
        waitForBotVisitToComplete(in: app, padKeyIdentifier: "cricket_20", timeout: timeout)

        XCTAssertFalse(
            botThrowingBanner(in: app).waitForExistence(timeout: 2),
            "Bot throwing banner should clear after the cricket visit completes"
        )
    }

    // MARK: - X01 bust advance (b1f0352)

    func testX01BustAdvancesToNextPlayer() {
        let app = launchForRegression()
        configureStraightOut101Match(app, timeout: timeout)
        selectAliceAndBob(from: app, timeout: timeout)
        tapStartMatch(in: app, timeout: timeout)
        waitForX01MatchBoard(in: app, timeout: timeout + 15)

        scoreSingleVisit(app, segments: [20, 20, 20], timeout: timeout)
        submitMissVisit(on: app, timeout: timeout)
        _ = waitForPadReady(app, timeout: timeout + 5)

        scoreSingleVisit(app, segments: [20, 20, 5], timeout: timeout)

        _ = waitForPadReady(app, timeout: timeout + 15)
        let card = activeX01ScoreCard(in: app)
        XCTAssertTrue(card.waitForExistence(timeout: timeout))
        XCTAssertTrue(
            card.label.localizedCaseInsensitiveContains("Bob"),
            "Bob should be up after Alice busts (got '\(card.label)')"
        )
    }

    // MARK: - Landscape pad layout (77a3d1b, a777654, 120f0b2)

    func testX01FullWidthPadKeysReachableInLandscape() {
        let app = launchForRegression()
        startTwoPlayerX01MatchForRegression(from: app, timeout: timeout)

        rotateToLandscapeLeftForTest(app: app)
        addTeardownBlock {
            XCUIDevice.shared.orientation = .portrait
        }

        let active = app.otherElements["scoreCard_active"]
        XCTAssertTrue(active.waitForExistence(timeout: timeout))
        let pad = waitForPadReady(app, timeout: timeout + 10)
        XCTAssertGreaterThanOrEqual(
            pad.frame.minY,
            active.frame.maxY - 8,
            "Scoring pad should sit below the pinned active card in landscape"
        )

        let keyIdentifiers = [
            "pad_20", "pad_19", "pad_18", "pad_17", "pad_16", "pad_15",
            "pad_25", "pad_0", "pad_double", "pad_triple", "pad_undo"
        ]
        assertScoringKeysBelowPinnedArea(active, in: app, keyIdentifiers: keyIdentifiers, timeout: timeout)

        let undo = app.buttons["pad_undo"]
        XCTAssertGreaterThan(undo.frame.height, 28, "Undo should not collapse to a thin bar in landscape")
    }

    func testX01LandscapeScoringRecordsDartFromWidePad() {
        let app = launchForRegression()
        startTwoPlayerX01MatchForRegression(from: app, timeout: timeout)

        rotateToLandscapeLeftForTest(app: app)
        addTeardownBlock {
            XCUIDevice.shared.orientation = .portrait
        }

        let twenty = waitForPadReady(app, timeout: timeout + 10)
        twenty.tap()

        assertActiveScoreCardLabel(app, contains: "81", timeout: timeout)
    }

    // MARK: - Phase 5 regression extension

    func testX01UndoFromSummaryResumesPlay() {
        let app = launchForRegression()
        finishQuickX01Checkout(for: app, timeout: timeout)

        undoFromMatchSummary(in: app, timeout: timeout)
        _ = waitForPadReady(app, timeout: timeout + 15)
        XCTAssertFalse(
            app.otherElements["matchSummaryHeader"].waitForExistence(timeout: 2),
            "Undo from summary should return to the live match board"
        )
    }

    func testCricketCutThroatBotFullVisit() {
        let app = launchForRegression()
        ensurePlayTab(app, timeout: timeout)
        selectCricketMode(in: app, timeout: timeout)
        tapCricketCutThroatMode(in: app)
        selectPlayerFromRoster("Alice", in: app, timeout: timeout)
        addEasyBot(from: app, timeout: timeout)
        tapStartMatch(in: app, timeout: timeout + 10)
        waitForRegressionCricketPadReady(app, timeout: timeout + 10)

        submitCricketMissVisit(in: app, timeout: timeout)
        waitForBotVisitToComplete(in: app, padKeyIdentifier: "cricket_20", timeout: timeout + 20)
        XCTAssertTrue(app.buttons["cricket_20"].isEnabled)
    }

    func testX01BotVisitCompletesWithoutFreezingPad() {
        let app = launchForRegression()
        startAliceVersusEasyBotX01MatchForRegression(from: app, timeout: timeout)

        submitMissVisit(on: app, timeout: timeout)
        waitForBotVisitToComplete(in: app, timeout: timeout)

        XCTAssertFalse(
            botThrowingBanner(in: app).waitForExistence(timeout: 2),
            "Bot banner should clear after the visit"
        )
        XCTAssertTrue(app.buttons["pad_20"].isEnabled, "Human pad should re-enable after bot visit")
    }

    func testX01TwoBotsPlayConsecutivelyAfterHumanTurn() {
        let app = launchAppWithFullProductSurface([
            "-seed_players",
            Self.disableFeedbackLaunchArgument,
            Self.instantBotsLaunchArgument
        ])
        ensurePlayTab(app, timeout: timeout)
        configureFastX01MatchForUITest(app, timeout: timeout)
        selectPlayerFromRoster("Alice", in: app, timeout: timeout)
        addEasyBot(from: app, timeout: timeout)
        addEasyBot(from: app, timeout: timeout)
        tapStartMatch(in: app, timeout: timeout)
        waitForX01MatchBoard(in: app, timeout: timeout + 15)

        submitMissVisit(on: app, timeout: timeout)
        waitForBotVisitToComplete(in: app, timeout: timeout + 20)
        waitForBotVisitToComplete(in: app, timeout: timeout + 20)

        XCTAssertTrue(
            app.buttons["pad_20"].isEnabled,
            "Pad should re-enable after consecutive bot visits"
        )
    }
}
