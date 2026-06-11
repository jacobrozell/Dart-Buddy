import Testing
@testable import DartBuddy

struct OnboardingStepTests {
    @Test func progressIndexMapsSteps() {
        #expect(OnboardingStep.welcome.progressIndex == 1)
        #expect(OnboardingStep.experienceQuestion.progressIndex == 2)
        #expect(OnboardingStep.preferences.progressIndex == 3)
        #expect(OnboardingStep.learnToPlay.progressIndex == 3)
        #expect(OnboardingStep.appTour.progressIndex == 4)
        #expect(OnboardingStep.support.progressIndex == 5)
        #expect(OnboardingStep.ready.progressIndex == 6)
        #expect(OnboardingStep.progressTotal == 6)
    }

    @Test func backStepFromExperienceReturnsWelcome() {
        #expect(OnboardingStep.experienceQuestion.backStep(experience: nil) == .welcome)
    }

    @Test func backStepFromAppTourUsesExperienceBranch() {
        #expect(OnboardingStep.appTour.backStep(experience: .experienced) == .preferences)
        #expect(OnboardingStep.appTour.backStep(experience: .beginner) == .learnToPlay)
    }

    @Test func backStepFromReadyReturnsSupport() {
        #expect(OnboardingStep.ready.backStep(experience: .experienced) == .support)
    }
}
