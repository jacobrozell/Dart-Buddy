import SwiftUI

struct OnboardingAppTourStepView: View {
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
                Text(L10n.string("onboarding.tour.title"))
                    .font(.title.bold())
                    .foregroundStyle(Brand.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text(L10n.onboardingTourIntro)
                    .font(.body)
                    .foregroundStyle(Brand.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)

                if GameplayLayout.usesIPadMainShell() {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: DS.Spacing.s3),
                            GridItem(.flexible(), spacing: DS.Spacing.s3)
                        ],
                        spacing: DS.Spacing.s3
                    ) {
                        tourCard(
                            symbolName: "play.circle.fill",
                            titleKey: "onboarding.tour.play.title",
                            bodyKey: "onboarding.tour.play.body",
                            identifier: "onboarding_tour_play"
                        )
                        tourCard(
                            symbolName: "person.2.fill",
                            titleKey: "onboarding.tour.players.title",
                            bodyKey: "onboarding.tour.players.body",
                            identifier: "onboarding_tour_players"
                        )
                        tourCard(
                            symbolName: "chart.bar.fill",
                            titleKey: "onboarding.tour.activity.title",
                            bodyKey: "onboarding.tour.activity.body",
                            identifier: "onboarding_tour_activity"
                        )
                        tourCard(
                            symbolName: "gearshape.fill",
                            titleKey: "onboarding.tour.settings.title",
                            bodyKey: "onboarding.tour.settings.body",
                            identifier: "onboarding_tour_settings"
                        )
                    }
                } else {
                    VStack(spacing: DS.Spacing.s3) {
                        tourCard(
                            symbolName: "play.circle.fill",
                            titleKey: "onboarding.tour.play.title",
                            bodyKey: "onboarding.tour.play.body",
                            identifier: "onboarding_tour_play"
                        )
                        tourCard(
                            symbolName: "person.2.fill",
                            titleKey: "onboarding.tour.players.title",
                            bodyKey: "onboarding.tour.players.body",
                            identifier: "onboarding_tour_players"
                        )
                        tourCard(
                            symbolName: "chart.bar.fill",
                            titleKey: "onboarding.tour.activity.title",
                            bodyKey: "onboarding.tour.activity.body",
                            identifier: "onboarding_tour_activity"
                        )
                        tourCard(
                            symbolName: "gearshape.fill",
                            titleKey: "onboarding.tour.settings.title",
                            bodyKey: "onboarding.tour.settings.body",
                            identifier: "onboarding_tour_settings"
                        )
                    }
                }

                Text(L10n.onboardingTourRoadmap)
                    .font(.footnote)
                    .foregroundStyle(Brand.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .multilineTextAlignment(.center)
            }
        } footer: {
            OnboardingPrimaryButton(
                title: L10n.onboardingContinue,
                accessibilityIdentifier: "onboarding_tour_continue"
            ) {
                onContinue()
            }
        }
    }

    private func tourCard(
        symbolName: String,
        titleKey: String,
        bodyKey: String,
        identifier: String
    ) -> some View {
        HStack(alignment: .top, spacing: DS.Spacing.s3) {
            Image(systemName: symbolName)
                .font(.title2.weight(.medium))
                .foregroundStyle(Brand.green)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 44, height: 44)

            VStack(alignment: .leading, spacing: DS.Spacing.s1) {
                Text(LocalizedStringKey(titleKey))
                    .font(.headline)
                    .foregroundStyle(Brand.textPrimary)
                Text(LocalizedStringKey(bodyKey))
                    .font(.subheadline)
                    .foregroundStyle(Brand.textBodyOnCard)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(DS.Spacing.s4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier(identifier)
    }
}
