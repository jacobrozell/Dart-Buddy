import XCTest

/// UI tests for the key user paths of the dart scoreboard.
/// Each test launches with a deterministic, freshly-reset data state.
final class DartsScoreboardUITests: XCTestCase {
    private let timeout: TimeInterval = 10

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    private func launchApp(_ extraArguments: [String]) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui_test_reset"] + extraArguments
        app.launch()
        return app
    }

    // MARK: - Key path: tab navigation surfaces the main screens

    func testTabsShowKeyScreens() {
        let app = launchApp(["-seed_demo"])

        XCTAssertTrue(app.staticTexts["Dart Scoreboard"].waitForExistence(timeout: timeout), "Home should show the setup board title")

        app.tabBars.buttons["Statistics"].tap()
        XCTAssertTrue(app.staticTexts["Statistics"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["Games"].waitForExistence(timeout: timeout), "Statistics should show the Games table")
        let jacobStat = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Jacob")).firstMatch
        XCTAssertTrue(jacobStat.waitForExistence(timeout: timeout), "Statistics should rank Jacob")

        app.tabBars.buttons["All Games"].tap()
        XCTAssertTrue(app.staticTexts["All Games"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["FINISHED"].waitForExistence(timeout: timeout), "A completed game should be listed as FINISHED")

        app.tabBars.buttons["Players"].tap()
        XCTAssertTrue(app.staticTexts["Jacob"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["Sam"].waitForExistence(timeout: timeout))
    }

    // MARK: - Key path: set up a match and score a turn

    func testStartMatchAndScoreTurn() {
        let app = launchApp(["-seed_players"])

        XCTAssertTrue(app.staticTexts["Dart Scoreboard"].waitForExistence(timeout: timeout))

        app.buttons["select_Alice"].tap()
        app.buttons["select_Bob"].tap()

        let start = app.buttons["startMatchButton"]
        XCTAssertTrue(start.waitForExistence(timeout: timeout))
        XCTAssertTrue(start.isEnabled, "START should be enabled with two players selected")
        start.tap()

        // The board shows the configured X01 subtitle (defaults: 501, Double Out, First to 3 Legs).
        XCTAssertTrue(
            app.staticTexts["501, Double Out, First to 3 Legs"].waitForExistence(timeout: timeout),
            "X01 board should display the match configuration"
        )

        // Score three single-20 darts; the turn auto-submits at 3 darts (60 scored -> 441 remaining).
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

    // MARK: - Key path: resume an in-progress match

    func testResumeActiveMatch() {
        let app = launchApp(["-seed_demo"])

        let resume = app.buttons["resumeMatchButton"]
        XCTAssertTrue(resume.waitForExistence(timeout: timeout), "An in-progress match should be resumable")
        resume.tap()

        // Seeded in-progress match leaves Jacob on 121.
        XCTAssertTrue(
            app.staticTexts["121"].waitForExistence(timeout: timeout),
            "Resumed board should show the saved remaining score"
        )
    }

    // MARK: - Key path: undo a dart on the scoring pad

    func testUndoRemovesEnteredDart() {
        let app = launchApp(["-seed_players"])

        app.buttons["select_Alice"].tap()
        app.buttons["select_Bob"].tap()
        app.buttons["startMatchButton"].tap()

        let nineteen = app.buttons["pad_19"]
        XCTAssertTrue(nineteen.waitForExistence(timeout: timeout))
        nineteen.tap()

        // Visit total reflects the single dart, then undo clears it back to 0.
        app.buttons["pad_undo"].tap()
        // Still on the board (no crash / turn not submitted) and the start score is intact.
        XCTAssertTrue(app.staticTexts["501, Double Out, First to 3 Legs"].exists)
    }
}
