import XCTest

final class CricketMatchUITests: DartBuddyUITestCase {
    func testCricketMatchContinuesAfterFirstPlayerClosesAllTargets() {
        let app = launchApp(["-seed_players"])

        startTwoPlayerCricketMatch(from: app)

        closeAllCricketTargets(in: app, timeout: timeout)

        XCTAssertFalse(
            app.otherElements["matchSummaryHeader"].waitForExistence(timeout: 2),
            "Match should not end until every player has closed all targets"
        )
        waitForActiveCricketPlayer("Bob", in: app, timeout: timeout + 10)
        XCTAssertTrue(app.buttons["cricket_20"].isEnabled, "Opponent should still be able to score")
    }

    func testCricketGridScoringRecordsMarks() {
        let app = launchApp(["-seed_players"])

        startTwoPlayerCricketMatch(from: app)

        let target20 = app.buttons["cricket_20"]
        XCTAssertTrue(target20.waitForExistence(timeout: timeout))
        target20.tap()

        XCTAssertTrue(app.staticTexts["20"].waitForExistence(timeout: timeout), "Visit preview should show the entered dart")

        target20.tap()
        target20.tap()

        let closedMark = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", "Closed"))
            .firstMatch
        XCTAssertTrue(
            closedMark.waitForExistence(timeout: timeout + 5),
            "Three marks on 20 should close the target on the board"
        )
    }

    func testThreePlayerCricketMatchContinuesAfterFirstPlayerClosesAllTargets() {
        let app = launchApp(["-seed_players"])

        startThreePlayerCricketMatch(from: app)

        closeAllCricketTargetsForCurrentPlayer(in: app, playerCount: 3, timeout: timeout)

        XCTAssertFalse(
            app.otherElements["matchSummaryHeader"].waitForExistence(timeout: 2),
            "Match should not end until every player has closed all targets"
        )
        waitForActiveCricketPlayer("Bob", in: app, timeout: timeout + 10)
        XCTAssertTrue(app.buttons["cricket_20"].isEnabled, "Opponent should still be able to score")
    }

    // Full 3-player Cricket completion is covered by unit tests
    // (`cricketUIEquivalentThreePlayerSynchronizedSweepCompletesMatch`); a UI replay is
    // slow and brittle in CI. Continuation after the first finisher is asserted above.

    func testCricketPointsOffDisablesModeChip() {
        let app = launchApp(["-seed_players"])
        selectCricketMode(in: app, timeout: timeout)
        tapCricketPointsOff(in: app)
        let pointsChip = app.descendants(matching: .any)["setup_cricketPointsChip"]
        XCTAssertTrue(pointsChip.waitForExistence(timeout: timeout))
        XCTAssertTrue(
            pointsChip.label.localizedCaseInsensitiveContains("Off"),
            "Points chip should show Off before asserting mode chip state (got '\(pointsChip.label)')"
        )
        let modeChip = app.descendants(matching: .any)["setup_cricketModeChip"]
        XCTAssertTrue(modeChip.waitForExistence(timeout: timeout))
        XCTAssertTrue(
            modeChip.wait(for: \.isEnabled, toEqual: false, timeout: timeout + 5),
            "Mode chip should be disabled when cricket points are off"
        )
    }

    func testCricketCutThroatSubtitleOnMatchStart() {
        let app = launchApp(["-seed_players"])
        selectCricketMode(in: app, timeout: timeout)
        tapCricketCutThroatMode(in: app)
        selectPlayerFromRoster("Alice", in: app)
        selectPlayerFromRoster("Bob", in: app)
        tapStartMatch(in: app, timeout: timeout)
        let subtitle = app.staticTexts["cricket_match_subtitle"]
        XCTAssertTrue(subtitle.waitForExistence(timeout: timeout))
        XCTAssertTrue(subtitle.label.contains("Cut Throat") || subtitle.label.contains("Lowest"))
    }

    func testCricketLiveMprAndDartsIdentifiersOnActiveColumn() {
        let app = launchApp(["-seed_players"])
        startTwoPlayerCricketMatch(from: app)

        waitForCricketScoringPadReady(app, timeout: timeout)
        app.buttons["cricket_triple"].tap()
        app.buttons["cricket_20"].tap()

        assertActiveCricketColumnLabel(app, contains: "1 darts", timeout: timeout + 5)
        assertActiveCricketColumnLabel(app, contains: "marks per round", timeout: timeout + 5)
    }

