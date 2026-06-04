import XCTest

final class HistoryDetailUITests: DartBuddyUITestCase {
    func testGameDetailShowsStatsAndDeletes() {
        let app = launchApp(["-seed_demo"])

        tapTabBarItem(named: "History", identifier: "tab_history", in: app)
        let gameCard = app.buttons.containing(
            NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@", "X01", "301")
        ).firstMatch
        XCTAssertTrue(gameCard.waitForExistence(timeout: timeout + 5))
        gameCard.tap()

        XCTAssertTrue(app.staticTexts["Game Statistics"].waitForExistence(timeout: timeout))
        let resultCard = app.otherElements["historyDetailResultCard"]
        XCTAssertTrue(resultCard.waitForExistence(timeout: timeout + 15), "Stats should finish loading")
        scrollToHistoryStats(app)
        XCTAssertTrue(
            app.staticTexts["Average & Highest Score"].waitForExistence(timeout: timeout),
            "X01 game detail should show average stats"
        )
        XCTAssertTrue(app.staticTexts["Throws"].waitForExistence(timeout: timeout), "Game detail should show throw stats")
        XCTAssertTrue(app.staticTexts["Hits in Sector"].waitForExistence(timeout: timeout))

        let delete = app.buttons["historyDetailDeleteButton"]
        XCTAssertTrue(delete.waitForExistence(timeout: timeout), "Game detail should show a Delete button")
        delete.tap()

        let confirm = app.alerts.buttons["Delete"]
        XCTAssertTrue(confirm.waitForExistence(timeout: timeout))
        confirm.tap()

        XCTAssertTrue(app.staticTexts["History"].waitForExistence(timeout: timeout))
        XCTAssertFalse(
            app.staticTexts["No games yet. Start a match to see it here."].waitForExistence(timeout: 2),
            "One completed game should remain after deleting a single seeded match"
        )
        XCTAssertTrue(
            app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "FINISHED")).firstMatch.waitForExistence(timeout: timeout),
            "History should still list the remaining completed match"
        )
    }

    func testGameDetailShowsPerPlayerSectorCharts() {
        let app = launchApp(["-seed_demo"])

        tapTabBarItem(named: "History", identifier: "tab_history", in: app)
        let gameCard = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "FINISHED")).firstMatch
        XCTAssertTrue(gameCard.waitForExistence(timeout: timeout + 5))
        gameCard.tap()

        XCTAssertTrue(app.staticTexts["Game Statistics"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["Hits in Sector"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["Jacob"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["Sam"].waitForExistence(timeout: timeout))
    }

    func testAllGamesEmptyBeforeAnyMatchCompletes() {
        let app = launchApp(["-seed_players"])

        tapTabBarItem(named: "History", identifier: "tab_history", in: app)
        XCTAssertTrue(app.staticTexts["History"].firstMatch.waitForExistence(timeout: timeout))
        XCTAssertTrue(
            app.staticTexts["No games yet. Start a match to see it here."].waitForExistence(timeout: timeout),
            "History should be empty before any match completes"
        )
    }
}
