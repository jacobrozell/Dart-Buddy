import XCTest

extension XCTestCase {
    func applyDefaultLaunchEnvironment(to app: XCUIApplication) {
        var environment = app.launchEnvironment
        if environment["UIPreferredContentSizeCategoryName"] == nil {
            environment["UIPreferredContentSizeCategoryName"] = AccessibilityTestLaunch.defaultContentSizeCategory
        }
        app.launchEnvironment = environment
    }

    func tapTabBarItem(
        named label: String,
        identifier: String? = nil,
        in app: XCUIApplication,
        timeout: TimeInterval = 10
    ) {
        if let identifier {
            let byIdentifier = app.tabBars.buttons.matching(identifier: identifier).firstMatch
            if byIdentifier.waitForExistence(timeout: 2) {
                byIdentifier.tap()
                return
            }
        }

        let byLabel = app.tabBars.buttons[label].firstMatch
        XCTAssertTrue(byLabel.waitForExistence(timeout: timeout), "Missing tab bar item '\(label)'")
        byLabel.tap()
    }

    @discardableResult
    func assertBrandAppTitleVisible(in app: XCUIApplication, timeout: TimeInterval? = nil) -> Bool {
        let wait = timeout ?? 10
        let title = app.descendants(matching: .any)["brand_app_title"]
        guard title.waitForExistence(timeout: wait) else {
            XCTFail("Play tab should show the Dart Buddy brand title")
            return false
        }
        guard title.label == DartBuddyUITestCase.brandTitle else {
            XCTFail("Expected brand title '\(DartBuddyUITestCase.brandTitle)', got '\(title.label)'")
            return false
        }
        return true
    }

    func ensurePlayTab(_ app: XCUIApplication, timeout: TimeInterval = 10) {
        tapTabBarItem(named: "Play", identifier: "tab_play", in: app, timeout: timeout)
        _ = assertBrandAppTitleVisible(in: app, timeout: timeout)
    }

    func ensureModesTab(_ app: XCUIApplication, timeout: TimeInterval = 10) {
        tapTabBarItem(named: "Modes", identifier: "tab_modes", in: app, timeout: timeout)
        XCTAssertTrue(
            app.textFields["modesSearchField"].waitForExistence(timeout: timeout),
            "Modes catalog search should be visible"
        )
    }

    func ensureActivityTab(_ app: XCUIApplication, timeout: TimeInterval = 10) {
        tapTabBarItem(named: "Activity", identifier: "tab_activity", in: app, timeout: timeout)
        XCTAssertTrue(
            app.staticTexts["Activity"].waitForExistence(timeout: timeout)
                || app.buttons["activity_segment_history"].waitForExistence(timeout: timeout),
            "Activity tab should be visible"
        )
    }

    func ensureActivityHistorySegment(_ app: XCUIApplication, timeout: TimeInterval = 10) {
        ensureActivityTab(app, timeout: timeout)
        let historySegment = app.buttons["activity_segment_history"]
        if historySegment.waitForExistence(timeout: 2), !historySegment.isSelected {
            historySegment.tap()
        }
    }

    func ensureActivityStatisticsSegment(_ app: XCUIApplication, timeout: TimeInterval = 10) {
        ensureActivityTab(app, timeout: timeout)
        let statsSegment = app.buttons["activity_segment_statistics"]
        XCTAssertTrue(statsSegment.waitForExistence(timeout: timeout))
        statsSegment.tap()
    }

    func ensureSettingsTab(_ app: XCUIApplication, timeout: TimeInterval = 10) {
        tapTabBarItem(named: "Settings", identifier: "tab_settings", in: app, timeout: timeout)
        XCTAssertTrue(
            app.staticTexts["Settings"].waitForExistence(timeout: timeout)
                || app.otherElements["settings_form"].waitForExistence(timeout: timeout),
            "Settings tab should be visible"
        )
    }

