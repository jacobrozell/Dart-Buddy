import XCTest

/// Shared helpers for locale smoke UI tests (`de`, `es`, `fr`, `it`, `nl`, `zh-Hans`).
enum LocalizationSmokeUITestSupport {
    struct LocaleConfig {
        let languageCode: String
        let localeIdentifier: String
        let playTabLabel: String
        let playersTabLabel: String
        let activityTabLabel: String?
        let settingsTabLabel: String

        init(
            languageCode: String,
            localeIdentifier: String,
            playTabLabel: String,
            playersTabLabel: String,
            activityTabLabel: String? = nil,
            settingsTabLabel: String
        ) {
            self.languageCode = languageCode
            self.localeIdentifier = localeIdentifier
            self.playTabLabel = playTabLabel
            self.playersTabLabel = playersTabLabel
            self.activityTabLabel = activityTabLabel
            self.settingsTabLabel = settingsTabLabel
        }
    }

    private struct TabExpectation {
        let identifier: String
        let label: String
    }

    static func assertTabBarUsesLocalizedLabels(
        in app: XCUIApplication,
        config: LocaleConfig,
        timeout: TimeInterval
    ) {
        for tab in tabExpectations(for: config) {
            guard let element = waitForTabBarItem(identifier: tab.identifier, in: app, timeout: timeout) else {
                XCTFail("Missing tab bar item '\(tab.identifier)'")
                return
            }
            XCTAssertEqual(
                element.label,
                tab.label,
                "Tab '\(tab.identifier)' should use localized label '\(tab.label)', got '\(element.label)'"
            )
        }
    }

    static func tapTab(
        identifier: String,
        label: String,
        in app: XCUIApplication,
        timeout: TimeInterval
    ) {
        guard let tab = waitForTabBarItem(identifier: identifier, in: app, timeout: timeout) else {
            XCTFail("Missing tab bar item '\(identifier)'")
            return
        }
        XCTAssertEqual(
            tab.label,
            label,
            "Tab '\(identifier)' should use localized label '\(label)', got '\(tab.label)'"
        )
        tapIfPossible(tab)
    }

    static func tapPlayTab(in app: XCUIApplication, config: LocaleConfig, timeout: TimeInterval) {
        tapTab(identifier: "tab_play", label: config.playTabLabel, in: app, timeout: timeout)
    }

    static func tapPlayersTab(in app: XCUIApplication, config: LocaleConfig, timeout: TimeInterval) {
        tapTab(identifier: "tab_players", label: config.playersTabLabel, in: app, timeout: timeout)
    }

    static func assertPlaySetupChromeVisible(in app: XCUIApplication, timeout: TimeInterval) {
        let brandTitle = app.descendants(matching: .any)["brand_app_title"]
        let changeMode = app.buttons["setup_changeModeButton"]
        XCTAssertTrue(
            brandTitle.waitForExistence(timeout: timeout) || changeMode.waitForExistence(timeout: timeout),
            "Play setup should show brand title or change-mode control"
        )
    }

    static func assertButton(
        identifier: String,
        localizedLabel: String,
        in app: XCUIApplication,
        timeout: TimeInterval,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let button = app.buttons[identifier]
        XCTAssertTrue(button.waitForExistence(timeout: timeout), file: file, line: line)
        XCTAssertEqual(button.label, localizedLabel, file: file, line: line)
    }

    static func assertStaticText(
        _ label: String,
        in app: XCUIApplication,
        timeout: TimeInterval,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            app.staticTexts[label].waitForExistence(timeout: timeout),
            "Expected localized copy '\(label)'",
            file: file,
            line: line
        )
    }

    static func launchForLocaleSmoke(
        _ testCase: DartBuddyUITestCase,
        config: LocaleConfig,
        extraArguments: [String] = [],
        leanProductSurface: Bool = false
    ) -> XCUIApplication {
        let app: XCUIApplication
        if leanProductSurface {
            app = testCase.launchAppWithLeanProductSurface(
                extraArguments,
                localeLanguage: config.languageCode,
                localeIdentifier: config.localeIdentifier
            )
        } else {
            app = testCase.launchApp(
                extraArguments,
                localeLanguage: config.languageCode,
                localeIdentifier: config.localeIdentifier
            )
        }
        waitForAppShellReady(in: app, timeout: testCase.timeout + 10)
        return app
    }

    static func waitForAppShellReady(in app: XCUIApplication, timeout: TimeInterval) {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if waitForTabBarItem(identifier: "tab_play", in: app, timeout: 1) != nil { return }
            if app.descendants(matching: .any)["brand_app_title"].exists { return }
            if app.buttons["setup_changeModeButton"].exists { return }
            RunLoop.current.run(until: Date().addingTimeInterval(0.15))
        }
    }

    static func openModePicker(in app: XCUIApplication, timeout: TimeInterval) {
        let changeButton = app.buttons["setup_changeModeButton"]
        XCTAssertTrue(changeButton.waitForExistence(timeout: timeout), "Expected change-mode control on Play setup")
        changeButton.tap()
    }

    static func assertModePickerCardVisible(
        catalogID: String,
        in app: XCUIApplication,
        timeout: TimeInterval,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let card = app.descendants(matching: .any)["modes_card_\(catalogID)"]
        if !card.waitForExistence(timeout: 3) {
            for _ in 0 ..< 4 where card.exists == false {
                app.swipeUp()
            }
        }
        XCTAssertTrue(card.waitForExistence(timeout: timeout), "Expected mode card \(catalogID)", file: file, line: line)
    }

    private static func tabExpectations(for config: LocaleConfig) -> [TabExpectation] {
        var tabs = [
            TabExpectation(identifier: "tab_play", label: config.playTabLabel),
            TabExpectation(identifier: "tab_players", label: config.playersTabLabel),
        ]
        if let activityTabLabel = config.activityTabLabel {
            tabs.append(TabExpectation(identifier: "tab_activity", label: activityTabLabel))
        }
        tabs.append(TabExpectation(identifier: "tab_settings", label: config.settingsTabLabel))
        return tabs
    }

    private static func waitForTabBarItem(
        identifier: String,
        in app: XCUIApplication,
        timeout: TimeInterval
    ) -> XCUIElement? {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            for candidate in tabBarCandidates(identifier: identifier, in: app) where candidate.exists {
                return candidate
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.15))
        }
        return tabBarCandidates(identifier: identifier, in: app).first { $0.exists }
    }

    private static func tabBarCandidates(identifier: String, in app: XCUIApplication) -> [XCUIElement] {
        [
            app.descendants(matching: .any).matching(identifier: identifier).firstMatch,
            app.tabBars.buttons.matching(identifier: identifier).firstMatch,
            app.buttons.matching(identifier: identifier).firstMatch,
            app.cells.matching(identifier: identifier).firstMatch,
        ]
    }

    private static func tapIfPossible(_ element: XCUIElement) {
        if element.isHittable {
            element.tap()
            return
        }
        // iOS 26 floating tab bar + large content sizes can expose tabs before hit-testing passes.
        element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }
}
