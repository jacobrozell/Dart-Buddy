import XCTest

/// Smoke tests with French locale. `dev` bundles all locales; lean release branches may skip via XCTSkip.
final class FrenchLocalizationSmokeUITests: DartBuddyUITestCase {
    private let config = LocalizationSmokeUITestSupport.LocaleConfig(
        languageCode: "fr",
        localeIdentifier: "fr_FR",
        playTabLabel: "Jouer",
        playersTabLabel: "Joueurs",
        settingsTabLabel: "Réglages"
    )

    func testTabBarUsesFrenchLabels() throws {
        let app = LocalizationSmokeUITestSupport.launchForLocaleSmoke(self, config: config, extraArguments: ["-seed_players"])
        LocalizationSmokeUITestSupport.assertTabBarUsesLocalizedLabels(in: app, config: config, timeout: timeout)
    }

    func testPlaySetupUsesFrenchChrome() throws {
        let app = LocalizationSmokeUITestSupport.launchForLocaleSmoke(self, config: config, extraArguments: ["-seed_players"])
        LocalizationSmokeUITestSupport.tapPlayTab(in: app, config: config, timeout: timeout)
        LocalizationSmokeUITestSupport.assertPlaySetupChromeVisible(in: app, timeout: timeout)
    }
}
