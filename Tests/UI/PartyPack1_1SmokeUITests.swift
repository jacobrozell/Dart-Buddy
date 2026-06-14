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
        "practice.aroundTheClock",
    ]

    private static let hiddenModeCatalogIDs = [
        "party.golf",
        "coop.raid",
        "practice.aroundTheClock180",
        "standard.americanCricket",
    ]

    private func launchPartyPackApp(_ extraArguments: [String] = []) -> XCUIApplication {
        launchAppWithLeanProductSurface(extraArguments)
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

    func testPartyPackModePickerListsExactlySixModes() {
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

    func testPartyPackBaseballMatchStartsFromPlaySetup() {
        let app = launchPartyPackApp(["-seed_players"])
        ensurePlayTab(app, timeout: timeout)

        selectModeFromPlaySetupPicker("party.baseball", in: app, expectedModeName: "Baseball", timeout: timeout)
        selectPlayerFromRoster("Alice", in: app)
        selectPlayerFromRoster("Bob", in: app)
        tapStartMatch(in: app, timeout: timeout)

        XCTAssertTrue(
            app.descendants(matching: .any)["baseball_match_header"].waitForExistence(timeout: timeout + 5)
        )
    }

    func testPartyPackKillerMatchStartsWithThreePlayers() {
        let app = launchPartyPackApp(["-seed_players"])
        ensurePlayTab(app, timeout: timeout)

        selectModeFromPlaySetupPicker("party.killer", in: app, expectedModeName: "Killer", timeout: timeout)
        selectAliceBobAndCarol(from: app)
        tapStartMatch(in: app, timeout: timeout + 10)

        XCTAssertTrue(
            app.descendants(matching: .any)["killer_match_header"].waitForExistence(timeout: timeout + 10),
            "Killer should open after start with three players"
        )
    }

    func testPartyPackShanghaiMatchStartsFromPlaySetup() {
        let app = launchPartyPackApp(["-seed_players"])
        ensurePlayTab(app, timeout: timeout)

        selectModeFromPlaySetupPicker("party.shanghai", in: app, expectedModeName: "Shanghai", timeout: timeout)
        selectPlayerFromRoster("Alice", in: app)
        selectPlayerFromRoster("Bob", in: app)
        tapStartMatch(in: app, timeout: timeout)

        XCTAssertTrue(
            app.descendants(matching: .any)["shanghai_match_header"].waitForExistence(timeout: timeout + 5)
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
        tapStartMatch(in: app, timeout: timeout)

        XCTAssertTrue(
            app.descendants(matching: .any)["aroundTheClock_match_header"].waitForExistence(timeout: timeout + 5)
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
        if customBotOption.waitForExistence(timeout: 2) {
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

        tapTabBarItem(named: "Players", identifier: "tab_players", in: app, timeout: timeout)
        XCTAssertTrue(app.buttons["player_row_Jacob"].waitForExistence(timeout: timeout + 10))
        app.buttons["player_row_Jacob"].tap()
        XCTAssertTrue(app.staticTexts["X01"].waitForExistence(timeout: timeout + 15))

        XCTAssertFalse(app.buttons["playerDetail_export"].exists)
        XCTAssertFalse(app.staticTexts["Training Partner"].exists)
    }

    func testPartyPackResumeActiveMatchFromPlayHome() {
        let app = launchPartyPackApp(["-seed_demo"])

        let resume = app.buttons["resumeMatchButton"]
        XCTAssertTrue(resume.waitForExistence(timeout: timeout), "Demo seed should expose a resumable match")
        resume.tap()

        assertActiveScoreCardLabel(
            app,
            contains: "121",
            timeout: timeout + 5
        )
    }
}
