import XCTest

final class PlayerDetailUITests: DartBuddyUITestCase {
    func testPlayerDetailShowsStats() {
        let app = launchApp(["-seed_demo"])

        ensurePlayersTab(app, timeout: timeout)
        let jacobRow = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "Jacob")).firstMatch
        XCTAssertTrue(jacobRow.waitForExistence(timeout: timeout))
        jacobRow.tap()

        XCTAssertTrue(app.staticTexts["X01"].waitForExistence(timeout: timeout), "Player detail should show an X01 stats section")
        XCTAssertTrue(app.staticTexts["3-Dart Avg"].waitForExistence(timeout: timeout), "Player detail should show the 3-dart average tile")
        XCTAssertTrue(app.staticTexts["Hits in Sector"].waitForExistence(timeout: timeout), "Player detail should show hits in sector")
    }

    func testPlayerDetailRecentMatchOpensGameStatistics() {
        let app = launchApp(["-seed_demo"])

        ensurePlayersTab(app, timeout: timeout)
        XCTAssertTrue(app.buttons["player_row_Jacob"].waitForExistence(timeout: timeout))
        app.buttons["player_row_Jacob"].tap()
        XCTAssertTrue(app.staticTexts["Recent Matches"].waitForExistence(timeout: timeout + 10))

        let recentMatch = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'playerDetail_recentMatch_'")
        ).firstMatch
        XCTAssertTrue(recentMatch.waitForExistence(timeout: timeout + 10))
        recentMatch.tap()

        XCTAssertTrue(app.staticTexts["Game Statistics"].waitForExistence(timeout: timeout + 15))
        XCTAssertTrue(app.otherElements["historyDetailResultCard"].waitForExistence(timeout: timeout + 15))
    }

    func testPlayerDetailShowsExportButton() {
        let app = launchAppWithFullProductSurface(["-seed_demo"])

        ensurePlayersTab(app, timeout: timeout)
        XCTAssertTrue(app.buttons["player_row_Jacob"].waitForExistence(timeout: timeout))
        app.buttons["player_row_Jacob"].tap()
        XCTAssertTrue(app.staticTexts["X01"].waitForExistence(timeout: timeout + 10))

        let exportButton = app.buttons["playerDetail_export"]
        XCTAssertTrue(exportButton.waitForExistence(timeout: timeout), "Player detail should expose Export")
        XCTAssertTrue(exportButton.isEnabled, "Export should be enabled on player detail")
    }

    func testEditPlayerUpdatesProfile() {
        let app = launchApp(["-seed_demo"])

        ensurePlayersTab(app, timeout: timeout)
        XCTAssertTrue(app.buttons["player_row_Jacob"].waitForExistence(timeout: timeout))
        app.buttons["player_row_Jacob"].tap()
        XCTAssertTrue(app.staticTexts["X01"].waitForExistence(timeout: timeout + 10))

        app.buttons["playerDetail_edit"].tap()
        let nameField = app.textFields["playerEdit_name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: timeout), "Edit sheet should expose the name field")
        nameField.tap()
        nameField.clearAndEnterText("Jake")

        let save = app.buttons["playerEdit_save"]
        XCTAssertTrue(save.waitForExistence(timeout: timeout))
        XCTAssertTrue(save.isEnabled, "Save should be enabled for a unique renamed player")
        save.tap()

        let back = app.navigationBars.buttons.element(boundBy: 0)
        if back.waitForExistence(timeout: timeout) {
            back.tap()
        }

        XCTAssertTrue(app.buttons["player_row_Jake"].waitForExistence(timeout: timeout + 10), "List should show the renamed player")
        XCTAssertFalse(app.buttons["player_row_Jacob"].exists, "Old player row label should be gone after rename")
    }

    func testPlayerDetailShowsTrainingPartnerEligibilityProgress() {
        let app = launchAppWithFullProductSurface(["-seed_training_locked"])

        ensurePlayersTab(app, timeout: timeout)
        XCTAssertTrue(app.buttons["player_row_Alice"].waitForExistence(timeout: timeout))
        app.buttons["player_row_Alice"].tap()

        XCTAssertTrue(app.staticTexts["Training Partner"].waitForExistence(timeout: timeout))
        XCTAssertTrue(
            app.descendants(matching: .any)["training_bot_eligibility_progress"].firstMatch.waitForExistence(timeout: timeout),
            "Locked state should show games-until-unlock progress"
        )
        XCTAssertTrue(app.buttons["training_bot_create"].waitForExistence(timeout: timeout))
        XCTAssertFalse(app.buttons["training_bot_create"].isEnabled, "Create should stay disabled below 5 games")
    }

    func testPlayerDetailEnablesCreateWhenEligible() {
        let app = launchAppWithFullProductSurface(["-seed_training_eligible"])

        ensurePlayersTab(app, timeout: timeout)
        app.buttons["player_row_Alice"].tap()

        XCTAssertTrue(app.staticTexts["Training Partner"].waitForExistence(timeout: timeout + 30))

        let create = app.buttons["training_bot_create"]
        XCTAssertTrue(create.waitForExistence(timeout: timeout + 30))
        XCTAssertTrue(
            create.wait(for: \.isEnabled, toEqual: true, timeout: timeout + 30),
            "Create Training Partner should enable after five X01 games"
        )
    }

    func testPlayersListShowsSeededTrainingPartner() {
        let app = launchApp(["-seed_training_partner"])

        ensurePlayersTab(app, timeout: timeout)
        let partnerRow = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'player_row_' AND label CONTAINS %@", "Training Partner")
        ).firstMatch
        XCTAssertTrue(
            partnerRow.waitForExistence(timeout: timeout + 30),
            "Seeded Training Partner should appear on the players list"
        )
    }
}
