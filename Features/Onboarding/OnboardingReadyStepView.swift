import SwiftUI

struct OnboardingReadyStepView: View {
    let progressIndex: Int
    let rosterSummary: OnboardingRosterDraft?
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
                    bodyKey: rosterSummary == nil ? "onboarding.ready.body" : "onboarding.ready.bodyWithRoster"
                )

                if let rosterSummary {
                    VStack(alignment: .leading, spacing: DS.Spacing.s3) {
                        Text(L10n.onboardingReadyRosterTitle)
                            .font(.headline)
                            .foregroundStyle(Brand.textPrimary)

                        HStack(spacing: DS.Spacing.s3) {
                            PlayerRosterAvatar(
                                avatarStyle: rosterSummary.avatarStyle,
                                colorToken: rosterSummary.colorToken,
                                size: 36
                            )
                            Text(rosterSummary.name)
                                .font(.headline)
                                .foregroundStyle(Brand.textPrimary)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(rosterSummary.name)
                        .accessibilityIdentifier("onboarding_ready_human")

                        HStack(spacing: DS.Spacing.s3) {
                            Image(systemName: "cpu.fill")
                                .font(.title3)
                                .foregroundStyle(PlayerVisualViews.botDifficultyColor(rosterSummary.botDifficulty))
                                .frame(width: 36, height: 36)
                            Text(rosterSummary.botDifficulty.rosterName)
                                .font(.headline)
                                .foregroundStyle(Brand.textPrimary)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(rosterSummary.botDifficulty.rosterName)
                        .accessibilityIdentifier("onboarding_ready_bot")
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(DS.Spacing.s4)
                    .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
                    .accessibilityIdentifier("onboarding_ready_roster_summary")
                }

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
