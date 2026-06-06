import XCTest

/// Smoke tests with Spanish locale; functional UI tests keep English via default launch.
final class SpanishLocalizationSmokeUITests: DartBuddyUITestCase {
    private var spanishLaunchArgs: [String] {
        ["-AppleLanguages", "(es)", "-AppleLocale", "es_ES"]
    }

    func testTabBarUsesSpanishLabels() {
        let app = launchApp(spanishLaunchArgs)
        XCTAssertTrue(app.tabBars.buttons["Jugar"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.tabBars.buttons["Modos"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.tabBars.buttons["Jugadores"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.tabBars.buttons["Actividad"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.tabBars.buttons["Ajustes"].waitForExistence(timeout: timeout))
    }

    func testPlaySetupUsesSpanishChrome() {
        let app = launchApp(spanishLaunchArgs)
        app.tabBars.buttons["Jugar"].tap()
        assertBrandAppTitleVisible(in: app, timeout: timeout)
        XCTAssertTrue(app.buttons["startMatchButton"].waitForExistence(timeout: timeout))
    }

    func testSettingsUsesSpanishSectionLabels() {
        let app = launchApp(spanishLaunchArgs + ["-ui_test_disable_feedback"])
        app.tabBars.buttons["Ajustes"].tap()
        XCTAssertTrue(app.staticTexts["Apariencia"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["Modo inicial"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["Valores predeterminados de partida"].waitForExistence(timeout: timeout))
        scrollToSettingsControl("settings_botStaggerToggle", in: app, timeout: timeout)
        XCTAssertTrue(app.staticTexts["Durante el juego"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["Oponentes bot"].waitForExistence(timeout: timeout))
    }
}
