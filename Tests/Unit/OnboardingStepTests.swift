import Testing
@testable import DartBuddy

struct OnboardingStepTests {
    @Test func progressIndexMapsSteps() {
        #expect(OnboardingStep.welcome.progressIndex == 1)
        #expect(OnboardingStep.rosterSetup.progressIndex == 2)
        #expect(OnboardingStep.preferences.progressIndex == 3)
        #expect(OnboardingStep.learnToPlay.progressIndex == 3)
        #expect(OnboardingStep.appTour.progressIndex == 4)
        #expect(OnboardingStep.support.progressIndex == 5)
        #expect(OnboardingStep.ready.progressIndex == 6)
        #expect(OnboardingStep.progressTotal == 6)
    }

    @Test func backStepFromRosterSetupReturnsWelcome() {
        #expect(OnboardingStep.rosterSetup.backStep(showsRulesIntro: nil) == .welcome)
    }

    @Test func backStepFromAppTourUsesRulesBranch() {
        #expect(OnboardingStep.appTour.backStep(showsRulesIntro: false) == .preferences)
        #expect(OnboardingStep.appTour.backStep(showsRulesIntro: true) == .learnToPlay)
    }

    @Test func backStepFromReadyReturnsSupport() {
        #expect(OnboardingStep.ready.backStep(showsRulesIntro: true) == .support)
    }

    @Test func backStepFromPreferencesSkipsRosterWhenPrimaryExists() {
        #expect(OnboardingStep.preferences.backStep(showsRulesIntro: false, skipsRosterSetup: true) == .welcome)
        #expect(OnboardingStep.preferences.backStep(showsRulesIntro: false, skipsRosterSetup: false) == .rosterSetup)
    }
}

@Test(.tags(.unit, .regression))
func botDifficultyOnboardingSliderMapping() {
    #expect(BotDifficulty.fromOnboardingSliderIndex(0) == .veryEasy)
    #expect(BotDifficulty.fromOnboardingSliderIndex(2) == .medium)
    #expect(BotDifficulty.fromOnboardingSliderIndex(99) == .pro)
    #expect(BotDifficulty.veryEasy.showsOnboardingRulesIntro)
    #expect(BotDifficulty.easy.showsOnboardingRulesIntro)
    #expect(!BotDifficulty.medium.showsOnboardingRulesIntro)
}
