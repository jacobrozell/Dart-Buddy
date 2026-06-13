import XCTest

/// Smoke tests with Simplified Chinese locale. `dev` bundles all locales; lean release branches may skip via XCTSkip.
final class ChineseLocalizationSmokeUITests: DartBuddyUITestCase {
    private let config = LocalizationSmokeUITestSupport.LocaleConfig(
        languageCode: "zh-Hans",
        localeIdentifier: "zh-Hans_CN",
        playTabLabel: "开始",
        playersTabLabel: "玩家",
        settingsTabLabel: "设置"
    )

    func testTabBarUsesChineseLabels() throws {
        let app = LocalizationSmokeUITestSupport.launchForLocaleSmoke(self, config: config, extraArguments: ["-seed_players"])
        LocalizationSmokeUITestSupport.assertTabBarUsesLocalizedLabels(in: app, config: config, timeout: timeout)
    }

    func testPlaySetupUsesChineseChrome() throws {
        let app = LocalizationSmokeUITestSupport.launchForLocaleSmoke(self, config: config, extraArguments: ["-seed_players"])
        XCTAssertTrue(app.tabBars.buttons[config.playTabLabel].waitForExistence(timeout: timeout))
        app.tabBars.buttons[config.playTabLabel].tap()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: timeout))
    }
}
