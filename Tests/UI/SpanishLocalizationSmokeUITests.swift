import XCTest

final class SpanishLocalizationSmokeUITests: DartBuddyUITestCase {
    private let config = LocalizationSmokeUITestSupport.LocaleConfig(
        languageCode: "es",
        localeIdentifier: "es_ES",
        playTabLabel: "Jugar",
        playersTabLabel: "Jugadores",
        settingsTabLabel: "Ajustes"
    )

    func testTabBarUsesSpanishLabels() throws {
        let app = LocalizationSmokeUITestSupport.launchForLocaleSmoke(self, config: config, extraArguments: ["-seed_players"])
        LocalizationSmokeUITestSupport.assertTabBarUsesLocalizedLabels(in: app, config: config, timeout: timeout)
    }

    func testPlaySetupUsesSpanishChrome() throws {
        let app = LocalizationSmokeUITestSupport.launchForLocaleSmoke(self, config: config, extraArguments: ["-seed_players"])
        XCTAssertTrue(app.tabBars.buttons[config.playTabLabel].waitForExistence(timeout: timeout))
        app.tabBars.buttons[config.playTabLabel].tap()
        XCTAssertTrue(app.navigationBars.firstMatch.waitForExistence(timeout: timeout))
    }
}
