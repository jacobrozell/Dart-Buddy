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

    func scrollToDeleteButton(_ app: XCUIApplication) {
        let delete = app.buttons["historyDetailDeleteButton"]
        for _ in 0 ..< 6 where delete.exists == false || delete.isHittable == false {
            app.swipeUp()
        }
        XCTAssertTrue(delete.waitForExistence(timeout: timeout), "Delete button should be reachable after scrolling")
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

    func startThreePlayerX01Match(from app: XCUIApplication) {
        ensurePlayTab(app, timeout: timeout)
        configureFastX01MatchForUITest(app, timeout: timeout)
        selectAliceBobAndCarol(from: app)
        let start = app.buttons["startMatchButton"]
        waitForStartEnabled(start, timeout: timeout)
        start.tap()
        waitForX01MatchBoard(in: app, timeout: timeout + 15)
    }

    func startThreePlayerCricketMatch(from app: XCUIApplication) {
        selectCricketMode(in: app, timeout: timeout)
        selectAliceBobAndCarol(from: app)
        let start = app.buttons["startMatchButton"]
        waitForStartEnabled(start, timeout: timeout)
        start.tap()
        XCTAssertTrue(app.buttons["cricket_20"].waitForExistence(timeout: timeout + 15))
    }

    func tapCricketPointsOff(in app: XCUIApplication) {
        expandSetupOptions(in: app, timeout: timeout)
        tapMenuChip("setup_cricketPointsChip", in: app, timeout: timeout)
        for candidate in [
            app.menuItems.element(boundBy: 1),
            app.menuItems["Off"],
            app.buttons["Off"],
            app.descendants(matching: .any)["setup_cricketPointsOption_off"]
        ] {
            if candidate.waitForExistence(timeout: 2) {
                candidate.tap()
                return
            }
        }
        XCTFail("Expected cricket points Off menu option")
    }

    func tapCricketCutThroatMode(in app: XCUIApplication) {
        expandSetupOptions(in: app, timeout: timeout)
        tapMenuChip("setup_cricketModeChip", in: app, timeout: timeout)
        for candidate in [
            app.menuItems["Cut Throat"],
            app.menuItems.element(boundBy: 1),
            app.buttons["Cut Throat"],
            app.descendants(matching: .any)["setup_cricketModeOption_cutThroat"]
        ] {
            if candidate.waitForExistence(timeout: 2) {
                candidate.tap()
                return
            }
        }
        XCTFail("Expected cricket Cut Throat menu option")
    }

    func startTwoPlayerCricketMatch(from app: XCUIApplication, playerA: String = "Alice", playerB: String = "Bob") {
        selectCricketMode(in: app, timeout: timeout)
        selectPlayerFromRoster(playerA, in: app)
        selectPlayerFromRoster(playerB, in: app)
        let start = app.buttons["startMatchButton"]
        waitForStartEnabled(start, timeout: timeout)
        start.tap()
        XCTAssertTrue(app.buttons["cricket_20"].waitForExistence(timeout: timeout + 15))
    }
}
