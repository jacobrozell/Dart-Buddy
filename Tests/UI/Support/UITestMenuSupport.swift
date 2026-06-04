import XCTest

extension XCTestCase {
    func tapTabBarItem(
        named label: String,
        identifier: String? = nil,
        in app: XCUIApplication,
        timeout: TimeInterval = 10
    ) {
        if let identifier {
            let byIdentifier = app.tabBars.buttons.matching(identifier: identifier).firstMatch
            if byIdentifier.waitForExistence(timeout: 2) {
                byIdentifier.tap()
                return
            }
        }

        let byLabel = app.tabBars.buttons[label].firstMatch
        XCTAssertTrue(byLabel.waitForExistence(timeout: timeout), "Missing tab bar item '\(label)'")
        byLabel.tap()
    }

    func ensurePlayTab(_ app: XCUIApplication, timeout: TimeInterval = 10) {
        tapTabBarItem(named: "Play", identifier: "tab_play", in: app, timeout: timeout)
        XCTAssertTrue(
            app.staticTexts["Dart Scoreboard"].waitForExistence(timeout: timeout),
            "Play setup should be visible"
        )
    }

    func tapMenuChip(_ identifier: String, in app: XCUIApplication, timeout: TimeInterval = 10) {
        let button = app.buttons[identifier]
        let popUp = app.popUpButtons[identifier]
        if button.waitForExistence(timeout: timeout) {
            button.tap()
            return
        }
        XCTAssertTrue(
            popUp.waitForExistence(timeout: timeout),
            "Missing menu chip '\(identifier)'"
        )
        popUp.tap()
    }

    func selectMenuOption(
        identifier: String? = nil,
        title: String,
        in app: XCUIApplication,
        timeout: TimeInterval = 10
    ) {
        if let identifier {
            let option = app.buttons[identifier]
            if option.waitForExistence(timeout: 1.5) {
                option.tap()
                return
            }
        }

        let menuItem = app.menuItems[title]
        if menuItem.waitForExistence(timeout: timeout) {
            menuItem.tap()
            return
        }

        let button = app.buttons[title]
        XCTAssertTrue(
            button.waitForExistence(timeout: timeout),
            "Expected menu option '\(title)'"
        )
        button.tap()
    }

    func waitForStartEnabled(_ start: XCUIElement, timeout: TimeInterval = 10) {
        XCTAssertTrue(start.waitForExistence(timeout: timeout))
        XCTAssertTrue(
            start.wait(for: \.isEnabled, toEqual: true, timeout: timeout),
            "START should be enabled once setup is valid"
        )
    }

    @discardableResult
    func waitForSwitch(_ toggle: XCUIElement, on: Bool, timeout: TimeInterval = 10) -> Bool {
        let targets = on ? ["1", "true", "On", "YES"] : ["0", "false", "Off", "NO"]
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if let value = toggle.value as? String, targets.contains(value) {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
        return false
    }
}

extension XCUIElement {
    func clearAndEnterText(_ text: String) {
        tap()
        if let stringValue = value as? String, !stringValue.isEmpty {
            let delete = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
            typeText(delete)
        }
        typeText(text)
    }
}
