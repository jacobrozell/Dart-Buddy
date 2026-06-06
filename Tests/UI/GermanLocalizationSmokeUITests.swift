import XCTest

/// Smoke tests with German locale; functional UI tests keep English via default launch.
final class GermanLocalizationSmokeUITests: DartBuddyUITestCase {
    private var germanLaunchArgs: [String] {
        ["-AppleLanguages", "(de)", "-AppleLocale", "de_DE"]
    }

    func testTabBarUsesGermanLabels() {
        let app = launchApp(germanLaunchArgs)
        XCTAssertTrue(app.tabBars.buttons["Spielen"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.tabBars.buttons["Modi"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.tabBars.buttons["Spieler"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.tabBars.buttons["Aktivität"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.tabBars.buttons["Einstellungen"].waitForExistence(timeout: timeout))
    }

    func testPlaySetupUsesGermanChrome() {
        let app = launchApp(germanLaunchArgs)
        app.tabBars.buttons["Spielen"].tap()
        XCTAssertTrue(app.staticTexts["Dart-Scoreboard"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons["startMatchButton"].waitForExistence(timeout: timeout))
    }

    func testSettingsUsesGermanSectionLabels() {
        let app = launchApp(germanLaunchArgs + ["-ui_test_disable_feedback"])
        app.tabBars.buttons["Einstellungen"].tap()
        XCTAssertTrue(app.staticTexts["Darstellung"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["Startmodus"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["Spiel-Standards"].waitForExistence(timeout: timeout))
        scrollToSettingsControl("settings_botStaggerToggle", in: app, timeout: timeout)
        XCTAssertTrue(app.staticTexts["Während des Spiels"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["Bot-Gegner"].waitForExistence(timeout: timeout))
    }
}
