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
        LocalizationSmokeUITestSupport.tapPlayTab(in: app, config: config, timeout: timeout)
        LocalizationSmokeUITestSupport.assertPlaySetupChromeVisible(in: app, timeout: timeout)
    }
}
