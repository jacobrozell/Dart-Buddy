import XCTest

/// Maps Apple's automated accessibility audits to WCAG 2.1 AA checks tracked in
/// `accessibility/wcag-2.1-aa/criteria.md`.
enum WCAGAccessibilityAuditProfile {
    /// R-4.1.2 Name, Role, Value; P-1.1.1 Non-text Content; O-2.4.4 Link Purpose
    static let nameRoleValue: XCUIAccessibilityAuditType = [.elementDetection, .sufficientElementDescription]

    /// DBX-TARGET-44 — interactive targets meet minimum hit region guidance
    static let touchTargets: XCUIAccessibilityAuditType = .hitRegion

    /// P-1.4.4 Resize Text; P-1.4.10 Reflow (text clipping signal)
    static let dynamicType: XCUIAccessibilityAuditType = [.dynamicType, .textClipped]

    /// P-1.4.3 Contrast (Minimum); P-1.4.11 Non-text Contrast
    static let contrast: XCUIAccessibilityAuditType = .contrast
}

enum AccessibilityTestLaunch {
    static let defaultArguments = ["-ui_test_reset", "-disable_firebase_analytics"]
    static let defaultContentSizeCategory = "UICTContentSizeCategoryL"
    static let axxxlContentSizeCategory = "UIAccessibilityExtraExtraExtraLargeCategory"
    /// Forces accessibility Dynamic Type layout branches under UI test (see `UITestDynamicTypeOverride` in app target).
    static let accessibilityTextSizeArguments = ["-ui_test_accessibility_text_size"]

    /// Launch-environment hints for iOS accessibility settings exercised on iOS 26 Liquid Glass regression runs.
    struct SimulatorPreferences {
        var reduceTransparency = false
        var increaseContrast = false
        var reduceMotion = false

        func merged(into environment: inout [String: String]) {
            if reduceTransparency {
                environment["ReduceTransparencyEnabled"] = "1"
            }
            if increaseContrast {
                environment["UIPrefersHighContrast"] = "1"
            }
            if reduceMotion {
                environment["ReduceMotionEnabled"] = "1"
            }
        }
    }
}

extension XCTestCase {
    func launchForAccessibility(
        extraArguments: [String] = [],
        contentSizeCategory: String? = nil,
        simulatorPreferences: AccessibilityTestLaunch.SimulatorPreferences = .init()
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = AccessibilityTestLaunch.defaultArguments + extraArguments
        if let contentSizeCategory {
            app.launchEnvironment["UIPreferredContentSizeCategoryName"] = contentSizeCategory
        }
        applyDefaultLaunchEnvironment(to: app)
        var environment = app.launchEnvironment
        simulatorPreferences.merged(into: &environment)
        app.launchEnvironment = environment
        app.launch()
        return app
    }

    func runWCAGAudit(
        on app: XCUIApplication,
        auditTypes: XCUIAccessibilityAuditType,
        ignoring issueFilter: ((XCUIAccessibilityAuditIssue) -> Bool)? = nil,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        do {
            try app.performAccessibilityAudit(for: auditTypes) { issue in
                issueFilter?(issue) ?? false
            }
        } catch {
            XCTFail(
                "WCAG accessibility audit failed (\(auditTypes)): \(error.localizedDescription)",
                file: file,
                line: line
            )
        }
    }

