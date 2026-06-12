import XCTest

enum X01PadMultiplier {
    case single
    case double
    case triple
}

enum CricketPadMultiplier {
    case single
    case double
    case triple
}

extension XCTestCase {
    func tapX01Segment(
        _ segment: Int,
        multiplier: X01PadMultiplier = .single,
        in app: XCUIApplication,
        timeout: TimeInterval = 10
    ) {
        switch multiplier {
        case .single:
            break
        case .double:
            app.buttons["pad_double"].tap()
        case .triple:
            app.buttons["pad_triple"].tap()
        }
        let key = app.buttons["pad_\(segment)"]
        XCTAssertTrue(key.waitForExistence(timeout: timeout))
        key.tap()
    }

    func submitX01Visit(
        segments: [Int],
        multiplier: X01PadMultiplier = .single,
        in app: XCUIApplication,
        timeout: TimeInterval = 10
    ) {
        for segment in segments {
            tapX01Segment(segment, multiplier: multiplier, in: app, timeout: timeout)
        }
        _ = waitForPadReady(app, timeout: timeout + 5)
    }

    func tapCricketSegment(
        _ segment: String,
        multiplier: CricketPadMultiplier = .single,
        in app: XCUIApplication,
        timeout: TimeInterval = 10
    ) {
        switch multiplier {
        case .single:
            break
        case .double:
            app.buttons["cricket_double"].tap()
        case .triple:
            app.buttons["cricket_triple"].tap()
        }
        let key = app.buttons["cricket_\(segment)"]
        XCTAssertTrue(key.waitForExistence(timeout: timeout))
        key.tap()
    }

