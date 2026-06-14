import XCTest

/// Shared helpers for locale smoke UI tests (`de`, `es`, `fr`, `it`, `nl`, `zh-Hans`).
enum LocalizationSmokeUITestSupport {
    struct LocaleConfig {
        let languageCode: String
        let localeIdentifier: String
        let playTabLabel: String
        let playersTabLabel: String
        let settingsTabLabel: String
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

    static func tapPlayTab(in app: XCUIApplication, config: LocaleConfig, timeout: TimeInterval) {
        guard let playTab = waitForTabBarItem(identifier: "tab_play", in: app, timeout: timeout) else {
            XCTFail("Missing Play tab")
            return
        }
        XCTAssertEqual(
            playTab.label,
            config.playTabLabel,
            "Play tab should use localized label '\(config.playTabLabel)', got '\(playTab.label)'"
        )
        tapIfPossible(playTab)
    }

    static func assertPlaySetupChromeVisible(in app: XCUIApplication, timeout: TimeInterval) {
        let brandTitle = app.descendants(matching: .any)["brand_app_title"]
        let changeMode = app.buttons["setup_changeModeButton"]
        XCTAssertTrue(
            brandTitle.waitForExistence(timeout: timeout) || changeMode.waitForExistence(timeout: timeout),
            "Play setup should show brand title or change-mode control"
        )
    }

    static func launchForLocaleSmoke(
        _ testCase: DartBuddyUITestCase,
        config: LocaleConfig,
        extraArguments: [String] = []
    ) -> XCUIApplication {
        let app = testCase.launchApp(
            extraArguments,
            localeLanguage: config.languageCode,
            localeIdentifier: config.localeIdentifier
        )
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

    private static func tabExpectations(for config: LocaleConfig) -> [TabExpectation] {
        [
            TabExpectation(identifier: "tab_play", label: config.playTabLabel),
            TabExpectation(identifier: "tab_players", label: config.playersTabLabel),
            TabExpectation(identifier: "tab_settings", label: config.settingsTabLabel),
        ]
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
