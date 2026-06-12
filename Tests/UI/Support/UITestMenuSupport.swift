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
        let deadline = Date().addingTimeInterval(timeout)

        func tapIfPossible(_ element: XCUIElement) -> Bool {
            guard element.waitForExistence(timeout: 1) else { return false }
            if element.isHittable {
                element.tap()
                return true
            }
            // iOS 26 floating tab bar + AXXXL can expose tab items before they pass hit-testing.
            element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
            return true
        }

        while Date() < deadline {
            if let identifier {
                let candidates: [XCUIElement] = [
                    app.descendants(matching: .any).matching(identifier: identifier).firstMatch,
                    app.tabBars.buttons.matching(identifier: identifier).firstMatch,
                    app.buttons.matching(identifier: identifier).firstMatch,
                    app.cells.matching(identifier: identifier).firstMatch
                ]
                for candidate in candidates where tapIfPossible(candidate) {
                    return
                }
            }

            let labelCandidates: [XCUIElement] = [
                app.tabBars.buttons[label].firstMatch,
                app.buttons[label].firstMatch,
                app.cells[label].firstMatch,
                app.cells.containing(NSPredicate(format: "label == %@", label)).firstMatch,
                app.buttons.containing(NSPredicate(format: "label == %@", label)).firstMatch
            ]
            for candidate in labelCandidates where tapIfPossible(candidate) {
                return
            }

            RunLoop.current.run(until: Date().addingTimeInterval(0.15))
        }

        XCTFail("Missing tab bar item '\(label)' (identifier: \(identifier ?? "nil"))")
    }

    @discardableResult
    func assertBrandAppTitleVisible(in app: XCUIApplication, timeout: TimeInterval? = nil) -> Bool {
        let wait = timeout ?? 10
        let title = app.descendants(matching: .any)["brand_app_title"]
        let deadline = Date().addingTimeInterval(wait)
        while Date() < deadline {
            if title.exists, title.label == DartBuddyUITestCase.brandTitle {
                return true
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        if !title.exists {
            XCTFail("Play tab should show the Dart Buddy brand title")
            return false
        }
        XCTFail("Expected brand title '\(DartBuddyUITestCase.brandTitle)', got '\(title.label)'")
        return false
    }

    func ensurePlayTab(_ app: XCUIApplication, timeout: TimeInterval = 10) {
        if app.descendants(matching: .any)["brand_app_title"].waitForExistence(timeout: 2) {
            return
        }
        tapTabBarItem(named: "Play", identifier: "tab_play", in: app, timeout: timeout)
        for _ in 0 ..< 3 where !app.descendants(matching: .any)["brand_app_title"].exists {
            app.swipeDown()
        }
        _ = assertBrandAppTitleVisible(in: app, timeout: timeout)
    }

    func waitForLocalDataResetToFinish(in app: XCUIApplication, timeout: TimeInterval = 15) {
        let alert = app.alerts["Reset all local data?"]
        if alert.exists {
            _ = alert.waitForNonExistence(timeout: timeout)
        }
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if app.alerts.count == 0 {
                return
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
    }

    func activeX01ScoreCard(in app: XCUIApplication) -> XCUIElement {
        app.otherElements["scoreCard_active"]
    }

    func inactiveX01ScoreCards(in app: XCUIApplication) -> XCUIElementQuery {
        app.otherElements.matching(identifier: "scoreCard")
    }

    func assertActiveScoreCardLabel(
        _ app: XCUIApplication,
        contains fragment: String,
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let card = activeX01ScoreCard(in: app)
        XCTAssertTrue(
            card.waitForExistence(timeout: timeout),
            "Active score card should exist",
            file: file,
            line: line
        )
        XCTAssertTrue(
            card.label.contains(fragment),
            "Active score card label should contain '\(fragment)' (got '\(card.label)')",
            file: file,
            line: line
        )
    }

    func assertX01MatchConfigSummaryVisible(
        in app: XCUIApplication,
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let summary = app.descendants(matching: .any)["x01_match_config_summary"]
        if summary.waitForExistence(timeout: timeout) {
            XCTAssertFalse(summary.label.isEmpty, file: file, line: line)
            return
        }
        let fallback = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@", "Double Out", "Leg")
        ).firstMatch
        XCTAssertTrue(
            fallback.waitForExistence(timeout: timeout),
            "X01 match should expose config summary in header or body",
            file: file,
            line: line
        )
    }

    func assertMatchSummaryShowsWinner(
        _ name: String,
        in app: XCUIApplication,
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let header = app.otherElements["matchSummaryHeader"]
        XCTAssertTrue(header.waitForExistence(timeout: timeout), file: file, line: line)
        XCTAssertTrue(
            header.label.localizedCaseInsensitiveContains(name),
            "Summary header should announce winner '\(name)' (got '\(header.label)')",
            file: file,
            line: line
        )
    }

    func activeCricketColumn(in app: XCUIApplication) -> XCUIElement {
        app.otherElements["cricket_column_active"]
    }

    func assertActiveCricketColumnLabel(
        _ app: XCUIApplication,
        contains fragment: String,
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let column = activeCricketColumn(in: app)
        XCTAssertTrue(column.waitForExistence(timeout: timeout), file: file, line: line)
        XCTAssertTrue(
            column.label.localizedCaseInsensitiveContains(fragment),
            "Active cricket column label should contain '\(fragment)' (got '\(column.label)')",
            file: file,
            line: line
        )
    }

    func ensurePlayersTab(_ app: XCUIApplication, timeout: TimeInterval = 10) {
        let search = app.descendants(matching: .any)["players_searchField"]
        let playerRow = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH %@", "player_row_")
        ).firstMatch
        if search.waitForExistence(timeout: 1) || playerRow.waitForExistence(timeout: 1) {
            return
        }
        tapTabBarItem(named: "Players", identifier: "tab_players", in: app, timeout: timeout)
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if search.exists || playerRow.exists {
                return
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        XCTAssertTrue(search.exists || playerRow.exists, "Players tab should be visible")
    }

    func ensureModesTab(_ app: XCUIApplication, timeout: TimeInterval = 10) {
        tapTabBarItem(named: "Modes", identifier: "tab_modes", in: app, timeout: timeout)
        XCTAssertTrue(
            app.textFields["modesSearchField"].waitForExistence(timeout: timeout),
            "Modes catalog search should be visible"
        )
    }

    func ensureActivityTab(_ app: XCUIApplication, timeout: TimeInterval = 10) {
        if app.buttons["activity_segment_history"].waitForExistence(timeout: 1)
            || app.buttons["activity_segment_statistics"].waitForExistence(timeout: 1) {
            return
        }
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
        let form = app.descendants(matching: .any)["settings_form"]
        let themePicker = app.descendants(matching: .any)["settings_themePicker"]
        if form.waitForExistence(timeout: 1) || themePicker.waitForExistence(timeout: 1) {
            return
        }
        tapTabBarItem(named: "Settings", identifier: "tab_settings", in: app, timeout: timeout)
        let loading = app.descendants(matching: .any)["settings_loading"]
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if loading.exists {
                RunLoop.current.run(until: Date().addingTimeInterval(0.2))
                continue
            }
            if form.waitForExistence(timeout: 1) || themePicker.waitForExistence(timeout: 1) {
                return
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.2))
        }
        XCTFail("Settings tab should be visible")
    }

    func scrollToSettingsControl(
        _ identifier: String,
        in app: XCUIApplication,
        timeout: TimeInterval = 10
    ) {
        let control = app.descendants(matching: .any)[identifier]
        let deadline = Date().addingTimeInterval(timeout)
        var swipedUp = 0
        while Date() < deadline {
            if control.exists, control.isHittable {
                return
            }
            app.swipeUp()
            swipedUp += 1
            if swipedUp % 4 == 0 {
                app.swipeDown()
            }
        }
        for _ in 0 ..< 6 where control.exists == false || control.isHittable == false {
            app.swipeDown()
        }
        XCTAssertTrue(
            control.waitForExistence(timeout: 2),
            "Expected settings control '\(identifier)'"
        )
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
        RunLoop.current.run(until: Date().addingTimeInterval(0.35))
    }

    func scrollToFeedbackSwitches(_ app: XCUIApplication) {
        scrollToSettingsControl("settings_hapticsToggle", in: app)
    }

    func assertSettingsControlReachable(
        _ control: XCUIElement,
        in app: XCUIApplication,
        label: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(control.exists, "\(label) should exist", file: file, line: line)
        if control.isHittable {
            return
        }
        control.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
    }

    /// Scrolls the settings form so off-screen rows enter the accessibility hierarchy before audits.
    func scrollSettingsFormForAudit(_ app: XCUIApplication) {
        let markers = [
            "settings_themePicker",
            "settings_defaultModePicker",
            "settings_defaultCheckInPicker",
            "settings_defaultSetsToggle",
            "settings_turnTotalCallerToggle",
            "settings_botDartHapticsToggle",
            "settings_resetAllDataButton"
        ]
        for identifier in markers {
            scrollToSettingsControl(identifier, in: app, timeout: 6)
        }
        for _ in 0 ..< 4 {
            app.swipeUp()
        }
        for _ in 0 ..< 4 {
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
        assertSelectedModeName(expectedModeName, in: app, timeout: timeout)
    }

    func selectModeFromPlaySetupPicker(
        _ catalogId: String,
        in app: XCUIApplication,
        expectedModeName: String? = nil,
        timeout: TimeInterval = 10
    ) {
        let changeButton = app.buttons["setup_changeModeButton"]
        XCTAssertTrue(changeButton.waitForExistence(timeout: timeout), "Expected Change mode button")
        changeButton.tap()
        let card = app.descendants(matching: .any)["modes_card_\(catalogId)"]
        if !card.waitForExistence(timeout: 3) {
            for _ in 0 ..< 4 where card.exists == false {
                app.swipeUp()
            }
        }
        XCTAssertTrue(card.waitForExistence(timeout: timeout), "Expected picker card \(catalogId)")
        tapHittableElement(card)
        assertSelectedModeName(expectedModeName, in: app, timeout: timeout)
    }

    func selectCricketMode(in app: XCUIApplication, timeout: TimeInterval = 10) {
        ensurePlayTab(app, timeout: timeout)
        let modeName = app.descendants(matching: .any)["setup_selectedModeName"]
        if modeName.waitForExistence(timeout: 2),
           modeName.label.localizedCaseInsensitiveContains("Cricket") {
            return
        }
        if app.buttons["setup_changeModeButton"].waitForExistence(timeout: 2) {
            selectModeFromPlaySetupPicker(
                "standard.cricket",
                in: app,
                expectedModeName: "Cricket",
                timeout: timeout
            )
            return
        }
        selectModeFromCatalog("standard.cricket", in: app, expectedModeName: "Cricket", timeout: timeout)
    }

    private func assertSelectedModeName(
        _ expectedModeName: String?,
        in app: XCUIApplication,
        timeout: TimeInterval
    ) {
        guard let expectedModeName else { return }
        let modeName = app.descendants(matching: .any)["setup_selectedModeName"]
        XCTAssertTrue(
            modeName.waitForExistence(timeout: timeout + 10),
            "Play setup should expose the selected mode title"
        )
        XCTAssertTrue(
            modeName.label.localizedCaseInsensitiveContains(expectedModeName),
            "Play setup should show \(expectedModeName) after mode selection (got '\(modeName.label)')"
        )
    }

    func selectPlayerFromRoster(_ name: String, in app: XCUIApplication, timeout: TimeInterval = 10) {
        let wait = timeout + 15
        let button = app.buttons["select_\(name)"]
        let start = app.buttons["startMatchButton"]
        XCTAssertTrue(
            button.waitForExistence(timeout: wait),
            "Expected roster row for \(name)"
        )
        for _ in 0 ..< 10 {
            let clearsStartFooter = !start.exists || button.frame.maxY < start.frame.minY - 8
            if button.isHittable, clearsStartFooter {
                break
            }
            app.swipeUp()
        }
        XCTAssertTrue(
            button.isHittable,
            "Expected roster row for \(name) to be reachable above the sticky Start footer"
        )
        button.tap()
        let staged = app.descendants(matching: .any)["setup_selected_\(name)"].firstMatch
        if !staged.waitForExistence(timeout: timeout) {
            if button.waitForExistence(timeout: 2), button.isHittable {
                button.tap()
            }
            XCTAssertTrue(
                staged.waitForExistence(timeout: timeout),
                "Expected \(name) to appear in turn order after selection"
            )
        }
    }

    /// Taps START once the footer button is enabled.
    func tapStartMatch(in app: XCUIApplication, timeout: TimeInterval = 10) {
        let start = app.buttons["startMatchButton"]
        waitForStartEnabled(start, timeout: timeout)
        if !start.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(start.isHittable, "START should be reachable above the tab bar and sticky footer")
        start.tap()
    }

    func waitForX01MatchBoard(in app: XCUIApplication, timeout: TimeInterval = 10) {
        _ = waitForPadReady(app, timeout: timeout + 25)
        XCTAssertTrue(
            app.buttons["match_exit"].waitForExistence(timeout: 5),
            "X01 match screen should appear after start"
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
        scrollToSetupControl(identifier, in: app, timeout: timeout)
        let element = setupControl(identifier, in: app)
        XCTAssertTrue(
            element.waitForExistence(timeout: 1),
            "Expected setup chip '\(identifier)'",
            file: file,
            line: line
        )
    }

    func scrollToSetupControl(
        _ identifier: String,
        in app: XCUIApplication,
        timeout: TimeInterval = 10
    ) {
        let control = setupControl(identifier, in: app)
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if control.exists, control.isHittable {
                return
            }
            app.swipeUp()
        }
        for _ in 0 ..< 4 where control.exists == false || control.isHittable == false {
            app.swipeDown()
        }
        XCTAssertTrue(control.waitForExistence(timeout: 1), "Expected setup control '\(identifier)'")
    }

    func expandSetupOptions(in app: XCUIApplication, timeout: TimeInterval = 10) {
        ensurePlayTab(app, timeout: timeout)
        let optionChipIdentifiers = setupOptionChipIdentifiers()
        if setupOptionChipsExpanded(in: app, identifiers: optionChipIdentifiers) {
            return
        }
        scrollToSetupControl("setup_editOptionsButton", in: app, timeout: timeout)
        let edit = setupControl("setup_editOptionsButton", in: app)
        XCTAssertTrue(edit.waitForExistence(timeout: 1), "Expected Edit options control on Play setup")

        if edit.label.localizedCaseInsensitiveContains("Hide") {
            revealSetupOptionChips(in: app, identifiers: optionChipIdentifiers, timeout: timeout)
            if setupOptionChipsExpanded(in: app, identifiers: optionChipIdentifiers) {
                return
            }
        }

        tapHittableElement(edit)
        if revealSetupOptionChips(in: app, identifiers: optionChipIdentifiers, timeout: timeout) {
            return
        }

        tapHittableElement(edit)
        XCTAssertTrue(
            revealSetupOptionChips(in: app, identifiers: optionChipIdentifiers, timeout: timeout / 2),
            "Expected setup option chips after expanding Edit options"
        )
    }

    @discardableResult
    private func revealSetupOptionChips(
        in app: XCUIApplication,
        identifiers: [String],
        timeout: TimeInterval
    ) -> Bool {
        for _ in 0 ..< 4 {
            app.swipeDown()
        }
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if setupOptionChipsExpanded(in: app, identifiers: identifiers) {
                return true
            }
            app.swipeUp()
        }
        for _ in 0 ..< 4 where !setupOptionChipsExpanded(in: app, identifiers: identifiers) {
            app.swipeDown()
        }
        return setupOptionChipsExpanded(in: app, identifiers: identifiers)
    }

    private func setupOptionChipIdentifiers() -> [String] {
        [
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
    }

    private func setupControl(_ identifier: String, in app: XCUIApplication) -> XCUIElement {
        let button = app.buttons[identifier]
        if button.exists {
            return button
        }
        return app.descendants(matching: .any)[identifier]
    }

    private func tapHittableElement(_ element: XCUIElement) {
        if element.isHittable {
            element.tap()
        } else {
            element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
    }

    private func setupOptionChipsExpanded(in app: XCUIApplication, identifiers: [String]) -> Bool {
        if identifiers.contains(where: { setupChip($0, in: app).exists }) {
            return true
        }
        return setupChipByLabel(in: app).exists
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
        scrollToSetupControl(identifier, in: app, timeout: timeout)
        let chip = setupChip(identifier, in: app)
        XCTAssertTrue(
            chip.waitForExistence(timeout: 1),
            "Missing menu chip '\(identifier)'"
        )
        openSetupChipMenu(chip, in: app, timeout: timeout)
    }

    private func openSetupChipMenu(
        _ chip: XCUIElement,
        in app: XCUIApplication,
        timeout: TimeInterval
    ) {
        let openers: [() -> Void] = [
            { self.tapHittableElement(chip) },
            { chip.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.85)).tap() },
            { chip.press(forDuration: 0.75) }
        ]
        for opener in openers {
            opener()
            if waitForSetupMenu(in: app, timeout: 2) {
                return
            }
        }
        XCTAssertTrue(
            waitForSetupMenu(in: app, timeout: timeout),
            "Setup chip menu should present options"
        )
    }

    /// Waits for a setup chip menu to finish presenting after `tapMenuChip`.
    @discardableResult
    func waitForSetupMenu(in app: XCUIApplication, timeout: TimeInterval = 2) -> Bool {
        if app.menuItems.firstMatch.waitForExistence(timeout: timeout) {
            return true
        }
        let setupOption = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'setup_' AND identifier CONTAINS 'Option'")
        ).firstMatch
        return setupOption.waitForExistence(timeout: min(timeout, 1))
    }

    func waitForDemoSeed(in app: XCUIApplication, timeout: TimeInterval = 30) {
        ensurePlayersTab(app, timeout: timeout)
        let jacob = app.buttons["player_row_Jacob"]
        let botRow = app.buttons.matching(
            NSPredicate(format: "identifier BEGINSWITH 'player_row_bot_'")
        ).firstMatch
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if jacob.exists || botRow.exists {
                return
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        XCTAssertTrue(jacob.exists || botRow.exists, "Demo seed should populate the Players roster")
    }

    /// Waits until the cricket pad accepts input after auto-submit, bot visits, or closure transitions.
    func waitForCricketScoringPadReady(
        _ app: XCUIApplication,
        keyIdentifier: String = "cricket_20",
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let key = app.buttons[keyIdentifier]
        XCTAssertTrue(key.waitForExistence(timeout: timeout), file: file, line: line)
        XCTAssertTrue(
            key.wait(for: \.isEnabled, toEqual: true, timeout: timeout + 5),
            "Cricket pad key '\(keyIdentifier)' should enable when the visit is ready",
            file: file,
            line: line
        )
    }

    /// Rotates to landscape and waits until a gameplay landmark is hittable again.
    func rotateToLandscapeLeft(for app: XCUIApplication, timeout: TimeInterval = 5) {
        XCUIDevice.shared.orientation = .landscapeLeft
        let landmarks: [XCUIElement] = [
            app.buttons["pad_20"],
            app.buttons["cricket_20"],
            app.otherElements["scoreCard_active"],
            app.otherElements["cricket_column_active"],
        ]
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if landmarks.contains(where: { $0.exists && $0.isHittable }) {
                return
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.05))
        }
    }

    func selectMenuOption(
        identifier: String? = nil,
        title: String,
        in app: XCUIApplication,
        timeout: TimeInterval = 10
    ) {
        if let identifier {
            let option = app.descendants(matching: .any)[identifier]
            if option.waitForExistence(timeout: timeout) {
                option.tap()
                return
            }
        }

        let menuItem = app.menuItems[title]
        if menuItem.waitForExistence(timeout: timeout) {
            menuItem.tap()
            return
        }

        let menuItemCaseInsensitive = app.menuItems.matching(
            NSPredicate(format: "label ==[c] %@", title)
        ).firstMatch
        if menuItemCaseInsensitive.waitForExistence(timeout: 2) {
            menuItemCaseInsensitive.tap()
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
        if cell.waitForExistence(timeout: timeout) {
            cell.tap()
            return
        }

        let looseLabel = app.descendants(matching: .any).matching(
            NSPredicate(format: "label ==[c] %@", title)
        ).firstMatch
        XCTAssertTrue(
            looseLabel.waitForExistence(timeout: 2),
            "Expected menu option '\(title)'"
        )
        looseLabel.tap()
    }

    func waitForStartEnabled(_ start: XCUIElement, timeout: TimeInterval = 10) {
        XCTAssertTrue(start.waitForExistence(timeout: timeout))
        XCTAssertTrue(
            start.wait(for: \.isEnabled, toEqual: true, timeout: timeout),
            "START should be enabled once setup is valid"
        )
    }

    func waitForStartDisabled(_ start: XCUIElement, timeout: TimeInterval = 10) {
        XCTAssertTrue(start.waitForExistence(timeout: timeout))
        XCTAssertTrue(
            start.wait(for: \.isEnabled, toEqual: false, timeout: timeout),
            "START should stay disabled until setup is valid"
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

    /// Select-all style replacement for fields where delete-backspace entry is flaky on large phones.
    func replaceText(_ text: String) {
        tap()
        let existing = (value as? String) ?? ""
        if !existing.isEmpty {
            tap(withNumberOfTaps: 3, numberOfTouches: 1)
            typeText(text)
            if (value as? String) == text { return }
            tap()
            let delete = String(repeating: XCUIKeyboardKey.delete.rawValue, count: existing.count + 4)
            typeText(delete)
        }
        typeText(text)
    }
}