    func waitForActiveCricketPlayer(
        _ name: String,
        in app: XCUIApplication,
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let column = app.otherElements["cricket_column_active"]
        XCTAssertTrue(column.waitForExistence(timeout: timeout), file: file, line: line)
        let predicate = NSPredicate(format: "label BEGINSWITH[c] %@", name)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: column)
        XCTAssertEqual(
            XCTWaiter.wait(for: [expectation], timeout: timeout),
            .completed,
            "Expected active cricket player '\(name)' (got '\(column.label)')",
            file: file,
            line: line
        )
    }

    func waitForActiveX01Player(
        _ name: String,
        in app: XCUIApplication,
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let card = app.otherElements["scoreCard_active"]
        XCTAssertTrue(card.waitForExistence(timeout: timeout), file: file, line: line)
        let predicate = NSPredicate(format: "label BEGINSWITH[c] %@", name)
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: card)
        XCTAssertEqual(
            XCTWaiter.wait(for: [expectation], timeout: timeout),
            .completed,
            "Expected active X01 player '\(name)' (got '\(card.label)')",
            file: file,
            line: line
        )
    }

    func submitCricketTripleCloseVisit(
        targets: [String],
        in app: XCUIApplication,
        timeout: TimeInterval = 10
    ) {
        XCTAssertEqual(targets.count, 3)
        waitForCricketScoringPadReady(app, timeout: timeout)
        app.buttons["cricket_triple"].tap()
        for target in targets {
            let key = app.buttons["cricket_\(target)"]
            XCTAssertTrue(key.waitForExistence(timeout: timeout))
            key.tap()
        }
        waitForCricketScoringPadReady(app, timeout: timeout + 5)
    }

    func submitCricketBullCloseVisit(in app: XCUIApplication, timeout: TimeInterval = 10) {
        waitForCricketScoringPadReady(app, timeout: timeout)
        let bull = app.buttons["cricket_bull"]
        XCTAssertTrue(bull.waitForExistence(timeout: timeout))
        for _ in 0 ..< 2 {
            app.buttons["cricket_double"].tap()
            bull.tap()
        }
        app.buttons["cricket_enter"].tap()
        let summary = app.otherElements["matchSummaryHeader"]
        if summary.waitForExistence(timeout: 3) { return }
        waitForCricketScoringPadReady(app, timeout: timeout + 5)
    }

    func submitCricketMissVisit(in app: XCUIApplication, timeout: TimeInterval = 10) {
        waitForCricketScoringPadReady(app, timeout: timeout)
        let miss = app.buttons["cricket_miss"]
        XCTAssertTrue(miss.waitForExistence(timeout: timeout))
        miss.tap()
        miss.tap()
        miss.tap()
        waitForCricketScoringPadReady(app, timeout: timeout + 5)
    }

    func closeAllCricketTargets(in app: XCUIApplication, timeout: TimeInterval = 10) {
        submitCricketTripleCloseVisit(targets: ["20", "19", "18"], in: app, timeout: timeout)
        submitCricketTripleCloseVisit(targets: ["17", "16", "15"], in: app, timeout: timeout)
        submitCricketBullCloseVisit(in: app, timeout: timeout)
    }

    func closeAllCricketTargetsForCurrentPlayer(
        in app: XCUIApplication,
        playerCount: Int,
        timeout: TimeInterval = 10
    ) {
        submitCricketTripleCloseVisit(targets: ["20", "19", "18"], in: app, timeout: timeout)
        for _ in 0 ..< (playerCount - 1) {
            submitCricketMissVisit(in: app, timeout: timeout)
        }
        submitCricketTripleCloseVisit(targets: ["17", "16", "15"], in: app, timeout: timeout)
        for _ in 0 ..< (playerCount - 1) {
            submitCricketMissVisit(in: app, timeout: timeout)
        }
        submitCricketBullCloseVisit(in: app, timeout: timeout)
    }

    func tapRematch(
        in app: XCUIApplication,
        timeout: TimeInterval = 10
    ) {
        let rematch = app.buttons["matchSummaryRematch"]
        XCTAssertTrue(rematch.waitForExistence(timeout: timeout))
        rematch.tap()
        XCTAssertTrue(
            app.buttons["match_exit"].waitForExistence(timeout: timeout + 15),
            "Rematch should return to the live match screen"
        )
    }

    func tapSummaryDone(in app: XCUIApplication, timeout: TimeInterval = 10) {
        let done = app.buttons["matchSummaryDone"]
        XCTAssertTrue(done.waitForExistence(timeout: timeout))
        done.tap()
        XCTAssertTrue(
            assertBrandAppTitleVisible(in: app, timeout: timeout),
            "Done should return to Play home"
        )
    }

    func tapMatchExit(in app: XCUIApplication, timeout: TimeInterval = 10) {
        let exit = app.buttons["match_exit"]
        XCTAssertTrue(exit.waitForExistence(timeout: timeout))
        exit.tap()
    }

    func dismissExitConfirmation(in app: XCUIApplication) {
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.12)).tap()
    }

    func tapExitAlertButton(
        _ title: String,
        identifier: String? = nil,
        in app: XCUIApplication,
        timeout: TimeInterval = 10
    ) {
        if let identifier {
            let identified = app.descendants(matching: .any).matching(identifier: identifier).firstMatch
            if identified.waitForExistence(timeout: timeout) {
                identified.tap()
                return
            }
        }

        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            let candidates: [XCUIElement] = [
                app.buttons.matching(NSPredicate(format: "label ==[c] %@", title)).firstMatch,
                app.descendants(matching: .any).matching(NSPredicate(format: "label ==[c] %@", title)).firstMatch,
                app.alerts.buttons.matching(NSPredicate(format: "label ==[c] %@", title)).firstMatch,
                app.buttons.containing(NSPredicate(format: "label CONTAINS[c] %@", title)).firstMatch
            ]
            for candidate in candidates where candidate.waitForExistence(timeout: 1) {
                if candidate.isHittable {
                    candidate.tap()
                } else {
                    candidate.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
                }
                return
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.15))
        }

        XCTAssertTrue(false, "Expected exit dialog button '\(title)'")
    }

    func tapExitSaveAndForfeit(in app: XCUIApplication, timeout: TimeInterval = 10) {
        tapMatchExit(in: app, timeout: timeout)
        tapExitAlertButton(
            "Save & Forfeit",
            identifier: "match_exit_save_and_forfeit",
            in: app,
            timeout: timeout + 5
        )
    }

    func forfeitMatchFromExit(
        asPlayer name: String? = nil,
        winner winnerName: String? = nil,
        in app: XCUIApplication,
        timeout: TimeInterval = 10
    ) {
        tapExitSaveAndForfeit(in: app, timeout: timeout)
        if app.otherElements["forfeit_player_picker"].waitForExistence(timeout: 2), let name {
            pickForfeitPlayer(named: name, in: app, timeout: timeout)
        }
        if app.otherElements["forfeit_winner_picker"].waitForExistence(timeout: 2), let winnerName {
            pickForfeitWinner(named: winnerName, in: app, timeout: timeout)
        }
        confirmForfeitFinal(in: app, timeout: timeout)
    }

    func forfeitMatchFromExit(in app: XCUIApplication, timeout: TimeInterval = 10) {
        forfeitMatchFromExit(asPlayer: nil, winner: nil, in: app, timeout: timeout)
    }

    func confirmForfeitFinal(in app: XCUIApplication, timeout: TimeInterval = 10) {
        let confirm = app.descendants(matching: .any).matching(identifier: "forfeit_confirm_action").firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: timeout + 5))
        confirm.tap()
    }

    func assertMatchSummaryForfeitBanner(
        in app: XCUIApplication,
        timeout: TimeInterval = 10,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let banner = app.descendants(matching: .any).matching(identifier: "matchSummaryForfeitBanner").firstMatch
        if banner.waitForExistence(timeout: timeout) {
            return
        }
        let header = app.otherElements["matchSummaryHeader"]
        XCTAssertTrue(header.waitForExistence(timeout: timeout), file: file, line: line)
        XCTAssertTrue(
            header.label.localizedCaseInsensitiveContains("ended early")
                || header.label.localizedCaseInsensitiveContains("forfeit"),
            "Expected forfeit summary header (got '\(header.label)')",
            file: file,
            line: line
        )
    }

    func pickForfeitPlayer(named name: String, in app: XCUIApplication, timeout: TimeInterval = 10) {
        let sanitized = name
            .lowercased()
            .replacingOccurrences(of: " ", with: "_")
            .filter { $0.isLetter || $0.isNumber || $0 == "_" }
        let row = app.buttons["forfeit_pick_\(sanitized)"]
        XCTAssertTrue(row.waitForExistence(timeout: timeout))
        row.tap()
    }

    func pickForfeitWinner(named name: String, in app: XCUIApplication, timeout: TimeInterval = 10) {
        pickForfeitPlayer(named: name, in: app, timeout: timeout)
    }

    func saveAndExitMatch(in app: XCUIApplication, timeout: TimeInterval = 10) {
        tapMatchExit(in: app, timeout: timeout)
        tapExitAlertButton("Save & Exit", in: app, timeout: timeout)
        XCTAssertTrue(assertBrandAppTitleVisible(in: app, timeout: timeout))
    }

    func abandonMatchFromExit(in app: XCUIApplication, timeout: TimeInterval = 10) {
        tapMatchExit(in: app, timeout: timeout)
        tapExitAlertButton("Abandon Match", identifier: "match_exit_abandon", in: app, timeout: timeout)
        XCTAssertTrue(assertBrandAppTitleVisible(in: app, timeout: timeout))
    }

    func undoFromMatchSummary(in app: XCUIApplication, timeout: TimeInterval = 10) {
        let undo = app.buttons["matchSummaryUndoLastThrow"]
        XCTAssertTrue(undo.waitForExistence(timeout: timeout))
        undo.tap()
    }
}
