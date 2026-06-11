import SwiftUI

struct OnboardingSupportStepView: View {
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
                OnboardingHeroStepContent(
                    symbolName: "lifepreserver",
                    titleKey: "onboarding.support.title",
                    bodyKey: "onboarding.support.body"
                )

                VStack(spacing: DS.Spacing.s3) {
                    supportLink(
                        title: L10n.onboardingSupportHelp,
                        systemImage: "questionmark.circle",
                        destination: AppLinks.support,
                        accessibilityLabel: L10n.onboardingSupportHelpAccessibility,
                        identifier: "onboarding_support_help"
                    )
                    supportLink(
                        title: L10n.onboardingSupportFeedback,
                        systemImage: "envelope",
                        destination: AppSupport.feedbackMailtoURL,
                        accessibilityLabel: L10n.onboardingSupportFeedbackAccessibility,
                        identifier: "onboarding_support_feedback"
                    )
                    supportLink(
                        title: L10n.onboardingSupportPrivacy,
                        systemImage: "hand.raised",
                        destination: AppLinks.privacy,
                        accessibilityLabel: L10n.onboardingSupportPrivacyAccessibility,
                        identifier: "onboarding_support_privacy"
                    )
                }
            }
        } footer: {
            OnboardingPrimaryButton(
                title: L10n.onboardingContinue,
                accessibilityIdentifier: "onboarding_support_continue"
            ) {
                onContinue()
            }
        }
    }

    private func supportLink(
        title: LocalizedStringKey,
        systemImage: String,
        destination: URL,
        accessibilityLabel: LocalizedStringKey,
        identifier: String
    ) -> some View {
        Link(destination: destination) {
            HStack(spacing: DS.Spacing.s3) {
                Image(systemName: systemImage)
                    .font(.title3.weight(.medium))
                    .foregroundStyle(Brand.green)
                    .symbolRenderingMode(.hierarchical)
                    .frame(width: 44, height: 44)

                Text(title)
                    .font(.headline)
                    .foregroundStyle(Brand.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "arrow.up.right")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(Brand.textSecondary)
            }
            .padding(DS.Spacing.s4)
            .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
            .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        }
        .accessibilityLabel(accessibilityLabel)
        .accessibilityIdentifier(identifier)
    }
}
