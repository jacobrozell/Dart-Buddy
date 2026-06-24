import SwiftUI

struct SetupHomeStartFooter: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ObservedObject var setupViewModel: MatchSetupViewModel
    @Binding var startTask: Task<Void, Never>?
    let onStart: () -> Void
    var onShowCustomBot: (() -> Void)?
    var onShowAddPlayer: (() -> Void)?

    private var showsAddButtons: Bool {
        onShowCustomBot != nil || onShowAddPlayer != nil
    }

    private var showsBotMenu: Bool {
        guard let _ = onShowCustomBot else { return false }
        guard setupViewModel.setupCategory != .party || ProductSurface.showsPartyModes else { return false }
        return setupViewModel.setupCategory != .party
            || setupViewModel.partyGame == .baseball
            || setupViewModel.partyGame == .shanghai
            || setupViewModel.partyGame == .killer
    }

    private var allowsAdvancedBotMenuItems: Bool {
        setupViewModel.setupCategory != .party
            || setupViewModel.partyGame == .baseball
            || setupViewModel.partyGame == .shanghai
    }

    private var showsTrainingBotsInSetup: Bool {
        ProductSurface.showsTrainingBots && allowsAdvancedBotMenuItems
    }

    private var showsCustomBotsInSetup: Bool {
        ProductSurface.showsCustomBots && allowsAdvancedBotMenuItems
    }

    var body: some View {
        VStack(spacing: DS.Spacing.s2) {
            if showsAddButtons {
                footerActionButtons
            }

            PrimaryActionButton(
                title: setupViewModel.isSubmitting ? L10n.setupStartingButton : L10n.setupStartButton,
                accent: .green,
                isEnabled: setupViewModel.canStart && !setupViewModel.isSubmitting,
                action: onStart
            )
            .accessibilityLabel(L10n.string(setupViewModel.isSubmitting ? "play.setup.startingButton" : "play.setup.startButton"))
            .modifier(OptionalAccessibilityHint(hint: setupStartAccessibilityHint))
            .accessibilityIdentifier("startMatchButton")

            if !GameplayLayout.usesAccessibilitySetupHomeLayout(dynamicTypeSize: dynamicTypeSize) {
                ForEach(setupViewModel.displayValidationErrors, id: \.self) { key in
                    ErrorBanner(messageKey: key, style: .hint)
                        .accessibilityHidden(true)
                }
            }
        }
    }

    @ViewBuilder
    private var footerActionButtons: some View {
        HStack(spacing: DS.Spacing.s3) {
            if showsBotMenu, let onShowCustomBot {
                Menu {
                    if showsTrainingBotsInSetup, !setupViewModel.availableTrainingBots.isEmpty {
                        Section(L10n.trainingBotSetupSection) {
                            ForEach(setupViewModel.availableTrainingBots) { bot in
                                Button {
                                    setupViewModel.addTrainingBot(bot.id)
                                } label: {
                                    Label {
                                        Text(bot.name)
                                    } icon: {
                                        Circle()
                                            .fill(PlayerVisualViews.trainingBotColor(linkedToken: bot.colorToken))
                                            .frame(width: 10, height: 10)
                                    }
                                }
                                .accessibilityIdentifier("training_bot_add_footer")
                            }
                        }
                    }
                    if showsCustomBotsInSetup, !setupViewModel.availableCustomBots.isEmpty {
                        Section(L10n.customBotSetupSection) {
                            ForEach(setupViewModel.availableCustomBots) { bot in
                                Button {
                                    setupViewModel.addExistingCustomBot(bot.id)
                                } label: {
                                    Text(bot.name)
                                }
                            }
                        }
                    }
                    Section(L10n.addBotTitle) {
                        if showsCustomBotsInSetup {
                            Button(action: onShowCustomBot) {
                                Label(L10n.customBotAddMenu, systemImage: "slider.horizontal.3")
                            }
                            .accessibilityIdentifier("setup_footer_addCustomBot")
                        }
                        ForEach(BotDifficulty.allCases, id: \.self) { difficulty in
                            botMenuButton(difficulty.displayName, difficulty: difficulty, color: PlayerVisualViews.botDifficultyColor(difficulty))
                        }
                    }
                } label: {
                    footerActionButtonLabel(systemImage: "cpu", title: L10n.addBotTitle)
                }
                .accessibilityLabel(L10n.addBotTitle)
                .accessibilityIdentifier("setup_footer_addBot")
                .footerActionButtonChrome(background: Brand.cardElevated, border: Brand.textSecondary.opacity(0.35))
            }

            if let onShowAddPlayer {
                Button(action: onShowAddPlayer) {
                    footerActionButtonLabel(systemImage: "person.badge.plus", title: L10n.setupAddPlayers)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.setupAddPlayers)
                .accessibilityIdentifier("setup_footer_addPlayer")
                .footerActionButtonChrome(background: Brand.green)
            }
        }
    }

    private func botMenuButton(_ title: String, difficulty: BotDifficulty, color: Color) -> some View {
        Button {
            startTask?.cancel()
            startTask = Task { await setupViewModel.addBot(difficulty) }
        } label: {
            Label {
                Text(title)
            } icon: {
                Circle().fill(color).frame(width: 10, height: 10)
            }
        }
        .accessibilityIdentifier("add_bot_footer_\(difficulty.rawValue)")
    }

    private func footerActionButtonLabel(systemImage: String, title: LocalizedStringKey) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .accessibilityHidden(true)
            Text(title)
                .font(.subheadline.weight(.semibold))
        }
        .foregroundStyle(Brand.textPrimary)
        .padding(.horizontal, DS.Spacing.s4)
        .padding(.vertical, DS.Spacing.s3)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 44)
    }

    private var setupStartAccessibilityHint: String? {
        guard !setupViewModel.canStart else { return nil }
        if setupViewModel.isRosterEmpty {
            return L10n.string("play.setup.playersEmptyHint")
        }
        if setupViewModel.setupCategory == .party,
           setupViewModel.validationErrors.contains("setup.validation.partyComingSoon") {
            return L10n.string("setup.validation.partyComingSoon")
        }
        return SetupValidationMessages.startButtonAccessibilityHint(
            canStart: setupViewModel.canStart,
            validationErrors: setupViewModel.validationErrors
        )
    }
}

private extension View {
    @ViewBuilder
    func footerActionButtonChrome(background: Color, border: Color? = nil) -> some View {
        let base = self
            .frame(maxWidth: .infinity)
            .background(background, in: RoundedRectangle(cornerRadius: DS.Radius.sm))

        if let border {
            base.overlay(RoundedRectangle(cornerRadius: DS.Radius.sm).stroke(border, lineWidth: 1))
        } else {
            base
        }
    }
}
