import SwiftUI

struct OnboardingReadyStepView: View {
    let progressIndex: Int
    let showsBack: Bool
    let onBack: () -> Void
    let onGetStarted: () -> Void

    var body: some View {
        OnboardingStepChrome(
            showsSkip: false,
            onSkip: {},
            progressIndex: progressIndex,
            showsBack: showsBack,
            onBack: onBack
        ) {
            VStack(spacing: DS.Spacing.s4) {
                OnboardingHeroStepContent(
                    symbolName: "checkmark.circle.fill",
                    titleKey: "onboarding.ready.title",
                    bodyKey: "onboarding.ready.body"
                )

                Text(L10n.onboardingReadyReplayHint)
                    .font(.footnote)
                    .foregroundStyle(Brand.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        } footer: {
            OnboardingPrimaryButton(
                title: L10n.onboardingStartMatch,
                accessibilityIdentifier: "onboarding_get_started"
            ) {
                onGetStarted()
            }
        }
    }
}
