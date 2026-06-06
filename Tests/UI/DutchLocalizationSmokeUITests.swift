import XCTest

/// Smoke tests with Dutch locale; functional UI tests keep English via default launch.
final class DutchLocalizationSmokeUITests: DartBuddyUITestCase {
    private var dutchLaunchArgs: [String] {
        ["-AppleLanguages", "(nl)", "-AppleLocale", "nl_NL"]
    }

    func testTabBarUsesDutchLabels() {
        let app = launchApp(dutchLaunchArgs)
        XCTAssertTrue(app.tabBars.buttons["Spelen"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.tabBars.buttons["Modi"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.tabBars.buttons["Spelers"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.tabBars.buttons["Activiteit"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.tabBars.buttons["Instellingen"].waitForExistence(timeout: timeout))
    }

    func testPlaySetupUsesDutchChrome() {
        let app = launchApp(dutchLaunchArgs)
        app.tabBars.buttons["Spelen"].tap()
        XCTAssertTrue(app.staticTexts["Dart-scorebord"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons["startMatchButton"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons["STARTEN"].waitForExistence(timeout: timeout))
    }

    func testSettingsUsesDutchSectionLabels() {
        let app = launchApp(dutchLaunchArgs + ["-ui_test_disable_feedback"])
        app.tabBars.buttons["Instellingen"].tap()
        XCTAssertTrue(app.staticTexts["Weergave"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["Startmodus"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["Wedstrijdstandaarden"].waitForExistence(timeout: timeout))
        scrollToSettingsControl("settings_botStaggerToggle", in: app, timeout: timeout)
        XCTAssertTrue(app.staticTexts["Tijdens het spel"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["Bot-tegenstanders"].waitForExistence(timeout: timeout))
    }
}
