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
    static let axxxlContentSizeCategory = "UIAccessibilityExtraExtraExtraLargeCategory"
}

extension XCTestCase {
    func launchForAccessibility(
        extraArguments: [String] = [],
        contentSizeCategory: String? = nil
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = AccessibilityTestLaunch.defaultArguments + extraArguments
        if let contentSizeCategory {
            app.launchEnvironment["UIPreferredContentSizeCategoryName"] = contentSizeCategory
        }
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

    func assertReachable(_ element: XCUIElement, identifier: String, file: StaticString = #filePath, line: UInt = #line) {
        for _ in 0 ..< 6 where element.exists == false || element.isHittable == false {
            XCUIApplication().swipeUp()
        }
        XCTAssertTrue(
            element.waitForExistence(timeout: 10),
            "Expected '\(identifier)' to exist",
            file: file,
            line: line
        )
        XCTAssertTrue(
            element.isHittable,
            "Expected '\(identifier)' to remain reachable at current content size",
            file: file,
            line: line
        )
    }

    func startTwoPlayerX01Match(from app: XCUIApplication, timeout: TimeInterval = 10) {
        app.buttons["select_Alice"].tap()
        app.buttons["select_Bob"].tap()
        let start = app.buttons["startMatchButton"]
        XCTAssertTrue(start.waitForExistence(timeout: timeout))
        start.tap()
        XCTAssertTrue(app.buttons["pad_20"].waitForExistence(timeout: timeout))
    }

    func startTwoPlayerCricketMatch(from app: XCUIApplication, timeout: TimeInterval = 10) {
        app.buttons["setup_mode_cricket"].tap()
        app.buttons["select_Alice"].tap()
        app.buttons["select_Bob"].tap()
        let start = app.buttons["startMatchButton"]
        XCTAssertTrue(start.waitForExistence(timeout: timeout))
        start.tap()
        XCTAssertTrue(app.buttons["cricket_20"].waitForExistence(timeout: timeout))
    }

    func configureQuickX01Match(_ app: XCUIApplication, timeout: TimeInterval = 10) {
        let startScore = app.buttons["setup_startScoreChip"]
        XCTAssertTrue(startScore.waitForExistence(timeout: timeout))
        startScore.tap()
        app.buttons["101"].tap()
        app.buttons["setup_checkoutChip"].tap()
        app.buttons["Straight Out"].tap()
        app.buttons["setup_legsChip"].tap()
        app.buttons["setup_legsOption_1"].tap()
    }

    func configureDoubleOut101Match(_ app: XCUIApplication, timeout: TimeInterval = 10) {
        let startScore = app.buttons["setup_startScoreChip"]
        XCTAssertTrue(startScore.waitForExistence(timeout: timeout))
        startScore.tap()
        app.buttons["101"].tap()
        app.buttons["setup_checkoutChip"].tap()
        app.buttons["Double Out"].tap()
        app.buttons["setup_legsChip"].tap()
        app.buttons["setup_legsOption_1"].tap()
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
        let easy = app.buttons["add_bot_easy"]
        XCTAssertTrue(easy.waitForExistence(timeout: timeout))
        easy.tap()
        let botRow = app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Easy Bot")).firstMatch
        XCTAssertTrue(botRow.waitForExistence(timeout: timeout + 10))
    }

    /// Scores a quick 101 straight-out leg win for Alice vs Easy Bot (core flow terminus).
    func finishQuickX01Checkout(for app: XCUIApplication, timeout: TimeInterval = 10) {
        configureQuickX01Match(app, timeout: timeout)
        app.buttons["select_Alice"].tap()
        addEasyBot(from: app, timeout: timeout)
        app.buttons["startMatchButton"].tap()

        let twenty = app.buttons["pad_20"]
        XCTAssertTrue(twenty.waitForExistence(timeout: timeout))
        twenty.tap()
        twenty.tap()
        twenty.tap()

        _ = twenty.wait(for: \.isEnabled, toEqual: true, timeout: timeout + 10)
        app.buttons["pad_double"].tap()
        app.buttons["pad_20"].tap()
        app.buttons["pad_1"].tap()

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
        app.tabBars.buttons["History"].tap()
        XCTAssertTrue(app.staticTexts["History"].waitForExistence(timeout: timeout))
        let gameCard = app.buttons.containing(
            NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@", "X01", "301")
        ).firstMatch
        XCTAssertTrue(gameCard.waitForExistence(timeout: timeout + 15))
        gameCard.tap()
        XCTAssertTrue(app.staticTexts["Game Statistics"].waitForExistence(timeout: timeout))
    }

    func selectAliceAndBob(from app: XCUIApplication, timeout: TimeInterval = 10) {
        assertInteractiveElement(app.buttons["select_Alice"], identifier: "select_Alice", timeout: timeout)
        app.buttons["select_Alice"].tap()
        assertInteractiveElement(app.buttons["select_Bob"], identifier: "select_Bob", timeout: timeout)
        app.buttons["select_Bob"].tap()
    }

    func startAliceVersusEasyBotMatch(from app: XCUIApplication, timeout: TimeInterval = 10) {
        configureQuickX01Match(app, timeout: timeout)
        app.buttons["select_Alice"].tap()
        addEasyBot(from: app, timeout: timeout)
        let start = app.buttons["startMatchButton"]
        XCTAssertTrue(start.waitForExistence(timeout: timeout))
        start.tap()
        XCTAssertTrue(app.buttons["pad_20"].waitForExistence(timeout: timeout))
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
