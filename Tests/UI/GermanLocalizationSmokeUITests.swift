import XCTest

/// German (`de`) locale smoke — tab chrome plus Smart 1.2 store-surface strings.
/// Launch with `-AppleLanguages (de)`; uses `-enable_lean_product_surface` for 1.2 coverage.
final class GermanLocalizationSmokeUITests: DartBuddyUITestCase {
    private enum Copy {
        static let trainingPartner = "Trainingspartner"
        static let exportAccessibility = "Spielerdaten exportieren"
        static let addBot = "Bot hinzufügen"
        static let helpFAQ = "Hilfe & FAQ"
        static let halveIt = "Halbiere es"
        static let raid = "Überfall"
        static let modePickerTitle = "Modus wählen"
    }

    private let config = LocalizationSmokeUITestSupport.LocaleConfig(
        languageCode: "de",
        localeIdentifier: "de_DE",
        playTabLabel: "Spielen",
        playersTabLabel: "Spieler",
        activityTabLabel: "Aktivität",
        settingsTabLabel: "Einstellungen"
    )

    private func launchGermanSmart12(_ extraArguments: [String] = []) -> XCUIApplication {
        LocalizationSmokeUITestSupport.launchForLocaleSmoke(
            self,
            config: config,
            extraArguments: extraArguments,
            leanProductSurface: true
        )
    }

    func testTabBarUsesGermanLabels() throws {
        let app = launchGermanSmart12(["-seed_players"])
        LocalizationSmokeUITestSupport.assertTabBarUsesLocalizedLabels(in: app, config: config, timeout: timeout)
    }

    func testPlaySetupUsesGermanChrome() throws {
        let app = launchGermanSmart12(["-seed_players"])
        LocalizationSmokeUITestSupport.tapPlayTab(in: app, config: config, timeout: timeout)
        LocalizationSmokeUITestSupport.assertPlaySetupChromeVisible(in: app, timeout: timeout)
    }

    func testSmart12ModePickerShowsGermanShippedModes() throws {
        let app = launchGermanSmart12(["-seed_players"])
        LocalizationSmokeUITestSupport.tapPlayTab(in: app, config: config, timeout: timeout)
        LocalizationSmokeUITestSupport.openModePicker(in: app, timeout: timeout)

        XCTAssertTrue(
            app.staticTexts[Copy.modePickerTitle].waitForExistence(timeout: timeout),
            "Mode picker sheet should use German navigation title"
        )

        for catalogID in [
            "standard.x01",
            "standard.cricket",
            "party.baseball",
            "party.golf",
            "coop.raid",
            "practice.aroundTheClock",
            "practice.bobs27",
            "practice.halveIt",
        ] {
            LocalizationSmokeUITestSupport.assertModePickerCardVisible(
                catalogID: catalogID,
                in: app,
                timeout: timeout
            )
        }

        LocalizationSmokeUITestSupport.assertStaticText(Copy.halveIt, in: app, timeout: timeout)
        LocalizationSmokeUITestSupport.assertStaticText(Copy.raid, in: app, timeout: timeout)

        XCTAssertFalse(app.buttons["modes_card_practice.chaseTheDragon"].exists)
    }

    func testSmart12TrainingPartnerSectionUsesGermanCopy() throws {
        let app = launchGermanSmart12(["-seed_training_locked"])
        LocalizationSmokeUITestSupport.tapPlayersTab(in: app, config: config, timeout: timeout)

        XCTAssertTrue(app.buttons["player_row_Alice"].waitForExistence(timeout: timeout))
        app.buttons["player_row_Alice"].tap()

        LocalizationSmokeUITestSupport.assertStaticText(Copy.trainingPartner, in: app, timeout: timeout)
        XCTAssertTrue(
            app.descendants(matching: .any)["training_bot_eligibility_progress"].firstMatch
                .waitForExistence(timeout: timeout),
            "Locked Training Partner should show eligibility progress"
        )
    }

    func testSmart12ExportButtonUsesGermanLabel() throws {
        let app = launchGermanSmart12(["-seed_demo"])
        LocalizationSmokeUITestSupport.tapPlayersTab(in: app, config: config, timeout: timeout)

        XCTAssertTrue(app.buttons["player_row_Jacob"].waitForExistence(timeout: timeout))
        app.buttons["player_row_Jacob"].tap()
        XCTAssertTrue(app.staticTexts["X01"].waitForExistence(timeout: timeout + 10))

        let exportButton = app.buttons["playerDetail_export"]
        XCTAssertTrue(exportButton.waitForExistence(timeout: timeout))
        XCTAssertEqual(exportButton.label, Copy.exportAccessibility)
        XCTAssertTrue(exportButton.isEnabled)
    }

    func testSmart12AddBotMenuUsesGermanLabel() throws {
        let app = launchGermanSmart12(["-seed_training_partner"])
        LocalizationSmokeUITestSupport.tapPlayTab(in: app, config: config, timeout: timeout + 30)

        LocalizationSmokeUITestSupport.assertButton(
            identifier: "setup_addBot",
            localizedLabel: Copy.addBot,
            in: app,
            timeout: timeout
        )
        app.buttons["setup_addBot"].tap()

        XCTAssertTrue(
            app.buttons["training_bot_add_setup"].waitForExistence(timeout: timeout + 10),
            "Add Bot menu should list the linked Training Partner"
        )
    }

    func testSettingsSupportLinkUsesGermanLabel() throws {
        let app = launchGermanSmart12(["-seed_players"])
        LocalizationSmokeUITestSupport.tapTab(
            identifier: "tab_settings",
            label: config.settingsTabLabel,
            in: app,
            timeout: timeout
        )

        scrollToSettingsControl("settings_supportFAQLink", in: app, timeout: timeout)
        XCTAssertTrue(
            app.descendants(matching: .any)["settings_supportFAQLink"].waitForExistence(timeout: timeout)
        )
        LocalizationSmokeUITestSupport.assertStaticText(Copy.helpFAQ, in: app, timeout: timeout)
    }
}
