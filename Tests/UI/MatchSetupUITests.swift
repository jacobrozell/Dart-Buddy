import XCTest

final class MatchSetupUITests: DartBuddyUITestCase {
    func testStartingWithActiveMatchPromptsToReplaceIt() {
        let app = launchApp(["-seed_demo"])

        assertBrandAppTitleVisible(in: app, timeout: timeout)
        XCTAssertTrue(app.buttons["resumeMatchButton"].waitForExistence(timeout: timeout))

        // Stage bot first so the turn-order list does not cover the human roster on compact simulators.
        addEasyBot(from: app, timeout: timeout)
        selectPlayerFromRoster("Jacob", in: app)

        let start = app.buttons["startMatchButton"]
        waitForStartEnabled(start, timeout: timeout + 5)
        if !start.isHittable {
            app.swipeUp()
        }
        start.tap()

        let abandonAndStart = app.alerts.buttons["Abandon & Start"]
        XCTAssertTrue(
            abandonAndStart.waitForExistence(timeout: timeout + 5),
            "Starting with an active match should prompt to replace it"
        )
        abandonAndStart.tap()

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

        assertBrandAppTitleVisible(in: app, timeout: timeout)
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

        selectPlayerFromRoster("Alice", in: app)
        addEasyBot(from: app, timeout: timeout)

        let start = app.buttons["startMatchButton"]
        XCTAssertTrue(start.isEnabled, "START should enable with one human and one bot")
        tapStartMatch(in: app, timeout: timeout + 5)

        waitForX01MatchBoard(in: app, timeout: timeout + 5)
    }

    func testRemovePlayerFromTurnOrderRestoresAvailableRoster() {
        let app = launchApp(["-seed_players"])

        assertBrandAppTitleVisible(in: app, timeout: timeout)

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

    func testMatchSetupAddsTrainingPartnerBot() {
        let app = launchApp(["-seed_training_partner", "-enqueue_training_match"])

        ensurePlayTab(app, timeout: timeout + 30)
        let stagedPartner = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'setup_selected_' AND label CONTAINS[c] %@", "Training Partner")
        ).firstMatch
        XCTAssertTrue(
            stagedPartner.waitForExistence(timeout: timeout + 30),
            "Seeded training partner launch should pre-stage the linked bot"
        )

        let start = app.buttons["startMatchButton"]
        waitForStartEnabled(start, timeout: timeout + 15)
        start.tap()

        XCTAssertTrue(app.buttons["pad_20"].waitForExistence(timeout: timeout + 15))
    }

    func testMatchSetupAddBotMenuIncludesTrainingPartner() {
        let app = launchApp(["-seed_training_partner"])

        ensurePlayTab(app, timeout: timeout + 30)

        let addBot = app.buttons["Add Bot"]
        XCTAssertTrue(addBot.waitForExistence(timeout: timeout))
        addBot.tap()

        let trainingOption = app.buttons.containing(
            NSPredicate(format: "label CONTAINS %@", "Training Partner")
        ).firstMatch
        XCTAssertTrue(
            trainingOption.waitForExistence(timeout: timeout + 10),
            "Add Bot menu should list the linked Training Partner after removing it from turn order"
        )
    }
}
