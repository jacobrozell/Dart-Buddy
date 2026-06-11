import XCTest

final class OnboardingUITests: DartBuddyUITestCase {
    func testSkipFromWelcomeLandsOnPlay() {
        let app = launchOnboardingApp()

        let skip = app.buttons["onboarding_skip"]
        XCTAssertTrue(skip.waitForExistence(timeout: timeout))
        skip.tap()

        finishOnboarding(in: app)
        assertBrandAppTitleVisible(in: app, timeout: timeout)
    }

    func testBeginnerPathShowsRulesContent() {
        let app = launchOnboardingApp()

        advancePastWelcome(in: app)
        app.buttons["onboarding_experience_no"].tap()

        XCTAssertTrue(
            app.buttons["rules_mode_x01"].waitForExistence(timeout: timeout),
            "Beginner path should show the rules mode picker"
        )
        XCTAssertTrue(
            app.staticTexts["The game"].waitForExistence(timeout: timeout),
            "Beginner path should show X01 rule content"
        )

        app.buttons["onboarding_learn_continue"].tap()
        advanceThroughSharedFinale(in: app)
    }

    func testExperiencedPathShowsPreferences() {
        let app = launchOnboardingApp()

        advancePastWelcome(in: app)
        app.buttons["onboarding_experience_yes"].tap()

        XCTAssertTrue(
            app.buttons["onboarding_preferences_continue"].waitForExistence(timeout: timeout + 5),
            "Experienced path should show the continue action"
        )
        XCTAssertTrue(
            app.staticTexts["Appearance"].waitForExistence(timeout: timeout + 5),
            "Preferences step should include appearance controls"
        )

        app.buttons["onboarding_preferences_continue"].tap()
        advanceThroughSharedFinale(in: app)
    }

    func testSettingsReplayOpensOnboardingFlow() {
        let app = launchApp(["-skip_onboarding"])

        assertBrandAppTitleVisible(in: app, timeout: timeout)

        app.tabBars.buttons["Settings"].tap()
        scrollToSettingsControl("settings_viewOnboardingButton", in: app, timeout: timeout)
        app.buttons["settings_viewOnboardingButton"].tap()

        XCTAssertTrue(
            app.buttons["onboarding_next"].waitForExistence(timeout: timeout),
            "Settings replay should present the onboarding welcome step"
        )
    }

    private func launchOnboardingApp(extraArguments: [String] = []) -> XCUIApplication {
        launchApp(["-ui_test_onboarding"] + extraArguments)
    }

    private func advancePastWelcome(in app: XCUIApplication) {
        let next = app.buttons["onboarding_next"]
        XCTAssertTrue(next.waitForExistence(timeout: timeout))
        next.tap()

        let experienced = app.buttons["onboarding_experience_yes"]
        XCTAssertTrue(experienced.waitForExistence(timeout: timeout))
    }

    private func advanceThroughSharedFinale(in app: XCUIApplication) {
        let tourContinue = app.buttons["onboarding_tour_continue"]
        XCTAssertTrue(
            tourContinue.waitForExistence(timeout: timeout),
            "Both paths should reach the app tour step"
        )
        tourContinue.tap()

        let supportContinue = app.buttons["onboarding_support_continue"]
        XCTAssertTrue(
            supportContinue.waitForExistence(timeout: timeout),
            "Both paths should reach the support step"
        )
        supportContinue.tap()

        finishOnboarding(in: app)
    }

    private func finishOnboarding(in app: XCUIApplication) {
        let getStarted = app.buttons["onboarding_get_started"]
        XCTAssertTrue(getStarted.waitForExistence(timeout: timeout))
        getStarted.tap()

        assertBrandAppTitleVisible(in: app, timeout: timeout)
    }
}
