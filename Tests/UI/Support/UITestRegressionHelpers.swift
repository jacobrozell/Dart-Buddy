import XCTest

extension DartBuddyUITestCase {
    func launchForRegression(
        extraArguments: [String] = [],
        localeLanguage: String? = nil,
        localeIdentifier: String? = nil
    ) -> XCUIApplication {
        launchApp(
            [
                "-seed_players",
                Self.disableFeedbackLaunchArgument,
                Self.instantBotsLaunchArgument,
            ] + extraArguments,
            localeLanguage: localeLanguage,
            localeIdentifier: localeIdentifier
        )
    }

    func botThrowingBanner(in app: XCUIApplication) -> XCUIElement {
        app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS[c] %@", "Bot throwing")
        ).firstMatch
    }

    func waitForBotVisitToComplete(in app: XCUIApplication, padKeyIdentifier: String = "pad_20", timeout: TimeInterval = 10) {
        let pad = app.buttons[padKeyIdentifier]
        XCTAssertTrue(pad.waitForExistence(timeout: timeout), "Expected scoring pad key '\(padKeyIdentifier)'")
        let banner = botThrowingBanner(in: app)
        if banner.waitForExistence(timeout: 2) {
            let cleared = NSPredicate(format: "exists == false")
            let expectation = XCTNSPredicateExpectation(predicate: cleared, object: banner)
            _ = XCTWaiter.wait(for: [expectation], timeout: timeout + 20)
        }
        XCTAssertTrue(
            pad.wait(for: \.isEnabled, toEqual: true, timeout: timeout + 25),
            "Scoring pad should re-enable after the bot visit completes"
        )
    }

    func waitForRegressionCricketPadReady(_ app: XCUIApplication, timeout: TimeInterval = 10) {
        waitForCricketScoringPadReady(app, timeout: timeout)
    }

    func dismissExitAlertStay(in app: XCUIApplication, timeout: TimeInterval = 10) {
        let exit = app.buttons["match_exit"]
        XCTAssertTrue(exit.waitForExistence(timeout: timeout))
        exit.tap()
        let stay = app.alerts.buttons["Stay"]
        XCTAssertTrue(stay.waitForExistence(timeout: timeout), "Exit confirmation should offer Stay")
        stay.tap()
    }

    func startAliceVersusEasyBotX01MatchForRegression(
        from app: XCUIApplication,
        timeout: TimeInterval = 10
    ) {
        ensurePlayTab(app, timeout: timeout)
        configureFastX01MatchForUITest(app, timeout: timeout)
        selectPlayerFromRoster("Alice", in: app, timeout: timeout)
        addEasyBot(from: app, timeout: timeout)
        tapStartMatch(in: app, timeout: timeout)
        waitForX01MatchBoard(in: app, timeout: timeout + 15)
    }

    func startAliceVersusEasyBotCricketMatchForRegression(
        from app: XCUIApplication,
        timeout: TimeInterval = 10
    ) {
        ensurePlayTab(app, timeout: timeout)
        selectCricketMode(in: app, timeout: timeout)
        selectPlayerFromRoster("Alice", in: app, timeout: timeout)
        addEasyBot(from: app, timeout: timeout)
        tapStartMatch(in: app, timeout: timeout + 10)
        XCTAssertTrue(app.buttons["cricket_20"].waitForExistence(timeout: timeout + 10))
    }

    func submitCricketMissVisitAndInterruptWithExitStay(
        in app: XCUIApplication,
        timeout: TimeInterval = 10
    ) {
        waitForRegressionCricketPadReady(app, timeout: timeout)
        let miss = app.buttons["cricket_miss"]
        XCTAssertTrue(miss.waitForExistence(timeout: timeout))
        for index in 0 ..< 3 {
            miss.tap()
            if index == 2 {
                let exit = app.buttons["match_exit"]
                if exit.waitForExistence(timeout: 2) {
                    exit.tap()
                    let stay = app.alerts.buttons["Stay"]
                    if stay.waitForExistence(timeout: timeout) {
                        stay.tap()
                        return
                    }
                }
            }
        }
        dismissExitAlertStay(in: app, timeout: timeout)
    }

    func startTwoPlayerX01MatchForRegression(from app: XCUIApplication, timeout: TimeInterval = 10) {
        ensurePlayTab(app, timeout: timeout)
        configureFastX01MatchForUITest(app, timeout: timeout)
        selectAliceAndBob(from: app, timeout: timeout)
        tapStartMatch(in: app, timeout: timeout)
        waitForX01MatchBoard(in: app, timeout: timeout + 15)
    }

    func configureStraightOut101Match(_ app: XCUIApplication, timeout: TimeInterval = 10) {
        ensurePlayTab(app, timeout: timeout)
        expandSetupOptions(in: app, timeout: timeout)
        tapMenuChip("setup_startScoreChip", in: app, timeout: timeout)
        selectMenuOption(identifier: "setup_startScoreOption_101", title: "101", in: app, timeout: timeout)
        tapMenuChip("setup_checkoutChip", in: app, timeout: timeout)
        selectMenuOption(identifier: "setup_checkoutOption_singleOut", title: "Straight Out", in: app, timeout: timeout)
        tapMenuChip("setup_legsChip", in: app, timeout: timeout)
        selectMenuOption(identifier: "setup_legsOption_1", title: "1", in: app, timeout: timeout)
    }

    func assertScoringKeysBelowPinnedArea(
        _ anchor: XCUIElement,
        in app: XCUIApplication,
        keyIdentifiers: [String],
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        XCTAssertTrue(anchor.waitForExistence(timeout: timeout), file: file, line: line)
        for identifier in keyIdentifiers {
            let key = app.buttons[identifier]
            XCTAssertTrue(
                key.waitForExistence(timeout: timeout),
                "\(identifier) should exist in landscape",
                file: file,
                line: line
            )
            XCTAssertGreaterThan(
                key.frame.minY,
                anchor.frame.minY,
                "\(identifier) should sit below the pinned score area",
                file: file,
                line: line
            )
        }
    }

    func rotateToLandscapeLeftForTest(app: XCUIApplication, timeout: TimeInterval = 5) {
        rotateToLandscapeLeft(for: app, timeout: timeout)
    }

    func assertActiveScoreCardNamesBot(in app: XCUIApplication, timeout: TimeInterval = 10) {
        let card = activeX01ScoreCard(in: app)
        XCTAssertTrue(card.waitForExistence(timeout: timeout))
        let label = card.label
        XCTAssertTrue(
            label.localizedCaseInsensitiveContains("DartBot")
                || label.localizedCaseInsensitiveContains("Easy")
                || label.localizedCaseInsensitiveContains("Bot"),
            "Active score card should name the bot opponent (got '\(label)')"
        )
    }

    func assertActiveScoreCardNamesAlice(in app: XCUIApplication, timeout: TimeInterval = 10) {
        let card = activeX01ScoreCard(in: app)
        XCTAssertTrue(card.waitForExistence(timeout: timeout))
        XCTAssertTrue(
            card.label.localizedCaseInsensitiveContains("Alice"),
            "Alice should be active after the bot visit resumes and completes (got '\(card.label)')"
        )
    }

}
