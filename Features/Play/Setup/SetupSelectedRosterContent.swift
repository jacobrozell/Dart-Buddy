import SwiftUI

struct SetupSelectedRosterContent: View {
    @ObservedObject var setupViewModel: MatchSetupViewModel

    var body: some View {
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
                SetupRosterTurnOrderList(setupViewModel: setupViewModel)
            }
        }
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
}

struct SetupRosterTurnOrderList: View {
    @ObservedObject var setupViewModel: MatchSetupViewModel

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @ScaledMetric(relativeTo: .body) private var turnOrderRowVerticalInset: CGFloat = 8

    var body: some View {
        VStack(spacing: DS.Spacing.s2) {
            ForEach(Array(setupViewModel.selectedPlayers.enumerated()), id: \.element.id) { index, player in
                selectedRosterRow(player: player, position: index + 1)
                    .padding(.horizontal, DS.Spacing.s3)
                    .padding(.vertical, turnOrderRowVerticalInset)
                    .background(Brand.cardElevated, in: RoundedRectangle(cornerRadius: DS.Radius.md))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        // `children: .contain` keeps each staged row a distinct accessibility element.
        // Without it, a lone row merges into this identified container and loses its own
        // `setup_selected_<name>` identifier (see docs/release/onboarding-staging-tests.md).
        .accessibilityElement(children: .contain)
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
}
