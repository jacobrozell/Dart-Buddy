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

    func testLeanPlaySetupOpensModePickerSheet() {
        let app = launchApp(["-seed_players"])
        ensurePlayTab(app, timeout: timeout)

        XCTAssertTrue(
            app.buttons["setup_changeModeButton"].waitForExistence(timeout: timeout),
            "Lean 1.0 should offer Change mode via the in-place picker"
        )
        app.buttons["setup_changeModeButton"].tap()
        XCTAssertTrue(
            app.buttons["modes_card_standard.x01"].waitForExistence(timeout: timeout),
            "Mode picker should list X01"
        )
        XCTAssertTrue(
            app.buttons["modes_card_standard.cricket"].waitForExistence(timeout: timeout),
            "Mode picker should list Cricket"
        )
        XCTAssertFalse(
            app.buttons["modes_card_standard.americanCricket"].exists,
            "Lean 1.0 mode picker should not tease American Cricket"
        )
        XCTAssertFalse(
            app.buttons["modes_card_party.baseball"].exists,
            "Lean 1.0 mode picker should not tease party modes"
        )
        XCTAssertFalse(
            app.buttons["modePicker_moreComing_standard"].exists,
            "Lean 1.0 mode picker should not show coming-soon standard rows"
        )
        XCTAssertFalse(
            app.buttons["modePicker_moreComing_party"].exists,
            "Lean 1.0 mode picker should not show coming-soon party rows"
        )
    }

    func testLeanX01MatchStartsFromPlaySetup() {
        let app = launchApp(["-seed_players", "-ui_test_disable_feedback"])
        ensurePlayTab(app, timeout: timeout + 10)

        configureFastX01MatchForUITest(app, timeout: timeout + 10)
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

        selectCricketMode(in: app)
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
            app.staticTexts["FINISHED"].waitForExistence(timeout: timeout + 5),
            "Demo history should list a completed game as FINISHED"
        )

        ensureActivityStatisticsSegment(app, timeout: timeout)
        XCTAssertTrue(
            app.staticTexts["Games"].waitForExistence(timeout: timeout + 5),
            "Statistics segment should show the Games summary"
        )
    }

    func testLeanAddBotMenuOffersCustomBotCreation() {
        let app = launchApp(["-seed_players"])
        ensurePlayTab(app, timeout: timeout)

        let addBot = app.buttons["Add Bot"]
        XCTAssertTrue(addBot.waitForExistence(timeout: timeout))
        addBot.tap()

        let customBotOption = app.buttons["setup_addCustomBot"]
        let customBotByLabel = app.buttons.containing(
            NSPredicate(format: "label CONTAINS %@", "Custom Bot")
        ).firstMatch
        if customBotOption.waitForExistence(timeout: 2) {
            XCTAssertTrue(customBotOption.exists)
        } else {
            XCTAssertTrue(
                customBotByLabel.waitForExistence(timeout: timeout),
                "Lean 1.0 should offer custom bot creation in Add Bot menu"
            )
        }

        XCTAssertFalse(
            app.staticTexts["Training Partner"].exists,
            "Lean 1.0 should not expose Training Partner in Add Bot menu"
        )
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

    func testLeanResetAllLocalDataClearsSeededPlayers() {
        let app = launchApp(["-seed_demo"])
        waitForDemoSeed(in: app, timeout: timeout + 30)

        ensureSettingsTab(app, timeout: timeout + 10)
        scrollToSettingsControl("settings_resetAllDataButton", in: app, timeout: timeout + 15)
        app.buttons["settings_resetAllDataButton"].tap()

        let alert = app.alerts["Reset all local data?"]
        XCTAssertTrue(alert.waitForExistence(timeout: timeout))
        alert.buttons["Reset Data"].tap()
        waitForLocalDataResetToFinish(in: app, timeout: timeout + 10)

        ensurePlayTab(app, timeout: timeout + 15)
        assertBrandAppTitleVisible(in: app, timeout: timeout + 10)

        tapTabBarItem(named: "Players", identifier: "tab_players", in: app, timeout: timeout)
        XCTAssertFalse(
            app.buttons["player_row_Jacob"].waitForExistence(timeout: 2),
            "Reset should remove demo players from the roster"
        )
    }

    func testLeanResumeActiveMatchFromPlayHome() {
        let app = launchApp(["-seed_demo"])

        let resume = app.buttons["resumeMatchButton"]
        XCTAssertTrue(resume.waitForExistence(timeout: timeout), "Demo seed should expose a resumable match")
        resume.tap()

        assertActiveScoreCardLabel(
            app,
            contains: "121",
            timeout: timeout + 5
        )
    }

    func testLeanX01ForfeitAfterOneTurn() {
        let app = launchApp(["-seed_players"])
        startTwoPlayerX01Match(from: app, timeout: timeout)
        scoreSingleVisit(app, segments: [20, 20, 20], timeout: timeout)
        forfeitMatchFromExit(in: app, timeout: timeout)
        assertMatchSummaryForfeitBanner(in: app, timeout: timeout + 5)
        XCTAssertFalse(
            app.buttons["matchSummaryUndoLastThrow"].waitForExistence(timeout: 2),
            "Forfeit summary should not offer undo"
        )
        app.buttons["View Game Statistics"].tap()
        XCTAssertTrue(app.staticTexts["Game Statistics"].waitForExistence(timeout: timeout))
        let back = app.navigationBars.buttons.element(boundBy: 0)
        if back.waitForExistence(timeout: timeout) {
            back.tap()
        }
        tapSummaryDone(in: app, timeout: timeout)
        ensureActivityHistorySegment(app, timeout: timeout)
        XCTAssertTrue(app.staticTexts["FORFEIT"].waitForExistence(timeout: timeout))
    }
}
