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
        app.buttons["cricket_double"].tap()
        bull.tap()
        Thread.sleep(forTimeInterval: 0.15)
        bull.tap()
        app.buttons["cricket_enter"].tap()
        waitForCricketPadReady(app, timeout: timeout + 5)
    }

    private func closeAllCricketTargets(in app: XCUIApplication, timeout: TimeInterval) {
        submitTripleCloseVisit(targets: ["20", "19", "18"], in: app, timeout: timeout)
        submitTripleCloseVisit(targets: ["17", "16", "15"], in: app, timeout: timeout)
        submitBullCloseVisit(in: app, timeout: timeout)
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
}
