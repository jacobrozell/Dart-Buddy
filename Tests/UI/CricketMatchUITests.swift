import XCTest

final class CricketMatchUITests: DartBuddyUITestCase {
    /// Submits one visit that triple-closes three number targets (20, 19, 18).
    private func waitForActivePlayer(_ name: String, in app: XCUIApplication, timeout: TimeInterval) {
        let column = app.otherElements["cricket_column_active"]
        XCTAssertTrue(column.waitForExistence(timeout: timeout))
        let predicate = NSPredicate(format: "label BEGINSWITH[c] %@", name)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: column)
        XCTAssertEqual(XCTWaiter.wait(for: [expectation], timeout: timeout), .completed)
    }

    private func submitTripleCloseVisit(
        targets: [String],
        in app: XCUIApplication,
        timeout: TimeInterval
    ) {
        XCTAssertEqual(targets.count, 3)
        waitForCricketScoringPadReady(app, timeout: timeout)
        app.buttons["cricket_triple"].tap()
        for target in targets {
            let key = app.buttons["cricket_\(target)"]
            XCTAssertTrue(key.waitForExistence(timeout: timeout))
            key.tap()
        }
        waitForCricketScoringPadReady(app, timeout: timeout + 5)
    }

    /// Submits one visit that closes the bull (two inner-bull marks).
    private func submitBullCloseVisit(in app: XCUIApplication, timeout: TimeInterval) {
        waitForCricketScoringPadReady(app, timeout: timeout)
        let bull = app.buttons["cricket_bull"]
        XCTAssertTrue(bull.waitForExistence(timeout: timeout))
        for _ in 0 ..< 2 {
            app.buttons["cricket_double"].tap()
            bull.tap()
        }
        app.buttons["cricket_enter"].tap()
        let summary = app.otherElements["matchSummaryHeader"]
        if summary.waitForExistence(timeout: 3) { return }
        waitForCricketScoringPadReady(app, timeout: timeout + 5)
    }

    private func closeAllCricketTargets(in app: XCUIApplication, timeout: TimeInterval) {
        submitTripleCloseVisit(targets: ["20", "19", "18"], in: app, timeout: timeout)
        submitTripleCloseVisit(targets: ["17", "16", "15"], in: app, timeout: timeout)
        submitBullCloseVisit(in: app, timeout: timeout)
    }

    private func submitMissVisit(in app: XCUIApplication, timeout: TimeInterval) {
        waitForCricketScoringPadReady(app, timeout: timeout)
        let miss = app.buttons["cricket_miss"]
        XCTAssertTrue(miss.waitForExistence(timeout: timeout))
        miss.tap()
        miss.tap()
        miss.tap()
        waitForCricketScoringPadReady(app, timeout: timeout + 5)
    }

    /// Closes every target for whoever is active, skipping `(playerCount - 1)` opponents between close visits.
    private func closeAllCricketTargetsForCurrentPlayer(
        in app: XCUIApplication,
        playerCount: Int,
        timeout: TimeInterval
    ) {
        submitTripleCloseVisit(targets: ["20", "19", "18"], in: app, timeout: timeout)
        for _ in 0 ..< (playerCount - 1) {
            submitMissVisit(in: app, timeout: timeout)
        }
        submitTripleCloseVisit(targets: ["17", "16", "15"], in: app, timeout: timeout)
        for _ in 0 ..< (playerCount - 1) {
            submitMissVisit(in: app, timeout: timeout)
        }
        submitBullCloseVisit(in: app, timeout: timeout)
    }

    /// Each player closes the same target group in turn order.
    private func runSynchronizedCloseSweep(in app: XCUIApplication, playerCount: Int, timeout: TimeInterval) {
        for targets in [["20", "19", "18"], ["17", "16", "15"]] {
            for _ in 0 ..< playerCount {
                submitTripleCloseVisit(targets: targets, in: app, timeout: timeout)
            }
        }
        for _ in 0 ..< playerCount {
            submitBullCloseVisit(in: app, timeout: timeout)
        }
    }

    func testCricketMatchContinuesAfterFirstPlayerClosesAllTargets() {
        let app = launchApp(["-seed_players"])

        startTwoPlayerCricketMatch(from: app)

        closeAllCricketTargets(in: app, timeout: timeout)

        XCTAssertFalse(
            app.otherElements["matchSummaryHeader"].waitForExistence(timeout: 2),
            "Match should not end until every player has closed all targets"
        )
        waitForActivePlayer("Bob", in: app, timeout: timeout + 10)
        XCTAssertTrue(app.buttons["cricket_20"].isEnabled, "Opponent should still be able to score")
    }

    func testCricketGridScoringRecordsMarks() {
        let app = launchApp(["-seed_players"])

        startTwoPlayerCricketMatch(from: app)

        let target20 = app.buttons["cricket_20"]
        XCTAssertTrue(target20.waitForExistence(timeout: timeout))
        target20.tap()

        XCTAssertTrue(app.staticTexts["20"].waitForExistence(timeout: timeout), "Visit preview should show the entered dart")

        target20.tap()
        target20.tap()

        let closedMark = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", "Closed"))
            .firstMatch
        XCTAssertTrue(
            closedMark.waitForExistence(timeout: timeout + 5),
            "Three marks on 20 should close the target on the board"
        )
    }

    func testThreePlayerCricketMatchContinuesAfterFirstPlayerClosesAllTargets() {
        let app = launchApp(["-seed_players"])

        startThreePlayerCricketMatch(from: app)

        closeAllCricketTargetsForCurrentPlayer(in: app, playerCount: 3, timeout: timeout)

        XCTAssertFalse(
            app.otherElements["matchSummaryHeader"].waitForExistence(timeout: 2),
            "Match should not end until every player has closed all targets"
        )
        waitForActivePlayer("Bob", in: app, timeout: timeout + 10)
        XCTAssertTrue(app.buttons["cricket_20"].isEnabled, "Opponent should still be able to score")
    }

    // Full 3-player Cricket completion is covered by unit tests
    // (`cricketUIEquivalentThreePlayerSynchronizedSweepCompletesMatch`); a UI replay is
    // slow and brittle in CI. Continuation after the first finisher is asserted above.

    func testCricketSetupChipGridVisible() {
        let app = launchApp(["-seed_players"])
        selectCricketMode(in: app, timeout: timeout)
        expandSetupOptions(in: app, timeout: timeout)
        assertSetupChip("setup_cricketPointsChip", in: app, timeout: timeout)
        assertSetupChip("setup_cricketModeChip", in: app, timeout: timeout)
        assertSetupChip("setup_cricketSetLegChip", in: app, timeout: timeout)
        assertSetupChip("setup_cricketSetsChip", in: app, timeout: timeout)
        assertSetupChip("setup_cricketLegsChip", in: app, timeout: timeout)
    }

    func testCricketPointsOffDisablesModeChip() {
        let app = launchApp(["-seed_players"])
        selectCricketMode(in: app, timeout: timeout)
        tapCricketPointsOff(in: app)
        let modeChip = app.descendants(matching: .any)["setup_cricketModeChip"]
        XCTAssertTrue(modeChip.waitForExistence(timeout: timeout))
        XCTAssertFalse(modeChip.isEnabled)
    }

    func testCricketCutThroatSubtitleOnMatchStart() {
        let app = launchApp(["-seed_players"])
        selectCricketMode(in: app, timeout: timeout)
        tapCricketCutThroatMode(in: app)
        selectPlayerFromRoster("Alice", in: app)
        selectPlayerFromRoster("Bob", in: app)
        tapStartMatch(in: app, timeout: timeout)
        let subtitle = app.staticTexts["cricket_match_subtitle"]
        XCTAssertTrue(subtitle.waitForExistence(timeout: timeout))
        XCTAssertTrue(subtitle.label.contains("Cut Throat") || subtitle.label.contains("Lowest"))
    }

    func testCutThroatCricketBotMatchStartsAndBotThrows() {
        let app = launchApp(["-seed_players", Self.instantBotsLaunchArgument])
        selectCricketMode(in: app)
        tapCricketCutThroatMode(in: app)
        selectPlayerFromRoster("Alice", in: app)
        addEasyBot(from: app, timeout: timeout)
        tapStartMatch(in: app, timeout: timeout + 10)
        XCTAssertTrue(app.buttons["cricket_20"].waitForExistence(timeout: timeout + 10))

        let padDisabledHint = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] %@", "bot")
        ).firstMatch
        let padKey = app.buttons["cricket_20"]
        let botTurnActive = padDisabledHint.waitForExistence(timeout: timeout + 15)
            || !padKey.isEnabled
        XCTAssertTrue(botTurnActive, "Bot should take the opening cut-throat visit")
    }

    func testCricketLiveMprAndDartsIdentifiersOnActiveColumn() {
        let app = launchApp(["-seed_players"])
        startTwoPlayerCricketMatch(from: app)
        submitTripleCloseVisit(targets: ["20", "19", "18"], in: app, timeout: timeout)
        let column = activeCricketColumn(in: app)
        XCTAssertTrue(column.waitForExistence(timeout: timeout + 5))
        XCTAssertTrue(
            column.label.contains("3 darts"),
            "Active cricket column should announce darts thrown in its combined label (got '\(column.label)')"
        )
        XCTAssertTrue(
            column.label.contains("marks per round"),
            "Active cricket column should announce MPR in its combined label (got '\(column.label)')"
        )
    }

    func testCricketBoardVisibleInLandscape() {
        let app = launchApp(["-seed_players"])
        startTwoPlayerCricketMatch(from: app)
        XCTAssertTrue(app.buttons["cricket_20"].waitForExistence(timeout: timeout))

        XCUIDevice.shared.orientation = .landscapeLeft
        addTeardownBlock {
            XCUIDevice.shared.orientation = .portrait
        }

        // iPhone landscape pins the active player's board at the top with the full-width
        // pad below it (X01-style), so both stay on screen at once.
        // Run on Pro Max (or Plus-class) simulators: they report regular horizontal size class
        // in landscape — the case that previously picked the iPad side-by-side layout.
        let column = app.otherElements["cricket_column_active"]
        XCTAssertTrue(column.waitForExistence(timeout: timeout))
        XCTAssertTrue(column.isHittable, "Active player board should stay locked at the top in landscape")
        XCTAssertTrue(app.buttons["cricket_20"].isHittable, "Scoring pad should remain reachable below the board")

        let enter = app.buttons["cricket_enter"]
        XCTAssertTrue(enter.waitForExistence(timeout: timeout))
        XCTAssertGreaterThan(enter.frame.height, 32, "Enter should not collapse to a thin bar in landscape")

        // The pad sits above the board's footer; assert the keys are below the active board header.
        XCTAssertGreaterThan(
            enter.frame.minY,
            column.frame.minY,
            "Keyboard should be pinned below the current player's board in iPhone landscape"
        )

        let columnLabel = column.label
        XCTAssertTrue(
            columnLabel.contains("darts"),
            "Player footer stats should be spoken on the active column in landscape (got '\(columnLabel)')"
        )
        XCTAssertTrue(
            column.isHittable,
            "Transposed active-player board should keep footer stats on screen in iPhone landscape"
        )
    }

    func testCricketFullWidthPadKeysReachableInLandscape() {
        let app = launchApp(["-seed_players"])
        startTwoPlayerCricketMatch(from: app)
        XCTAssertTrue(app.buttons["cricket_20"].waitForExistence(timeout: timeout))

        XCUIDevice.shared.orientation = .landscapeLeft
        addTeardownBlock {
            XCUIDevice.shared.orientation = .portrait
        }

        let column = app.otherElements["cricket_column_active"]
        XCTAssertTrue(column.waitForExistence(timeout: timeout))

        // The full-width landscape pad lays every Cricket key out below the board.
        let keyIdentifiers = [
            "cricket_20", "cricket_19", "cricket_18",
            "cricket_17", "cricket_16", "cricket_15",
            "cricket_bull", "cricket_miss",
            "cricket_double", "cricket_triple", "cricket_undo", "cricket_enter"
        ]
        for identifier in keyIdentifiers {
            let key = app.buttons[identifier]
            XCTAssertTrue(key.waitForExistence(timeout: timeout), "\(identifier) should exist in landscape")
            XCTAssertTrue(key.isHittable, "\(identifier) should be reachable in the full-width landscape pad")
            XCTAssertGreaterThan(
                key.frame.minY,
                column.frame.minY,
                "\(identifier) should sit below the pinned current-player board"
            )
        }
    }

    func testCricketLandscapeScoringRecordsMarkFromWidePad() {
        let app = launchApp(["-seed_players"])
        startTwoPlayerCricketMatch(from: app)
        XCTAssertTrue(app.buttons["cricket_20"].waitForExistence(timeout: timeout))

        XCUIDevice.shared.orientation = .landscapeLeft
        addTeardownBlock {
            XCUIDevice.shared.orientation = .portrait
        }

        let target20 = app.buttons["cricket_20"]
        XCTAssertTrue(target20.waitForExistence(timeout: timeout))
        XCTAssertTrue(target20.isHittable)
        target20.tap()
        target20.tap()
        target20.tap()

        let closedMark = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", "Closed"))
            .firstMatch
        XCTAssertTrue(
            closedMark.waitForExistence(timeout: timeout + 5),
            "Scoring three 20s from the landscape pad should close the target on the board"
        )
    }
}
