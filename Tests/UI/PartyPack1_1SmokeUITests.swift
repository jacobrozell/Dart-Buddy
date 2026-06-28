import XCTest

/// Party Pack 1.1 smoke — matches `docs/release/1.1.0-ship-checklist.md` §2 and §4.
/// Runs with `-enable_lean_product_surface` (Release defaults to `party1_1` on `release/1.1.0`).
/// **CI:** `DartBuddyUILean` scheme on `release/*` branches.
final class PartyPack1_1SmokeUITests: DartBuddyUITestCase {
    private static let shippedModeCatalogIDs = [
        "standard.x01",
        "standard.cricket",
        "party.baseball",
        "party.killer",
        "party.shanghai",
        "coop.raid",
        "practice.aroundTheClock",
    ]

    private static let hiddenModeCatalogIDs = [
        "party.golf",
        "practice.aroundTheClock180",
        "standard.americanCricket",
    ]

    private func launchPartyPackApp(_ extraArguments: [String] = []) -> XCUIApplication {
        launchAppWithLeanProductSurface(extraArguments)
    }

    private func launchPartyPackAppShowingHighlights(_ extraArguments: [String] = []) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = [
            "-ui_test_reset",
            "-disable_firebase_analytics",
            "-enable_lean_product_surface",
        ] + extraArguments
        applyDefaultLaunchEnvironment(to: app)
        app.launch()
        waitForAppBootstrapReady(in: app, timeout: 30)
        return app
    }

    func testPartyPackShellShowsFourTabsWithoutModes() {
        let app = launchPartyPackApp(["-seed_players"])

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

    func testPartyPackModePickerListsExactlySevenModes() {
        let app = launchPartyPackApp(["-seed_players"])
        ensurePlayTab(app, timeout: timeout)

        XCTAssertTrue(app.buttons["setup_changeModeButton"].waitForExistence(timeout: timeout))
        app.buttons["setup_changeModeButton"].tap()

        for catalogId in Self.shippedModeCatalogIDs {
            let card = app.descendants(matching: .any)["modes_card_\(catalogId)"]
            var found = card.waitForExistence(timeout: 2)
            if !found {
                for _ in 0 ..< 8 where card.exists == false {
                    app.swipeUp()
                }
                found = card.waitForExistence(timeout: timeout)
            }
            XCTAssertTrue(found, "Mode picker should list \(catalogId)")
        }

        for catalogId in Self.hiddenModeCatalogIDs {
            XCTAssertFalse(
                app.buttons["modes_card_\(catalogId)"].exists,
                "Mode picker should not tease \(catalogId)"
            )
        }

        for section in ["standard", "party", "practice", "coop"] {
            XCTAssertFalse(
                app.buttons["modePicker_moreComing_\(section)"].exists,
                "Mode picker should not show coming-soon rows for \(section)"
            )
        }
    }

    func testPartyPackX01MatchStartsFromPlaySetup() {
        let app = launchPartyPackApp(["-seed_players", "-ui_test_disable_feedback"])
        ensurePlayTab(app, timeout: timeout + 10)

        configureFastX01MatchForUITest(app, timeout: timeout + 10)
        selectPlayerFromRoster("Alice", in: app)
        selectPlayerFromRoster("Bob", in: app)
        tapStartMatch(in: app, timeout: timeout)
        waitForX01MatchBoard(in: app, timeout: timeout + 5)

        XCTAssertTrue(app.buttons["pad_20"].waitForExistence(timeout: timeout))
    }

    func testPartyPackCricketNormalMatchStartsFromPlaySetup() {
        let app = launchPartyPackApp(["-seed_players"])
        ensurePlayTab(app, timeout: timeout)

        selectCricketMode(in: app)
        selectPlayerFromRoster("Alice", in: app)
        selectPlayerFromRoster("Bob", in: app)
        tapStartMatch(in: app, timeout: timeout)

        XCTAssertTrue(app.buttons["cricket_20"].waitForExistence(timeout: timeout + 5))
    }

    func testPartyPackBaseballMatchStartsFromPlaySetup() {
        let app = launchPartyPackApp(["-seed_players"])
        ensurePlayTab(app, timeout: timeout)

        selectModeFromPlaySetupPicker("party.baseball", in: app, expectedModeName: "Baseball", timeout: timeout)
        selectPlayerFromRoster("Alice", in: app)
        selectPlayerFromRoster("Bob", in: app)
        tapStartMatch(in: app, timeout: timeout)

        waitForMatchGameplayChrome(
            headerIdentifier: "baseball_match_header",
            in: app,
            timeout: timeout + 15
        )
    }

    func testPartyPackKillerMatchStartsWithThreePlayers() {
        let app = launchPartyPackApp(["-seed_players", "-ui_test_disable_feedback"])
        ensurePlayTab(app, timeout: timeout)

        selectModeFromPlaySetupPicker("party.killer", in: app, expectedModeName: "Killer", timeout: timeout + 10)
        selectAliceBobAndCarol(from: app)
        tapStartMatch(in: app, timeout: timeout + 15)

        XCTAssertTrue(
            app.buttons["killer_undo"].waitForExistence(timeout: timeout + 30)
                || app.descendants(matching: .any)["killer_match_header"].waitForExistence(timeout: timeout + 30),
            "Killer match should open in pick or play phase"
        )
    }

    func testPartyPackKillerSetupBlocksTwoPlayers() {
        let app = launchPartyPackApp(["-seed_players"])
        ensurePlayTab(app, timeout: timeout + 10)

        selectModeFromPlaySetupPicker("party.killer", in: app, expectedModeName: "Killer", timeout: timeout + 10)
        selectPlayerFromRoster("Alice", in: app, timeout: timeout + 15)
        selectPlayerFromRoster("Bob", in: app, timeout: timeout + 15)

        let start = app.buttons["startMatchButton"]
        XCTAssertTrue(start.waitForExistence(timeout: timeout))
        XCTAssertFalse(start.isEnabled, "Killer should block start with only two players")

        let inlineHints = app.descendants(matching: .any)["setupValidationHints"]
        let killerValidationCopy = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] %@", "three players")
        ).firstMatch
        if inlineHints.waitForExistence(timeout: 2),
           inlineHints.label.localizedCaseInsensitiveContains("three players") {
            XCTAssertTrue(inlineHints.exists)
        } else {
            XCTAssertTrue(
                killerValidationCopy.waitForExistence(timeout: timeout),
                "Killer setup should explain the three-player minimum"
            )
        }
    }

    func testPartyPackShanghaiMatchStartsFromPlaySetup() {
        let app = launchPartyPackApp(["-seed_players"])
        ensurePlayTab(app, timeout: timeout)

        selectModeFromPlaySetupPicker("party.shanghai", in: app, expectedModeName: "Shanghai", timeout: timeout)
        selectPlayerFromRoster("Alice", in: app)
        selectPlayerFromRoster("Bob", in: app)
        tapStartMatch(in: app, timeout: timeout)

        waitForMatchGameplayChrome(
            headerIdentifier: "shanghai_match_header",
            in: app,
            timeout: timeout + 15
        )
    }

    func testPartyPackAroundTheClockStartsSolo() {
        let app = launchPartyPackApp(["-seed_players"])
        ensurePlayTab(app, timeout: timeout)

        selectModeFromPlaySetupPicker(
            "practice.aroundTheClock",
            in: app,
            expectedModeName: "Around the Clock",
            timeout: timeout
        )
        selectPlayerFromRoster("Alice", in: app)
        XCTAssertFalse(
            app.descendants(matching: .any)["setup_selected_Bob"].exists,
            "Around the Clock solo setup should not require a second player"
        )
        let start = app.buttons["startMatchButton"]
        XCTAssertTrue(start.waitForExistence(timeout: timeout))
        waitForStartEnabled(start, timeout: timeout)
        tapStartMatch(in: app, timeout: timeout)

        waitForMatchGameplayChrome(
            headerIdentifier: "aroundTheClock_match_header",
            in: app,
            timeout: timeout + 20
        )
    }

    func testPartyPackRaidMatchStartsSolo() {
        let app = launchPartyPackApp(["-seed_players", "-ui_test_disable_feedback"])
        ensurePlayTab(app, timeout: timeout)

        selectModeFromPlaySetupPicker("coop.raid", in: app, expectedModeName: "Raid", timeout: timeout)
        selectPlayerFromRoster("Alice", in: app)
        XCTAssertFalse(
            app.descendants(matching: .any)["setup_selected_Bob"].exists,
            "Raid solo setup should not require a second hero"
        )
        let start = app.buttons["startMatchButton"]
        XCTAssertTrue(start.waitForExistence(timeout: timeout))
        waitForStartEnabled(start, timeout: timeout)
        tapStartMatch(in: app, timeout: timeout)

        waitForMatchGameplayChrome(
            headerIdentifier: "raid_match_header",
            in: app,
            timeout: timeout + 20
        )
    }

    func testPartyPackAddBotMenuOffersCustomBotCreation() {
        let app = launchPartyPackApp(["-seed_players"])
        ensurePlayTab(app, timeout: timeout)

        let addBot = app.buttons["Add Bot"]
        XCTAssertTrue(addBot.waitForExistence(timeout: timeout))
        addBot.tap()

        let customBotOption = app.buttons["setup_addCustomBot"]
        let customBotByLabel = app.buttons.containing(
            NSPredicate(format: "label CONTAINS %@", "Custom Bot")
        ).firstMatch
        if !customBotOption.waitForExistence(timeout: timeout) {
            XCTAssertTrue(
                waitForSetupMenu(in: app, timeout: timeout) || customBotByLabel.waitForExistence(timeout: 1),
                "Add Bot menu should present setup options"
            )
        }
        if customBotOption.exists {
            XCTAssertTrue(customBotOption.exists)
        } else {
            XCTAssertTrue(
                customBotByLabel.waitForExistence(timeout: timeout),
                "Party Pack should offer custom bot creation in Add Bot menu"
            )
        }

        XCTAssertFalse(app.staticTexts["Training Partner"].exists)
    }

    func testPartyPackPlayerDetailHidesExportAndTrainingPartner() {
        let app = launchPartyPackApp(["-seed_demo"])
        waitForDemoSeed(in: app, timeout: timeout + 30)

        ensurePlayersTab(app, timeout: timeout)
        XCTAssertTrue(app.buttons["player_row_Jacob"].waitForExistence(timeout: timeout + 10))
        app.buttons["player_row_Jacob"].tap()
        XCTAssertTrue(app.staticTexts["X01"].waitForExistence(timeout: timeout + 15))

        XCTAssertFalse(app.buttons["playerDetail_export"].exists)
        XCTAssertFalse(app.staticTexts["Training Partner"].exists)
    }

    func testPartyPackResumeActiveMatchFromPlayHome() {
        let app = launchPartyPackApp(["-seed_demo"])
        waitForDemoSeed(in: app, timeout: timeout + 30)

        let resume = app.buttons["resumeMatchButton"]
        XCTAssertTrue(resume.waitForExistence(timeout: timeout), "Demo seed should expose a resumable match")
        resume.tap()

        assertActiveScoreCardLabel(
            app,
            contains: "121",
            timeout: timeout + 5
        )
    }

    func testPartyPackActivitySegmentsSwitchHistoryAndStatistics() {
        let app = launchPartyPackApp(["-seed_demo"])
        waitForDemoSeed(in: app, timeout: timeout + 30)

        ensureActivityHistorySegment(app, timeout: timeout)
        waitForSeededActivityHistoryContent(app, timeout: timeout + 15)
        XCTAssertTrue(
            app.staticTexts["FINISHED"].waitForExistence(timeout: timeout + 5),
            "Demo history should list completed games as FINISHED"
        )
        XCTAssertTrue(
            app.buttons["activityModeFilterMenu"].waitForExistence(timeout: timeout),
            "Activity history should expose the mode filter menu"
        )

        ensureActivityStatisticsSegment(app, timeout: timeout)
        waitForActivityStatisticsAuditReady(app, timeout: timeout + 10)
        let gamesLabel = app.descendants(matching: .any).containing(
            NSPredicate(format: "label CONTAINS[c] %@", "Games")
        ).firstMatch
        XCTAssertTrue(
            gamesLabel.waitForExistence(timeout: timeout + 5),
            "Statistics segment should show the Games summary"
        )
        XCTAssertTrue(
            app.buttons["activityModeFilterMenu"].waitForExistence(timeout: timeout),
            "Activity statistics should expose the mode filter menu"
        )
    }

    func testPartyPackSettingsExposeCoreToggles() {
        let app = launchPartyPackApp(["-seed_players"])
        ensureSettingsTab(app, timeout: timeout + 10)

        scrollToSettingsControl("settings_themePicker", in: app, timeout: timeout + 10)
        XCTAssertTrue(app.descendants(matching: .any)["settings_themePicker"].waitForExistence(timeout: timeout))
        scrollToSettingsControl("settings_soundToggle", in: app, timeout: timeout + 10)
        let soundToggle = app.descendants(matching: .any)["settings_soundToggle"]
        XCTAssertTrue(soundToggle.waitForExistence(timeout: timeout))
    }

    func testPartyPackHiddenModeResumeNotOffered() {
        let app = launchPartyPackApp(["-seed_players", "-seed_unreachable_active_match"])
        ensurePlayTab(app, timeout: timeout + 10)

        assertBrandAppTitleVisible(in: app, timeout: timeout)
        XCTAssertFalse(
            app.buttons["resumeMatchButton"].waitForExistence(timeout: 2),
            "Unreachable in-progress match should not expose Resume on Play home"
        )
        XCTAssertTrue(
            app.buttons["startMatchButton"].waitForExistence(timeout: timeout),
            "Play setup should remain available when resume is blocked"
        )
    }

    func testReleaseHighlightsSheetCanBeDismissed() {
        let app = launchPartyPackAppShowingHighlights(["-seed_players", "-skip_onboarding"])
        let sheet = app.otherElements["release_highlights_sheet"]
        XCTAssertTrue(sheet.waitForExistence(timeout: timeout), "Party Pack upgrade should show What's New once")
        app.buttons["release_highlights_gotIt"].tap()
        XCTAssertFalse(sheet.waitForExistence(timeout: 2), "Got It should dismiss the highlights sheet")
    }
}
