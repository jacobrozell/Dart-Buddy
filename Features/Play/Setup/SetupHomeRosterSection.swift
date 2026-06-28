import SwiftUI

struct SetupHomeRosterSection: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @ScaledMetric(relativeTo: .body) private var rosterRowHeight: CGFloat = 52
    @ScaledMetric(relativeTo: .body) private var turnOrderRowVerticalInset: CGFloat = 8
    @ObservedObject var setupViewModel: MatchSetupViewModel
    @Binding var startTask: Task<Void, Never>?
    let onShowCustomBot: () -> Void
    let onShowAddPlayer: () -> Void

    private var usesWideLayout: Bool {
        GameplayLayout.usesWideSetupHomeLayout(
            horizontalSizeClass: horizontalSizeClass,
            dynamicTypeSize: dynamicTypeSize
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            rosterSectionHeader
            rosterSectionContent
        }
    }

    @ViewBuilder
    private var rosterSectionHeader: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(L10n.addToMatchSection)
                .font(.headline)
                .foregroundStyle(Brand.textPrimary)
            Spacer(minLength: DS.Spacing.s2)
        }
    }

    @ViewBuilder
    private var rosterSectionContent: some View {
        selectedRosterContent
        if !usesWideLayout {
            rosterControls
        }
        availablePlayersContent
    }

    var rosterControls: some View {
        rosterActionButtons
            .padding(.top, DS.Spacing.s2)
    }

    private var randomOrderToggle: some View {
        Button { setupViewModel.randomOrder.toggle() } label: {
            HStack(spacing: 8) {
                Image(systemName: setupViewModel.randomOrder ? "checkmark.square.fill" : "square")
                    .foregroundStyle(setupViewModel.randomOrder ? Brand.green : Brand.textSecondary)
                    .accessibilityHidden(true)
                Text(L10n.setupRandomOrder).foregroundStyle(Brand.textPrimary)
            }
            .frame(minHeight: 44, alignment: .leading)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.setupRandomOrder)
        .accessibilityAddTraits(setupViewModel.randomOrder ? .isSelected : [])
        .accessibilityIdentifier("setup_randomOrderToggle")
    }

    private var showsBotMenu: Bool {
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

    @ViewBuilder
    private var rosterActionButtons: some View {
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

    @ViewBuilder
    private var selectedRosterContent: some View {
        if !setupViewModel.selectedPlayers.isEmpty {
            VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                HStack(alignment: .firstTextBaseline) {
                    Text(L10n.setupTurnOrder)
                        .font(.subheadline)
                        .foregroundStyle(Brand.textSecondary)
                    Spacer(minLength: DS.Spacing.s2)
                    randomOrderToggle
                }
                if setupViewModel.randomOrder {
                    BrandHelperText(message: L10n.setupTurnOrderRandomHint, icon: "shuffle")
                }
                accessibilityTurnOrderList
            }
        }
    }

    @ViewBuilder
    private var availablePlayersContent: some View {
        if setupViewModel.isRosterEmpty {
            BrandEmptyHint(message: L10n.setupPlayersEmptyHint, icon: "person.2")
        } else if !setupViewModel.availableHumans.isEmpty || !setupViewModel.availableBots.isEmpty {
            VStack(alignment: .leading, spacing: DS.Spacing.s3) {
                if !setupViewModel.availableBots.isEmpty {
                    Text(L10n.botsSectionTitle)
                        .font(.subheadline)
                        .foregroundStyle(Brand.textSecondary)
                    botRosterList
                }

                if !setupViewModel.availableHumans.isEmpty {
                    Text(L10n.playersSectionTitle)
                        .font(.subheadline)
                        .foregroundStyle(Brand.textSecondary)
                    humanRosterList
                }
            }
        }
    }

    private var accessibilityTurnOrderList: some View {
        VStack(spacing: DS.Spacing.s2) {
            ForEach(Array(setupViewModel.selectedPlayers.enumerated()), id: \.element.id) { index, player in
                selectedRosterRow(player: player, position: index + 1)
                    .padding(.horizontal, DS.Spacing.s3)
                    .padding(.vertical, turnOrderRowVerticalInset)
                    .background(Brand.cardElevated, in: RoundedRectangle(cornerRadius: DS.Radius.md))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityIdentifier("setup_turnOrderList")
    }

    private func selectedRosterRowAccessibilityLabel(player: PlayerSummary, position: Int) -> String {
        L10n.format("play.setup.turnOrder.rowAccessibilityFormat", position, player.name)
    }

    private func selectedRosterRow(player: PlayerSummary, position: Int) -> some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                accessibilitySelectedRosterRow(player: player, position: position)
            } else {
                compactSelectedRosterRow(player: player, position: position)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(selectedRosterRowAccessibilityLabel(player: player, position: position))
        .accessibilityIdentifier("setup_selected_\(player.name)")
        .accessibilityAction(named: Text(L10n.setupRemoveFromMatch)) {
            setupViewModel.removeFromSelection(player.id)
        }
    }

    private func compactSelectedRosterRow(player: PlayerSummary, position: Int) -> some View {
        HStack(spacing: DS.Spacing.s3) {
            HStack(spacing: DS.Spacing.s3) {
                Text(L10n.format("common.playerOrdinal", position))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Brand.textSecondary)
                    .frame(width: 28, alignment: .leading)
                    .accessibilityHidden(true)
                PlayerRosterAvatar(
                    avatarStyle: player.avatarStyle,
                    colorToken: player.colorToken,
                    size: 28
                )
                .accessibilityHidden(true)
                Text(player.name)
                    .font(.headline)
                    .foregroundStyle(Brand.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                    .layoutPriority(1)
                    .accessibilityHidden(true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            selectedRosterRowTrailingControls(player: player, stacksBadgeWithRemove: false)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
            selectedRosterRemoveSwipeAction(player: player)
        }
    }

    private func accessibilitySelectedRosterRow(player: PlayerSummary, position: Int) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            HStack(alignment: .top, spacing: DS.Spacing.s3) {
                Text(L10n.format("common.playerOrdinal", position))
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Brand.textSecondary)
                    .fixedSize()
                    .accessibilityHidden(true)
                PlayerRosterAvatar(
                    avatarStyle: player.avatarStyle,
                    colorToken: player.colorToken,
                    size: 28
                )
                .accessibilityHidden(true)
                Text(player.name)
                    .font(.headline)
                    .foregroundStyle(Brand.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityHidden(true)
            }
            selectedRosterRowTrailingControls(player: player, stacksBadgeWithRemove: true)
        }
    }

    @ViewBuilder
    private func selectedRosterRowTrailingControls(
        player: PlayerSummary,
        stacksBadgeWithRemove: Bool
    ) -> some View {
        HStack(alignment: .center, spacing: DS.Spacing.s2) {
            if let difficulty = player.botDifficulty {
                BotDifficultyBadge(difficulty: difficulty, prominence: .compact)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityHidden(true)
            } else if player.isCustomBot, let metrics = player.customBotMetrics {
                CustomBotBadge(metrics: metrics, prominence: .compact)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityHidden(true)
            }
            if stacksBadgeWithRemove {
                Spacer(minLength: 0)
            }
            if !voiceOverEnabled {
                selectedRosterRemoveButton(player: player)
            }
        }
        .frame(maxWidth: stacksBadgeWithRemove ? .infinity : nil, alignment: .trailing)
    }

    private func selectedRosterRemoveButton(player: PlayerSummary) -> some View {
        Button {
            setupViewModel.removeFromSelection(player.id)
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.title3)
                .foregroundStyle(Brand.textSecondary)
        }
        .buttonStyle(.plain)
        .frame(minWidth: 44, minHeight: 44)
        .contentShape(Rectangle())
        .accessibilityLabel(L10n.setupRemoveFromMatch)
        .accessibilityIdentifier("setup_remove_\(player.name)")
    }

    private func selectedRosterRemoveSwipeAction(player: PlayerSummary) -> some View {
        Button(role: .destructive) {
            setupViewModel.removeFromSelection(player.id)
        } label: {
            Text(L10n.setupRemoveFromMatch)
        }
        .accessibilityLabel(L10n.setupRemoveFromMatch)
        .accessibilityIdentifier("setup_remove_\(player.name)")
    }

    private var botRosterList: some View {
        VStack(spacing: DS.Spacing.s2) {
            ForEach(setupViewModel.availableBots) { bot in
                rosterRow(
                    player: bot,
                    accessibilityId: "select_bot_\(bot.botDifficultyRaw ?? "unknown")"
                )
            }
        }
    }

    private var humanRosterList: some View {
        VStack(spacing: DS.Spacing.s2) {
            ForEach(setupViewModel.availableHumans) { player in
                rosterRow(
                    player: player,
                    accessibilityId: "select_\(player.name)"
                )
            }
        }
    }

    private func rosterRow(player: PlayerSummary, accessibilityId: String) -> some View {
        Button { setupViewModel.togglePlayer(player.id) } label: {
            HStack(spacing: DS.Spacing.s3) {
                PlayerRosterAvatar(
                    avatarStyle: player.avatarStyle,
                    colorToken: player.colorToken,
                    size: 32
                )
                Text(player.name)
                    .font(.headline)
                    .foregroundStyle(Brand.textPrimary)
                Spacer()
                if let difficulty = player.botDifficulty {
                    BotDifficultyBadge(difficulty: difficulty, prominence: .compact)
                } else if player.isCustomBot, let metrics = player.customBotMetrics {
                    CustomBotBadge(metrics: metrics, prominence: .compact)
                }
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Brand.green)
                    .accessibilityHidden(true)
            }
            .frame(minHeight: 44)
            .padding(.horizontal, DS.Spacing.s3)
            .padding(.vertical, DS.Spacing.s3)
            .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
            .contentShape(RoundedRectangle(cornerRadius: DS.Radius.md))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(nameAccessibilityLabel(for: player))
        .accessibilityIdentifier(accessibilityId)
    }

    private func nameAccessibilityLabel(for player: PlayerSummary) -> String {
        if let difficulty = player.botDifficulty {
            return L10n.format("players.bots.roster.accessibilityFormat", player.name, difficulty.displayName)
        }
        return player.name
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
