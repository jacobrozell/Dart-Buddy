import XCTest

final class X01MatchUITests: DartBuddyUITestCase {
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
        XCTAssertTrue(app.buttons["Rematch"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons["Done"].waitForExistence(timeout: timeout))
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

        rotateToLandscapeLeft(for: app, timeout: timeout)
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

        rotateToLandscapeLeft(for: app, timeout: timeout)
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

    // MARK: - Phase 1 core gameplay

    func testX01TripleScoringUpdatesRemaining() {
        let app = launchApp(["-seed_players"])
        startTwoPlayerX01Match(from: app, timeout: timeout)

        tapX01Segment(20, multiplier: .triple, in: app, timeout: timeout)
        assertActiveScoreCardLabel(app, contains: "41", timeout: timeout)
    }

    func testX01DoubleScoringUpdatesRemaining() {
        let app = launchApp(["-seed_players"])
        startTwoPlayerX01Match(from: app, timeout: timeout)

        tapX01Segment(20, multiplier: .double, in: app, timeout: timeout)
        assertActiveScoreCardLabel(app, contains: "61", timeout: timeout)
    }

    func testX01MissRecordsInVisit() {
        let app = launchApp(["-seed_players"])
        startTwoPlayerX01Match(from: app, timeout: timeout)

        app.buttons["pad_0"].tap()
        assertActiveScoreCardLabel(app, contains: "Visit darts Miss", timeout: timeout)
    }

    func testX01ThreeDartVisitAutoSubmits() {
        let app = launchApp(["-seed_players"])
        startTwoPlayerX01Match(from: app, timeout: timeout)

        scoreSingleVisit(app, segments: [20, 20, 20], timeout: timeout)
        waitForActiveX01Player("Bob", in: app, timeout: timeout + 10)
    }

    func testX01RematchFromSummary() {
        let app = launchApp(["-seed_players"])
        configureQuickX01Match(app, timeout: timeout)
        ensurePlayTab(app, timeout: timeout)
        selectAliceAndBob(from: app, timeout: timeout)
        tapStartMatch(in: app, timeout: timeout)
        waitForX01MatchBoard(in: app, timeout: timeout + 15)

        scoreSingleVisit(app, segments: [20, 20, 20], timeout: timeout)
        submitMissVisit(on: app, timeout: timeout)
        _ = waitForPadReady(app, timeout: timeout + 5)
        scoreSingleVisit(app, segments: [20, 20, 1], timeout: timeout)

        XCTAssertTrue(
            app.otherElements["matchSummaryHeader"].waitForExistence(timeout: timeout + 10),
            "Match summary should appear after checkout"
        )
        tapRematch(in: app, timeout: timeout)
        XCTAssertTrue(app.buttons["match_exit"].waitForExistence(timeout: timeout + 15))
        XCTAssertTrue(
            app.buttons["pad_20"].waitForExistence(timeout: timeout + 15),
            "Rematch should return to the X01 scoring pad"
        )
    }

    func testX01SetupChipGridVisible() {
        let app = launchApp(["-seed_players"])
        ensurePlayTab(app, timeout: timeout)
        expandSetupOptions(in: app, timeout: timeout)
        assertSetupChip("setup_startScoreChip", in: app, timeout: timeout)
        assertSetupChip("setup_checkoutChip", in: app, timeout: timeout)
        assertSetupChip("setup_legsChip", in: app, timeout: timeout)
    }

    func testX01HeaderUndoRemovesDart() {
        let app = launchApp(["-seed_players"])
        startTwoPlayerX01Match(from: app, timeout: timeout)

        app.buttons["pad_19"].tap()
        app.buttons["match_undo"].tap()
        assertActiveScoreCardLabel(app, contains: "101", timeout: timeout)
    }

    // MARK: - Phase 4 multi-player

    func testThreePlayerX01AllPadKeysReachableInLandscape() {
        let app = launchApp(["-seed_players"])
        startThreePlayerX01Match(from: app)

        rotateToLandscapeLeft(for: app, timeout: timeout)
        addTeardownBlock {
            XCUIDevice.shared.orientation = .portrait
        }

        let active = app.otherElements["scoreCard_active"]
        XCTAssertTrue(active.waitForExistence(timeout: timeout))
        let keyIdentifiers = [
            "pad_20", "pad_19", "pad_18", "pad_17", "pad_16", "pad_15",
            "pad_25", "pad_0", "pad_double", "pad_triple", "pad_undo"
        ]
        assertScoringKeysBelowPinnedArea(active, in: app, keyIdentifiers: keyIdentifiers, timeout: timeout)
    }

    func testThreePlayerX01TurnRotation() {
        let app = launchApp(["-seed_players"])
        startThreePlayerX01Match(from: app)

        submitMissVisit(on: app, timeout: timeout)
        waitForActiveX01Player("Bob", in: app, timeout: timeout + 10)
        submitMissVisit(on: app, timeout: timeout)
        waitForActiveX01Player("Carol", in: app, timeout: timeout + 10)
    }

    func testThreePlayerX01InactiveCardsVisible() {
        let app = launchApp(["-seed_players"])
        startThreePlayerX01Match(from: app)

        XCTAssertTrue(app.otherElements["scoreCard_active"].waitForExistence(timeout: timeout))
        let inactiveNames = ["Bob", "Carol"]
        for name in inactiveNames {
            let card = inactiveX01ScoreCards(in: app).matching(
                NSPredicate(format: "label CONTAINS[c] %@", name)
            ).firstMatch
            XCTAssertTrue(
                card.waitForExistence(timeout: timeout),
                "Inactive score card for \(name) should remain in the scoreboard"
            )
        }
    }
}
