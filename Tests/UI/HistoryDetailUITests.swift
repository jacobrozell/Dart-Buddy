import XCTest

final class HistoryDetailUITests: DartBuddyUITestCase {
    private func assertSectorChartsVisible(in app: XCUIApplication, timeout: TimeInterval) {
        let sectorChart = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'gameDetail_sectorChart_'")
        ).firstMatch
        XCTAssertTrue(
            sectorChart.waitForExistence(timeout: timeout),
            "Game detail should show per-player sector hit charts"
        )
    }

    func testGameDetailShowsStatsAndDeletes() {
        let app = launchApp(["-seed_demo"])

        ensureActivityHistorySegment(app, timeout: timeout)
        waitForSeededActivityHistoryContent(app, timeout: timeout + 10)
        let gameCard = app.buttons.containing(
            NSPredicate(format: "label CONTAINS[c] %@ AND label CONTAINS[c] %@", "X01", "301")
        ).firstMatch
        XCTAssertTrue(gameCard.waitForExistence(timeout: timeout + 10), "History should list the seeded X01 301 match")
        gameCard.tap()

        XCTAssertTrue(app.staticTexts["Game Statistics"].waitForExistence(timeout: timeout + 10))
        let resultCard = app.otherElements["historyDetailResultCard"]
        XCTAssertTrue(resultCard.waitForExistence(timeout: timeout + 20), "Stats should finish loading")
        scrollToHistoryStats(app)
        XCTAssertTrue(
            app.staticTexts["Average & Highest Score"].waitForExistence(timeout: timeout),
            "X01 game detail should show average stats"
        )
        XCTAssertTrue(app.staticTexts["Throws"].waitForExistence(timeout: timeout), "Game detail should show throw stats")
        assertSectorChartsVisible(in: app, timeout: timeout)

        let delete = app.buttons["historyDetailDeleteButton"]
        XCTAssertTrue(delete.waitForExistence(timeout: timeout), "Game detail should show a Delete button")
        delete.tap()

        let confirm = app.alerts.buttons["Delete"]
        XCTAssertTrue(confirm.waitForExistence(timeout: timeout))
        confirm.tap()

        XCTAssertTrue(app.staticTexts["Activity"].waitForExistence(timeout: timeout))
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

        ensureActivityHistorySegment(app, timeout: timeout)
        waitForSeededActivityHistoryContent(app, timeout: timeout + 10)
        let gameCard = app.buttons.containing(
            NSPredicate(format: "label CONTAINS[c] %@ AND label CONTAINS[c] %@", "X01", "301")
        ).firstMatch
        XCTAssertTrue(gameCard.waitForExistence(timeout: timeout + 10), "History should list the seeded X01 301 match")
        gameCard.tap()

        XCTAssertTrue(app.staticTexts["Game Statistics"].waitForExistence(timeout: timeout + 10))
        XCTAssertTrue(app.otherElements["historyDetailResultCard"].waitForExistence(timeout: timeout + 20))
        scrollToHistoryStats(app)
        assertSectorChartsVisible(in: app, timeout: timeout + 10)
        XCTAssertTrue(app.staticTexts["Jacob"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["Sam"].waitForExistence(timeout: timeout))
    }

}
