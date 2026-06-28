import XCTest

final class SettingsUITests: DartBuddyUITestCase {
    func testSettingsTabShowsOrganizedSections() {
        let app = launchApp(["-seed_players"])

        ensureSettingsTab(app, timeout: timeout)

        XCTAssertTrue(app.staticTexts["Appearance"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["Starting Mode"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["Match Defaults"].waitForExistence(timeout: timeout))
        scrollToSettingsControl("settings_defaultSetsToggle", in: app, timeout: timeout)
        XCTAssertTrue(app.switches["settings_defaultSetsToggle"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.staticTexts["X01 Defaults"].waitForExistence(timeout: timeout))

        scrollToFeedbackSwitches(app)
        XCTAssertTrue(app.switches["settings_hapticsToggle"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.switches["settings_soundToggle"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.switches["settings_turnTotalCallerToggle"].waitForExistence(timeout: timeout))
        scrollToSettingsControl("settings_instantBotTurnsToggle", in: app, timeout: timeout)
        XCTAssertTrue(app.switches["settings_instantBotTurnsToggle"].waitForExistence(timeout: timeout))

        scrollToSettingsControl("settings_botStaggerToggle", in: app, timeout: timeout)
        XCTAssertTrue(app.staticTexts["Bot Opponents"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.switches["settings_botStaggerToggle"].waitForExistence(timeout: timeout))
        XCTAssertTrue(app.switches["settings_botDartHapticsToggle"].waitForExistence(timeout: timeout))
    }

    func testSettingsDefaultModePrefillsPlay() {
        let app = launchApp(["-seed_players"])

        ensureSettingsTab(app, timeout: timeout)
        selectSettingsPickerOption(
            pickerIdentifier: "settings_defaultModePicker",
            optionTitle: "Cricket",
            in: app,
            timeout: timeout
        )

        ensurePlayTab(app, timeout: timeout)
        let modeName = app.descendants(matching: .any)["setup_selectedModeName"]
        XCTAssertTrue(modeName.waitForExistence(timeout: timeout + 10))
        XCTAssertTrue(
            modeName.label.localizedCaseInsensitiveContains("Cricket"),
            "Play setup should prefill Cricket from Settings starting mode (got '\(modeName.label)')"
        )
    }

    func testSettingsX01StartScorePrefillsPlay() {
        let app = launchApp(["-seed_players"])

        ensureSettingsTab(app, timeout: timeout)
        selectSettingsPickerOption(
            pickerIdentifier: "settings_defaultStartScorePicker",
            optionTitle: "301",
            in: app,
            timeout: timeout
        )

        ensurePlayTab(app, timeout: timeout)
        expandSetupOptions(in: app, timeout: timeout)
        let startScoreChip = setupStartScoreChip(in: app, timeout: timeout)
        XCTAssertTrue(
            startScoreChip.label.contains("301"),
            "Play setup should prefill start score 301 from Settings (got '\(startScoreChip.label)')"
        )
    }

    func testSettingsFeedbackTogglesPersistAcrossTabs() {
        let app = launchApp(["-seed_players", "-ui_test_disable_feedback"])

        ensureSettingsTab(app, timeout: timeout)
        scrollToFeedbackSwitches(app)
        let haptics = app.switches["settings_hapticsToggle"]
        let sound = app.switches["settings_soundToggle"]
        XCTAssertTrue(haptics.waitForExistence(timeout: timeout))
        XCTAssertTrue(sound.waitForExistence(timeout: timeout))
        XCTAssertTrue(waitForSwitch(haptics, on: false, timeout: timeout), "Haptics toggle should load off")
        XCTAssertTrue(waitForSwitch(sound, on: false, timeout: timeout), "Sound toggle should load off")

        ensurePlayTab(app, timeout: timeout)
        ensureSettingsTab(app, timeout: timeout)
        scrollToFeedbackSwitches(app)

        let hapticsAfter = app.switches["settings_hapticsToggle"]
        let soundAfter = app.switches["settings_soundToggle"]
        XCTAssertTrue(hapticsAfter.waitForExistence(timeout: timeout))
        XCTAssertTrue(waitForSwitch(hapticsAfter, on: false, timeout: timeout), "Haptics toggle should stay off after tab change")
        XCTAssertTrue(waitForSwitch(soundAfter, on: false, timeout: timeout), "Sound toggle should stay off after tab change")
    }

    func testSettingsResetShowsConfirmation() {
        let app = launchApp(["-seed_players"])

        ensureSettingsTab(app, timeout: timeout)
        scrollToSettingsControl("settings_resetAllDataButton", in: app, timeout: timeout)
        app.buttons["settings_resetAllDataButton"].tap()

        XCTAssertTrue(app.alerts["Reset all local data?"].waitForExistence(timeout: timeout))
        app.buttons["Cancel"].tap()
        XCTAssertFalse(app.alerts["Reset all local data?"].exists)
    }

    func testSettingsControlsReachableInLandscape() {
        let app = launchApp([
            "-seed_players",
            "-ui_test_disable_feedback",
            "-snapshot_tab",
            "settings",
        ])

        ensureSettingsTab(app, timeout: timeout + 5)
        setSimulatorOrientation(.landscapeLeft)
        defer { resetSimulatorOrientationToPortrait() }
        RunLoop.current.run(until: Date().addingTimeInterval(1.0))

        let themePicker = app.descendants(matching: .any)["settings_themePicker"]
        XCTAssertTrue(
            themePicker.waitForExistence(timeout: timeout + 5),
            "Settings should remain usable after rotating to landscape"
        )
        assertSettingsControlReachable(themePicker, in: app, label: "Theme picker")
    }

    func testSettingsResetAlertAccessibilityContract() {
        let app = launchApp(["-seed_players"])

        ensureSettingsTab(app, timeout: timeout)
        scrollToSettingsControl("settings_resetAllDataButton", in: app, timeout: timeout)

        let reset = app.buttons["settings_resetAllDataButton"]
        XCTAssertTrue(reset.waitForExistence(timeout: timeout))
        XCTAssertEqual(reset.label, "Reset all data", "Destructive row should use the concise accessibility label")

        reset.tap()

        let alert = app.alerts["Reset all local data?"]
        XCTAssertTrue(alert.waitForExistence(timeout: timeout), "Reset should present a confirmation alert")

        let message = alert.staticTexts.containing(
            NSPredicate(format: "label CONTAINS %@", "players, matches, settings")
        ).firstMatch
        XCTAssertTrue(message.waitForExistence(timeout: timeout), "Alert should describe what reset clears")

        let cancel = alert.buttons["Cancel"]
        let confirm = alert.buttons["Reset Data"]
        XCTAssertTrue(cancel.waitForExistence(timeout: timeout))
        XCTAssertTrue(confirm.waitForExistence(timeout: timeout))
        XCTAssertTrue(cancel.isHittable)
        XCTAssertTrue(confirm.isHittable)

        cancel.tap()
        XCTAssertFalse(alert.waitForExistence(timeout: 2))
    }

    func testSettingsHelpAndFeedbackLinksExist() {
        let app = launchApp(["-skip_onboarding"])

        ensureSettingsTab(app, timeout: timeout)
        let linkIdentifiers = [
            "settings_supportFAQLink",
            "settings_sendFeedbackLink",
            "settings_rateAppLink",
            "settings_accessibilityLink",
            "settings_privacyPolicyLink",
        ]
        for identifier in linkIdentifiers {
            scrollToSettingsControl(identifier, in: app, timeout: timeout)
            XCTAssertTrue(
                app.descendants(matching: .any)[identifier].waitForExistence(timeout: timeout),
                "Expected settings link '\(identifier)'"
            )
        }
        scrollToSettingsControl("settings_aboutVersion", in: app, timeout: timeout)
        XCTAssertTrue(app.staticTexts["settings_aboutVersion"].waitForExistence(timeout: timeout))
    }
}
