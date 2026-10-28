import SwiftUI

struct PlayersListRow: View {
    let player: EditablePlayer
    let summary: PlayerListSummary?
    let onSelect: () -> Void
    let onArchiveToggle: () -> Void
    let onDelete: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: DS.Spacing.s3) {
                PlayerAvatarChip(player: player, size: 40)
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: DS.Spacing.s2) {
                        Text(player.name)
                            .font(.headline)
                            .foregroundStyle(Brand.textPrimary)
                        if player.isPrimaryPlayer {
                            Text(L10n.playersPrimaryBadge)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(Brand.inkOnBright)
                                .padding(.horizontal, DS.Spacing.s2)
                                .padding(.vertical, 2)
                                .background(Brand.green, in: Capsule())
                                .accessibilityHidden(true)
                        }
                    }
                    if let difficulty = player.botDifficulty {
                        BotDifficultyBadge(difficulty: difficulty, prominence: .compact)
                    } else if player.isCustomBot {
                        CustomBotBadge(
                            metrics: CustomBotMetrics(
                                x01Average: player.customX01Average,
                                cricketMPR: player.customCricketMPR
                            ),
                            prominence: .compact
                        )
                    } else if let summary, summary.games > 0 {
                        Text(L10n.format("players.list.record", summary.games, summary.wins))
                            .font(.caption)
                            .foregroundStyle(Brand.textSecondary)
                    }
                }
                if player.isArchived {
                    Text(L10n.archived).font(.caption).foregroundStyle(Brand.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Brand.textSecondary)
                    .accessibilityHidden(true)
            }
            .padding(DS.Spacing.s3)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
            .contentShape(RoundedRectangle(cornerRadius: DS.Radius.md))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityIdentifier(player.botDifficulty == nil ? "player_row_\(player.name)" : "player_row_bot_\(player.id.uuidString)")
        .contextMenu {
            Button(action: onArchiveToggle) {
                Label(
                    player.isArchived ? L10n.string("players.unarchive") : L10n.string("players.archive"),
                    systemImage: player.isArchived ? "tray.and.arrow.up" : "archivebox"
                )
            }
            Button(role: .destructive, action: onDelete) {
                Label(L10n.delete, systemImage: "trash")
            }
        }
    }

    private var accessibilitySummary: String {
        var suffix = ""
        if let difficulty = player.botDifficulty {
            suffix += L10n.format("players.row.botSuffix", difficulty.displayName)
        } else if player.isCustomBot {
            suffix += L10n.format(
                "customBot.row.accessibilitySuffix",
                player.customX01Average,
                player.customCricketMPR
            )
        } else if let summary, summary.games > 0 {
            suffix += ", \(L10n.format("players.list.record.accessibility", summary.games, summary.wins))"
        }
        if player.isPrimaryPlayer {
            suffix += L10n.string("players.row.primarySuffix")
        }
        if player.isArchived {
            suffix += L10n.string("players.row.archivedSuffix")
        }
        return L10n.format("players.row.accessibilityFormat", player.name, suffix)
    }
}
