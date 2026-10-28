import SwiftUI

struct SetupAvailablePlayersContent: View {
    @ObservedObject var setupViewModel: MatchSetupViewModel

    var body: some View {
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