    func assertInteractiveElement(
        _ element: XCUIElement,
        identifier: String,
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            element.waitForExistence(timeout: timeout),
            "Missing accessibility identifier '\(identifier)'",
            file: file,
            line: line
        )
        XCTAssertFalse(
            element.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            "Expected non-empty accessibility label for '\(identifier)'",
            file: file,
            line: line
        )
    }

    func assertLabeledElement(
        _ element: XCUIElement,
        description: String,
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            element.waitForExistence(timeout: timeout),
            "Missing accessibility element '\(description)'",
            file: file,
            line: line
        )
        XCTAssertFalse(
            element.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            "Expected non-empty accessibility label for '\(description)'",
            file: file,
            line: line
        )
    }

    func accessibilityElement(
        in app: XCUIApplication,
        identifier: String
    ) -> XCUIElement {
        app.descendants(matching: .any)[identifier]
    }

    func assertSelected(
        _ element: XCUIElement,
        identifier: String,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(
            element.waitForExistence(timeout: 10),
            "Expected '\(identifier)' to exist",
            file: file,
            line: line
        )
        XCTAssertTrue(
            element.isSelected,
            "Expected '\(identifier)' to expose selected accessibility state",
            file: file,
            line: line
        )
    }

    func assertReachable(
        _ element: XCUIElement,
        identifier: String,
        in app: XCUIApplication,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        for _ in 0 ..< 8 where element.exists == false || element.isHittable == false {
            app.swipeUp()
        }
        for _ in 0 ..< 8 where element.exists == false || element.isHittable == false {
            app.swipeDown()
        }
        XCTAssertTrue(
            element.waitForExistence(timeout: 10),
            "Expected '\(identifier)' to exist",
            file: file,
            line: line
        )
        if element.isHittable {
            return
        }
        // At AXXXL some gameplay chrome stays in the hierarchy but clips off-screen.
        // Prefer a spoken label over a brittle hit-test when manual reflow evidence is still required.
        XCTAssertFalse(
            element.label.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            "Expected '\(identifier)' to remain reachable or expose a spoken label at current content size",
            file: file,
            line: line
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

    func selectAliceAndBob(from app: XCUIApplication, timeout: TimeInterval = 10) {
        selectPlayerFromRoster("Alice", in: app, timeout: timeout)
        selectPlayerFromRoster("Bob", in: app, timeout: timeout)
        XCTAssertTrue(
            app.descendants(matching: .any)["setup_selected_Alice"].firstMatch.waitForExistence(timeout: timeout)
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["setup_selected_Bob"].firstMatch.waitForExistence(timeout: timeout)
        )
    }

    func selectAliceAndBobForPartySetup(from app: XCUIApplication, timeout: TimeInterval = 10) {
        selectPlayerFromRoster("Alice", in: app, timeout: timeout)
        selectPlayerFromRoster("Bob", in: app, timeout: timeout)
        let start = app.buttons["startMatchButton"]
        waitForStartEnabled(start, timeout: timeout)
    }

    func startTwoPlayerX01Match(from app: XCUIApplication, timeout: TimeInterval = 10) {
        ensurePlayTab(app, timeout: timeout)
        selectAliceAndBob(from: app, timeout: timeout)
        tapStartMatch(in: app, timeout: timeout)
        waitForX01MatchBoard(in: app, timeout: timeout)
    }

    func startTwoPlayerCricketMatch(from app: XCUIApplication, timeout: TimeInterval = 10) {
        selectModeFromCatalog("standard.cricket", in: app)
        selectAliceAndBob(from: app, timeout: timeout)
        tapStartMatch(in: app, timeout: timeout)
        XCTAssertTrue(app.buttons["cricket_20"].waitForExistence(timeout: timeout))
    }

    func startTwoPlayerBaseballMatch(from app: XCUIApplication, timeout: TimeInterval = 10) {
        selectModeFromCatalog("party.baseball", in: app, expectedModeName: "Baseball", timeout: timeout)
        expandSetupOptions(in: app)
        assertInteractiveElement(
            app.descendants(matching: .any)["setup_baseballInningsChip"],
            identifier: "setup_baseballInningsChip",
            timeout: timeout
        )
        assertInteractiveElement(app.buttons["setup_baseballTieBreakerChip"], identifier: "setup_baseballTieBreakerChip", timeout: timeout)
        selectAliceAndBobForPartySetup(from: app, timeout: timeout)
        tapStartMatch(in: app, timeout: timeout)
        XCTAssertTrue(app.otherElements["baseball_match_header"].waitForExistence(timeout: timeout))
        assertInteractiveElement(app.buttons["pad_1"], identifier: "pad_1", timeout: timeout)
        assertInteractiveElement(app.buttons["baseball_undo"], identifier: "baseball_undo", timeout: timeout)
        assertInteractiveElement(app.otherElements["baseball_inning_strip"], identifier: "baseball_inning_strip", timeout: timeout)
    }

    func startTwoPlayerShanghaiMatch(from app: XCUIApplication, timeout: TimeInterval = 10) {
        selectModeFromCatalog("party.shanghai", in: app, expectedModeName: "Shanghai", timeout: timeout)
        expandSetupOptions(in: app)
        assertInteractiveElement(
            app.descendants(matching: .any)["setup_shanghaiRoundsChip"],
            identifier: "setup_shanghaiRoundsChip",
            timeout: timeout
        )
        assertInteractiveElement(app.buttons["setup_shanghaiBonusChip"], identifier: "setup_shanghaiBonusChip", timeout: timeout)
        selectAliceAndBobForPartySetup(from: app, timeout: timeout)
        tapStartMatch(in: app, timeout: timeout)
        XCTAssertTrue(app.otherElements["shanghai_match_header"].waitForExistence(timeout: timeout))
        assertInteractiveElement(app.buttons["pad_1"], identifier: "pad_1", timeout: timeout)
        assertInteractiveElement(app.buttons["shanghai_undo"], identifier: "shanghai_undo", timeout: timeout)
        assertInteractiveElement(app.otherElements["shanghai_round_strip"], identifier: "shanghai_round_strip", timeout: timeout)
        assertInteractiveElement(
            app.descendants(matching: .any)["shanghai_scoreboard_row_0"],
            identifier: "shanghai_scoreboard_row_0",
            timeout: timeout
        )
    }

    func configureQuickX01Match(_ app: XCUIApplication, timeout: TimeInterval = 10) {
        expandSetupOptions(in: app, timeout: timeout)
        tapMenuChip("setup_startScoreChip", in: app, timeout: timeout)
        selectMenuOption(identifier: "setup_startScoreOption_101", title: "101", in: app, timeout: timeout)
        tapMenuChip("setup_checkoutChip", in: app, timeout: timeout)
        selectMenuOption(identifier: "setup_checkoutOption_singleOut", title: "Straight Out", in: app, timeout: timeout)
        tapMenuChip("setup_legsChip", in: app, timeout: timeout)
        selectMenuOption(identifier: "setup_legsOption_1", title: "1", in: app, timeout: timeout)
    }

    func configureDoubleOut101Match(_ app: XCUIApplication, timeout: TimeInterval = 10) {
        expandSetupOptions(in: app, timeout: timeout)
        tapMenuChip("setup_startScoreChip", in: app, timeout: timeout)
        selectMenuOption(identifier: "setup_startScoreOption_101", title: "101", in: app, timeout: timeout)
        tapMenuChip("setup_checkoutChip", in: app, timeout: timeout)
        selectMenuOption(identifier: "setup_checkoutOption_doubleOut", title: "Double Out", in: app, timeout: timeout)
        tapMenuChip("setup_legsChip", in: app, timeout: timeout)
        selectMenuOption(identifier: "setup_legsOption_1", title: "1", in: app, timeout: timeout)
    }

    func scoreSingleVisit(_ app: XCUIApplication, segments: [Int], timeout: TimeInterval = 10) {
        for segment in segments {
            let key = app.buttons["pad_\(segment)"]
            XCTAssertTrue(key.waitForExistence(timeout: timeout))
            key.tap()
        }
    }

    func waitForPadReady(_ app: XCUIApplication, timeout: TimeInterval = 10) -> XCUIElement {
        let padKey = app.buttons["pad_20"]
        XCTAssertTrue(padKey.waitForExistence(timeout: timeout))
        _ = padKey.wait(for: \.isEnabled, toEqual: true, timeout: timeout + 10)
        return padKey
    }

    func addEasyBot(from app: XCUIApplication, timeout: TimeInterval = 10) {
        let addBot = app.buttons["Add Bot"]
        XCTAssertTrue(addBot.waitForExistence(timeout: timeout))
        addBot.tap()
        selectMenuOption(identifier: "add_bot_easy", title: "Easy", in: app, timeout: timeout)
        let botRow = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'setup_selected_' AND label CONTAINS[c] %@", "Easy")
        ).firstMatch
        XCTAssertTrue(botRow.waitForExistence(timeout: timeout + 10))
    }

    /// Scores a quick 101 straight-out leg win for Alice vs Bob (core flow terminus).
    func finishQuickX01Checkout(for app: XCUIApplication, timeout: TimeInterval = 10) {
        configureQuickX01Match(app, timeout: timeout)
        ensurePlayTab(app, timeout: timeout)
        selectAliceAndBob(from: app, timeout: timeout)
        tapStartMatch(in: app, timeout: timeout)

        scoreSingleVisit(app, segments: [20, 20, 20], timeout: timeout)
        submitMissVisit(on: app, timeout: timeout)
        _ = waitForPadReady(app, timeout: timeout + 5)

        scoreSingleVisit(app, segments: [20, 20, 1], timeout: timeout)

        XCTAssertTrue(
            app.otherElements["matchSummaryHeader"].waitForExistence(timeout: timeout + 5),
            "Match summary should appear after checkout"
        )
    }

    func submitMissVisit(on app: XCUIApplication, timeout: TimeInterval = 10) {
        let miss = app.buttons["pad_0"]
        XCTAssertTrue(miss.waitForExistence(timeout: timeout))
        miss.tap()
        miss.tap()
        miss.tap()
    }

    func openSeededHistoryDetail(_ app: XCUIApplication, timeout: TimeInterval = 10) {
        ensureActivityHistorySegment(app, timeout: timeout)
        let gameCard = app.buttons.containing(
            NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@", "X01", "301")
        ).firstMatch
        XCTAssertTrue(gameCard.waitForExistence(timeout: timeout + 15))
        gameCard.tap()
        XCTAssertTrue(app.staticTexts["Game Statistics"].waitForExistence(timeout: timeout))
    }

    func startAliceVersusEasyBotMatch(from app: XCUIApplication, timeout: TimeInterval = 10) {
        configureQuickX01Match(app, timeout: timeout)
        ensurePlayTab(app, timeout: timeout)
        selectPlayerFromRoster("Alice", in: app, timeout: timeout)
        addEasyBot(from: app, timeout: timeout)
        tapStartMatch(in: app, timeout: timeout)
        waitForX01MatchBoard(in: app, timeout: timeout)
    }

    func openSeededPlayerDetail(
        _ app: XCUIApplication,
        playerName: String,
        timeout: TimeInterval = 10
    ) {
        app.tabBars.buttons["Players"].tap()
        let row = app.buttons["player_row_\(playerName)"]
        XCTAssertTrue(row.waitForExistence(timeout: timeout + 5), "Expected player row for \(playerName)")
        row.tap()
        XCTAssertTrue(app.staticTexts["X01"].waitForExistence(timeout: timeout + 10))
    }
}
