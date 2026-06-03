import XCTest

final class PlayerDetailUITests: DartBuddyUITestCase {
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

    func testEditPlayerUpdatesProfile() {
        let app = launchApp(["-seed_demo"])

        app.tabBars.buttons["Players"].tap()
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
}
