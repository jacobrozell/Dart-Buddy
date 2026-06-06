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

    func ensureSetupReady(_ app: XCUIApplication, timeout: TimeInterval = 10) {
        ensurePlayTab(app, timeout: timeout)
        let rosterRow = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'select_'")
        ).firstMatch
        XCTAssertTrue(
            rosterRow.waitForExistence(timeout: timeout + 15),
            "Setup roster should finish loading before player selection"
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

    func waitForStartDisabled(_ start: XCUIElement, timeout: TimeInterval = 10) {
        XCTAssertTrue(start.waitForExistence(timeout: timeout))
        XCTAssertTrue(
            start.wait(for: \.isEnabled, toEqual: false, timeout: timeout),
            "START should stay disabled until setup is valid"
        )
    }

    func selectPlayerFromRoster(_ name: String, in app: XCUIApplication, timeout: TimeInterval = 10) {
        let button = app.buttons["select_\(name)"]
        let start = app.buttons["startMatchButton"]
        XCTAssertTrue(
            button.waitForExistence(timeout: timeout),
            "Expected roster row for \(name)"
        )
        for _ in 0 ..< 10 {
            let clearsStartFooter = !start.exists || button.frame.maxY < start.frame.minY - 8
            if button.isHittable, clearsStartFooter {
                break
            }
            app.swipeUp()
        }
        XCTAssertTrue(
            button.isHittable,
            "Expected roster row for \(name) to be reachable above the sticky Start footer"
        )
        button.tap()
        let staged = app.descendants(matching: .any)["setup_selected_\(name)"].firstMatch
        XCTAssertTrue(
            staged.waitForExistence(timeout: timeout),
            "Expected \(name) to appear in turn order after selection"
        )
    }

    func selectAliceAndBob(from app: XCUIApplication, timeout: TimeInterval = 10) {
        selectPlayerFromRoster("Alice", in: app, timeout: timeout)
        selectPlayerFromRoster("Bob", in: app, timeout: timeout)
    }

    func tapStartMatch(
        in app: XCUIApplication,
        expectingBoardKey: String,
        timeout: TimeInterval = 10
    ) {
        let start = app.buttons["startMatchButton"]
        waitForStartEnabled(start, timeout: timeout)
        if !start.isHittable {
            app.swipeUp()
        }
        start.tap()
        XCTAssertTrue(
            app.buttons[expectingBoardKey].waitForExistence(timeout: timeout + 15),
            "Match board '\(expectingBoardKey)' should appear after start"
        )
    }

    func startTwoPlayerX01Match(from app: XCUIApplication, timeout: TimeInterval = 10) {
        ensureSetupReady(app, timeout: timeout)
        selectAliceAndBob(from: app, timeout: timeout)
        tapStartMatch(in: app, expectingBoardKey: "pad_20", timeout: timeout)
    }

    func startTwoPlayerCricketMatch(from app: XCUIApplication, timeout: TimeInterval = 10) {
        ensureSetupReady(app, timeout: timeout)
        app.buttons["setup_mode_cricket"].tap()
        selectAliceAndBob(from: app, timeout: timeout)
        tapStartMatch(in: app, expectingBoardKey: "cricket_20", timeout: timeout)
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
