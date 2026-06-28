import XCTest

final class OnboardingUITests: DartBuddyUITestCase {
    func testSkipFromWelcomeLandsOnPlayWithoutStagedRoster() {
        let app = launchOnboardingApp()

        skipOnboardingFromWelcomeAndFinish(in: app)

        XCTAssertTrue(
            app.buttons["setup_addPlayer"].waitForExistence(timeout: timeout),
            "Skipping onboarding should leave Play without a staged roster"
        )
        XCTAssertFalse(
            app.descendants(matching: .any).matching(
                NSPredicate(format: "identifier BEGINSWITH 'setup_selected_'")
            ).firstMatch.waitForExistence(timeout: 2),
            "Skipping onboarding should not stage players on Play setup"
        )
    }

    func testRosterSetupPreviewUpdatesWithExperienceSlider() {
        let app = launchOnboardingApp(experienceTierIndex: 4)

        advancePastWelcome(in: app)
        assertOnboardingExperienceTier(4, in: app)

        XCTAssertTrue(
            app.descendants(matching: .any)["onboarding_bot_preview"].waitForExistence(timeout: timeout),
            "Roster setup should show the live opponent preview card"
        )
    }

    func testVeryEasyPathShowsRulesContent() {
        let app = launchOnboardingApp(experienceTierIndex: 0)

        advancePastWelcome(in: app)
        assertOnboardingExperienceTier(0, in: app)
        fillOnboardingRoster(named: "Casey", in: app)

        XCTAssertTrue(
            app.buttons["rules_mode_x01"].waitForExistence(timeout: timeout),
            "Very Easy experience should show the rules mode picker"
        )
        XCTAssertTrue(
            app.staticTexts["The game"].waitForExistence(timeout: timeout),
            "Beginner experience should show X01 rule content"
        )

        app.buttons["onboarding_learn_continue"].tap()
        advanceThroughSharedFinale(in: app)
    }

    func testMediumExperiencePathShowsPreferences() {
        let app = launchOnboardingApp(experienceTierIndex: 2)

        advancePastWelcome(in: app)
        assertOnboardingExperienceTier(2, in: app)
        fillOnboardingRoster(named: "Casey", in: app)

        XCTAssertTrue(
            app.buttons["onboarding_preferences_continue"].waitForExistence(timeout: timeout + 5),
            "Medium experience should continue to preferences"
        )
        XCTAssertTrue(
            app.staticTexts["Appearance"].waitForExistence(timeout: timeout + 5),
            "Preferences step should include appearance controls"
        )

        app.buttons["onboarding_preferences_continue"].tap()
        advanceThroughSharedFinale(in: app)
    }

    func testFinishOnboardingStagesPlayerAndBotOnPlay() {
        let app = launchOnboardingApp(experienceTierIndex: 2)
        let playerName = "Casey"

        advancePastWelcome(in: app)
        fillOnboardingRoster(named: playerName, in: app)

        app.buttons["onboarding_preferences_continue"].tap()
        advanceThroughSharedFinale(in: app)

        waitForStagedPlayer(playerName, in: app)
        assertStagedBot(in: app, nameContains: "Medium Bot")
    }

    func testFinishOnboardingEasyPathStagesEasyBotOnPlay() {
        let app = launchOnboardingApp(experienceTierIndex: 0)
        let playerName = "Casey"

        advancePastWelcome(in: app)
        fillOnboardingRoster(named: playerName, in: app)
        app.buttons["onboarding_learn_continue"].tap()
        advanceThroughSharedFinale(in: app)

        waitForStagedPlayer(playerName, in: app)
        assertStagedBot(in: app, nameContains: "Very Easy Bot")
    }

    func testReadyStepShowsRosterSummary() {
        let app = launchOnboardingApp(experienceTierIndex: 2)

        advancePastWelcome(in: app)
        fillOnboardingRoster(named: "Jordan", in: app)
        app.buttons["onboarding_preferences_continue"].tap()
        app.buttons["onboarding_tour_continue"].tap()
        app.buttons["onboarding_support_continue"].tap()

        let rosterSummary = app.descendants(matching: .any)["onboarding_ready_roster_summary"]
        if !rosterSummary.waitForExistence(timeout: timeout) {
            app.swipeUp()
        }

        XCTAssertTrue(
            rosterSummary.waitForExistence(timeout: timeout),
            "Ready step should summarize the staged roster"
        )
        XCTAssertTrue(
            app.staticTexts.containing(NSPredicate(format: "label == %@", "Jordan")).firstMatch
                .waitForExistence(timeout: timeout),
            "Ready step should show the new human player"
        )
        XCTAssertTrue(
            app.staticTexts.containing(NSPredicate(format: "label CONTAINS %@", "DartBot")).firstMatch
                .waitForExistence(timeout: timeout),
            "Ready step should show the matched bot opponent"
        )

        finishOnboarding(in: app)
    }

    func testSettingsReplayOpensOnboardingFlow() {
        let app = launchApp(["-skip_onboarding"])

        assertBrandAppTitleVisible(in: app, timeout: timeout)

        ensureSettingsTab(app, timeout: timeout)
        scrollToSettingsControl("settings_viewOnboardingButton", in: app, timeout: timeout)
        app.buttons["settings_viewOnboardingButton"].tap()

        XCTAssertTrue(
            app.buttons["onboarding_next"].waitForExistence(timeout: timeout),
            "Settings replay should present the onboarding welcome step"
        )
    }
}
