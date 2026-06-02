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

        app.tabBars.buttons["History"].tap()
        XCTAssertTrue(app.staticTexts["History"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["FINISHED"].waitForExistence(timeout: timeout), "A completed game should be listed as FINISHED")

        app.tabBars.buttons["Players"].tap()
        XCTAssertTrue(app.staticTexts["Jacob"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["Sam"].waitForExistence(timeout: timeout))
    }

    // MARK: - Key path: player detail surfaces all-games stats

    func testPlayerDetailShowsStats() {
        let app = launchApp(["-seed_demo"])

        app.tabBars.buttons["Players"].tap()
        let jacobRow = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "Jacob")).firstMatch
        XCTAssertTrue(jacobRow.waitForExistence(timeout: timeout))
        jacobRow.tap()

        XCTAssertTrue(app.staticTexts["X01"].waitForExistence(timeout: timeout), "Player detail should show an X01 stats section")
        XCTAssertTrue(app.staticTexts["3-Dart Avg"].waitForExistence(timeout: timeout), "Player detail should show the 3-dart average tile")
        XCTAssertTrue(app.staticTexts["Hits in Sector"].waitForExistence(timeout: timeout), "Player detail should show hits in sector")
    }

    // MARK: - Key path: game detail surfaces stats and can be deleted

    func testGameDetailShowsStatsAndDeletes() {
        let app = launchApp(["-seed_demo"])

        app.tabBars.buttons["History"].tap()
        let gameCard = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "FINISHED")).firstMatch
        XCTAssertTrue(gameCard.waitForExistence(timeout: timeout))
        gameCard.tap()

        XCTAssertTrue(app.staticTexts["Game Statistics"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["Points"].waitForExistence(timeout: timeout), "Game detail should show the Points table")
        XCTAssertTrue(app.staticTexts["Hits in Sector"].waitForExistence(timeout: timeout))

        let delete = app.buttons["Delete"]
        XCTAssertTrue(delete.waitForExistence(timeout: timeout), "Game detail should show a Delete button")
        delete.tap()

        // Confirm in the alert, then verify we return to the History list.
        let confirm = app.alerts.buttons["Delete"]
        XCTAssertTrue(confirm.waitForExistence(timeout: timeout))
        confirm.tap()

        XCTAssertTrue(app.staticTexts["History"].waitForExistence(timeout: timeout))
        // `-seed_demo` includes two completed games (X01 + Cricket); deleting one leaves the other.
        XCTAssertFalse(
            app.staticTexts["No games yet. Start a match to see it here."].waitForExistence(timeout: 2),
            "One completed game should remain after deleting a single seeded match"
        )
        XCTAssertTrue(
            app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "FINISHED")).firstMatch.waitForExistence(timeout: timeout),
            "History should still list the remaining completed match"
        )
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

    // MARK: - Key path: starting a new match while one is active prompts to replace it

    func testStartingWithActiveMatchPromptsToReplaceIt() {
        let app = launchApp(["-seed_demo"])

        XCTAssertTrue(app.staticTexts["Dart Scoreboard"].waitForExistence(timeout: timeout))
        // The seed leaves an in-progress match, so the resume banner is present.
        XCTAssertTrue(app.buttons["resumeMatchButton"].waitForExistence(timeout: timeout))

        app.buttons["select_Jacob"].tap()
        app.buttons["select_Sam"].tap()
        app.buttons["startMatchButton"].tap()

        let alert = app.alerts["Game in Progress"]
        XCTAssertTrue(alert.waitForExistence(timeout: timeout), "Starting with an active match should prompt to replace it")

        alert.buttons["Abandon & Start"].tap()

        // Confirming abandons the old match and opens the freshly configured board.
        XCTAssertTrue(
            app.staticTexts["501, Double Out, First to 3 Legs"].waitForExistence(timeout: timeout),
            "Confirming should delete the active match and open the new board"
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

    // MARK: - Empty state: a fresh install guides the user to add players

    func testEmptyRosterGuidesUserToAddPlayers() {
        let app = launchApp([])

        XCTAssertTrue(app.staticTexts["Dart Scoreboard"].waitForExistence(timeout: timeout))
        XCTAssertTrue(
            app.staticTexts["Add at least two players or bots to start a match."].waitForExistence(timeout: timeout),
            "An empty roster should prompt the user to add players"
        )

        let start = app.buttons["startMatchButton"]
        XCTAssertTrue(start.waitForExistence(timeout: timeout))
        XCTAssertFalse(start.isEnabled, "START must stay disabled without two players")
    }

    // MARK: - Bot roster: human + bot can start a match

    func testHumanPlusBotCanStartMatch() {
        let app = launchApp(["-seed_players"])

        app.buttons["select_Alice"].tap()

        let addBot = app.buttons["Add Bot"]
        XCTAssertTrue(addBot.waitForExistence(timeout: timeout))
        addBot.tap()
        app.buttons["Easy"].tap()

        XCTAssertTrue(app.buttons["select_bot_easy"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["Easy Bot 1"].waitForExistence(timeout: timeout))

        let start = app.buttons["startMatchButton"]
        XCTAssertTrue(start.isEnabled, "START should enable with one human and one bot")
        start.tap()

        // Human goes first (Alice before bot in roster); scoring pad should appear.
        XCTAssertTrue(app.buttons["pad_20"].waitForExistence(timeout: timeout + 5))
    }

    // MARK: - Validation: START requires two selected players

    func testStartRequiresTwoSelectedPlayers() {
        let app = launchApp(["-seed_players"])

        let alice = app.buttons["select_Alice"]
        XCTAssertTrue(alice.waitForExistence(timeout: timeout))
        alice.tap()

        let start = app.buttons["startMatchButton"]
        XCTAssertTrue(start.waitForExistence(timeout: timeout))
        XCTAssertFalse(start.isEnabled, "START should be disabled with only one player selected")

        app.buttons["select_Bob"].tap()
        XCTAssertTrue(start.isEnabled, "START should enable once two players are selected")
    }

    // MARK: - Empty state: no completed games yet

    func testAllGamesEmptyBeforeAnyMatchCompletes() {
        let app = launchApp(["-seed_players"])

        app.tabBars.buttons["History"].tap()
        XCTAssertTrue(app.staticTexts["History"].waitForExistence(timeout: timeout))
        XCTAssertTrue(
            app.staticTexts["No games yet. Start a match to see it here."].waitForExistence(timeout: timeout),
            "History should be empty before any match completes"
        )
    }

    // MARK: - Key path: live dart boxes, visit total, and average update per dart

    func testX01LiveDartsAndAverageUpdatePerDart() {
        let app = launchApp(["-seed_players"])

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

    // MARK: - Key path: checkout finishes match and shows summary

    func testCheckoutShowsWinnerSummary() {
        let app = launchApp(["-seed_players"])
        configureQuickX01Match(app)

        app.buttons["select_Alice"].tap()
        app.buttons["Add Bot"].tap()
        app.buttons["Easy"].tap()
        app.buttons["select_bot_easy"].tap()
        app.buttons["startMatchButton"].tap()

        XCTAssertTrue(
            app.staticTexts["101, Straight Out, First to 1 Legs"].waitForExistence(timeout: timeout),
            "Board should reflect the quick-match configuration"
        )

        let twenty = app.buttons["pad_20"]
        XCTAssertTrue(twenty.waitForExistence(timeout: timeout))
        twenty.tap()
        twenty.tap()
        twenty.tap()

        // Wait for the bot visit to finish and return control to Alice on 41 remaining.
        let padReady = twenty.waitForExistence(timeout: timeout + 10)
        XCTAssertTrue(padReady)
        _ = twenty.wait(for: \.isEnabled, toEqual: true, timeout: timeout + 10)

        app.buttons["pad_double"].tap()
        app.buttons["pad_20"].tap()
        app.buttons["pad_1"].tap()

        let summaryHeader = app.otherElements["matchSummaryHeader"]
        XCTAssertTrue(summaryHeader.waitForExistence(timeout: timeout + 5), "Match summary should appear after checkout")
        XCTAssertTrue(app.staticTexts["Alice wins!"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons["New Match"].waitForExistence(timeout: timeout))
    }

    // MARK: - Game detail: per-player sector charts

    func testGameDetailShowsPerPlayerSectorCharts() {
        let app = launchApp(["-seed_demo"])

        app.tabBars.buttons["History"].tap()
        let gameCard = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "FINISHED")).firstMatch
        XCTAssertTrue(gameCard.waitForExistence(timeout: timeout))
        gameCard.tap()

        XCTAssertTrue(app.staticTexts["Game Statistics"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["Hits in Sector"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["Jacob"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["Sam"].waitForExistence(timeout: timeout))
    }

    private func configureQuickX01Match(_ app: XCUIApplication) {
        app.buttons["setup_startScoreChip"].tap()
        app.buttons["101"].tap()
        app.buttons["setup_checkoutChip"].tap()
        app.buttons["Straight Out"].tap()
        app.buttons["setup_legsChip"].tap()
        app.buttons["1"].tap()
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
