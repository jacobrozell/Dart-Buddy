import SwiftUI

struct OnboardingRosterSetupStepView: View {
    let progressIndex: Int
    let showsBack: Bool
    let onBack: () -> Void
    let onContinue: (OnboardingRosterDraft) -> Void

    @State private var name = ""
    @State private var avatarStyle: PlayerAvatarStyle = .dart
    @State private var colorToken: PlayerColorToken = .green
    @State private var tierIndex: Double = Double(BotDifficulty.easy.onboardingSliderIndex)
    @FocusState private var isNameFocused: Bool

    private var selectedDifficulty: BotDifficulty {
        BotDifficulty.fromOnboardingSliderIndex(Int(tierIndex.rounded()))
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

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
                    symbolName: "person.2.fill",
                    titleKey: "onboarding.roster.title",
                    bodyKey: "onboarding.roster.body"
                )

                VStack(alignment: .leading, spacing: DS.Spacing.s3) {
                    Text(L10n.onboardingRosterYouSection)
                        .font(.headline)
                        .foregroundStyle(Brand.textPrimary)

                    TextField("onboarding.roster.name", text: $name)
                        .textInputAutocapitalization(.words)
                        .textFieldStyle(.roundedBorder)
                        .focused($isNameFocused)
                        .submitLabel(.done)
                        .onSubmit { isNameFocused = false }
                        .accessibilityIdentifier("onboarding_player_name")
                }
                .padding(DS.Spacing.s4)
                .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))

                VStack(alignment: .leading, spacing: DS.Spacing.s3) {
                    Text(L10n.playersEditAvatar)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Brand.textSecondary)
                    AvatarStylePicker(selection: $avatarStyle)

                    Text(L10n.playersEditColor)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Brand.textSecondary)
                    PlayerColorTokenPicker(selection: $colorToken)
                }
                .padding(DS.Spacing.s4)
                .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))

                VStack(alignment: .leading, spacing: DS.Spacing.s3) {
                    Text(L10n.onboardingRosterExperienceSection)
                        .font(.headline)
                        .foregroundStyle(Brand.textPrimary)

                    Text(L10n.onboardingRosterExperienceHint)
                        .font(.footnote)
                        .foregroundStyle(Brand.textSecondary)

                    Slider(
                        value: $tierIndex,
                        in: 0 ... Double(BotDifficulty.onboardingOrder.count - 1),
                        step: 1
                    ) {
                        Text(L10n.onboardingRosterExperienceSection)
                    } minimumValueLabel: {
                        Text(L10n.onboardingRosterExperienceMin)
                            .font(.caption2)
                            .foregroundStyle(Brand.textSecondary)
                    } maximumValueLabel: {
                        Text(L10n.onboardingRosterExperienceMax)
                            .font(.caption2)
                            .foregroundStyle(Brand.textSecondary)
                    }
                    .accessibilityIdentifier("onboarding_experience_slider")

                    Text(L10n.format("onboarding.roster.experience.selectedFormat", selectedDifficulty.displayName))
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Brand.textPrimary)
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(
                            L10n.format("onboarding.roster.experience.selectedFormat", selectedDifficulty.displayName)
                        )
                        .accessibilityIdentifier("onboarding_experience_selected")
                }
                .padding(DS.Spacing.s4)
                .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))

                VStack(alignment: .leading, spacing: DS.Spacing.s3) {
                    Text(L10n.onboardingRosterOpponentSection)
                        .font(.headline)
                        .foregroundStyle(Brand.textPrimary)

                    Text(L10n.format("onboarding.roster.opponent.summaryFormat", selectedDifficulty.rosterName))
                        .font(.subheadline)
                        .foregroundStyle(Brand.textSecondary)
                        .accessibilityIdentifier("onboarding_bot_summary")

                    BotDifficultyBadge(difficulty: selectedDifficulty, showsReferenceMetrics: true)
                        .accessibilityIdentifier("onboarding_bot_tier_\(selectedDifficulty.rawValue)")

                    BotDifficultyStatsSection(profile: selectedDifficulty.displayProfile, showsHeader: false)
                }
                .padding(DS.Spacing.s4)
                .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
                .accessibilityIdentifier("onboarding_bot_preview")
            }
        } footer: {
            OnboardingPrimaryButton(
                title: L10n.onboardingContinue,
                accessibilityIdentifier: "onboarding_roster_continue",
                isEnabled: !trimmedName.isEmpty
            ) {
                onContinue(
                    OnboardingRosterDraft(
                        name: trimmedName,
                        avatarStyle: avatarStyle,
                        colorToken: colorToken,
                        botDifficulty: selectedDifficulty
                    )
                )
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button(L10n.gameRulesSheetDone) {
                    isNameFocused = false
                }
            }
        }
        .onAppear {
            if ProcessInfo.processInfo.arguments.contains(OnboardingStore.uiTestOnboardingLaunchArgument),
               let raw = ProcessInfo.processInfo.environment["UI_TEST_ONBOARDING_TIER"],
               let index = Int(raw) {
                let maxIndex = BotDifficulty.onboardingOrder.count - 1
                tierIndex = Double(min(max(index, 0), maxIndex))
            }
        }
    }
}
