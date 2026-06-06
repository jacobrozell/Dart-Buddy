import SwiftUI

struct OnboardingReadyStepView: View {
    let onGetStarted: () -> Void

    var body: some View {
        OnboardingStepChrome(showsSkip: false, onSkip: {}) {
            OnboardingHeroStepContent(
                symbolName: "checkmark.circle.fill",
                titleKey: "onboarding.ready.title",
                bodyKey: "onboarding.ready.body"
            )
        } footer: {
            OnboardingPrimaryButton(
                title: L10n.onboardingGetStarted,
                accessibilityIdentifier: "onboarding_get_started"
            ) {
                onGetStarted()
            }
        }
    }
}
