import SwiftUI

struct BotIdentityCard: View {
    let name: String
    let avatarStyle: PlayerAvatarStyle
    let colorToken: PlayerColorToken
    let difficulty: BotDifficulty?
    var customMetrics: CustomBotMetrics? = nil
    var notes: String = ""

    private var accent: Color {
        PlayerVisualViews.accentColor(token: colorToken)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            HStack(spacing: DS.Spacing.s4) {
                PlayerRosterAvatar(avatarStyle: avatarStyle, colorToken: colorToken, size: 72)
                VStack(alignment: .leading, spacing: DS.Spacing.s1) {
                    Text(name)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(Brand.textPrimary)
                    HStack(spacing: DS.Spacing.s2) {
                        Circle()
                            .fill(accent)
                            .frame(width: 10, height: 10)
                        Text(colorToken.displayName)
                            .font(.subheadline)
                            .foregroundStyle(Brand.textSecondary)
                    }
                    if !notes.isEmpty {
                        Text(notes)
                            .font(.caption)
                            .foregroundStyle(Brand.textSecondary)
                            .lineLimit(2)
                    }
                }
                Spacer(minLength: 0)
            }

            if let difficulty {
                VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                    Text(L10n.botDifficultyLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Brand.textSecondary)
                        .textCase(.uppercase)
                    BotDifficultyBadge(difficulty: difficulty, showsReferenceMetrics: true)
                }
            } else if let customMetrics {
                VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                    Text(L10n.customBotKindLabel)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Brand.textSecondary)
                        .textCase(.uppercase)
                    CustomBotBadge(metrics: customMetrics)
                }
            } else {
                Text(L10n.trainingBotSectionTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Brand.green)
            }
        }
        .padding(DS.Spacing.s4)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.md)
                .strokeBorder(accent.opacity(0.35), lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            L10n.format(
                "players.bots.identity.accessibilityFormat",
                name,
                colorToken.displayName,
                difficulty?.displayName ?? L10n.string("trainingBot.section.title")
            )
        )
    }
}

struct PlayerIdentityCard: View {
    let player: EditablePlayer

    private var accent: Color {
        PlayerVisualViews.accentColor(token: player.colorToken)
    }

    var body: some View {
        HStack(spacing: DS.Spacing.s4) {
            PlayerAvatarChip(player: player, size: 72)
            VStack(alignment: .leading, spacing: DS.Spacing.s1) {
                Text(player.name)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(Brand.textPrimary)
                HStack(spacing: DS.Spacing.s2) {
                    Circle()
                        .fill(accent)
                        .frame(width: 10, height: 10)
                    Text(player.colorToken.displayName)
                        .font(.subheadline)
                        .foregroundStyle(Brand.textSecondary)
                }
                if !player.notes.isEmpty {
                    Text(player.notes)
                        .font(.caption)
                        .foregroundStyle(Brand.textSecondary)
                        .lineLimit(2)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(DS.Spacing.s4)
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.md)
                .strokeBorder(accent.opacity(0.35), lineWidth: 1)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.format("players.detail.identity.accessibilityFormat", player.name, ""))
    }
}
