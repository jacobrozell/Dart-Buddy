import XCTest

/// Automated WCAG 2.1 AA regression checks for core Dart Buddy flows.
///
/// Tracker: `accessibility/wcag-2.1-aa/`
/// Manual VoiceOver, contrast, and 4-way appearance evidence remain required for release sign-off.
final class WCAGAccessibilityUITests: XCTestCase {
    private let timeout: TimeInterval = 10

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    // MARK: - R-4.1.2 / P-1.1.1 automated audits (Name, Role, Value)

    func testMatchSetupPassesNameRoleValueAudit() throws {
        let app = launchForAccessibility(extraArguments: ["-seed_players"])
        XCTAssertTrue(app.staticTexts["Dart Scoreboard"].waitForExistence(timeout: timeout))
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
    }

    func testX01MatchPassesNameRoleValueAudit() throws {
        let app = launchForAccessibility(extraArguments: ["-seed_players"])
        startTwoPlayerX01Match(from: app, timeout: timeout)
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
    }

    func testCricketMatchPassesNameRoleValueAudit() throws {
        let app = launchForAccessibility(extraArguments: ["-seed_players"])
        startTwoPlayerCricketMatch(from: app, timeout: timeout)
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
    }

    func testBaseballMatchPassesNameRoleValueAudit() throws {
        let app = launchForAccessibility(extraArguments: ["-seed_players"])
        startTwoPlayerBaseballMatch(from: app, timeout: timeout)
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
    }

