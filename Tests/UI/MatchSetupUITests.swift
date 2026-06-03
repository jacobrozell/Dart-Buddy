import XCTest

final class MatchSetupUITests: DartBuddyUITestCase {
    func testStartingWithActiveMatchPromptsToReplaceIt() {
        let app = launchApp(["-seed_demo"])

        XCTAssertTrue(app.staticTexts["Dart Scoreboard"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons["resumeMatchButton"].waitForExistence(timeout: timeout))

        XCTAssertTrue(app.buttons["select_Jacob"].waitForExistence(timeout: timeout))
        app.buttons["select_Jacob"].tap()
        app.buttons["select_Sam"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["setup_selected_Jacob"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.descendants(matching: .any)["setup_selected_Sam"].waitForExistence(timeout: timeout))

        let start = app.buttons["startMatchButton"]
        waitForStartEnabled(start, timeout: timeout + 5)
        start.tap()

        let alert = app.alerts["Game in Progress"]
        XCTAssertTrue(alert.waitForExistence(timeout: timeout + 5), "Starting with an active match should prompt to replace it")

        alert.buttons["Abandon & Start"].tap()

        XCTAssertTrue(
            app.staticTexts["501, Double Out, First to 3 Legs"].waitForExistence(timeout: timeout),
            "Confirming should delete the active match and open the new board"
        )
    }

    func testResumeActiveMatch() {
        let app = launchApp(["-seed_demo"])

        let resume = app.buttons["resumeMatchButton"]
        XCTAssertTrue(resume.waitForExistence(timeout: timeout), "An in-progress match should be resumable")
        resume.tap()

        XCTAssertTrue(
            app.staticTexts["121"].waitForExistence(timeout: timeout),
            "Resumed board should show the saved remaining score"
        )
    }

    func testEmptyRosterGuidesUserToAddPlayers() {
        let app = launchApp()

        XCTAssertTrue(app.staticTexts["Dart Scoreboard"].waitForExistence(timeout: timeout))
        XCTAssertTrue(
            app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Add Players")).firstMatch
                .waitForExistence(timeout: timeout),
            "An empty roster should guide the user to add players"
        )
        XCTAssertFalse(
            app.descendants(matching: .any)["errorBanner"].firstMatch.exists,
            "Minimum-player validation should not duplicate the empty-roster hint"
        )

        let start = app.buttons["startMatchButton"]
        XCTAssertTrue(start.waitForExistence(timeout: timeout))
        XCTAssertFalse(start.isEnabled, "START must stay disabled without two players")
    }

    func testHumanPlusBotCanStartMatch() {
        let app = launchApp(["-seed_players"])

        app.buttons["select_Alice"].tap()
        addEasyBot(from: app, timeout: timeout)

        let start = app.buttons["startMatchButton"]
        XCTAssertTrue(start.isEnabled, "START should enable with one human and one bot")
        start.tap()

        XCTAssertTrue(app.buttons["pad_20"].waitForExistence(timeout: timeout + 5))
    }

    func testRemovePlayerFromTurnOrderRestoresAvailableRoster() {
        let app = launchApp(["-seed_players"])

        XCTAssertTrue(app.staticTexts["Dart Scoreboard"].waitForExistence(timeout: timeout))

        let selectAlice = app.buttons["select_Alice"]
        XCTAssertTrue(selectAlice.waitForExistence(timeout: timeout))
        selectAlice.tap()
        XCTAssertTrue(app.descendants(matching: .any)["setup_selected_Alice"].waitForExistence(timeout: timeout))

        let selectBob = app.buttons["select_Bob"]
        XCTAssertTrue(selectBob.waitForExistence(timeout: timeout))
        if !selectBob.isHittable {
            app.swipeUp()
        }
        selectBob.tap()

        let start = app.buttons["startMatchButton"]
        waitForStartEnabled(start, timeout: timeout)

        removePlayerFromTurnOrder(named: "Alice", in: app)

        XCTAssertFalse(
            app.descendants(matching: .any)["setup_selected_Alice"].waitForExistence(timeout: 2),
            "Alice should leave the turn order list after removal"
        )
        XCTAssertTrue(app.buttons["select_Alice"].waitForExistence(timeout: timeout), "Alice should return to the available roster")
        XCTAssertFalse(start.isEnabled, "START should disable when only one player remains staged")

        removePlayerFromTurnOrder(named: "Bob", in: app)

        XCTAssertFalse(
            app.descendants(matching: .any)["setup_selected_Bob"].waitForExistence(timeout: 2),
            "Bob should leave the turn order list after removal"
        )
        XCTAssertTrue(app.buttons["select_Bob"].waitForExistence(timeout: timeout), "Bob should return to the available roster")
        XCTAssertFalse(start.isEnabled, "START should stay disabled with no staged players")

        app.buttons["select_Alice"].tap()
        app.buttons["select_Bob"].tap()
        waitForStartEnabled(start, timeout: timeout)
    }

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
}
