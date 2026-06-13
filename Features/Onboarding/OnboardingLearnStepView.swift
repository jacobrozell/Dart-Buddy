import SwiftUI

struct OnboardingLearnStepView: View {
    let progressIndex: Int
    let showsBack: Bool
    let onBack: () -> Void
    let onContinue: () -> Void

    var body: some View {
        OnboardingStepChrome(
            showsSkip: false,
            onSkip: {},
            progressIndex: progressIndex,
            showsBack: showsBack,
            onBack: onBack
        ) {
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

                GameRulesGuideContent(initialMode: .x01, showsModePicker: true)
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
