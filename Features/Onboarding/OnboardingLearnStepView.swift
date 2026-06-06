import SwiftUI

struct OnboardingLearnStepView: View {
    let onContinue: () -> Void

    var body: some View {
        OnboardingStepChrome(showsSkip: false, onSkip: {}) {
            VStack(alignment: .leading, spacing: DS.Spacing.s4) {
                Text(L10n.onboardingLearnTitle)
                    .font(.title.bold())
                    .foregroundStyle(Brand.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text(L10n.onboardingLearnIntro)
                    .font(.body)
                    .foregroundStyle(Brand.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)

                GameRulesGuideContent(initialMode: .x01)
            }
        } footer: {
            OnboardingPrimaryButton(
                title: L10n.onboardingContinue,
                accessibilityIdentifier: "onboarding_learn_continue"
            ) {
                onContinue()
            }
        }
    }
}
