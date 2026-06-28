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

struct BotDifficultyStatsSection: View {
    let profile: BotDifficultyDisplayProfile
    var showsHeader: Bool = true
    @State private var showsEngineDetails = false

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            if showsHeader {
                Text(L10n.botStatsSection)
                    .font(.headline)
                    .foregroundStyle(Brand.textPrimary)
            }

            if let summary = profile.summary, summary.hasValues {
                summaryCard(summary)
            }

            DisclosureGroup(isExpanded: $showsEngineDetails) {
                engineDetailsContent
            } label: {
                Text(L10n.botStatsEngineDetails)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Brand.textPrimary)
            }
            .accessibilityIdentifier("botStats_engineDetails")

            Text(L10n.botStatsFooter)
                .font(.caption)
                .foregroundStyle(Brand.textSecondary)
        }
    }

    @ViewBuilder
    private var engineDetailsContent: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s3) {
            modeCard(title: L10n.x01Title) {
                BotStatRow(
                    labelKey: "players.bots.stats.scoringVisitRange",
                    value: BotDifficultyDisplayProfile.range(profile.x01.scoringVisitMin, profile.x01.scoringVisitMax)
                )
                statDivider
                hitChanceRows(profile.x01.hitChances)
                statDivider
                BotStatRow(
                    labelKey: "players.bots.stats.checkoutAttemptRate",
                    value: BotDifficultyDisplayProfile.percent(profile.x01.checkoutAttemptChance)
                )
                BotStatRow(
                    labelKey: "players.bots.stats.offBoardMiss",
                    value: BotDifficultyDisplayProfile.percent(profile.x01.offBoardMissChance)
                )
                BotStatRow(
                    labelKey: "players.bots.stats.bustRisk",
                    value: BotDifficultyDisplayProfile.percent(profile.x01.riskyBustChance)
                )
                BotStatRow(
                    labelKey: "players.bots.stats.triplePreference",
                    value: BotDifficultyDisplayProfile.percent(profile.x01.triplePreference)
                )
                BotStatRow(
                    labelKey: "players.bots.stats.checkInBoost",
                    value: BotDifficultyDisplayProfile.percent(profile.x01.checkInHitBoost, signed: true)
                )
                if profile.x01.innerBullAimChance > 0 {
                    BotStatRow(
                        labelKey: "players.bots.stats.innerBullAim",
                        value: BotDifficultyDisplayProfile.percent(profile.x01.innerBullAimChance)
                    )
                }
                if profile.x01.masterInTripleOpenerChance > 0 {
                    BotStatRow(
                        labelKey: "players.bots.stats.masterInTriple",
                        value: BotDifficultyDisplayProfile.percent(profile.x01.masterInTripleOpenerChance)
                    )
                }
            }

            modeCard(title: L10n.cricketTitle) {
                hitChanceRows(profile.cricket.hitChances)
                statDivider
                BotStatRow(
                    labelKey: "players.bots.stats.offBoardMiss",
                    value: BotDifficultyDisplayProfile.percent(profile.cricket.offBoardMissChance)
                )
                BotStatRow(
                    labelKey: "players.bots.stats.wrongBed",
                    value: BotDifficultyDisplayProfile.percent(profile.cricket.wrongBedChance)
                )
            }
        }
        .padding(.top, DS.Spacing.s2)
    }

    @ViewBuilder
    private func summaryCard(_ summary: BotModeSummaryMetrics) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            Text(L10n.botStatsSummarySection)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Brand.textSecondary)
                .textCase(.uppercase)

            VStack(spacing: 0) {
                if let x01Average = summary.x01Average {
                    BotStatRow(
                        labelKey: "customBot.x01Average.label",
                        value: String(format: "%.0f", x01Average)
                    )
                }
                if summary.x01Average != nil, summary.cricketMPR != nil {
                    statDivider
                }
                if let cricketMPR = summary.cricketMPR {
                    BotStatRow(
                        labelKey: "customBot.cricketMPR.label",
                        value: String(format: "%.2f", cricketMPR)
                    )
                }
            }
            .padding(.horizontal, DS.Spacing.s3)
            .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))

            Text(L10n.botStatsSummaryHint)
                .font(.caption)
                .foregroundStyle(Brand.textSecondary)
        }
        .accessibilityIdentifier("botStats_summary")
    }

    @ViewBuilder
    private func modeCard(title: LocalizedStringKey, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Brand.textSecondary)
                .textCase(.uppercase)

            VStack(spacing: 0) {
                content()
            }
            .padding(.horizontal, DS.Spacing.s3)
            .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
        }
    }

    @ViewBuilder
    private func hitChanceRows(_ chances: BotDifficultyDisplayProfile.HitChances) -> some View {
        BotStatRow(
            labelKey: "players.bots.stats.hitChanceSingle",
            value: BotDifficultyDisplayProfile.percent(chances.single)
        )
        BotStatRow(
            labelKey: "players.bots.stats.hitChanceDouble",
            value: BotDifficultyDisplayProfile.percent(chances.double)
        )
        BotStatRow(
            labelKey: "players.bots.stats.hitChanceTriple",
            value: BotDifficultyDisplayProfile.percent(chances.triple)
        )
    }

    private var statDivider: some View {
        Divider().overlay(Brand.cardElevated)
    }
}

private struct BotStatRow: View {
    let labelKey: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(LocalizedStringKey(labelKey))
                .font(.subheadline)
                .foregroundStyle(Brand.textSecondary)
            Spacer(minLength: DS.Spacing.s3)
            Text(value)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Brand.textPrimary)
                .monospacedDigit()
        }
        .padding(.vertical, DS.Spacing.s2)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(L10n.format("stats.statTile.accessibilityFormat", L10n.string(labelKey), value))
    }
}

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
                        .foregroundStyle(isSelected ? Brand.textPrimary : Brand.textSecondary)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .padding(.vertical, DS.Spacing.s3)
                        .background(Brand.cardElevated, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
                        .overlay {
                            if isSelected {
                                RoundedRectangle(cornerRadius: DS.Radius.sm)
                                    .strokeBorder(Brand.green, lineWidth: 2)
                            }
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(style.displayName)
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
                                    .foregroundStyle(Brand.textOnAccent)
                            }
                        }
                        .frame(minWidth: 44, minHeight: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(token.displayName)
                .accessibilityAddTraits(isSelected ? .isSelected : [])
            }
        }
    }
}
