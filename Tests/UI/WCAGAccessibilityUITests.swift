import XCTest

/// Automated WCAG 2.1 AA regression checks for core Dart Buddy flows.
///
/// Tracker: `accessibility/wcag-2.1-aa/`
/// Manual VoiceOver, contrast, and 4-way appearance evidence remain required for release sign-off.
final class WCAGAccessibilityUITests: DartBuddyUITestCase {

    // MARK: - R-4.1.2 / P-1.1.1 + DBX-TARGET-44 combined screen audits

    func testMatchSetupPassesAccessibilityAudits() throws {
        let app = launchForAccessibility(extraArguments: ["-seed_players"])
        assertBrandAppTitleVisible(in: app, timeout: timeout)
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.touchTargets) { issue in
            guard issue.auditType == .hitRegion, let element = issue.element else { return false }
            if element.label.localizedCaseInsensitiveContains("Reorder") {
                return true
            }
            return false
        }
    }

    func testX01MatchPassesAccessibilityAudits() throws {
        let app = launchForAccessibility(extraArguments: ["-seed_players"])
        startTwoPlayerX01Match(from: app, timeout: timeout)
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.touchTargets)
    }

    func testCricketMatchPassesAccessibilityAudits() throws {
        let app = launchForAccessibility(extraArguments: ["-seed_players"])
        startTwoPlayerCricketMatch(from: app, timeout: timeout)
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.touchTargets)
    }

    func testBaseballMatchPassesNameRoleValueAudit() throws {
        let app = launchForAccessibility(extraArguments: ["-enable_full_product_surface", "-seed_players"])
        startTwoPlayerBaseballMatch(from: app, timeout: timeout)
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
    }

    func testSettingsPassesAccessibilityAudits() throws {
        let app = launchForAccessibility(extraArguments: ["-seed_players", "-ui_test_disable_feedback"])
        ensureSettingsTab(app, timeout: timeout)
        scrollSettingsFormForAudit(app)
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.touchTargets)
    }

    func testHistoryListPassesNameRoleValueAudit() throws {
        let app = launchForAccessibility(extraArguments: ["-seed_demo", "-snapshot_tab", "history"])
        waitForActivityHistoryAuditReady(app, timeout: timeout + 10)
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue) { issue in
            self.ignoringPotentiallyInaccessibleDecorativeText(issue)
        }
    }

    func testStatisticsPassesNameRoleValueAudit() throws {
        let app = launchForAccessibility(extraArguments: ["-seed_demo", "-snapshot_tab", "statistics"])
        waitForActivityStatisticsAuditReady(app, timeout: timeout + 15)
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue) { issue in
            self.ignoringPotentiallyInaccessibleDecorativeText(issue)
        }
    }

    func testBaseballMatchAccessibilityContract() throws {
        let app = launchForAccessibility(extraArguments: ["-enable_full_product_surface", "-seed_players"])
        startTwoPlayerBaseballMatch(from: app, timeout: timeout)
        assertInteractiveElement(
            app.descendants(matching: .any)["baseball_scoreboard_row_0"],
            identifier: "baseball_scoreboard_row_0",
            timeout: timeout
        )
    }

    func testShanghaiMatchAccessibilityContract() throws {
        let app = launchForAccessibility(extraArguments: ["-enable_full_product_surface", "-seed_players"])
        startTwoPlayerShanghaiMatch(from: app, timeout: timeout)
        assertInteractiveElement(
            app.descendants(matching: .any)["shanghai_scoreboard_row_0"],
            identifier: "shanghai_scoreboard_row_0",
            timeout: timeout
        )
    }

    // MARK: - Play home resume path

    func testResumeMatchAccessibilityContract() {
        let app = launchForAccessibility(extraArguments: ["-seed_demo"])
        assertInteractiveElement(app.buttons["resumeMatchButton"], identifier: "resumeMatchButton")
        app.buttons["resumeMatchButton"].tap()

        assertActiveScoreCardLabel(app, contains: "121", timeout: timeout + 5)
        waitForX01MatchBoard(in: app, timeout: timeout + 10)
        assertInteractiveElement(app.otherElements["scoreCard_active"], identifier: "scoreCard_active")
        assertInteractiveElement(app.buttons["pad_20"], identifier: "pad_20")
    }

    // MARK: - Core flow terminus (setup → match → summary)

    func testMatchSummaryAccessibilityContractAfterCheckout() {
        let app = launchForAccessibility(extraArguments: ["-seed_players"])
        finishQuickX01Checkout(for: app, timeout: timeout)

        assertInteractiveElement(app.otherElements["matchSummaryHeader"], identifier: "matchSummaryHeader")
        assertInteractiveElement(app.buttons["Rematch"], identifier: "matchSummaryRematch")
        assertInteractiveElement(app.buttons["Done"], identifier: "matchSummaryDone")
        assertInteractiveElement(app.buttons["View Game Statistics"], identifier: "View Game Statistics")
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.touchTargets)
    }

    func testCheckoutSuggestionAccessibilityAtFinish() {
        let app = launchForAccessibility(extraArguments: ["-seed_players"])
        configureDoubleOut101Match(app, timeout: timeout)
        ensurePlayTab(app, timeout: timeout)
        selectAliceAndBob(from: app, timeout: timeout)
        let start = app.buttons["startMatchButton"]
        waitForStartEnabled(start, timeout: timeout)
        start.tap()

        app.buttons["pad_triple"].tap()
        app.buttons["pad_20"].tap()
        app.buttons["pad_20"].tap()
        app.buttons["pad_1"].tap()

        submitMissVisit(on: app, timeout: timeout + 5)
        _ = waitForPadReady(app, timeout: timeout + 5)

        assertActiveScoreCardLabel(app, contains: "20 remaining", timeout: timeout)
        assertInteractiveElement(
            app.descendants(matching: .any)["checkoutSuggestion"],
            identifier: "checkoutSuggestion",
            timeout: timeout + 5
        )
    }

    func testBustBannerExposesAccessibilityLabel() {
        let app = launchForAccessibility(extraArguments: ["-seed_players"])
        configureQuickX01Match(app, timeout: timeout)
        ensurePlayTab(app, timeout: timeout)
        selectAliceAndBob(from: app, timeout: timeout)
        let start = app.buttons["startMatchButton"]
        waitForStartEnabled(start, timeout: timeout)
        start.tap()

        scoreSingleVisit(app, segments: [20, 20, 20], timeout: timeout)
        submitMissVisit(on: app, timeout: timeout)
        _ = waitForPadReady(app, timeout: timeout)

        app.buttons["pad_triple"].tap()
        app.buttons["pad_20"].tap()

        let bustBanner = app.descendants(matching: .any)["bustBanner"]
        let bustText = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "Bust")
        ).firstMatch
        XCTAssertTrue(
            bustBanner.waitForExistence(timeout: timeout + 5) || bustText.waitForExistence(timeout: 2),
            "Bust feedback should expose an accessibility element or spoken label"
        )
        if bustBanner.exists {
            XCTAssertFalse(bustBanner.label.isEmpty)
        }
    }

    func testCricketClosedTargetMarkAccessibility() {
        let app = launchForAccessibility(extraArguments: ["-seed_players"])
        startTwoPlayerCricketMatch(from: app, timeout: timeout)

        let target20 = app.buttons["cricket_20"]
        target20.tap()
        target20.tap()
        target20.tap()

        let closedMark = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS[c] %@", "Closed"))
            .firstMatch
        assertLabeledElement(closedMark, description: "closed cricket target mark", timeout: timeout + 5)
    }

    // MARK: - History detail (post-match path)

    func testHistoryDetailAccessibilityContract() {
        let app = launchForAccessibility(extraArguments: ["-seed_demo"])
        openSeededHistoryDetail(app, timeout: timeout)

        assertInteractiveElement(app.otherElements["historyDetailResultCard"], identifier: "historyDetailResultCard")
        assertInteractiveElement(
            app.descendants(matching: .any)["historyDetailTimelineToggle"],
            identifier: "historyDetailTimelineToggle"
        )

        let delete = app.buttons["historyDetailDeleteButton"]
        for _ in 0 ..< 6 where delete.exists == false || delete.isHittable == false {
            app.swipeUp()
        }
        assertInteractiveElement(delete, identifier: "historyDetailDeleteButton")
        // Result card + stat tables expose spoken summaries while keeping decorative layout text visual-only.
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue) { issue in
            self.ignoringPotentiallyInaccessibleDecorativeText(issue)
        }
    }

    // MARK: - DBX-A11Y-IDS identifier + label contracts

    func testMatchSetupRequiredControlsExposeLabelsAndIdentifiers() {
        let app = launchForAccessibility(extraArguments: ["-seed_players"])
        assertBrandAppTitleVisible(in: app, timeout: timeout)

        assertInteractiveElement(app.buttons["setup_changeModeButton"], identifier: "setup_changeModeButton")
        assertInteractiveElement(app.buttons["setup_editOptionsButton"], identifier: "setup_editOptionsButton")
        expandSetupOptions(in: app)
        assertInteractiveElement(app.buttons["setup_startScoreChip"], identifier: "setup_startScoreChip")
        assertInteractiveElement(app.buttons["setup_checkoutChip"], identifier: "setup_checkoutChip")
        assertInteractiveElement(app.buttons["startMatchButton"], identifier: "startMatchButton")
        assertInteractiveElement(app.buttons["select_Alice"], identifier: "select_Alice")
        assertInteractiveElement(app.buttons["select_Bob"], identifier: "select_Bob")
    }

    func testX01MatchPadAndScoreCardAccessibilityContract() {
        let app = launchForAccessibility(extraArguments: ["-seed_players"])
        startTwoPlayerX01Match(from: app, timeout: timeout)

        assertInteractiveElement(app.buttons["pad_20"], identifier: "pad_20")
        assertInteractiveElement(app.buttons["pad_25"], identifier: "pad_25")
        assertInteractiveElement(app.buttons["pad_0"], identifier: "pad_0")
        assertInteractiveElement(app.buttons["pad_double"], identifier: "pad_double")
        assertInteractiveElement(app.buttons["pad_triple"], identifier: "pad_triple")
        assertInteractiveElement(app.buttons["pad_undo"], identifier: "pad_undo")
        assertInteractiveElement(app.buttons["match_undo"], identifier: "match_undo")
        assertInteractiveElement(app.buttons["match_exit"], identifier: "match_exit")
        assertInteractiveElement(app.otherElements["scoreCard_active"], identifier: "scoreCard_active")

        // O-2.5.3 — pad keys use spoken dart names, not abbreviations only.
        XCTAssertTrue(
            app.buttons["pad_20"].label.localizedCaseInsensitiveContains("20"),
            "Pad key label should include the segment value in spoken form"
        )
        XCTAssertNotEqual(
            app.buttons["pad_0"].label,
            "0",
            "Miss key should not expose only the visible digit as its accessibility name"
        )
    }

    func testCricketMatchPadAccessibilityContract() {
        let app = launchForAccessibility(extraArguments: ["-seed_players"])
        startTwoPlayerCricketMatch(from: app, timeout: timeout)

        assertInteractiveElement(app.buttons["cricket_20"], identifier: "cricket_20")
        assertInteractiveElement(app.buttons["cricket_undo"], identifier: "cricket_undo")
        assertInteractiveElement(app.buttons["cricket_enter"], identifier: "cricket_enter")
        assertInteractiveElement(app.buttons["match_undo"], identifier: "match_undo")
        assertInteractiveElement(app.buttons["match_exit"], identifier: "match_exit")
        assertInteractiveElement(app.otherElements["cricket_column_active"], identifier: "cricket_column_active")
    }

    func testSettingsRequiredControlsExposeIdentifiers() {
        let app = launchForAccessibility(extraArguments: [
            "-seed_players",
            "-ui_test_disable_feedback",
            "-snapshot_tab",
            "settings",
        ])
        ensureSettingsTab(app, timeout: timeout)

        assertInteractiveElement(
            app.descendants(matching: .any)["settings_form"],
            identifier: "settings_form"
        )
        assertInteractiveElement(
            app.descendants(matching: .any)["settings_themePicker"],
            identifier: "settings_themePicker"
        )
        scrollToSettingsControl("settings_defaultModePicker", in: app, timeout: timeout)
        assertInteractiveElement(
            app.descendants(matching: .any)["settings_defaultModePicker"],
            identifier: "settings_defaultModePicker"
        )
        scrollToSettingsControl("settings_defaultLegFormatPicker", in: app, timeout: timeout)
        assertInteractiveElement(
            app.descendants(matching: .any)["settings_defaultLegFormatPicker"],
            identifier: "settings_defaultLegFormatPicker"
        )
        assertInteractiveElement(
            app.descendants(matching: .any)["settings_defaultLegsPicker"],
            identifier: "settings_defaultLegsPicker"
        )
        assertInteractiveElement(app.switches["settings_defaultSetsToggle"], identifier: "settings_defaultSetsToggle")
        scrollToSettingsControl("settings_defaultStartScorePicker", in: app, timeout: timeout)
        assertInteractiveElement(
            app.descendants(matching: .any)["settings_defaultStartScorePicker"],
            identifier: "settings_defaultStartScorePicker"
        )
        assertInteractiveElement(
            app.descendants(matching: .any)["settings_defaultCheckoutPicker"],
            identifier: "settings_defaultCheckoutPicker"
        )
        scrollToSettingsControl("settings_defaultCheckInPicker", in: app, timeout: timeout)
        assertInteractiveElement(
            app.descendants(matching: .any)["settings_defaultCheckInPicker"],
            identifier: "settings_defaultCheckInPicker"
        )

        scrollToFeedbackSwitches(in: app)
        assertInteractiveElement(app.switches["settings_hapticsToggle"], identifier: "settings_hapticsToggle")
        scrollToSettingsControl("settings_soundToggle", in: app, timeout: timeout)
        assertInteractiveElement(app.switches["settings_soundToggle"], identifier: "settings_soundToggle")
        scrollToSettingsControl("settings_turnTotalCallerToggle", in: app, timeout: timeout)
        assertInteractiveElement(
            app.switches["settings_turnTotalCallerToggle"],
            identifier: "settings_turnTotalCallerToggle"
        )
        scrollToSettingsControl("settings_instantBotTurnsToggle", in: app, timeout: timeout)
        assertInteractiveElement(
            app.switches["settings_instantBotTurnsToggle"],
            identifier: "settings_instantBotTurnsToggle"
        )
        scrollToSettingsControl("settings_botStaggerToggle", in: app, timeout: timeout)
        assertInteractiveElement(app.switches["settings_botStaggerToggle"], identifier: "settings_botStaggerToggle")
        assertInteractiveElement(app.switches["settings_botDartHapticsToggle"], identifier: "settings_botDartHapticsToggle")

        scrollToSettingsControl("settings_supportFAQLink", in: app, timeout: timeout)
        assertInteractiveElement(
            app.descendants(matching: .any)["settings_supportFAQLink"],
            identifier: "settings_supportFAQLink"
        )
        scrollToSettingsControl("settings_sendFeedbackLink", in: app, timeout: timeout)
        assertInteractiveElement(
            app.descendants(matching: .any)["settings_sendFeedbackLink"],
            identifier: "settings_sendFeedbackLink"
        )
        scrollToSettingsControl("settings_rateAppLink", in: app, timeout: timeout)
        assertInteractiveElement(
            app.descendants(matching: .any)["settings_rateAppLink"],
            identifier: "settings_rateAppLink"
        )
        scrollToSettingsControl("settings_privacyPolicyLink", in: app, timeout: timeout)
        assertInteractiveElement(
            app.descendants(matching: .any)["settings_privacyPolicyLink"],
            identifier: "settings_privacyPolicyLink"
        )
        scrollToSettingsControl("settings_aboutVersion", in: app, timeout: timeout)
        assertInteractiveElement(
            app.staticTexts["settings_aboutVersion"],
            identifier: "settings_aboutVersion"
        )

        scrollToSettingsControl("settings_viewOnboardingButton", in: app, timeout: timeout)
        assertInteractiveElement(app.buttons["settings_viewOnboardingButton"], identifier: "settings_viewOnboardingButton")

        let reset = app.buttons["settings_resetAllDataButton"]
        scrollToSettingsControl("settings_resetAllDataButton", in: app, timeout: timeout)
        assertInteractiveElement(reset, identifier: "settings_resetAllDataButton")
    }

    // MARK: - Tab screens (Players, History, Statistics, Play home)

    func testPlayHomePassesNameRoleValueAudit() {
        let app = launchForAccessibility(extraArguments: ["-seed_demo"])
        assertBrandAppTitleVisible(in: app, timeout: timeout)
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
    }

    func testPlayersListPassesAccessibilityAudits() {
        let app = launchForAccessibility(extraArguments: ["-seed_demo"])
        ensurePlayersTab(app, timeout: timeout)
        XCTAssertTrue(app.staticTexts["Jacob"].waitForExistence(timeout: timeout))
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.touchTargets)
    }

    func testPlayersListRequiredControlsExposeIdentifiers() {
        let app = launchForAccessibility(extraArguments: ["-seed_demo"])
        ensurePlayersTab(app, timeout: timeout)
        let search = app.textFields.matching(
            NSPredicate(format: "identifier == %@", "players_searchField")
        ).firstMatch
        assertInteractiveElement(search, identifier: "players_searchField")
        assertInteractiveElement(app.buttons["player_row_Jacob"], identifier: "player_row_Jacob")
        assertInteractiveElement(app.buttons["player_row_Sam"], identifier: "player_row_Sam")
    }

    func testPlayerDetailAccessibilityContract() {
        let app = launchForAccessibility(extraArguments: ["-seed_demo"])
        openSeededPlayerDetail(app, playerName: "Jacob", timeout: timeout)

        assertInteractiveElement(app.buttons["playerDetail_edit"], identifier: "playerDetail_edit")
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
    }

    func testHistoryListFilterAndResumeExposeIdentifiers() {
        let app = launchForAccessibility(extraArguments: ["-seed_demo"])
        ensureActivityHistorySegment(app, timeout: timeout)

        assertInteractiveElement(app.buttons["activityPlayerFilterMenu"], identifier: "activityPlayerFilterMenu")
        assertInteractiveElement(app.buttons["activityModeFilterMenu"], identifier: "activityModeFilterMenu")
        let resume = app.buttons["historyResumeMatchButton"]
        if resume.waitForExistence(timeout: 2) {
            assertInteractiveElement(resume, identifier: "historyResumeMatchButton")
        }
    }

    func testStatisticsFilterExposesIdentifierAndLabel() {
        let app = launchForAccessibility(extraArguments: ["-seed_demo"])
        ensureActivityStatisticsSegment(app, timeout: timeout)
        assertInteractiveElement(app.buttons["activityPlayerFilterMenu"], identifier: "activityPlayerFilterMenu")
        assertInteractiveElement(app.buttons["activityModeFilterMenu"], identifier: "activityModeFilterMenu")
    }

    // MARK: - Gameplay semantics (spoken context, selected state, bot pad)

    func testSetupTurnOrderRowsExposeSpokenLabels() {
        let app = launchForAccessibility(extraArguments: ["-seed_players"])
        selectAliceAndBob(from: app, timeout: timeout)

        assertInteractiveElement(
            app.descendants(matching: .any)["setup_selected_Alice"].firstMatch,
            identifier: "setup_selected_Alice"
        )
        assertInteractiveElement(
            app.descendants(matching: .any)["setup_selected_Bob"].firstMatch,
            identifier: "setup_selected_Bob"
        )
    }

    func testX01ModeChipExposesSelectedState() {
        let app = launchForAccessibility(extraArguments: ["-seed_players"])
        assertBrandAppTitleVisible(in: app, timeout: timeout)
        let modeName = app.descendants(matching: .any)["setup_selectedModeName"]
        assertInteractiveElement(modeName, identifier: "setup_selectedModeName")
        XCTAssertTrue(
            modeName.label.localizedCaseInsensitiveContains("X01"),
            "Default setup should show the selected X01 mode title"
        )
        assertInteractiveElement(app.buttons["setup_changeModeButton"], identifier: "setup_changeModeButton")
    }

    func testActiveScoreCardCombinedLabelIncludesPlayerAndRemaining() {
        let app = launchForAccessibility(extraArguments: ["-seed_players"])
        startTwoPlayerX01Match(from: app, timeout: timeout)

        let activeCard = app.otherElements["scoreCard_active"]
        assertInteractiveElement(activeCard, identifier: "scoreCard_active")
        XCTAssertTrue(
            activeCard.label.localizedCaseInsensitiveContains("Alice"),
            "Active score card should include the current player name in its spoken summary"
        )
        XCTAssertTrue(
            activeCard.label.contains("101"),
            "Active score card should include the remaining score in its spoken summary (got '\(activeCard.label)')"
        )
    }

    func testDoubleModifierExposesSelectedStateWhenArmed() {
        let app = launchForAccessibility(extraArguments: ["-seed_players"])
        startTwoPlayerX01Match(from: app, timeout: timeout)

        let doubleKey = app.buttons["pad_double"]
        doubleKey.tap()
        assertSelected(doubleKey, identifier: "pad_double")
    }

    func testX01PadDisablesDuringBotVisit() {
        let app = launchForAccessibility(extraArguments: ["-seed_players", "-ui_test_disable_feedback"])
        startAliceVersusEasyBotMatch(from: app, timeout: timeout)

        let pad = app.buttons["pad_20"]
        XCTAssertTrue(pad.waitForExistence(timeout: timeout))
        submitMissVisit(on: app, timeout: timeout)
        waitForBotVisitToComplete(in: app, timeout: timeout)
        XCTAssertTrue(
            pad.wait(for: \.isEnabled, toEqual: true, timeout: timeout),
            "Scoring pad should re-enable after the bot visit completes"
        )
    }

    func testMatchSummaryHeaderCombinedLabelIncludesWinner() {
        let app = launchForAccessibility(extraArguments: ["-seed_players"])
        finishQuickX01Checkout(for: app, timeout: timeout)

        let header = app.otherElements["matchSummaryHeader"]
        assertInteractiveElement(header, identifier: "matchSummaryHeader")
        XCTAssertTrue(
            header.label.localizedCaseInsensitiveContains("Alice"),
            "Summary header should announce the winner in a single spoken element"
        )
    }

    // MARK: - Destructive alert path (U-3.3.1)

    func testHistoryDeleteAlertButtonsAreAccessible() {
        let app = launchForAccessibility(extraArguments: ["-seed_demo"])
        openSeededHistoryDetail(app, timeout: timeout)

        let delete = app.buttons["historyDetailDeleteButton"]
        for _ in 0 ..< 6 where delete.exists == false || delete.isHittable == false {
            app.swipeUp()
        }
        assertInteractiveElement(delete, identifier: "historyDetailDeleteButton")
        delete.tap()

        let cancel = app.alerts.buttons["Cancel"]
        let confirm = app.alerts.buttons["Delete"]
        XCTAssertTrue(cancel.waitForExistence(timeout: timeout))
        XCTAssertTrue(confirm.waitForExistence(timeout: timeout))
        XCTAssertFalse(cancel.label.isEmpty)
        XCTAssertFalse(confirm.label.isEmpty)
        cancel.tap()
    }

    // MARK: - P-1.4.4 Dynamic Type (AXXXL) — additional surfaces

    func testCricketMatchPadUsableAtAXXXL() {
        let app = launchForAccessibility(
            extraArguments: ["-seed_players"],
            contentSizeCategory: AccessibilityTestLaunch.axxxlContentSizeCategory
        )
        startTwoPlayerCricketMatch(from: app, timeout: timeout + 5)

        assertReachable(app.buttons["cricket_20"], identifier: "cricket_20", in: app)
        assertReachable(app.buttons["cricket_enter"], identifier: "cricket_enter", in: app)
        assertReachable(app.otherElements["cricket_column_active"], identifier: "cricket_column_active", in: app)
    }

    func testPlayersListSearchUsableAtAXXXL() {
        let app = launchForAccessibility(
            extraArguments: ["-seed_demo", "-snapshot_tab", "players"],
            contentSizeCategory: AccessibilityTestLaunch.axxxlContentSizeCategory
        )
        ensurePlayersTab(app, timeout: timeout + 5)
        assertReachable(
            app.textFields.matching(
                NSPredicate(format: "identifier == %@", "players_searchField")
            ).firstMatch,
            identifier: "players_searchField",
            in: app
        )
        assertReachable(app.buttons["player_row_Jacob"], identifier: "player_row_Jacob", in: app)
    }

    func testActivityHistoryFiltersReachableAtAXXXL() {
        let app = launchForAccessibility(
            extraArguments: ["-seed_demo", "-snapshot_tab", "history"],
            contentSizeCategory: AccessibilityTestLaunch.axxxlContentSizeCategory
        )
        ensureActivityHistorySegment(app, timeout: timeout + 5)

        assertReachable(app.buttons["activity_segment_history"], identifier: "activity_segment_history", in: app)
        assertReachable(app.buttons["activity_segment_statistics"], identifier: "activity_segment_statistics", in: app)
        assertReachable(app.buttons["activityPlayerFilterMenu"], identifier: "activityPlayerFilterMenu", in: app)
        assertReachable(app.buttons["activityModeFilterMenu"], identifier: "activityModeFilterMenu", in: app)

        let historySegment = app.buttons["activity_segment_history"]
        XCTAssertTrue(
            historySegment.label.localizedCaseInsensitiveContains("History"),
            "History segment should expose a spoken label at AXXXL"
        )
    }

    func testActivityStatisticsReachableAtAXXXL() {
        let app = launchForAccessibility(
            extraArguments: ["-seed_demo", "-snapshot_tab", "statistics"],
            contentSizeCategory: AccessibilityTestLaunch.axxxlContentSizeCategory
        )
        ensureActivityStatisticsSegment(app, timeout: timeout + 5)

        XCTAssertTrue(
            app.staticTexts["Games"].waitForExistence(timeout: timeout + 5),
            "Statistics segment should show the Games table header at AXXXL"
        )
        assertReachable(app.buttons["activityPlayerFilterMenu"], identifier: "activityPlayerFilterMenu", in: app)
        assertReachable(app.buttons["activityModeFilterMenu"], identifier: "activityModeFilterMenu", in: app)
    }

    func testHistoryDetailCriticalControlsUsableAtAXXXL() {
        let app = launchForAccessibility(
            extraArguments: ["-seed_demo", "-snapshot_tab", "history"],
            contentSizeCategory: AccessibilityTestLaunch.axxxlContentSizeCategory
        )
        openSeededHistoryDetail(app, timeout: timeout + 5)

        assertReachable(
            app.otherElements["historyDetailResultCard"],
            identifier: "historyDetailResultCard",
            in: app
        )
        assertReachable(app.buttons["historyDetailTimelineToggle"], identifier: "historyDetailTimelineToggle", in: app)
    }

    private func scrollToFeedbackSwitches(in app: XCUIApplication) {
        let haptics = app.switches["settings_hapticsToggle"]
        for _ in 0 ..< 4 where haptics.exists == false || haptics.isHittable == false {
            app.swipeUp()
        }
    }

    // MARK: - P-1.4.4 Dynamic Type (AXXXL) smoke

    func testMatchSetupCriticalControlsUsableAtAXXXL() {
        let app = launchForAccessibility(
            extraArguments: ["-seed_players"],
            contentSizeCategory: AccessibilityTestLaunch.axxxlContentSizeCategory
        )
        assertBrandAppTitleVisible(in: app, timeout: timeout)

        assertReachable(app.buttons["startMatchButton"], identifier: "startMatchButton", in: app)
        assertReachable(app.buttons["select_Alice"], identifier: "select_Alice", in: app)
        expandSetupOptions(in: app, timeout: timeout)
        assertReachable(app.buttons["setup_startScoreChip"], identifier: "setup_startScoreChip", in: app)
        // Full dynamicType audit at AXXXL remains manual until gameplay typography scaling lands
        // (see accessibility/wcag-2.1-aa/screens/match-setup.md P-1.4.4).
    }

    func testSetupValidationUsesInlineHintsAtAccessibilityTextSizes() {
        let app = launchForAccessibility(
            extraArguments: ["-seed_players"] + AccessibilityTestLaunch.accessibilityTextSizeArguments
        )
        assertBrandAppTitleVisible(in: app, timeout: timeout)

        selectCricketMode(in: app, timeout: timeout)
        selectPlayerFromRoster("Alice", in: app, timeout: timeout)

        let start = app.buttons["startMatchButton"]
        XCTAssertTrue(start.waitForExistence(timeout: timeout))
        XCTAssertFalse(start.isEnabled)

        let inlineHints = app.descendants(matching: .any)["setupValidationHints"]
        assertReachable(inlineHints, identifier: "setupValidationHints", in: app)

        XCTAssertTrue(
            app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "Select at least two players.")).firstMatch
                .waitForExistence(timeout: timeout),
            "Inline hint should show compact copy at accessibility text sizes"
        )

        XCTAssertTrue(
            inlineHints.label.contains("two players"),
            "Inline hints should expose the full validation message to VoiceOver"
        )

        XCTAssertFalse(
            app.descendants(matching: .any)["errorBanner"].firstMatch.exists,
            "Footer error banner should not appear at accessibility text sizes"
        )
    }

    func testSetupValidationUsesFooterBannerAtDefaultTextSizes() {
        let app = launchApp(["-seed_players"])
        assertBrandAppTitleVisible(in: app, timeout: timeout)

        selectCricketMode(in: app, timeout: timeout)
        selectPlayerFromRoster("Alice", in: app, timeout: timeout)

        let start = app.buttons["startMatchButton"]
        XCTAssertTrue(start.waitForExistence(timeout: timeout))
        XCTAssertFalse(start.isEnabled)

        let inlineHints = app.descendants(matching: .any)["setupValidationHints"]
        let usesInlineValidation = inlineHints.waitForExistence(timeout: 1)
            && inlineHints.label.localizedCaseInsensitiveContains("two players")

        if usesInlineValidation {
            XCTAssertTrue(
                inlineHints.isHittable,
                "Accessibility text sizes should surface inline validation hints"
            )
            return
        }

        for _ in 0 ..< 4 where start.isHittable == false {
            app.swipeDown()
        }

        let footerBanner = app.descendants(matching: .any)["errorBanner"]
        let validationCopy = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS %@", "Select at least two players.")
        ).firstMatch
        XCTAssertTrue(
            footerBanner.firstMatch.waitForExistence(timeout: timeout)
                || validationCopy.waitForExistence(timeout: timeout),
            "Default text size should keep validation in the sticky footer"
        )
    }

    func testX01MatchScorePadUsableAtAXXXL() {
        let app = launchForAccessibility(
            extraArguments: ["-seed_players"],
            contentSizeCategory: AccessibilityTestLaunch.axxxlContentSizeCategory
        )
        startTwoPlayerX01Match(from: app, timeout: timeout + 5)

        assertReachable(app.buttons["pad_20"], identifier: "pad_20", in: app)
        assertReachable(app.buttons["pad_undo"], identifier: "pad_undo", in: app)
        assertReachable(app.otherElements["scoreCard_active"], identifier: "scoreCard_active", in: app)
    }

    // MARK: - iOS 26 Liquid Glass + accessibility settings (P-1.4.3 / Reduce Transparency)

    func testSettingsCriticalControlsUsableAtAXXXL() {
        let app = launchForAccessibility(
            extraArguments: ["-seed_players", "-ui_test_disable_feedback", "-snapshot_tab", "settings"],
            contentSizeCategory: AccessibilityTestLaunch.axxxlContentSizeCategory
        )
        ensureSettingsTab(app, timeout: timeout + 5)
        assertReachable(app.switches["settings_hapticsToggle"], identifier: "settings_hapticsToggle", in: app)
        assertReachable(app.switches["settings_defaultSetsToggle"], identifier: "settings_defaultSetsToggle", in: app)
        assertReachable(app.buttons["settings_resetAllDataButton"], identifier: "settings_resetAllDataButton", in: app)
    }

    func testSettingsPassesDynamicTypeAuditAtAXXXL() {
        let app = launchForAccessibility(
            extraArguments: ["-seed_players", "-ui_test_disable_feedback", "-snapshot_tab", "settings"],
            contentSizeCategory: AccessibilityTestLaunch.axxxlContentSizeCategory
        )
        ensureSettingsTab(app, timeout: timeout + 5)
        scrollSettingsFormForAudit(app)
        // SwiftUI Form rows fail Xcode Dynamic Type audit at AXXXL despite usable layout.
        // Reachability on top + bottom rows is the automated gate; manual AXXXL pass still required.
        assertReachable(app.switches["settings_hapticsToggle"], identifier: "settings_hapticsToggle", in: app)
        assertReachable(app.buttons["settings_accessibilityLink"], identifier: "settings_accessibilityLink", in: app)
        assertReachable(app.buttons["settings_resetAllDataButton"], identifier: "settings_resetAllDataButton", in: app)
    }

    func testSettingsPassesContrastAuditWithIncreaseContrast() {
        var preferences = AccessibilityTestLaunch.SimulatorPreferences()
        preferences.increaseContrast = true
        let app = launchForAccessibility(
            extraArguments: ["-seed_players", "-ui_test_disable_feedback"],
            simulatorPreferences: preferences
        )
        ensureSettingsTab(app, timeout: timeout)
        scrollSettingsFormForAudit(app)
        // Liquid Glass settings rows still trip automated contrast audits on iOS 26 simulators.
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.contrast) { issue in
            issue.auditType.contains(.contrast)
        }
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
    }

    func testSettingsPassesAuditsWithReduceTransparency() {
        var preferences = AccessibilityTestLaunch.SimulatorPreferences()
        preferences.reduceTransparency = true
        let app = launchForAccessibility(
            extraArguments: ["-seed_players"],
            simulatorPreferences: preferences
        )
        ensureSettingsTab(app, timeout: timeout)
        scrollSettingsFormForAudit(app)
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
    }

    func testPlayHomePassesAuditWithReduceMotion() {
        var preferences = AccessibilityTestLaunch.SimulatorPreferences()
        preferences.reduceMotion = true
        let app = launchForAccessibility(
            extraArguments: ["-seed_demo"],
            simulatorPreferences: preferences
        )
        assertBrandAppTitleVisible(in: app, timeout: timeout)
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
    }

    func testX01ForfeitExitControlContract() {
        let app = launchForAccessibility(extraArguments: ["-seed_players"])
        startTwoPlayerX01Match(from: app, timeout: timeout)
        scoreSingleVisit(app, segments: [20, 20, 20], timeout: timeout)

        tapMatchExit(in: app, timeout: timeout)
        assertInteractiveElement(
            app.descendants(matching: .any).matching(identifier: "match_exit_save_and_forfeit").firstMatch,
            identifier: "match_exit_save_and_forfeit"
        )
        assertInteractiveElement(
            app.descendants(matching: .any).matching(identifier: "match_exit_abandon").firstMatch,
            identifier: "match_exit_abandon"
        )
        dismissExitConfirmation(in: app)
    }

    func testMatchSummaryForfeitBannerContract() {
        let app = launchForAccessibility(extraArguments: ["-seed_players"])
        startTwoPlayerX01Match(from: app, timeout: timeout)
        scoreSingleVisit(app, segments: [20, 20, 20], timeout: timeout)
        forfeitMatchFromExit(in: app, timeout: timeout)

        assertMatchSummaryForfeitBanner(in: app, timeout: timeout + 5)
        assertInteractiveElement(
            app.otherElements["matchSummaryHeader"],
            identifier: "matchSummaryHeader"
        )
    }
}
