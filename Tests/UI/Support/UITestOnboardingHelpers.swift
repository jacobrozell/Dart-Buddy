import XCTest

extension DartBuddyUITestCase {
    func launchOnboardingApp(
        experienceTierIndex: Int? = nil,
        extraArguments: [String] = []
    ) -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-ui_test_reset", "-disable_firebase_analytics", "-ui_test_onboarding"] + extraArguments
        applyDefaultLaunchEnvironment(to: app)
        if let experienceTierIndex {
            var environment = app.launchEnvironment
            environment["UI_TEST_ONBOARDING_TIER"] = String(experienceTierIndex)
            app.launchEnvironment = environment
        }
        app.launch()
        return app
    }

    func advancePastWelcome(in app: XCUIApplication, timeout: TimeInterval? = nil) {
        let wait = timeout ?? self.timeout
        let next = app.buttons["onboarding_next"]
        XCTAssertTrue(next.waitForExistence(timeout: wait))
        next.tap()

        let nameField = app.textFields["onboarding_player_name"]
        if !nameField.waitForExistence(timeout: wait) {
            app.swipeUp()
        }
        XCTAssertTrue(
            nameField.waitForExistence(timeout: wait),
            "Onboarding should present the roster setup step after welcome"
        )
    }

    /// Display names for onboarding slider tiers (index 0 … 4).
    private var onboardingTierDisplayNames: [String] {
        ["Very Easy", "Easy", "Medium", "Hard", "Pro"]
    }

    func assertOnboardingExperienceTier(
        _ tierIndex: Int,
        in app: XCUIApplication,
        timeout: TimeInterval? = nil
    ) {
        let wait = timeout ?? self.timeout
        let clamped = min(max(tierIndex, 0), onboardingTierDisplayNames.count - 1)
        let targetName = onboardingTierDisplayNames[clamped]

        let selected = app.descendants(matching: .any)["onboarding_experience_selected"]
        if !selected.waitForExistence(timeout: 2) {
            app.swipeUp()
        }
        XCTAssertTrue(
            selected.waitForExistence(timeout: wait),
            "Experience tier should expose the selected-level label"
        )
        XCTAssertTrue(
            selected.label.localizedCaseInsensitiveContains(targetName),
            "Experience tier should show \(targetName), got '\(selected.label)'"
        )
    }

    func fillOnboardingRoster(
        named name: String,
        in app: XCUIApplication,
        timeout: TimeInterval? = nil
    ) {
        let wait = timeout ?? self.timeout
        let nameField = app.textFields["onboarding_player_name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: wait))
        nameField.tap()
        nameField.clearAndEnterText(name)

        if app.keyboards.count > 0 {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15)).tap()
        }

        let continueButton = app.buttons["onboarding_roster_continue"]
        if !continueButton.waitForExistence(timeout: 2) {
            app.swipeUp()
        }
        XCTAssertTrue(continueButton.waitForExistence(timeout: wait))
        XCTAssertTrue(continueButton.isEnabled)
        continueButton.tap()
    }

    func advanceThroughSharedFinale(in app: XCUIApplication, timeout: TimeInterval? = nil) {
        let wait = timeout ?? self.timeout
        let tourContinue = app.buttons["onboarding_tour_continue"]
        XCTAssertTrue(
            tourContinue.waitForExistence(timeout: wait),
            "Both paths should reach the app tour step"
        )
        tourContinue.tap()

        let supportContinue = app.buttons["onboarding_support_continue"]
        XCTAssertTrue(
            supportContinue.waitForExistence(timeout: wait),
            "Both paths should reach the support step"
        )
        supportContinue.tap()

        finishOnboarding(in: app, timeout: wait)
    }

    func finishOnboarding(in app: XCUIApplication, timeout: TimeInterval? = nil) {
        let wait = timeout ?? self.timeout
        let getStarted = app.buttons["onboarding_get_started"]
        XCTAssertTrue(
            getStarted.waitForExistence(timeout: wait + 5),
            "Onboarding ready step should expose Get Started"
        )
        getStarted.tap()

        assertBrandAppTitleVisible(in: app, timeout: wait)
    }

    func skipOnboardingFromWelcomeAndFinish(in app: XCUIApplication, timeout: TimeInterval? = nil) {
        let wait = timeout ?? self.timeout
        let skip = app.buttons["onboarding_skip"]
        XCTAssertTrue(skip.waitForExistence(timeout: wait))
        skip.tap()
        finishOnboarding(in: app, timeout: wait)
    }

    func assertStagedBot(in app: XCUIApplication, nameContains needle: String, timeout: TimeInterval? = nil) {
        let wait = timeout ?? self.timeout
        let stagedBot = app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier BEGINSWITH 'setup_selected_' AND label CONTAINS %@", needle)
        ).firstMatch
        XCTAssertTrue(
            stagedBot.waitForExistence(timeout: wait + 10),
            "Expected staged bot row containing '\(needle)'"
        )
    }
}
