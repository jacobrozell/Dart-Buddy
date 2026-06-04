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

    func addTrainingPartner(from app: XCUIApplication, timeout: TimeInterval = 10) {
        let addBot = app.buttons["Add Bot"]
        XCTAssertTrue(addBot.waitForExistence(timeout: timeout))
        addBot.tap()
        let trainingOption = app.buttons["training_bot_add_setup"].firstMatch
        let trainingByLabel = app.buttons.containing(
            NSPredicate(format: "label CONTAINS %@", "Training Partner")
        ).firstMatch
        if trainingOption.waitForExistence(timeout: 2) {
            trainingOption.tap()
        } else {
            XCTAssertTrue(
                trainingByLabel.waitForExistence(timeout: timeout),
                "Training Partner should appear in the Add Bot menu when seeded"
            )
            trainingByLabel.tap()
        }
        let partnerRow = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'setup_selected_' AND label CONTAINS[c] %@", "Training Partner")
        ).firstMatch
        XCTAssertTrue(partnerRow.waitForExistence(timeout: timeout + 10))
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

    func selectCricketMode(in app: XCUIApplication) {
        ensurePlayTab(app, timeout: timeout)
        app.buttons["setup_mode_cricket"].tap()
    }

    func tapCricketPointsOff(in app: XCUIApplication) {
        let chip = app.buttons["setup_cricketPointsChip"]
        XCTAssertTrue(chip.waitForExistence(timeout: timeout))
        chip.tap()
        app.buttons["Off"].tap()
    }

    func tapCricketCutThroatMode(in app: XCUIApplication) {
        let chip = app.buttons["setup_cricketModeChip"]
        XCTAssertTrue(chip.waitForExistence(timeout: timeout))
        chip.tap()
        app.buttons["Cut Throat"].tap()
    }

    func startTwoPlayerCricketMatch(from app: XCUIApplication, playerA: String = "Alice", playerB: String = "Bob") {
        selectCricketMode(in: app)
        selectPlayerFromRoster(playerA, in: app)
        selectPlayerFromRoster(playerB, in: app)
        let start = app.buttons["startMatchButton"]
        waitForStartEnabled(start, timeout: timeout)
        start.tap()
        XCTAssertTrue(app.buttons["cricket_20"].waitForExistence(timeout: timeout))
    }
}
