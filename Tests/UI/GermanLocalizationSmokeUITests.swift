import XCTest

/// Smoke tests with German locale; functional UI tests keep English via default launch.
final class GermanLocalizationSmokeUITests: DartBuddyUITestCase {
    private var germanLaunchArgs: [String] {
        ["-AppleLanguages", "(de)", "-AppleLocale", "de_DE"]
    }

    func testTabBarUsesGermanLabels() {
        let app = launchApp(germanLaunchArgs)
        XCTAssertTrue(app.tabBars.buttons["Spielen"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.tabBars.buttons["Spieler"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.tabBars.buttons["Statistik"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.tabBars.buttons["Verlauf"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.tabBars.buttons["Einstellungen"].waitForExistence(timeout: timeout))
    }

    func testPlaySetupUsesGermanChrome() {
        let app = launchApp(germanLaunchArgs)
        app.tabBars.buttons["Spielen"].tap()
        XCTAssertTrue(app.staticTexts["Dart-Scoreboard"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons["startMatchButton"].waitForExistence(timeout: timeout))
    }
}
