import SwiftUI

enum PlayerVisualViews {
    static func accentColor(token: PlayerColorToken, isBot: Bool, botDifficulty: BotDifficulty?) -> Color {
        if isBot, let botDifficulty {
            return botDifficultyColor(botDifficulty)
        }
        return color(for: token)
    }

    static func color(for token: PlayerColorToken) -> Color {
        switch token {
        case .green: Brand.green
        case .amber: Brand.amber
        case .red: Brand.red
        case .blue: Color(red: 0.35, green: 0.55, blue: 0.95)
        case .purple: Brand.proBot
        case .teal: Color(red: 0.25, green: 0.78, blue: 0.78)
        }
    }

    static func botDifficultyColor(_ difficulty: BotDifficulty?) -> Color {
        switch difficulty {
        case .veryEasy: Color(red: 0.45, green: 0.82, blue: 0.55)
        case .easy: Brand.green
        case .medium: Brand.amber
        case .hard: Brand.red
        case .pro: Brand.proBot
        case .none: Brand.textSecondary
        }
    }
}

struct PlayerAvatarChip: View {
    let player: EditablePlayer
    var size: CGFloat = 44

    private var accent: Color {
        PlayerVisualViews.accentColor(
            token: player.colorToken,
            isBot: player.isBot,
            botDifficulty: player.botDifficulty
        )
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(accent.opacity(0.22))
            if player.isBot {
                Image(systemName: "cpu.fill")
                    .font(.system(size: size * 0.38, weight: .semibold))
                    .foregroundStyle(accent)
            } else {
                Image(systemName: player.avatarStyle.symbolName)
                    .font(.system(size: size * 0.38, weight: .semibold))
                    .foregroundStyle(accent)
                    .rotationEffect(player.avatarStyle == .dart ? .degrees(135) : .zero)
            }
        }
        .frame(width: size, height: size)
        .overlay(Circle().strokeBorder(accent.opacity(0.55), lineWidth: 1.5))
        .accessibilityLabel(player.name)
    }
}

struct PlayerIdentityCard: View {
    let player: EditablePlayer

    private var accent: Color {
        PlayerVisualViews.accentColor(
            token: player.colorToken,
            isBot: player.isBot,
            botDifficulty: player.botDifficulty
        )
    }

    var body: some View {
        HStack(spacing: DS.Spacing.s4) {
            PlayerAvatarChip(player: player, size: 72)
            VStack(alignment: .leading, spacing: DS.Spacing.s1) {
                Text(player.name)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(.white)
                if player.isBot, let difficulty = player.botDifficulty {
                    Text(difficulty.displayName)
                        .font(.subheadline)
                        .foregroundStyle(PlayerVisualViews.botDifficultyColor(difficulty))
                } else {
                    HStack(spacing: DS.Spacing.s2) {
                        Circle()
                            .fill(accent)
                            .frame(width: 10, height: 10)
                        Text(LocalizedStringKey("players.identity.color.\(player.colorToken.rawValue)"))
                            .font(.subheadline)
                            .foregroundStyle(Brand.textSecondary)
                    }
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
        .accessibilityLabel(playerIdentityAccessibilityLabel)
    }

    private var playerIdentityAccessibilityLabel: String {
        var suffix = ""
        if player.isBot, let difficulty = player.botDifficulty {
            suffix = L10n.format("players.row.botSuffix", difficulty.displayName)
        }
        return L10n.format("players.detail.identity.accessibilityFormat", player.name, suffix)
    }
}

struct AvatarStylePicker: View {
    @Binding var selection: PlayerAvatarStyle

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: DS.Spacing.s2) {
            ForEach(PlayerAvatarStyle.allCases) { style in
                let isSelected = selection == style
                Button {
                    selection = style
                } label: {
                    Image(systemName: style.symbolName)
                        .font(.title3)
                        .foregroundStyle(isSelected ? Brand.background : Brand.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .padding(.vertical, DS.Spacing.s3)
                        .background(isSelected ? Brand.green : Brand.cardElevated, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(LocalizedStringKey("players.avatar.\(style.rawValue)"))
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}

struct PlayerColorTokenPicker: View {
    @Binding var selection: PlayerColorToken

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: DS.Spacing.s2) {
            ForEach(PlayerColorToken.allCases) { token in
                let isSelected = selection == token
                Button {
                    selection = token
                } label: {
                    Circle()
                        .fill(PlayerVisualViews.color(for: token))
                        .frame(width: 32, height: 32)
                        .overlay {
                            if isSelected {
                                Image(systemName: "checkmark")
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(.white)
                            }
                        }
                        .frame(minWidth: 44, minHeight: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(LocalizedStringKey("players.identity.color.\(token.rawValue)"))
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}
