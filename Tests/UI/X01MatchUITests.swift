import XCTest

final class X01MatchUITests: DartBuddyUITestCase {
    func testStartMatchAndScoreTurn() {
        let app = launchApp(["-seed_players"])

        XCTAssertTrue(app.staticTexts["Dart Scoreboard"].waitForExistence(timeout: timeout))

        app.buttons["select_Alice"].tap()
        app.buttons["select_Bob"].tap()

        let start = app.buttons["startMatchButton"]
        XCTAssertTrue(start.waitForExistence(timeout: timeout))
        XCTAssertTrue(start.isEnabled, "START should be enabled with two players selected")
        start.tap()

        XCTAssertTrue(
            app.staticTexts["501, Double Out, First to 3 Legs"].waitForExistence(timeout: timeout),
            "X01 board should display the match configuration"
        )

        let twenty = app.buttons["pad_20"]
        XCTAssertTrue(twenty.waitForExistence(timeout: timeout))
        twenty.tap()
        twenty.tap()
        twenty.tap()

        XCTAssertTrue(
            app.staticTexts["441"].waitForExistence(timeout: timeout),
            "After scoring 3x20 the remaining score should be 441"
        )
    }

    func testX01LiveDartsAndAverageUpdatePerDart() {
        let app = launchApp(["-seed_players"])
        ensurePlayTab(app, timeout: timeout)

        app.buttons["select_Alice"].tap()
        app.buttons["select_Bob"].tap()
        app.buttons["startMatchButton"].tap()

        let twenty = app.buttons["pad_20"]
        XCTAssertTrue(twenty.waitForExistence(timeout: timeout))
        twenty.tap()

        XCTAssertEqual(app.staticTexts["scoreCard_remaining"].label, "481")
        XCTAssertEqual(app.staticTexts["scoreCard_visitTotal"].label, "20")
        XCTAssertEqual(app.staticTexts["scoreCard_dartsThrown"].label, "1")
        XCTAssertEqual(app.staticTexts["scoreCard_average"].label, "60.00")
        XCTAssertEqual(app.staticTexts["scoreCard_dartSlot_0"].label, "20")

        twenty.tap()
        XCTAssertEqual(app.staticTexts["scoreCard_remaining"].label, "461")
        XCTAssertEqual(app.staticTexts["scoreCard_visitTotal"].label, "40")
        XCTAssertEqual(app.staticTexts["scoreCard_dartsThrown"].label, "2")
        XCTAssertEqual(app.staticTexts["scoreCard_average"].label, "60.00")
        XCTAssertEqual(app.staticTexts["scoreCard_dartSlot_1"].label, "20")
    }

    func testCheckoutShowsWinnerSummary() {
        let app = launchApp(["-seed_players"])
        finishQuickX01Checkout(for: app, timeout: timeout)

        XCTAssertTrue(app.staticTexts["Alice wins!"].waitForExistence(timeout: timeout))
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
            app.staticTexts["Dart Scoreboard"].waitForExistence(timeout: timeout),
            "Deleting from post-match stats should return to Play home"
        )
        XCTAssertFalse(
            app.staticTexts["Game Statistics"].waitForExistence(timeout: 2),
            "Stats screen should be dismissed after delete"
        )
        XCTAssertFalse(
            app.staticTexts["Alice wins!"].waitForExistence(timeout: 2),
            "Match summary should be dismissed after delete"
        )
    }

    func testUndoRemovesEnteredDart() {
        let app = launchApp(["-seed_players"])

        app.buttons["select_Alice"].tap()
        app.buttons["select_Bob"].tap()
        app.buttons["startMatchButton"].tap()

        let nineteen = app.buttons["pad_19"]
        XCTAssertTrue(nineteen.waitForExistence(timeout: timeout))
        nineteen.tap()

        app.buttons["pad_undo"].tap()
        XCTAssertTrue(app.staticTexts["501, Double Out, First to 3 Legs"].exists)
    }
}
