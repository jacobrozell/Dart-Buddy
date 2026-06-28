import XCTest

final class TabNavigationUITests: DartBuddyUITestCase {
    func testTabsShowKeyScreens() {
        let app = launchApp(["-seed_demo"])

        assertBrandAppTitleVisible(in: app, timeout: timeout)

        ensureActivityStatisticsSegment(app, timeout: timeout)
        XCTAssertTrue(app.staticTexts["Games"].waitForExistence(timeout: timeout), "Statistics should show the Games table")
        let jacobStat = app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Jacob")).firstMatch
        XCTAssertTrue(jacobStat.waitForExistence(timeout: timeout), "Statistics should rank Jacob")

        ensureActivityHistorySegment(app, timeout: timeout)
        XCTAssertTrue(app.staticTexts["FINISHED"].waitForExistence(timeout: timeout), "A completed game should be listed as FINISHED")

        tapTabBarItem(named: "Players", identifier: "tab_players", in: app)
        XCTAssertTrue(app.staticTexts["Jacob"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["Sam"].waitForExistence(timeout: timeout))

        ensureSettingsTab(app, timeout: timeout)
        XCTAssertTrue(app.staticTexts["Appearance"].waitForExistence(timeout: timeout))
        ensureSettingsSection("startingMode", in: app, timeout: timeout)
        XCTAssertTrue(app.staticTexts["Starting Mode"].waitForExistence(timeout: timeout))
    }

    func testModesTabShowsCatalogWhenFullSurfaceEnabled() {
        let app = launchAppWithFullProductSurface(["-seed_demo"])

        tapTabBarItem(named: "Modes", identifier: "tab_modes", in: app)
        XCTAssertTrue(app.buttons["modes_card_standard.x01"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons["modes_card_standard.cricket"].waitForExistence(timeout: timeout))
    }
}
