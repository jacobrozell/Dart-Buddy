import XCTest

final class X01MatchUITests: DartBuddyUITestCase {
    func testStartMatchAndScoreTurn() {
        let app = launchForAccessibility(extraArguments: ["-seed_players"])

        configureFastX01MatchForUITest(app, timeout: timeout)
        ensurePlayTab(app, timeout: timeout)
        selectAliceAndBob(from: app, timeout: timeout)

        let start = app.buttons["startMatchButton"]
        waitForStartEnabled(start, timeout: timeout)
        start.tap()
        _ = waitForPadReady(app, timeout: timeout + 15)

        app.buttons["pad_20"].tap()

        assertActiveScoreCardLabel(app, contains: "81", timeout: timeout)
    }

    func testX01LiveDartsAndAverageUpdatePerDart() {
        let app = launchApp(["-seed_players"])
        ensurePlayTab(app, timeout: timeout)
        configureFastX01MatchForUITest(app, timeout: timeout)

        selectAliceAndBob(from: app, timeout: timeout)
        let start = app.buttons["startMatchButton"]
        waitForStartEnabled(start, timeout: timeout)
        start.tap()
        waitForX01MatchBoard(in: app, timeout: timeout + 15)

        let twenty = app.buttons["pad_20"]
        XCTAssertTrue(twenty.waitForExistence(timeout: timeout))
        twenty.tap()

        assertActiveScoreCardLabel(app, contains: "81", timeout: timeout)
        assertActiveScoreCardLabel(app, contains: "Visit total 20", timeout: timeout)
        assertActiveScoreCardLabel(app, contains: "1 darts thrown", timeout: timeout)
        assertActiveScoreCardLabel(app, contains: "Three-dart average 20.00", timeout: timeout)
        assertActiveScoreCardLabel(app, contains: "Visit darts 20", timeout: timeout)

        twenty.tap()
        assertActiveScoreCardLabel(app, contains: "61", timeout: timeout)
        assertActiveScoreCardLabel(app, contains: "Visit total 40", timeout: timeout)
        assertActiveScoreCardLabel(app, contains: "2 darts thrown", timeout: timeout)
        assertActiveScoreCardLabel(app, contains: "Visit darts 20, 20", timeout: timeout)
    }

    func testCheckoutShowsWinnerSummary() {
        let app = launchApp(["-seed_players"])
        finishQuickX01Checkout(for: app, timeout: timeout)

        assertMatchSummaryShowsWinner("Alice", in: app, timeout: timeout)
        XCTAssertTrue(app.buttons["New Match"].waitForExistence(timeout: timeout))
    }

    func testPostMatchStatsDeleteReturnsToPlayHome() {
        let app = launchApp(["-seed_players"])
        finishQuickX01Checkout(for: app, timeout: timeout)

        app.buttons["View Game Statistics"].tap()
        XCTAssertTrue(app.staticTexts["Game Statistics"].waitForExistence(timeout: timeout))

        scrollToDeleteButton(app)
        app.buttons["historyDetailDeleteButton"].tap()
        let confirm = app.alerts.buttons["Delete"]
        XCTAssertTrue(confirm.waitForExistence(timeout: timeout))
        confirm.tap()

        XCTAssertTrue(
            assertBrandAppTitleVisible(in: app, timeout: timeout),
            "Deleting from post-match stats should return to Play home"
        )
        XCTAssertFalse(
            app.staticTexts["Game Statistics"].waitForExistence(timeout: 2),
            "Stats screen should be dismissed after delete"
        )
        XCTAssertFalse(
            app.otherElements["matchSummaryHeader"].waitForExistence(timeout: 2),
            "Match summary should be dismissed after delete"
        )
    }

    func testUndoRemovesEnteredDart() {
        let app = launchApp(["-seed_players"])
        configureFastX01MatchForUITest(app, timeout: timeout)

        selectAliceAndBob(from: app, timeout: timeout)
        let start = app.buttons["startMatchButton"]
        waitForStartEnabled(start, timeout: timeout)
        start.tap()
        waitForX01MatchBoard(in: app, timeout: timeout + 15)

        let nineteen = app.buttons["pad_19"]
        XCTAssertTrue(nineteen.waitForExistence(timeout: timeout))
        nineteen.tap()

        app.buttons["pad_undo"].tap()
        assertX01MatchConfigSummaryVisible(in: app, timeout: timeout)
        assertActiveScoreCardLabel(app, contains: "101", timeout: timeout)
    }

    func testThreePlayerX01PinnedActiveCardVisibleInLandscape() {
        let app = launchApp(["-seed_players"])
        startThreePlayerX01Match(from: app)

        XCUIDevice.shared.orientation = .landscapeLeft
        addTeardownBlock {
            XCUIDevice.shared.orientation = .portrait
        }

        let active = app.otherElements["scoreCard_active"]
        XCTAssertTrue(active.waitForExistence(timeout: timeout), "Active score card should exist")
        _ = waitForPadReady(app, timeout: timeout + 10)
        let pad = app.buttons["pad_20"]
        XCTAssertTrue(
            pad.frame.minY >= active.frame.maxY - 8,
            "Scoring pad should sit below the pinned active card in landscape"
        )
        XCTAssertTrue(app.buttons["pad_20"].waitForExistence(timeout: timeout))
    }

    func testX01ExitAndPadReachableInLandscape() {
        let app = launchApp(["-seed_players"])
        configureFastX01MatchForUITest(app, timeout: timeout)

        selectAliceAndBob(from: app, timeout: timeout)
        let start = app.buttons["startMatchButton"]
        waitForStartEnabled(start, timeout: timeout)
        start.tap()
        waitForX01MatchBoard(in: app, timeout: timeout + 15)

        XCUIDevice.shared.orientation = .landscapeLeft
        addTeardownBlock {
            XCUIDevice.shared.orientation = .portrait
        }

        let exit = app.buttons["match_exit"]
        XCTAssertTrue(exit.waitForExistence(timeout: timeout))
        XCTAssertTrue(exit.isHittable, "Exit control should stay visible in landscape")
        let pad = waitForPadReady(app, timeout: timeout + 10)
        XCTAssertTrue(pad.exists, "Scoring pad should remain reachable in landscape")
    }

    func testCompletedVisitPersistsOnInactiveScoreCard() {
        let app = launchApp(["-seed_players"])
        configureFastX01MatchForUITest(app, timeout: timeout)

        selectAliceAndBob(from: app, timeout: timeout)
        let start = app.buttons["startMatchButton"]
        waitForStartEnabled(start, timeout: timeout)
        start.tap()
        waitForX01MatchBoard(in: app, timeout: timeout + 15)

        scoreSingleVisit(app, segments: [20, 20, 20], timeout: timeout)

        XCTAssertTrue(app.otherElements["scoreCard_active"].waitForExistence(timeout: timeout + 5))

        let aliceCard = inactiveX01ScoreCards(in: app).matching(
            NSPredicate(format: "label CONTAINS[c] %@ AND label CONTAINS %@", "Alice", "Visit total 60")
        ).firstMatch
        XCTAssertTrue(
            aliceCard.waitForExistence(timeout: timeout),
            "Alice's completed visit should remain visible on the inactive score card after Bob's turn begins"
        )
    }
}
