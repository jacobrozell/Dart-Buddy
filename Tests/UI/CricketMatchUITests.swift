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

    private func waitForCricketPadReady(_ app: XCUIApplication, timeout: TimeInterval) {
        let key = app.buttons["cricket_20"]
        XCTAssertTrue(key.waitForExistence(timeout: timeout))
        XCTAssertTrue(key.wait(for: \.isEnabled, toEqual: true, timeout: timeout + 5))
        // Closure transitions briefly disable human input between visits.
        Thread.sleep(forTimeInterval: 0.75)
    }

    private func submitTripleCloseVisit(
        targets: [String],
        in app: XCUIApplication,
        timeout: TimeInterval
    ) {
        XCTAssertEqual(targets.count, 3)
        waitForCricketPadReady(app, timeout: timeout)
        app.buttons["cricket_triple"].tap()
        for target in targets {
            let key = app.buttons["cricket_\(target)"]
            XCTAssertTrue(key.waitForExistence(timeout: timeout))
            key.tap()
            Thread.sleep(forTimeInterval: 0.15)
        }
        // Three darts auto-submit; wait for the pad to return before the next visit.
        waitForCricketPadReady(app, timeout: timeout + 5)
    }

    /// Submits one visit that closes the bull (two inner-bull marks).
    private func submitBullCloseVisit(in app: XCUIApplication, timeout: TimeInterval) {
        waitForCricketPadReady(app, timeout: timeout)
        let bull = app.buttons["cricket_bull"]
        XCTAssertTrue(bull.waitForExistence(timeout: timeout))
        for _ in 0 ..< 2 {
            app.buttons["cricket_double"].tap()
            Thread.sleep(forTimeInterval: 0.35)
            bull.tap()
            Thread.sleep(forTimeInterval: 0.15)
        }
        app.buttons["cricket_enter"].tap()
        let summary = app.otherElements["matchSummaryHeader"]
        if summary.waitForExistence(timeout: 3) { return }
        waitForCricketPadReady(app, timeout: timeout + 5)
    }

    private func closeAllCricketTargets(in app: XCUIApplication, timeout: TimeInterval) {
        submitTripleCloseVisit(targets: ["20", "19", "18"], in: app, timeout: timeout)
        submitTripleCloseVisit(targets: ["17", "16", "15"], in: app, timeout: timeout)
        submitBullCloseVisit(in: app, timeout: timeout)
    }

    private func submitMissVisit(in app: XCUIApplication, timeout: TimeInterval) {
        waitForCricketPadReady(app, timeout: timeout)
        let miss = app.buttons["cricket_miss"]
        XCTAssertTrue(miss.waitForExistence(timeout: timeout))
        miss.tap()
        Thread.sleep(forTimeInterval: 0.15)
        miss.tap()
        Thread.sleep(forTimeInterval: 0.15)
        miss.tap()
        waitForCricketPadReady(app, timeout: timeout + 5)
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

        app.buttons["setup_mode_cricket"].tap()
        app.buttons["select_Alice"].tap()
        app.buttons["select_Bob"].tap()
        app.buttons["startMatchButton"].tap()

        XCTAssertTrue(app.buttons["cricket_20"].waitForExistence(timeout: timeout))

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

        app.buttons["setup_mode_cricket"].tap()
        app.buttons["select_Alice"].tap()
        app.buttons["select_Bob"].tap()
        app.buttons["startMatchButton"].tap()

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
        selectCricketMode(in: app)
        XCTAssertTrue(app.buttons["setup_cricketPointsChip"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons["setup_cricketModeChip"].exists)
        XCTAssertTrue(app.buttons["setup_cricketSetLegChip"].exists)
        XCTAssertTrue(app.buttons["setup_cricketSetsChip"].exists)
        XCTAssertTrue(app.buttons["setup_cricketLegsChip"].exists)
    }

    func testCricketPointsOffDisablesModeChip() {
        let app = launchApp(["-seed_players"])
        selectCricketMode(in: app)
        tapCricketPointsOff(in: app)
        XCTAssertFalse(app.buttons["setup_cricketModeChip"].isEnabled)
    }

    func testCricketCutThroatSubtitleOnMatchStart() {
        let app = launchApp(["-seed_players"])
        selectCricketMode(in: app)
        tapCricketCutThroatMode(in: app)
        startTwoPlayerCricketMatch(from: app)
        let subtitle = app.staticTexts["cricket_match_subtitle"]
        XCTAssertTrue(subtitle.waitForExistence(timeout: timeout))
        XCTAssertTrue(subtitle.label.contains("Cut Throat") || subtitle.label.contains("Lowest"))
    }

    func testCricketLiveMprAndDartsIdentifiersOnActiveColumn() {
        let app = launchApp(["-seed_players"])
        startTwoPlayerCricketMatch(from: app)
        submitTripleCloseVisit(targets: ["20", "19", "18"], in: app, timeout: timeout)
        let darts = app.staticTexts["cricket_column_darts"]
        let mpr = app.staticTexts["cricket_column_mpr"]
        XCTAssertTrue(darts.waitForExistence(timeout: timeout + 5))
        XCTAssertTrue(mpr.exists)
    }
}
