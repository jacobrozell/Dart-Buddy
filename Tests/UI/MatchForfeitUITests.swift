import XCTest

/// Save & Forfeit summary and multi-step picker flows (X01 + Cricket).
final class MatchForfeitUITests: DartBuddyUITestCase {
    func testX01ForfeitSummaryViewStatsOpensDetail() {
        let app = launchApp(["-seed_players"])
        startTwoPlayerX01Match(from: app, timeout: timeout)
        scoreSingleVisit(app, segments: [20, 20, 20], timeout: timeout)
        forfeitMatchFromExit(in: app, timeout: timeout)

        assertMatchSummaryForfeitBanner(in: app, timeout: timeout + 5)
        app.buttons["View Game Statistics"].tap()
        XCTAssertTrue(app.staticTexts["Game Statistics"].waitForExistence(timeout: timeout))
    }

    func testX01ForfeitUndoNotOffered() {
        let app = launchApp(["-seed_players"])
        startTwoPlayerX01Match(from: app, timeout: timeout)
        scoreSingleVisit(app, segments: [20, 20, 20], timeout: timeout)
        forfeitMatchFromExit(in: app, timeout: timeout)

        assertMatchSummaryForfeitBanner(in: app, timeout: timeout + 5)
        XCTAssertFalse(
            app.buttons["matchSummaryUndoLastThrow"].waitForExistence(timeout: 2),
            "Forfeit summary should not offer undo"
        )
    }
}
