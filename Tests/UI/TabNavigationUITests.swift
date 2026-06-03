import XCTest

final class TabNavigationUITests: DartBuddyUITestCase {
    func testTabsShowKeyScreens() {
        let app = launchApp(["-seed_demo"])

        XCTAssertTrue(app.staticTexts["Dart Scoreboard"].waitForExistence(timeout: timeout), "Home should show the setup board title")

        app.tabBars.buttons["Statistics"].tap()
        XCTAssertTrue(app.staticTexts["Statistics"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["Games"].waitForExistence(timeout: timeout), "Statistics should show the Games table")
        let jacobStat = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Jacob")).firstMatch
        XCTAssertTrue(jacobStat.waitForExistence(timeout: timeout), "Statistics should rank Jacob")

        app.tabBars.buttons["History"].tap()
        XCTAssertTrue(app.staticTexts["History"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["FINISHED"].waitForExistence(timeout: timeout), "A completed game should be listed as FINISHED")

        app.tabBars.buttons["Players"].tap()
        XCTAssertTrue(app.staticTexts["Jacob"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["Sam"].waitForExistence(timeout: timeout))
    }
}
