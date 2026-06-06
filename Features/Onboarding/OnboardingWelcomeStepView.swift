import SwiftUI

struct OnboardingWelcomeStepView: View {
    let onNext: () -> Void
    let onSkip: () -> Void

    var body: some View {
        OnboardingStepChrome(showsSkip: true, onSkip: onSkip) {
            OnboardingHeroStepContent(
                symbolName: "target",
                titleKey: "onboarding.welcome.title",
                bodyKey: "onboarding.welcome.body"
            )
        } footer: {
            OnboardingPrimaryButton(
                title: L10n.onboardingNext,
                accessibilityIdentifier: "onboarding_next"
            ) {
                onNext()
            }
        }
    }
}
