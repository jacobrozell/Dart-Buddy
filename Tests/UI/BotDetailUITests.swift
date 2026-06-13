import XCTest

final class BotDetailUITests: DartBuddyUITestCase {
    func testBotDetailShowsDifficultyAndSavesCustomization() {
        let app = launchApp(["-seed_demo"])
        waitForDemoSeed(in: app, timeout: timeout + 30)
        openBotRow(named: "Easy Bot 1", in: app, timeout: timeout + 30)

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
        enterBotDetailName("Challenger", in: nameField)
        dismissKeyboardIfPresent(in: app)

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

        XCTAssertTrue(
            waitForBotIdentityLabel(containing: ["Challenger", "Blue"], in: app, timeout: timeout + 10),
            "Identity card should reflect the new name and color after saving"
        )
        XCTAssertTrue(app.staticTexts["Easy"].waitForExistence(timeout: timeout), "Difficulty badge should remain visible after saving appearance changes")

        let back = app.navigationBars.buttons.element(boundBy: 0)
        if back.waitForExistence(timeout: timeout) {
            back.tap()
        }

        let renamedRow = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "Challenger")).firstMatch
        XCTAssertTrue(renamedRow.waitForExistence(timeout: timeout + 10), "Players list should show the renamed bot")
        XCTAssertTrue(renamedRow.label.contains("Easy"), "Bot list row should keep the difficulty badge visible")

        renamedRow.tap()
        XCTAssertTrue(app.navigationBars["Bot Detail"].waitForExistence(timeout: timeout))
        XCTAssertTrue(
            waitForBotIdentityLabel(containing: ["Challenger", "Blue"], in: app, timeout: timeout + 10),
            "Saved name and color should persist on reopen"
        )
        XCTAssertTrue(app.staticTexts["Easy"].waitForExistence(timeout: timeout), "Difficulty should stay visible on reopen")
    }

    private func enterBotDetailName(_ name: String, in nameField: XCUIElement) {
        nameField.replaceText(name)
        if waitForElementValue(nameField, toEqual: name, timeout: 3) { return }
        nameField.clearAndEnterText(name)
        XCTAssertTrue(
            waitForElementValue(nameField, toEqual: name, timeout: timeout + 5),
            "Bot name field should reflect the renamed value before saving"
        )
    }

    private func dismissKeyboardIfPresent(in app: XCUIApplication) {
        guard app.keyboards.count > 0 else { return }
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15)).tap()
    }

    private func waitForElementValue(
        _ element: XCUIElement,
        toEqual expected: String,
        timeout: TimeInterval
    ) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if (element.value as? String) == expected {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
        return (element.value as? String) == expected
    }

    private func waitForBotIdentityLabel(
        containing fragments: [String],
        in app: XCUIApplication,
        timeout: TimeInterval
    ) -> Bool {
        guard let first = fragments.first else { return false }
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            let card = app.descendants(matching: .any).matching(
                NSPredicate(
                    format: "label CONTAINS[c] %@ AND label CONTAINS[c] 'difficulty'",
                    first
                )
            ).firstMatch
            if card.exists, fragments.allSatisfy({ card.label.localizedCaseInsensitiveContains($0) }) {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
        let card = app.descendants(matching: .any).matching(
            NSPredicate(
                format: "label CONTAINS[c] %@ AND label CONTAINS[c] 'difficulty'",
                first
            )
        ).firstMatch
        return card.exists && fragments.allSatisfy { card.label.localizedCaseInsensitiveContains($0) }
    }
}
