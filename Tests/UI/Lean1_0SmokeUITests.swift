import XCTest

/// Lean 1.0 smoke — matches the device QA matrix in `docs/release/release_checklist.md` §1.
/// Runs against default product surface (no `-enable_full_product_surface`).
final class Lean1_0SmokeUITests: DartBuddyUITestCase {
    func testLeanShellShowsFourTabsWithoutModes() {
        let app = launchApp(["-seed_players"])

        assertBrandAppTitleVisible(in: app, timeout: timeout)

        for tab in [
            ("Play", "tab_play"),
            ("Players", "tab_players"),
            ("Activity", "tab_activity"),
            ("Settings", "tab_settings"),
        ] {
            tapTabBarItem(named: tab.0, identifier: tab.1, in: app, timeout: timeout)
        }

        XCTAssertFalse(
            app.tabBars.buttons["Modes"].exists,
            "Lean 1.0 should not expose the Modes tab"
        )
        XCTAssertFalse(
            app.tabBars.buttons["tab_modes"].exists,
            "Lean 1.0 should not expose the Modes tab identifier"
        )
    }

    func testLeanPlaySetupHidesChangeModeButton() {
        let app = launchApp(["-seed_players"])
        ensurePlayTab(app, timeout: timeout)

        XCTAssertFalse(
            app.buttons["setup_changeModeButton"].exists,
            "Lean 1.0 should not offer Change mode navigation to the hidden Modes tab"
        )
    }

    func testLeanX01MatchStartsFromPlaySetup() {
        let app = launchApp(["-seed_players"])
        ensurePlayTab(app, timeout: timeout)

        selectPlayerFromRoster("Alice", in: app)
        selectPlayerFromRoster("Bob", in: app)
        tapStartMatch(in: app, timeout: timeout)
        waitForX01MatchBoard(in: app, timeout: timeout + 5)

        XCTAssertTrue(app.buttons["pad_20"].waitForExistence(timeout: timeout))
    }

    func testLeanCricketNormalMatchStartsFromPlaySetup() {
        let app = launchApp(["-seed_players"])
        ensurePlayTab(app, timeout: timeout)

        selectCricketMode(in: app)
        selectPlayerFromRoster("Alice", in: app)
        selectPlayerFromRoster("Bob", in: app)
        tapStartMatch(in: app, timeout: timeout)

        XCTAssertTrue(app.buttons["cricket_20"].waitForExistence(timeout: timeout + 5))
    }

    func testLeanCricketCutThroatMatchStartsFromPlaySetup() {
        let app = launchApp(["-seed_players"])
        ensurePlayTab(app, timeout: timeout)

        tapCricketCutThroatMode(in: app)
        selectPlayerFromRoster("Alice", in: app)
        selectPlayerFromRoster("Bob", in: app)
        tapStartMatch(in: app, timeout: timeout)

        XCTAssertTrue(app.buttons["cricket_20"].waitForExistence(timeout: timeout + 5))
    }

    func testLeanActivitySegmentsSwitchHistoryAndStatistics() {
        let app = launchApp(["-seed_demo"])

        ensureActivityHistorySegment(app, timeout: timeout)
        XCTAssertTrue(
            app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "FINISHED")).firstMatch
                .waitForExistence(timeout: timeout + 5)
        )

        ensureActivityStatisticsSegment(app, timeout: timeout)
        XCTAssertTrue(app.staticTexts["Games"].waitForExistence(timeout: timeout))
    }

    func testLeanPlayerDetailHidesExportAndTrainingPartner() {
        let app = launchApp(["-seed_demo"])

        tapTabBarItem(named: "Players", identifier: "tab_players", in: app, timeout: timeout)
        XCTAssertTrue(app.buttons["player_row_Jacob"].waitForExistence(timeout: timeout))
        app.buttons["player_row_Jacob"].tap()
        XCTAssertTrue(app.staticTexts["X01"].waitForExistence(timeout: timeout + 10))

        XCTAssertFalse(app.buttons["playerDetail_export"].exists)
        XCTAssertFalse(app.staticTexts["Training Partner"].exists)
    }

    func testLeanSettingsExposeCoreToggles() {
        let app = launchApp(["-seed_players"])
        ensureSettingsTab(app, timeout: timeout)

        XCTAssertTrue(app.staticTexts["Appearance"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["Starting Mode"].waitForExistence(timeout: timeout))
        scrollToFeedbackSwitches(app)
        XCTAssertTrue(app.switches["settings_soundToggle"].waitForExistence(timeout: timeout))
    }
}
