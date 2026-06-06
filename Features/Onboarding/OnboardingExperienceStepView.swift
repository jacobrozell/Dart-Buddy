import SwiftUI

struct OnboardingExperienceStepView: View {
    let onExperienced: () -> Void
    let onBeginner: () -> Void

    var body: some View {
        OnboardingStepChrome(showsSkip: false, onSkip: {}) {
            VStack(spacing: DS.Spacing.s4) {
                OnboardingHeroStepContent(
                    symbolName: "questionmark.circle",
                    titleKey: "onboarding.experience.title",
                    bodyKey: "onboarding.experience.body"
                )

                VStack(spacing: DS.Spacing.s3) {
                    OnboardingChoiceButton(
                        title: L10n.onboardingExperienceYes,
                        systemImage: "checkmark.circle.fill",
                        accessibilityIdentifier: "onboarding_experience_yes",
                        accessibilityLabel: "onboarding.experience.yes.accessibility",
                        action: onExperienced
                    )

                    OnboardingChoiceButton(
                        title: L10n.onboardingExperienceNo,
                        systemImage: "book.fill",
                        accessibilityIdentifier: "onboarding_experience_no",
                        accessibilityLabel: "onboarding.experience.no.accessibility",
                        action: onBeginner
                    )
                }
            }
        } footer: {
            EmptyView()
        }
    }
}
