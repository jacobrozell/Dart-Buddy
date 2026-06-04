import XCTest

/// Smoke tests with Spanish locale; functional UI tests keep English via default launch.
final class SpanishLocalizationSmokeUITests: DartBuddyUITestCase {
    private var spanishLaunchArgs: [String] {
        ["-AppleLanguages", "(es)", "-AppleLocale", "es_ES"]
    }

    func testTabBarUsesSpanishLabels() {
        let app = launchApp(spanishLaunchArgs)
        XCTAssertTrue(app.tabBars.buttons["Jugar"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.tabBars.buttons["Jugadores"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.tabBars.buttons["Estadísticas"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.tabBars.buttons["Historial"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.tabBars.buttons["Ajustes"].waitForExistence(timeout: timeout))
    }

    func testPlaySetupUsesSpanishChrome() {
        let app = launchApp(spanishLaunchArgs)
        app.tabBars.buttons["Jugar"].tap()
        XCTAssertTrue(app.staticTexts["Dart Scoreboard"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons["startMatchButton"].waitForExistence(timeout: timeout))
    }
}
