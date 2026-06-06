import XCTest

final class ModesAndActivityUITests: DartBuddyUITestCase {
    func testModesCatalogPrefillsPlaySetup() {
        let app = launchAppWithFullProductSurface(["-seed_players"])

        selectModeFromCatalog("party.killer", in: app, expectedModeName: "Killer", timeout: timeout)
        XCTAssertTrue(app.buttons["setup_changeModeButton"].waitForExistence(timeout: timeout))
    }

    func testChangeModeOpensModesTab() {
        let app = launchAppWithFullProductSurface(["-seed_players"])

        ensurePlayTab(app, timeout: timeout)
        app.buttons["setup_changeModeButton"].tap()
        XCTAssertTrue(app.textFields["modesSearchField"].waitForExistence(timeout: timeout))
    }

    func testActivitySegmentsSwitchHistoryAndStatistics() {
        let app = launchApp(["-seed_demo"])

        ensureActivityHistorySegment(app, timeout: timeout)
        XCTAssertTrue(
            app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "FINISHED")).firstMatch
                .waitForExistence(timeout: timeout + 5),
            "History segment should list completed matches"
        )

        ensureActivityStatisticsSegment(app, timeout: timeout)
        XCTAssertTrue(app.staticTexts["Games"].waitForExistence(timeout: timeout))
    }
}
