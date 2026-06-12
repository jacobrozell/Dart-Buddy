import XCTest

/// Shared match chrome: exit, save/resume, summary actions (X01 + Cricket).
final class MatchChromeUITests: DartBuddyUITestCase {
    // MARK: - X01 exit

    func testX01ExitSaveAndResume() {
        let app = launchApp(["-seed_players"])
        startTwoPlayerX01Match(from: app, timeout: timeout)

        scoreSingleVisit(app, segments: [20, 20, 20], timeout: timeout)
        waitForActiveX01Player("Bob", in: app, timeout: timeout + 10)

        saveAndExitMatch(in: app, timeout: timeout)
        let resume = app.buttons["resumeMatchButton"]
        XCTAssertTrue(resume.waitForExistence(timeout: timeout))
        resume.tap()

        waitForX01MatchBoard(in: app, timeout: timeout + 15)
        waitForActiveX01Player("Bob", in: app, timeout: timeout + 10)
        let aliceCard = inactiveX01ScoreCards(in: app).matching(
            NSPredicate(format: "label CONTAINS[c] %@ AND label CONTAINS %@", "Alice", "41")
        ).firstMatch
        XCTAssertTrue(
            aliceCard.waitForExistence(timeout: timeout),
            "Resumed match should restore completed visits from before save & exit"
        )
    }

    func testX01ExitAbandonReturnsHome() {
        let app = launchApp(["-seed_players"])
        startTwoPlayerX01Match(from: app, timeout: timeout)

        abandonMatchFromExit(in: app, timeout: timeout)
        XCTAssertFalse(
            app.buttons["resumeMatchButton"].waitForExistence(timeout: 2),
            "Abandoned match should not offer resume"
        )
    }

    func testX01SummaryDoneReturnsToPlayHome() {
        let app = launchApp(["-seed_players"])
        finishQuickX01Checkout(for: app, timeout: timeout)
        tapSummaryDone(in: app, timeout: timeout)
    }

    func testX01SummaryViewStatsOpensDetail() {
        let app = launchApp(["-seed_players"])
        finishQuickX01Checkout(for: app, timeout: timeout)

        app.buttons["View Game Statistics"].tap()
        XCTAssertTrue(app.staticTexts["Game Statistics"].waitForExistence(timeout: timeout))
    }

    // MARK: - Cricket exit

    func testCricketExitSaveAndResume() {
        let app = launchApp(["-seed_players"])
        startTwoPlayerCricketMatch(from: app)

        submitCricketMissVisit(in: app, timeout: timeout)
        waitForActiveCricketPlayer("Bob", in: app, timeout: timeout + 10)

        saveAndExitMatch(in: app, timeout: timeout)

        let resume = app.buttons["resumeMatchButton"]
        XCTAssertTrue(resume.waitForExistence(timeout: timeout))
        resume.tap()

        XCTAssertTrue(app.buttons["cricket_20"].waitForExistence(timeout: timeout + 15))
        waitForActiveCricketPlayer("Bob", in: app, timeout: timeout + 10)
    }

    func testCricketExitAbandonReturnsHome() {
        let app = launchApp(["-seed_players"])
        startTwoPlayerCricketMatch(from: app)

        abandonMatchFromExit(in: app, timeout: timeout)
        XCTAssertFalse(
            app.buttons["resumeMatchButton"].waitForExistence(timeout: 2),
            "Abandoned cricket match should not offer resume"
        )
    }
}
