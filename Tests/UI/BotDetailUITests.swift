import XCTest

final class BotDetailUITests: DartBuddyUITestCase {
    func testBotDetailShowsDifficultyAndSavesCustomization() {
        let app = launchApp(["-seed_demo"])

        app.tabBars.buttons["Players"].tap()
        openBotRow(named: "Easy Bot 1", in: app)

        XCTAssertTrue(app.navigationBars["Bot Detail"].waitForExistence(timeout: timeout))
        XCTAssertTrue(
            app.staticTexts.containing(NSPredicate(format: "label CONTAINS[c] %@", "Difficulty")).firstMatch
                .waitForExistence(timeout: timeout),
            "Bot detail should label the fixed difficulty section"
        )
        XCTAssertTrue(app.staticTexts["Appearance"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["Easy"].waitForExistence(timeout: timeout), "Difficulty badge should show Easy")

        let nameField = app.textFields["botDetail_name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: timeout))
        nameField.tap()
        nameField.clearAndEnterText("Challenger")

        let trophy = app.buttons["Trophy"]
        XCTAssertTrue(trophy.waitForExistence(timeout: timeout), "Avatar picker should expose icon choices")
        trophy.tap()

        let blue = app.buttons["Blue"]
        XCTAssertTrue(blue.waitForExistence(timeout: timeout), "Color picker should expose color choices")
        blue.tap()

        let save = app.buttons["botDetail_save"]
        XCTAssertTrue(save.waitForExistence(timeout: timeout))
        XCTAssertTrue(save.isEnabled, "Save should enable once the bot name is valid")
        save.tap()

        XCTAssertTrue(app.staticTexts["Challenger"].waitForExistence(timeout: timeout), "Preview should reflect the new name")
        XCTAssertTrue(app.staticTexts["Blue"].waitForExistence(timeout: timeout), "Preview should reflect the chosen color")
        XCTAssertTrue(app.staticTexts["Easy"].exists, "Difficulty should remain visible after saving appearance changes")

        let back = app.navigationBars.buttons.element(boundBy: 0)
        if back.waitForExistence(timeout: timeout) {
            back.tap()
        }

        let renamedRow = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "Challenger")).firstMatch
        XCTAssertTrue(renamedRow.waitForExistence(timeout: timeout + 10), "Players list should show the renamed bot")
        XCTAssertTrue(renamedRow.label.contains("Easy"), "Bot list row should keep the difficulty badge visible")

        renamedRow.tap()
        XCTAssertTrue(app.navigationBars["Bot Detail"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["Challenger"].waitForExistence(timeout: timeout), "Saved name should persist on reopen")
        XCTAssertTrue(app.staticTexts["Blue"].waitForExistence(timeout: timeout), "Saved color should persist on reopen")
        XCTAssertTrue(app.staticTexts["Easy"].waitForExistence(timeout: timeout), "Difficulty should stay visible on reopen")
    }
}
