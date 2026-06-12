import XCTest

extension DartBuddyUITestCase {
    func addPlayerFromSetup(
        named name: String,
        in app: XCUIApplication,
        timeout: TimeInterval? = nil
    ) {
        let wait = timeout ?? self.timeout
        let addPlayer = app.buttons["setup_addPlayer"]
        XCTAssertTrue(addPlayer.waitForExistence(timeout: wait), "Setup should expose Add Players")
        addPlayer.tap()

        let nameField = app.textFields["playerEdit_name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: wait), "Add player sheet should expose the name field")
        nameField.tap()
        nameField.clearAndEnterText(name)

        let save = app.buttons["playerEdit_save"]
        XCTAssertTrue(save.waitForExistence(timeout: wait))
        XCTAssertTrue(save.isEnabled, "Save should enable once a name is entered")
        save.tap()

        XCTAssertTrue(
            app.descendants(matching: .any)["setup_selected_\(name)"].waitForExistence(timeout: wait + 10),
            "Created player should auto-select in turn order"
        )
    }

    func removePlayerFromTurnOrder(named name: String, in app: XCUIApplication) {
        let removeButton = app.buttons["setup_remove_\(name)"]
        XCTAssertTrue(
            removeButton.waitForExistence(timeout: timeout),
            "Expected remove control for \(name) in turn order"
        )
        removeButton.tap()
    }

    func openBotRow(named name: String, in app: XCUIApplication, timeout: TimeInterval? = nil) {
        let wait = timeout ?? self.timeout
        let botRow = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", name)).firstMatch
        if botRow.waitForExistence(timeout: wait) {
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

        XCTFail("Expected bot row containing '\(name)' on the Players list within \(wait)s")
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

    func tapCricketPointsOn(in app: XCUIApplication) {
        expandSetupOptions(in: app, timeout: timeout)
        tapMenuChip("setup_cricketPointsChip", in: app, timeout: timeout)
        selectMenuOption(identifier: "setup_cricketPointsOption_on", title: "On", in: app, timeout: timeout)
    }

    func tapCricketPointsOff(in app: XCUIApplication) {
        expandSetupOptions(in: app, timeout: timeout)
        tapMenuChip("setup_cricketPointsChip", in: app, timeout: timeout)
        selectMenuOption(identifier: "setup_cricketPointsOption_off", title: "Off", in: app, timeout: timeout)
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

    func startTwoPlayerCricketMatch(
        from app: XCUIApplication,
        playerA: String = "Alice",
        playerB: String = "Bob",
        timeout: TimeInterval? = nil
    ) {
        let wait = timeout ?? self.timeout
        selectCricketMode(in: app, timeout: wait)
        selectPlayerFromRoster(playerA, in: app)
        selectPlayerFromRoster(playerB, in: app)
        let start = app.buttons["startMatchButton"]
        waitForStartEnabled(start, timeout: wait)
        start.tap()
        XCTAssertTrue(app.buttons["cricket_20"].waitForExistence(timeout: wait + 15))
    }
}
