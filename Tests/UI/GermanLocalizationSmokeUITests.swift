import XCTest

final class GermanLocalizationSmokeUITests: DartBuddyUITestCase {
    private let config = LocalizationSmokeUITestSupport.LocaleConfig(
        languageCode: "de",
        localeIdentifier: "de_DE",
        playTabLabel: "Spielen",
        playersTabLabel: "Spieler",
        settingsTabLabel: "Einstellungen"
    )

    func testTabBarUsesGermanLabels() throws {
        let app = LocalizationSmokeUITestSupport.launchForLocaleSmoke(self, config: config, extraArguments: ["-seed_players"])
        LocalizationSmokeUITestSupport.assertTabBarUsesLocalizedLabels(in: app, config: config, timeout: timeout)
    }

    func testPlaySetupUsesGermanChrome() throws {
        let app = LocalizationSmokeUITestSupport.launchForLocaleSmoke(self, config: config, extraArguments: ["-seed_players"])
        XCTAssertTrue(app.tabBars.buttons[config.playTabLabel].waitForExistence(timeout: timeout))
        app.tabBars.buttons[config.playTabLabel].tap()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: timeout))
    }
}
