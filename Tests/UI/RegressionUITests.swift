import XCTest

/// UI regression tests for bugs that have recurred in git history.
/// See `docs/release/regression-ui-test-plan.md`.
final class RegressionUITests: DartBuddyUITestCase {
    // MARK: - Bot + undo (b53eaeb)

    func testX01BotVisitUndoStepsThroughRestoredDartsBeforePriorTurn() {
        let app = launchForRegression()
        startAliceVersusEasyBotX01MatchForRegression(from: app, timeout: timeout)

        submitMissVisit(on: app, timeout: timeout)
        waitForBotVisitToComplete(in: app, timeout: timeout)

        let undo = app.buttons["pad_undo"]
        XCTAssertTrue(undo.waitForExistence(timeout: timeout))
        undo.tap()
        assertActiveScoreCardNamesBot(in: app, timeout: timeout)

        undo.tap()
        assertActiveScoreCardNamesBot(in: app, timeout: timeout)
        XCTAssertFalse(
            activeX01ScoreCard(in: app).label.localizedCaseInsensitiveContains("Alice"),
            "Undo should step through bot darts before returning to Alice's prior turn"
        )
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

        let undo = app.buttons["cricket_undo"]
        XCTAssertTrue(undo.waitForExistence(timeout: timeout))
        undo.tap()

        let column = activeCricketColumn(in: app)
        XCTAssertTrue(column.waitForExistence(timeout: timeout))
        let label = column.label
        XCTAssertTrue(
            label.localizedCaseInsensitiveContains("DartBot")
                || label.localizedCaseInsensitiveContains("Easy")
                || label.localizedCaseInsensitiveContains("Bot"),
            "Undo should restore the bot visit instead of jumping to the prior player (got '\(label)')"
        )

        undo.tap()
        let columnAfterSecondUndo = activeCricketColumn(in: app)
        XCTAssertTrue(columnAfterSecondUndo.waitForExistence(timeout: timeout))
        let secondLabel = columnAfterSecondUndo.label
        XCTAssertTrue(
            secondLabel.localizedCaseInsensitiveContains("DartBot")
                || secondLabel.localizedCaseInsensitiveContains("Easy")
                || secondLabel.localizedCaseInsensitiveContains("Bot"),
            "Second undo should still be on the restored bot visit (got '\(secondLabel)')"
        )
    }

    // MARK: - Exit alert + Stay (baae976)

    func testX01ExitAlertStayRecoversBotPlayback() {
        let app = launchForRegression()
        startAliceVersusEasyBotX01MatchForRegression(from: app, timeout: timeout)

        submitMissVisit(on: app, timeout: timeout)

        let pad = app.buttons["pad_20"]
        XCTAssertTrue(pad.waitForExistence(timeout: timeout))
        let botStarted = botThrowingBanner(in: app).waitForExistence(timeout: timeout + 15)
            || !pad.isEnabled
        XCTAssertTrue(botStarted, "Bot should begin throwing after the human visit")

        dismissExitAlertStay(in: app, timeout: timeout)
        waitForBotVisitToComplete(in: app, timeout: timeout)

        XCTAssertFalse(
            botThrowingBanner(in: app).waitForExistence(timeout: 2),
            "Bot throwing banner should clear after the visit completes"
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

        rotateToLandscapeLeftForTest()
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

        rotateToLandscapeLeftForTest()
        addTeardownBlock {
            XCUIDevice.shared.orientation = .portrait
        }

        let twenty = waitForPadReady(app, timeout: timeout + 10)
        twenty.tap()

        assertActiveScoreCardLabel(app, contains: "81", timeout: timeout)
    }
}
