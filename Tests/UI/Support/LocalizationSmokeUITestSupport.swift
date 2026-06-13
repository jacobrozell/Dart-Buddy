import XCTest

/// Shared helpers for locale smoke UI tests (`de`, `es`, `fr`, `nl`, `zh-Hans`).
enum LocalizationSmokeUITestSupport {
    struct LocaleConfig {
        let languageCode: String
        let localeIdentifier: String
        let playTabLabel: String
        let playersTabLabel: String
        let settingsTabLabel: String
    }

    static func assertTabBarUsesLocalizedLabels(
        in app: XCUIApplication,
        config: LocaleConfig,
        timeout: TimeInterval
    ) {
        let playTab = app.tabBars.buttons[config.playTabLabel]
        XCTAssertTrue(playTab.waitForExistence(timeout: timeout), "Expected Play tab label \(config.playTabLabel)")
        XCTAssertTrue(app.tabBars.buttons[config.playersTabLabel].exists)
        XCTAssertTrue(app.tabBars.buttons[config.settingsTabLabel].exists)
    }

    static func launchForLocaleSmoke(
        _ testCase: DartBuddyUITestCase,
        config: LocaleConfig,
        extraArguments: [String] = []
    ) -> XCUIApplication {
        testCase.launchApp(
            extraArguments,
            localeLanguage: config.languageCode,
            localeIdentifier: config.localeIdentifier
        )
    }
}
