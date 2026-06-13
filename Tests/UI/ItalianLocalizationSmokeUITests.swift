import XCTest

/// Smoke tests with Italian locale. `dev` bundles all locales; lean release branches may skip via XCTSkip.
final class ItalianLocalizationSmokeUITests: DartBuddyUITestCase {
    private let config = LocalizationSmokeUITestSupport.LocaleConfig(
        languageCode: "it",
        localeIdentifier: "it_IT",
        playTabLabel: "Gioca",
        playersTabLabel: "Giocatori",
        settingsTabLabel: "Impostazioni"
    )

    func testTabBarUsesItalianLabels() throws {
        let app = LocalizationSmokeUITestSupport.launchForLocaleSmoke(self, config: config, extraArguments: ["-seed_players"])
        LocalizationSmokeUITestSupport.assertTabBarUsesLocalizedLabels(in: app, config: config, timeout: timeout)
    }

    func testPlaySetupUsesItalianChrome() throws {
        let app = LocalizationSmokeUITestSupport.launchForLocaleSmoke(self, config: config, extraArguments: ["-seed_players"])
        XCTAssertTrue(app.tabBars.buttons[config.playTabLabel].waitForExistence(timeout: timeout))
        app.tabBars.buttons[config.playTabLabel].tap()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: timeout))
    }
}