    func testSettingsPassesNameRoleValueAudit() throws {
        let app = launchForAccessibility(extraArguments: ["-seed_players"])
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: timeout))
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
    }

    func testHistoryListPassesNameRoleValueAudit() throws {
        let app = launchForAccessibility(extraArguments: ["-seed_demo"])
        app.tabBars.buttons["History"].tap()
        XCTAssertTrue(app.staticTexts["History"].waitForExistence(timeout: timeout))
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
    }

    func testStatisticsPassesNameRoleValueAudit() throws {
        let app = launchForAccessibility(extraArguments: ["-seed_demo"])
        app.tabBars.buttons["Statistics"].tap()
        XCTAssertTrue(app.staticTexts["Statistics"].waitForExistence(timeout: timeout))
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
    }

    // MARK: - DBX-TARGET-44 touch target audits

    func testMatchSetupPassesTouchTargetAudit() throws {
        let app = launchForAccessibility(extraArguments: ["-seed_players"])
        XCTAssertTrue(app.staticTexts["Dart Scoreboard"].waitForExistence(timeout: timeout))
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.touchTargets) { issue in
            guard issue.auditType == .hitRegion, let element = issue.element else { return false }
            // SwiftUI list reorder grips are system chrome below the 44pt guideline.
            if element.label.localizedCaseInsensitiveContains("Reorder") {
                return true
            }
            return false
        }
    }

    func testX01MatchPassesTouchTargetAudit() throws {
        let app = launchForAccessibility(extraArguments: ["-seed_players"])
        startTwoPlayerX01Match(from: app, timeout: timeout)
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.touchTargets)
    }

    func testCricketMatchPassesTouchTargetAudit() throws {
        let app = launchForAccessibility(extraArguments: ["-seed_players"])
        startTwoPlayerCricketMatch(from: app, timeout: timeout)
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.touchTargets)
    }

    func testBaseballMatchAccessibilityContract() throws {
        let app = launchForAccessibility(extraArguments: ["-seed_players"])
        startTwoPlayerBaseballMatch(from: app, timeout: timeout)
        assertInteractiveElement(
            app.descendants(matching: .any)["baseball_scoreboard_row_0"],
            identifier: "baseball_scoreboard_row_0",
            timeout: timeout
        )
    }

    func testShanghaiMatchAccessibilityContract() throws {
        let app = launchForAccessibility(extraArguments: ["-seed_players"])
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

        XCTAssertTrue(app.staticTexts["121"].waitForExistence(timeout: timeout))
        assertInteractiveElement(app.otherElements["scoreCard_active"], identifier: "scoreCard_active")
        assertInteractiveElement(app.buttons["pad_20"], identifier: "pad_20")
    }

    // MARK: - Core flow terminus (setup → match → summary)

    func testMatchSummaryAccessibilityContractAfterCheckout() {
        let app = launchForAccessibility(extraArguments: ["-seed_players"])
        finishQuickX01Checkout(for: app, timeout: timeout)

        assertInteractiveElement(app.otherElements["matchSummaryHeader"], identifier: "matchSummaryHeader")
        assertInteractiveElement(app.buttons["New Match"], identifier: "New Match")
        assertInteractiveElement(app.buttons["View Game Statistics"], identifier: "View Game Statistics")
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
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

        let remaining = app.staticTexts["scoreCard_remaining"]
        XCTAssertTrue(remaining.waitForExistence(timeout: timeout))
        XCTAssertEqual(remaining.label, "20", "Alice should return to the visit on 20 remaining")
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
        assertInteractiveElement(app.buttons["historyDetailTimelineToggle"], identifier: "historyDetailTimelineToggle")

        let delete = app.buttons["historyDetailDeleteButton"]
        for _ in 0 ..< 6 where delete.exists == false || delete.isHittable == false {
            app.swipeUp()
        }
        assertInteractiveElement(delete, identifier: "historyDetailDeleteButton")
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
    }

    // MARK: - DBX-A11Y-IDS identifier + label contracts

    func testMatchSetupRequiredControlsExposeLabelsAndIdentifiers() {
        let app = launchForAccessibility(extraArguments: ["-seed_players"])
        XCTAssertTrue(app.staticTexts["Dart Scoreboard"].waitForExistence(timeout: timeout))

        assertInteractiveElement(app.buttons["setup_mode_x01"], identifier: "setup_mode_x01")
        assertInteractiveElement(app.buttons["setup_mode_cricket"], identifier: "setup_mode_cricket")
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
        assertInteractiveElement(app.buttons["pad_0"], identifier: "pad_0")
        assertInteractiveElement(app.buttons["pad_double"], identifier: "pad_double")
        assertInteractiveElement(app.buttons["pad_triple"], identifier: "pad_triple")
        assertInteractiveElement(app.buttons["pad_undo"], identifier: "pad_undo")
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
        assertInteractiveElement(app.otherElements["cricket_column_active"], identifier: "cricket_column_active")
    }

    func testSettingsRequiredControlsExposeIdentifiers() {
        let app = launchForAccessibility(extraArguments: ["-seed_players", "-ui_test_disable_feedback"])
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: timeout))

        scrollToFeedbackSwitches(in: app)
        assertInteractiveElement(app.switches["settings_hapticsToggle"], identifier: "settings_hapticsToggle")
        assertInteractiveElement(app.switches["settings_soundToggle"], identifier: "settings_soundToggle")

        let reset = app.buttons["settings_resetAllDataButton"]
        for _ in 0 ..< 6 where reset.exists == false || reset.isHittable == false {
            app.swipeUp()
        }
        assertInteractiveElement(reset, identifier: "settings_resetAllDataButton")
    }

    // MARK: - Tab screens (Players, History, Statistics, Play home)

    func testPlayHomePassesNameRoleValueAudit() {
        let app = launchForAccessibility(extraArguments: ["-seed_demo"])
        XCTAssertTrue(app.staticTexts["Dart Scoreboard"].waitForExistence(timeout: timeout))
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
    }

    func testPlayersListPassesNameRoleValueAudit() {
        let app = launchForAccessibility(extraArguments: ["-seed_demo"])
        app.tabBars.buttons["Players"].tap()
        XCTAssertTrue(app.staticTexts["Jacob"].waitForExistence(timeout: timeout))
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.nameRoleValue)
    }

    func testPlayersListPassesTouchTargetAudit() {
        let app = launchForAccessibility(extraArguments: ["-seed_demo"])
        app.tabBars.buttons["Players"].tap()
        XCTAssertTrue(app.staticTexts["Jacob"].waitForExistence(timeout: timeout))
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.touchTargets)
    }

    func testPlayersListRequiredControlsExposeIdentifiers() {
        let app = launchForAccessibility(extraArguments: ["-seed_demo"])
        app.tabBars.buttons["Players"].tap()
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
        app.tabBars.buttons["History"].tap()
        XCTAssertTrue(app.staticTexts["History"].waitForExistence(timeout: timeout))

        assertInteractiveElement(app.buttons["historyPlayerFilterMenu"], identifier: "historyPlayerFilterMenu")
        let resume = app.buttons["historyResumeMatchButton"]
        if resume.waitForExistence(timeout: 2) {
            assertInteractiveElement(resume, identifier: "historyResumeMatchButton")
        }
    }

    func testStatisticsFilterExposesIdentifierAndLabel() {
        let app = launchForAccessibility(extraArguments: ["-seed_demo"])
        app.tabBars.buttons["Statistics"].tap()
        XCTAssertTrue(app.staticTexts["Statistics"].waitForExistence(timeout: timeout))
        assertInteractiveElement(app.buttons["statsPlayerFilterMenu"], identifier: "statsPlayerFilterMenu")
    }

    func testSettingsPassesTouchTargetAudit() {
        let app = launchForAccessibility(extraArguments: ["-seed_players", "-ui_test_disable_feedback"])
        app.tabBars.buttons["Settings"].tap()
        XCTAssertTrue(app.staticTexts["Settings"].waitForExistence(timeout: timeout))
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.touchTargets)
    }

    func testMatchSummaryPassesTouchTargetAudit() {
        let app = launchForAccessibility(extraArguments: ["-seed_players"])
        finishQuickX01Checkout(for: app, timeout: timeout)
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.touchTargets)
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
        XCTAssertTrue(app.staticTexts["Dart Scoreboard"].waitForExistence(timeout: timeout))
        assertSelected(app.buttons["setup_mode_x01"], identifier: "setup_mode_x01")
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
            activeCard.label.contains("501"),
            "Active score card should include the remaining score in its spoken summary"
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
        pad.tap()
        pad.tap()
        pad.tap()

        let botBanner = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] %@", "Bot throwing")
        ).firstMatch
        let disabledDuringBot = pad.wait(
            for: \.isEnabled,
            toEqual: false,
            timeout: timeout
        )
        let botBannerVisible = botBanner.waitForExistence(timeout: timeout)
        XCTAssertTrue(
            disabledDuringBot || botBannerVisible,
            "Scoring pad should disable or show the bot-turn banner while the bot is throwing"
        )
        _ = pad.wait(for: \.isEnabled, toEqual: true, timeout: timeout + 25)
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
            extraArguments: ["-seed_demo"],
            contentSizeCategory: AccessibilityTestLaunch.axxxlContentSizeCategory
        )
        app.tabBars.buttons["Players"].tap()
        assertReachable(
            app.textFields.matching(
                NSPredicate(format: "identifier == %@", "players_searchField")
            ).firstMatch,
            identifier: "players_searchField",
            in: app
        )
        assertReachable(app.buttons["player_row_Jacob"], identifier: "player_row_Jacob", in: app)
    }

    func testHistoryDetailCriticalControlsUsableAtAXXXL() {
        let app = launchForAccessibility(
            extraArguments: ["-seed_demo"],
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
        XCTAssertTrue(app.staticTexts["Dart Scoreboard"].waitForExistence(timeout: timeout))

        assertReachable(app.buttons["startMatchButton"], identifier: "startMatchButton", in: app)
        assertReachable(app.buttons["select_Alice"], identifier: "select_Alice", in: app)
        assertReachable(app.buttons["setup_startScoreChip"], identifier: "setup_startScoreChip", in: app)
        // Full dynamicType audit at AXXXL remains manual until gameplay typography scaling lands
        // (see accessibility/wcag-2.1-aa/screens/match-setup.md P-1.4.4).
    }

    func testSetupValidationUsesInlineHintsAtAccessibilityTextSizes() {
        let app = launchForAccessibility(
            extraArguments: ["-seed_players"] + AccessibilityTestLaunch.accessibilityTextSizeArguments
        )
        XCTAssertTrue(app.staticTexts["Dart Scoreboard"].waitForExistence(timeout: timeout))

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
        let app = launchForAccessibility(extraArguments: ["-seed_players"])
        XCTAssertTrue(app.staticTexts["Dart Scoreboard"].waitForExistence(timeout: timeout))

        selectPlayerFromRoster("Alice", in: app, timeout: timeout)

        let start = app.buttons["startMatchButton"]
        XCTAssertTrue(start.waitForExistence(timeout: timeout))
        XCTAssertFalse(start.isEnabled)

        let footerBanner = app.descendants(matching: .any)["errorBanner"]
        XCTAssertTrue(
            footerBanner.firstMatch.waitForExistence(timeout: timeout),
            "Default text size should keep validation in the sticky footer"
        )
        XCTAssertFalse(
            app.descendants(matching: .any)["setupValidationHints"].exists,
            "Inline validation container should only appear at accessibility text sizes"
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

    func testHistoryFiltersReachableAtAXXXL() {
        let app = launchForAccessibility(
            extraArguments: ["-seed_demo"] + AccessibilityTestLaunch.accessibilityTextSizeArguments
        )
        app.tabBars.buttons["History"].tap()
        XCTAssertTrue(app.staticTexts["History"].waitForExistence(timeout: timeout))

        let allGames = app.buttons["All Games"]
        let cricket = app.buttons["Cricket"]
        assertReachable(allGames, identifier: "All Games", in: app)
        assertReachable(cricket, identifier: "Cricket", in: app)
        XCTAssertFalse(allGames.label.contains("…"), "Filter label should not truncate at accessibility sizes")
        XCTAssertFalse(cricket.label.contains("…"), "Filter label should not truncate at accessibility sizes")
    }

    func testStatisticsReachableAtAXXXL() {
        let app = launchForAccessibility(
            extraArguments: ["-seed_demo"] + AccessibilityTestLaunch.accessibilityTextSizeArguments
        )
        app.tabBars.buttons["Statistics"].tap()
        XCTAssertTrue(app.staticTexts["Statistics"].waitForExistence(timeout: timeout))
        assertReachable(app.buttons["All Games"], identifier: "All Games", in: app)
        assertReachable(app.buttons["statsPlayerFilterMenu"], identifier: "statsPlayerFilterMenu", in: app)
    }

    func testCricketBoardTargetsLegibleAtAXXXL() {
        let app = launchForAccessibility(
            extraArguments: ["-seed_players"] + AccessibilityTestLaunch.accessibilityTextSizeArguments
        )
        startTwoPlayerCricketMatch(from: app, timeout: timeout + 5)

        assertReachable(
            app.descendants(matching: .any)["cricket_target_20"],
            identifier: "cricket_target_20",
            in: app
        )
        assertReachable(
            app.descendants(matching: .any)["cricket_target_19"],
            identifier: "cricket_target_19",
            in: app
        )
        assertReachable(
            app.descendants(matching: .any)["cricket_target_bull"],
            identifier: "cricket_target_bull",
            in: app
        )
    }

    func testOnboardingBodyVisibleAtAXXXL() {
        let app = launchForAccessibility(
            extraArguments: ["-ui_test_onboarding"] + AccessibilityTestLaunch.accessibilityTextSizeArguments
        )
        let body = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS %@", "local scorekeeper")
        ).firstMatch
        assertReachable(body, identifier: "onboarding welcome body", in: app)
        assertReachable(app.buttons["onboarding_next"], identifier: "onboarding_next", in: app)
    }

    func testHistoryPassesDynamicTypeAuditAtAccessibilityTextSize() throws {
        let app = launchForAccessibility(
            extraArguments: ["-seed_demo"] + AccessibilityTestLaunch.accessibilityTextSizeArguments
        )
        app.tabBars.buttons["History"].tap()
        XCTAssertTrue(app.staticTexts["History"].waitForExistence(timeout: timeout))
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.dynamicType)
    }

    func testStatisticsPassesDynamicTypeAuditAtAccessibilityTextSize() throws {
        let app = launchForAccessibility(
            extraArguments: ["-seed_demo"] + AccessibilityTestLaunch.accessibilityTextSizeArguments
        )
        app.tabBars.buttons["Statistics"].tap()
        XCTAssertTrue(app.staticTexts["Statistics"].waitForExistence(timeout: timeout))
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.dynamicType)
    }
}
