import XCTest

/// Smart 1.2 smoke — matches the store allowlist on `release/1.2.0`.
/// Runs with `-enable_lean_product_surface` (Release default on this branch).
/// **CI:** `DartBuddyUILean` scheme on `release/*` branches (see `docs/release/branch-strategy.md`).
final class Smart1_2SmokeUITests: DartBuddyUITestCase {
    private func launchSmart12App(_ extraArguments: [String] = []) -> XCUIApplication {
        launchAppWithLeanProductSurface(extraArguments)
    }

    func testSmart12ShellShowsFourTabsWithoutModes() {
        let app = launchSmart12App(["-seed_players"])

        assertBrandAppTitleVisible(in: app, timeout: timeout)

        for tab in [
            ("Play", "tab_play"),
            ("Players", "tab_players"),
            ("Activity", "tab_activity"),
            ("Settings", "tab_settings"),
        ] {
            tapTabBarItem(named: tab.0, identifier: tab.1, in: app, timeout: timeout)
        }

        XCTAssertFalse(app.tabBars.buttons["Modes"].exists)
        XCTAssertFalse(app.tabBars.buttons["tab_modes"].exists)
    }

    func testSmart12PlayerDetailShowsTrainingPartner() {
        let app = launchSmart12App(["-seed_training_locked"])

        ensurePlayersTab(app, timeout: timeout)
        XCTAssertTrue(app.buttons["player_row_Alice"].waitForExistence(timeout: timeout))
        app.buttons["player_row_Alice"].tap()

        XCTAssertTrue(app.staticTexts["Training Partner"].waitForExistence(timeout: timeout))
        XCTAssertTrue(
            app.descendants(matching: .any)["training_bot_eligibility_progress"].firstMatch.waitForExistence(timeout: timeout),
            "Locked state should show games-until-unlock progress"
        )
    }

    func testSmart12PlayerDetailShowsExport() {
        let app = launchSmart12App(["-seed_demo"])

        ensurePlayersTab(app, timeout: timeout)
        XCTAssertTrue(app.buttons["player_row_Jacob"].waitForExistence(timeout: timeout))
        app.buttons["player_row_Jacob"].tap()
        XCTAssertTrue(app.staticTexts["X01"].waitForExistence(timeout: timeout + 10))

        let exportButton = app.buttons["playerDetail_export"]
        XCTAssertTrue(exportButton.waitForExistence(timeout: timeout), "Smart 1.2 should expose player export")
        XCTAssertTrue(exportButton.isEnabled)
    }

    func testSmart12AddBotListsTrainingPartner() {
        let app = launchSmart12App(["-seed_training_partner"])

        ensurePlayTab(app, timeout: timeout + 30)

        let addBot = app.buttons["Add Bot"]
        XCTAssertTrue(addBot.waitForExistence(timeout: timeout))
        addBot.tap()

        XCTAssertTrue(
            app.buttons["training_bot_add_setup"].waitForExistence(timeout: timeout + 10),
            "Add Bot menu should list the linked Training Partner on smart 1.2"
        )
    }

    func testSmart12ModePickerShowsAllowlistAndHidesChaseTheDragon() {
        let app = launchSmart12App(["-seed_players"])
        ensurePlayTab(app, timeout: timeout)

        XCTAssertTrue(app.buttons["setup_changeModeButton"].waitForExistence(timeout: timeout))
        app.buttons["setup_changeModeButton"].tap()

        XCTAssertTrue(app.buttons["modes_card_standard.x01"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons["modes_card_standard.cricket"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons["modes_card_party.baseball"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons["modes_card_party.golf"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons["modes_card_practice.bobs27"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.buttons["modes_card_practice.halveIt"].waitForExistence(timeout: timeout))

        XCTAssertFalse(app.buttons["modes_card_standard.americanCricket"].exists)
        XCTAssertFalse(app.buttons["modes_card_practice.chaseTheDragon"].exists)
        XCTAssertFalse(app.buttons["modePicker_moreComing_party"].exists)
    }

    func testSmart12PracticePackSelectable() {
        let app = launchSmart12App(["-seed_players"])
        selectModeFromPlaySetupPicker("practice.bobs27", in: app, expectedModeName: "Bob", timeout: timeout)
    }

    func testSmart12ResumeActiveMatchFromPlayHome() {
        let app = launchSmart12App(["-seed_demo"])

        let resume = app.buttons["resumeMatchButton"]
        XCTAssertTrue(resume.waitForExistence(timeout: timeout), "Demo seed should expose a resumable match")
        resume.tap()

        assertActiveScoreCardLabel(app, contains: "121", timeout: timeout + 5)
    }
}