    func testCricketLandscapePadReachableAndScores() {
        let app = launchApp(["-seed_players"])
        startTwoPlayerCricketMatch(from: app)
        XCTAssertTrue(app.buttons["cricket_20"].waitForExistence(timeout: timeout))

        rotateToLandscapeLeftForTest(app: app, timeout: timeout + 5)

        let column = app.otherElements["cricket_column_active"]
        XCTAssertTrue(column.waitForExistence(timeout: timeout))
        XCTAssertTrue(column.isHittable, "Active player board should stay locked at the top in landscape")

        let keyIdentifiers = [
            "cricket_20", "cricket_19", "cricket_18",
            "cricket_17", "cricket_16", "cricket_15",
            "cricket_bull", "cricket_miss",
            "cricket_double", "cricket_triple", "cricket_undo", "cricket_enter"
        ]
        assertScoringKeysBelowPinnedArea(column, in: app, keyIdentifiers: keyIdentifiers, timeout: timeout)

        let enter = app.buttons["cricket_enter"]
        XCTAssertTrue(enter.waitForExistence(timeout: timeout))
        XCTAssertGreaterThan(enter.frame.height, 32, "Enter should not collapse to a thin bar in landscape")

        let target20 = app.buttons["cricket_20"]
        XCTAssertTrue(target20.isHittable)
        target20.tap()
        target20.tap()
        target20.tap()

        waitForActiveCricketPlayer("Bob", in: app, timeout: timeout + 10)
    }

    // MARK: - Phase 2 core gameplay

    func testCricketEnterSubmitsPartialVisit() {
        let app = launchApp(["-seed_players"])
        startTwoPlayerCricketMatch(from: app)

        app.buttons["cricket_bull"].tap()
        app.buttons["cricket_enter"].tap()
        waitForActiveCricketPlayer("Bob", in: app, timeout: timeout + 10)
    }

    func testCricketMissVisitAdvancesTurn() {
        let app = launchApp(["-seed_players"])
        startTwoPlayerCricketMatch(from: app)

        submitCricketMissVisit(in: app, timeout: timeout)
        waitForActiveCricketPlayer("Bob", in: app, timeout: timeout + 10)
    }

    func testCricketScoringModeShowsPoints() {
        let app = launchApp(["-seed_players"])
        selectCricketMode(in: app, timeout: timeout)
        tapCricketPointsOn(in: app)
        startTwoPlayerCricketMatch(from: app)

        app.buttons["cricket_20"].tap()
        app.buttons["cricket_20"].tap()
        app.buttons["cricket_20"].tap()

        let closedMark = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", "Closed"))
            .firstMatch
        XCTAssertTrue(
            closedMark.waitForExistence(timeout: timeout + 5),
            "Points-on cricket should still record marks and close targets"
        )
    }

    func testCricketUndoRemovesLastDart() {
        let app = launchApp(["-seed_players"])
        startTwoPlayerCricketMatch(from: app)

        app.buttons["cricket_20"].tap()
        app.buttons["cricket_undo"].tap()
        XCTAssertTrue(
            app.buttons["cricket_20"].isEnabled,
            "Pad undo should restore scoring without freezing the visit"
        )
    }

    func testCricketDoubleSingleMark() {
        let app = launchApp(["-seed_players"])
        startTwoPlayerCricketMatch(from: app)

        tapCricketSegment("19", multiplier: .double, in: app, timeout: timeout)
        XCTAssertTrue(
            app.staticTexts["19"].waitForExistence(timeout: timeout),
            "Double 19 should appear in the visit preview"
        )
    }

    // MARK: - Phase 4 multi-player

    func testThreePlayerCricketPinnedBoardVisibleInLandscape() {
        let app = launchApp(["-seed_players"])
        startThreePlayerCricketMatch(from: app)

        rotateToLandscapeLeftForTest(app: app, timeout: timeout + 5)

        let column = app.otherElements["cricket_column_active"]
        XCTAssertTrue(column.waitForExistence(timeout: timeout))
        XCTAssertTrue(column.isHittable)
        XCTAssertTrue(app.buttons["cricket_20"].isHittable)
    }

    func testThreePlayerCricketInactiveColumnReachableViaScroll() {
        let app = launchApp(["-seed_players"])
        startThreePlayerCricketMatch(from: app)

        let inactiveColumn = app.otherElements.matching(identifier: "cricket_column").matching(
            NSPredicate(format: "label CONTAINS[c] %@", "Bob")
        ).firstMatch
        if !(inactiveColumn.waitForExistence(timeout: 2) && inactiveColumn.isHittable) {
            for _ in 0 ..< 4 {
                app.swipeLeft()
                if inactiveColumn.waitForExistence(timeout: 2), inactiveColumn.isHittable {
                    break
                }
            }
        }
        XCTAssertTrue(
            inactiveColumn.waitForExistence(timeout: timeout),
            "Bob's cricket column should exist in the horizontal board scroll"
        )
        XCTAssertTrue(
            inactiveColumn.isHittable,
            "Bob's cricket column should be reachable in the horizontal board scroll"
        )
    }
}
