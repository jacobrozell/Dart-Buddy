import XCTest

extension DartBuddyUITestCase {
    func removePlayerFromTurnOrder(named name: String, in app: XCUIApplication) {
        let removeButton = app.buttons["setup_remove_\(name)"]
        XCTAssertTrue(
            removeButton.waitForExistence(timeout: timeout),
            "Expected remove control for \(name) in turn order"
        )
        removeButton.tap()
    }

    func openBotRow(named name: String, in app: XCUIApplication) {
        let botRow = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", name)).firstMatch
        if botRow.waitForExistence(timeout: timeout) {
            botRow.tap()
            return
        }

        for _ in 0 ..< 4 {
            app.swipeUp()
            if botRow.waitForExistence(timeout: 1) {
                botRow.tap()
                return
            }
        }

        XCTFail("Expected bot row containing '\(name)' on the Players list")
    }

    func scrollToHistoryStats(_ app: XCUIApplication) {
        let statsMarker = app.staticTexts["Average & Highest Score"]
        for _ in 0 ..< 4 where statsMarker.exists == false || statsMarker.isHittable == false {
            app.swipeUp()
        }
    }

    func scrollToFeedbackSwitches(_ app: XCUIApplication) {
        let haptics = app.switches["settings_hapticsToggle"]
        for _ in 0 ..< 4 where haptics.exists == false || haptics.isHittable == false {
            app.swipeUp()
        }
    }

    func scrollToDeleteButton(_ app: XCUIApplication) {
        let delete = app.buttons["historyDetailDeleteButton"]
        for _ in 0 ..< 6 where delete.exists == false || delete.isHittable == false {
            app.swipeUp()
        }
        XCTAssertTrue(delete.waitForExistence(timeout: timeout), "Delete button should be reachable after scrolling")
    }

    func selectPlayerFromRoster(_ name: String, in app: XCUIApplication) {
        let button = app.buttons["select_\(name)"]
        for _ in 0 ..< 4 where button.exists == false {
            app.swipeUp()
        }
        XCTAssertTrue(
            button.waitForExistence(timeout: timeout),
            "Expected roster row for \(name)"
        )
        button.tap()
    }

    func selectAliceBobAndCarol(from app: XCUIApplication) {
        selectPlayerFromRoster("Alice", in: app)
        selectPlayerFromRoster("Bob", in: app)
        selectPlayerFromRoster("Carol", in: app)
        XCTAssertTrue(
            app.descendants(matching: .any)["setup_selected_Alice"].firstMatch.waitForExistence(timeout: timeout)
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["setup_selected_Bob"].firstMatch.waitForExistence(timeout: timeout)
        )
        XCTAssertTrue(
            app.descendants(matching: .any)["setup_selected_Carol"].firstMatch.waitForExistence(timeout: timeout)
        )
    }

    func startThreePlayerCricketMatch(from app: XCUIApplication) {
        ensurePlayTab(app, timeout: timeout)
        app.buttons["setup_mode_cricket"].tap()
        selectAliceBobAndCarol(from: app)
        let start = app.buttons["startMatchButton"]
        waitForStartEnabled(start, timeout: timeout)
        start.tap()
        XCTAssertTrue(app.buttons["cricket_20"].waitForExistence(timeout: timeout))
    }
}