    func scrollToSettingsControl(
        _ identifier: String,
        in app: XCUIApplication,
        timeout: TimeInterval = 10
    ) {
        let control = app.descendants(matching: .any)[identifier]
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if control.exists, control.isHittable {
                return
            }
            app.swipeUp()
        }
        XCTAssertTrue(control.waitForExistence(timeout: 1), "Expected settings control '\(identifier)'")
    }

    func selectSettingsPickerOption(
        pickerIdentifier: String,
        optionTitle: String,
        in app: XCUIApplication,
        timeout: TimeInterval = 10
    ) {
        scrollToSettingsControl(pickerIdentifier, in: app, timeout: timeout)
        let picker = app.descendants(matching: .any)[pickerIdentifier]
        picker.tap()

        let menuItem = app.menuItems[optionTitle]
        if menuItem.waitForExistence(timeout: 2) {
            menuItem.tap()
            return
        }

        let button = app.buttons[optionTitle]
        XCTAssertTrue(
            button.waitForExistence(timeout: timeout),
            "Expected settings picker option '\(optionTitle)'"
        )
        button.tap()
    }

    func scrollToFeedbackSwitches(_ app: XCUIApplication) {
        scrollToSettingsControl("settings_hapticsToggle", in: app)
    }

    /// Scrolls the settings form so off-screen rows enter the accessibility hierarchy before audits.
    func scrollSettingsFormForAudit(_ app: XCUIApplication) {
        let markers = [
            "settings_themePicker",
            "settings_defaultModePicker",
            "settings_defaultSetsToggle",
            "settings_turnTotalCallerToggle",
            "settings_botDartHapticsToggle",
            "settings_resetAllDataButton"
        ]
        for identifier in markers {
            scrollToSettingsControl(identifier, in: app, timeout: 6)
        }
        for _ in 0 ..< 3 {
            app.swipeDown()
        }
    }

    func selectModeFromCatalog(
        _ catalogId: String,
        in app: XCUIApplication,
        expectedModeName: String? = nil,
        timeout: TimeInterval = 10
    ) {
        ensureModesTab(app, timeout: timeout)
        let card = app.buttons["modes_card_\(catalogId)"]
        XCTAssertTrue(card.waitForExistence(timeout: timeout), "Expected catalog card \(catalogId)")
        card.tap()
        ensurePlayTab(app, timeout: timeout)
        if let expectedModeName {
            let modeName = app.descendants(matching: .any)["setup_selectedModeName"]
            XCTAssertTrue(
                modeName.waitForExistence(timeout: timeout + 10),
                "Play setup should expose the selected mode title"
            )
            XCTAssertTrue(
                modeName.label.localizedCaseInsensitiveContains(expectedModeName),
                "Play setup should show \(expectedModeName) after catalog selection (got '\(modeName.label)')"
            )
        }
    }

    func selectCricketMode(in app: XCUIApplication, timeout: TimeInterval = 10) {
        selectModeFromCatalog("standard.cricket", in: app, expectedModeName: "Cricket", timeout: timeout)
    }

    /// Taps START after scrolling it clear of the sticky footer.
    func tapStartMatch(in app: XCUIApplication, timeout: TimeInterval = 10) {
        let start = app.buttons["startMatchButton"]
        waitForStartEnabled(start, timeout: timeout)
        for _ in 0 ..< 8 where start.exists == false || start.isHittable == false {
            app.swipeUp()
        }
        for _ in 0 ..< 4 where start.exists == false || start.isHittable == false {
            app.swipeDown()
        }
        XCTAssertTrue(start.isHittable, "START should be reachable above the tab bar and sticky footer")
        start.tap()
        let starting = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "Starting")
        ).firstMatch
        if starting.waitForExistence(timeout: 2) {
            XCTAssertTrue(
                starting.waitForNonExistence(timeout: timeout + 20),
                "Match start should finish submitting"
            )
        }
    }

    func waitForX01MatchBoard(in app: XCUIApplication, timeout: TimeInterval = 10) {
        let pad = app.buttons["pad_20"]
        XCTAssertTrue(
            pad.wait(for: \.exists, toEqual: true, timeout: timeout),
            "X01 match board should expose the scoring pad after start"
        )
    }

    /// Expands Play setup option chips when they are collapsed behind Edit options.
    func assertSetupChip(
        _ identifier: String,
        in app: XCUIApplication,
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let element = app.descendants(matching: .any)[identifier]
        for _ in 0 ..< 8 where element.exists == false || element.isHittable == false {
            app.swipeUp()
        }
        XCTAssertTrue(
            element.waitForExistence(timeout: timeout),
            "Expected setup chip '\(identifier)'",
            file: file,
            line: line
        )
    }

    func expandSetupOptions(in app: XCUIApplication, timeout: TimeInterval = 10) {
        let optionChipIdentifiers = [
            "setup_startScoreChip",
            "setup_checkoutChip",
            "setup_checkInChip",
            "setup_setLegChip",
            "setup_setsChip",
            "setup_legsChip",
            "setup_cricketPointsChip",
            "setup_cricketModeChip",
            "setup_baseballInningsChip",
            "setup_killerLivesChip",
            "setup_shanghaiRoundsChip"
        ]
        if optionChipIdentifiers.contains(where: { setupChip($0, in: app).exists }) {
            return
        }
        let edit = app.buttons["setup_editOptionsButton"]
        XCTAssertTrue(edit.waitForExistence(timeout: timeout), "Expected Edit options control on Play setup")
        for _ in 0 ..< 8 where edit.exists == false || edit.isHittable == false {
            app.swipeUp()
        }
        for _ in 0 ..< 4 where edit.exists == false || edit.isHittable == false {
            app.swipeDown()
        }
        edit.tap()
        for _ in 0 ..< 4 {
            app.swipeDown()
        }
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if optionChipIdentifiers.contains(where: { setupChip($0, in: app).waitForExistence(timeout: 1) }) {
                return
            }
            if setupChipByLabel(in: app).waitForExistence(timeout: 0.5) {
                return
            }
            app.swipeUp()
        }
        XCTAssertTrue(
            optionChipIdentifiers.contains(where: { setupChip($0, in: app).exists })
                || setupChipByLabel(in: app).exists,
            "Expected setup option chips after expanding Edit options"
        )
    }

    func setupChipByLabel(in app: XCUIApplication) -> XCUIElement {
        app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] %@ AND label MATCHES %@", "Points", ".*[0-9].*")
        ).firstMatch
    }

    func setupStartScoreChip(in app: XCUIApplication, timeout: TimeInterval = 10) -> XCUIElement {
        let byIdentifier = setupChip("setup_startScoreChip", in: app)
        if byIdentifier.waitForExistence(timeout: 2) {
            return byIdentifier
        }
        let byLabel = setupChipByLabel(in: app)
        XCTAssertTrue(byLabel.waitForExistence(timeout: timeout), "Expected start score setup chip")
        return byLabel
    }

    private func setupChip(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        let button = app.buttons[identifier]
        if button.exists {
            return button
        }
        let popUp = app.popUpButtons[identifier]
        if popUp.exists {
            return popUp
        }
        return app.descendants(matching: .any)[identifier]
    }

    func tapMenuChip(_ identifier: String, in app: XCUIApplication, timeout: TimeInterval = 10) {
        let button = app.buttons[identifier]
        let popUp = app.popUpButtons[identifier]
        if button.waitForExistence(timeout: timeout) {
            button.tap()
            return
        }
        XCTAssertTrue(
            popUp.waitForExistence(timeout: timeout),
            "Missing menu chip '\(identifier)'"
        )
        popUp.tap()
    }

    func selectMenuOption(
        identifier: String? = nil,
        title: String,
        in app: XCUIApplication,
        timeout: TimeInterval = 10
    ) {
        if let identifier {
            let option = app.descendants(matching: .any)[identifier]
            if option.waitForExistence(timeout: 1.5) {
                option.tap()
                return
            }
        }

        let menuItem = app.menuItems[title]
        if menuItem.waitForExistence(timeout: timeout) {
            menuItem.tap()
            return
        }

        let button = app.buttons[title]
        if button.waitForExistence(timeout: timeout) {
            button.tap()
            return
        }

        let byLabel = app.buttons.matching(
            NSPredicate(format: "label == %@", title)
        ).firstMatch
        if byLabel.waitForExistence(timeout: timeout) {
            byLabel.tap()
            return
        }

        let cell = app.cells.containing(NSPredicate(format: "label CONTAINS %@", title)).firstMatch
        XCTAssertTrue(
            cell.waitForExistence(timeout: 2),
            "Expected menu option '\(title)'"
        )
        cell.tap()
    }

    func waitForStartEnabled(_ start: XCUIElement, timeout: TimeInterval = 10) {
        XCTAssertTrue(start.waitForExistence(timeout: timeout))
        XCTAssertTrue(
            start.wait(for: \.isEnabled, toEqual: true, timeout: timeout),
            "START should be enabled once setup is valid"
        )
    }

    @discardableResult
    func waitForSwitch(_ toggle: XCUIElement, on: Bool, timeout: TimeInterval = 10) -> Bool {
        let targets = on ? ["1", "true", "On", "YES"] : ["0", "false", "Off", "NO"]
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if let value = toggle.value as? String, targets.contains(value) {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
        return false
    }
}

extension XCUIElement {
    func clearAndEnterText(_ text: String) {
        tap()
        if let stringValue = value as? String, !stringValue.isEmpty {
            let delete = String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count)
            typeText(delete)
        }
        typeText(text)
    }
}
