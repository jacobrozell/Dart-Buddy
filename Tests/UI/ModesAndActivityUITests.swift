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
}
