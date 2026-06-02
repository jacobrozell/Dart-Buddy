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
        runWCAGAudit(on: app, auditTypes: WCAGAccessibilityAuditProfile.touchTargets)
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
        app.buttons["select_Alice"].tap()
        app.buttons["select_Bob"].tap()
        app.buttons["startMatchButton"].tap()

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
        app.buttons["select_Alice"].tap()
        app.buttons["select_Bob"].tap()
        app.buttons["startMatchButton"].tap()

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

        assertReachable(app.buttons["startMatchButton"], identifier: "startMatchButton")
        assertReachable(app.buttons["select_Alice"], identifier: "select_Alice")
        assertReachable(app.buttons["setup_startScoreChip"], identifier: "setup_startScoreChip")
        // Full dynamicType audit at AXXXL remains manual until gameplay typography scaling lands
        // (see accessibility/wcag-2.1-aa/screens/match-setup.md P-1.4.4).
    }

    func testX01MatchScorePadUsableAtAXXXL() {
        let app = launchForAccessibility(
            extraArguments: ["-seed_players"],
            contentSizeCategory: AccessibilityTestLaunch.axxxlContentSizeCategory
        )
        startTwoPlayerX01Match(from: app, timeout: timeout + 5)

        assertReachable(app.buttons["pad_20"], identifier: "pad_20")
        assertReachable(app.buttons["pad_undo"], identifier: "pad_undo")
        assertReachable(app.otherElements["scoreCard_active"], identifier: "scoreCard_active")
    }
}
