import SwiftUI

struct OnboardingWelcomeStepView: View {
    let onNext: () -> Void
    let onSkip: () -> Void

    var body: some View {
        OnboardingStepChrome(showsSkip: true, onSkip: onSkip) {
            OnboardingHeroStepContent(
                symbolName: "target",
                titleKey: OnboardingCopy.hero.welcomeTitleKey,
                bodyKey: OnboardingCopy.hero.welcomeBodyKey
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
