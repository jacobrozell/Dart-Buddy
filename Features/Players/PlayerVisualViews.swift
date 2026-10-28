import SwiftUI

enum PlayerVisualViews {
    static func accentColor(token: PlayerColorToken) -> Color {
        color(for: token)
    }

    static func color(for token: PlayerColorToken) -> Color {
        switch token {
        case .green: Brand.green
        case .amber: Brand.amber
        case .red: Brand.red
        case .blue: Color(red: 0.35, green: 0.55, blue: 0.95)
        case .purple: Brand.proBot
        case .teal: Color(red: 0.25, green: 0.78, blue: 0.78)
        case .orange: Brand.orange
        case .pink: Color(red: 0.95, green: 0.35, blue: 0.55)
        case .indigo: Color(red: 0.35, green: 0.35, blue: 0.85)
        case .cyan: Color(red: 0.20, green: 0.75, blue: 0.95)
        case .lime: Color(red: 0.55, green: 0.78, blue: 0.22)
        case .coral: Color(red: 0.98, green: 0.50, blue: 0.45)
        case .mint: Color(red: 0.30, green: 0.85, blue: 0.62)
        case .magenta: Color(red: 0.85, green: 0.22, blue: 0.72)
        case .slate: Color(red: 0.48, green: 0.55, blue: 0.66)
        case .gold: Color(red: 0.92, green: 0.72, blue: 0.18)
        case .brown: Color(red: 0.64, green: 0.45, blue: 0.31)
        case .maroon: Color(red: 0.70, green: 0.22, blue: 0.32)
        }
    }

    static func trainingBotColor(linkedToken: PlayerColorToken) -> Color {
        accentColor(token: linkedToken).opacity(0.72)
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

struct BotDifficultyBadge: View {
    let difficulty: BotDifficulty
    var prominence: Prominence = .standard
    var showsReferenceMetrics: Bool = false

    enum Prominence {
        case standard
        case compact
    }

    private var difficultyColor: Color {
        PlayerVisualViews.botDifficultyColor(difficulty)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: prominence == .compact ? 4 : 6) {
                Image(systemName: "cpu.fill")
                    .font(prominence == .compact ? .caption2.weight(.semibold) : .caption.weight(.semibold))
                Text(difficulty.displayName)
                    .font(prominence == .compact ? .caption.weight(.semibold) : .subheadline.weight(.semibold))
            }
            if showsReferenceMetrics, let formatted = difficulty.referenceMetrics.formattedBadge() {
                Text(formatted)
                    .font(prominence == .compact ? .caption2 : .caption)
                    .monospacedDigit()
            }
        }
        .foregroundStyle(difficultyColor)
        .padding(.horizontal, prominence == .compact ? DS.Spacing.s2 : DS.Spacing.s3)
        .padding(.vertical, prominence == .compact ? 4 : 6)
        .background(difficultyColor.opacity(0.15), in: Capsule())
        .overlay(Capsule().strokeBorder(difficultyColor.opacity(0.35), lineWidth: 1))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityText)
    }

    private var accessibilityText: String {
        if showsReferenceMetrics,
           let metrics = difficulty.referenceMetrics.formattedBadge() {
            return L10n.format("players.bots.difficulty.withMetrics.accessibilityFormat", difficulty.displayName, metrics)
        }
        return L10n.format("players.bots.difficulty.accessibilityFormat", difficulty.displayName)
    }
}

struct PlayerRosterAvatar: View {
    let avatarStyle: PlayerAvatarStyle
    let colorToken: PlayerColorToken
    var size: CGFloat = 32

    private var accent: Color {
        PlayerVisualViews.accentColor(token: colorToken)
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(accent.opacity(0.22))
            Image(systemName: avatarStyle.symbolName)
                .font(.system(size: size * 0.38, weight: .semibold))
                .foregroundStyle(accent)
                .rotationEffect(avatarStyle == .dart ? .degrees(135) : .zero)
        }
        .frame(width: size, height: size)
        .overlay(Circle().strokeBorder(accent.opacity(0.55), lineWidth: 1.5))
        .accessibilityHidden(true)
    }
}

struct PlayerAvatarChip: View {
    let player: EditablePlayer
    var size: CGFloat = 44

    private var accent: Color {
        PlayerVisualViews.accentColor(token: player.colorToken)
    }

    var body: some View {
        ZStack {
            Circle()
                .fill(accent.opacity(0.22))
            Image(systemName: player.avatarStyle.symbolName)
                .font(.system(size: size * 0.38, weight: .semibold))
                .foregroundStyle(accent)
                .rotationEffect(player.avatarStyle == .dart ? .degrees(135) : .zero)
        }
        .frame(width: size, height: size)
        .overlay(Circle().strokeBorder(accent.opacity(0.55), lineWidth: 1.5))
        .accessibilityLabel(player.name)
    }
}
