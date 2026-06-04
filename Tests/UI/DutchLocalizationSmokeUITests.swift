import XCTest

/// Smoke tests with Dutch locale; functional UI tests keep English via default launch.
final class DutchLocalizationSmokeUITests: DartBuddyUITestCase {
    private var dutchLaunchArgs: [String] {
        ["-AppleLanguages", "(nl)", "-AppleLocale", "nl_NL"]
    }

    func testTabBarUsesDutchLabels() {
        let app = launchApp(dutchLaunchArgs)
        XCTAssertTrue(app.tabBars.buttons["Spelen"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.tabBars.buttons["Spelers"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.tabBars.buttons["Statistieken"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.tabBars.buttons["Geschiedenis"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.tabBars.buttons["Instellingen"].waitForExistence(timeout: timeout))
    }

    func testPlaySetupUsesDutchChrome() {
        let app = launchApp(dutchLaunchArgs)
        app.tabBars.buttons["Spelen"].tap()
        XCTAssertTrue(app.staticTexts["Dart-scorebord"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons["startMatchButton"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons["STARTEN"].waitForExistence(timeout: timeout))
    }
}
