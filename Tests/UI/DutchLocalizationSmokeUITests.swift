import XCTest

final class DutchLocalizationSmokeUITests: DartBuddyUITestCase {
    private let config = LocalizationSmokeUITestSupport.LocaleConfig(
        languageCode: "nl",
        localeIdentifier: "nl_NL",
        playTabLabel: "Spelen",
        playersTabLabel: "Spelers",
        settingsTabLabel: "Instellingen"
    )

    func testTabBarUsesDutchLabels() throws {
        let app = LocalizationSmokeUITestSupport.launchForLocaleSmoke(self, config: config, extraArguments: ["-seed_players"])
        LocalizationSmokeUITestSupport.assertTabBarUsesLocalizedLabels(in: app, config: config, timeout: timeout)
    }

    func testPlaySetupUsesDutchChrome() throws {
        let app = LocalizationSmokeUITestSupport.launchForLocaleSmoke(self, config: config, extraArguments: ["-seed_players"])
        XCTAssertTrue(app.tabBars.buttons[config.playTabLabel].waitForExistence(timeout: timeout))
        app.tabBars.buttons[config.playTabLabel].tap()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: timeout))
    }
}
