import SwiftUI

struct SetupRosterActionButtons: View {
    @ObservedObject var setupViewModel: MatchSetupViewModel
    @Binding var startTask: Task<Void, Never>?
    let onShowCustomBot: () -> Void
    let onShowAddPlayer: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var showsBotMenu: Bool {
        guard setupViewModel.botPlaySupport.allowsBots else { return false }
        if setupViewModel.setupCategory == .party, !ProductSurface.showsPartyModes { return false }
        return true
    }

    private var allowsAdvancedBotMenuItems: Bool {
        setupViewModel.botPlaySupport.allowsTrainingAndCustomBots
    }

    private var showsTrainingBotsInSetup: Bool {
        ProductSurface.showsTrainingBots && allowsAdvancedBotMenuItems
    }

    private var showsCustomBotsInSetup: Bool {
        ProductSurface.showsCustomBots && allowsAdvancedBotMenuItems
    }

    var body: some View {
        rosterActionButtonStack {
            if showsBotMenu {
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
                                .accessibilityIdentifier("training_bot_add_setup")
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
                            .accessibilityIdentifier("setup_addCustomBot")
                        }
                        ForEach(BotDifficulty.allCases, id: \.self) { difficulty in
                            botMenuButton(difficulty.displayName, difficulty: difficulty, color: PlayerVisualViews.botDifficultyColor(difficulty))
                        }
                    }
                } label: {
                    rosterActionButtonLabel(systemImage: "cpu", title: L10n.addBotTitle)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityLabel(L10n.addBotTitle)
                .accessibilityIdentifier("setup_addBot")
                .rosterActionButtonChrome(
                    background: Brand.cardElevated,
                    border: Brand.textSecondary.opacity(0.35)
                )
            }
            Button(action: onShowAddPlayer) {
                rosterActionButtonLabel(systemImage: "person.badge.plus", title: L10n.setupAddPlayers)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .buttonStyle(.plain)
            .accessibilityLabel(L10n.setupAddPlayers)
            .accessibilityIdentifier("setup_addPlayer")
            .rosterActionButtonChrome(background: Brand.green)
        }
    }

    @ViewBuilder
    private func rosterActionButtonStack<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(spacing: DS.Spacing.s2, content: content)
    }

    private func rosterActionButtonLabel(systemImage: String, title: LocalizedStringKey) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 6) {
            Image(systemName: systemImage)
                .font(.subheadline.weight(.semibold))
                .alignmentGuide(.firstTextBaseline) { dimensions in
                    dimensions[.bottom] * 0.82
                }
                .accessibilityHidden(true)
            rosterActionButtonTitle(title)
        }
        .foregroundStyle(Brand.textPrimary)
        .padding(.horizontal, DS.Spacing.s3)
        .padding(.vertical, DS.Spacing.s3)
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .frame(minHeight: 44)
    }

    @ViewBuilder
    private func rosterActionButtonTitle(_ title: LocalizedStringKey) -> some View {
        if dynamicTypeSize.isAccessibilitySize {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        } else {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .multilineTextAlignment(.leading)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func botMenuButton(_ title: String, difficulty: BotDifficulty, color: Color) -> some View {
        Button {
            startTask?.cancel()
            startTask = Task { await setupViewModel.addBot(difficulty) }
        } label: {
            Label {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                    if let formatted = difficulty.referenceMetrics.formattedBadge() {
                        Text(formatted)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .monospacedDigit()
                    }
                }
            } icon: {
                Circle().fill(color).frame(width: 10, height: 10)
            }
        }
        .accessibilityIdentifier("add_bot_\(difficulty.rawValue)")
    }
}

private extension View {
    @ViewBuilder
    func rosterActionButtonChrome(
        background: Color,
        border: Color? = nil
    ) -> some View {
        let base = self
            .frame(maxWidth: .infinity, alignment: .topLeading)
            .background(background, in: RoundedRectangle(cornerRadius: DS.Radius.sm))

        if let border {
            base.overlay(RoundedRectangle(cornerRadius: DS.Radius.sm).stroke(border, lineWidth: 1))
        } else {
            base
        }
    }
}
