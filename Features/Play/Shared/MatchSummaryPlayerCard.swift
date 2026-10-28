import SwiftUI

struct MatchSummaryPlayerCard: View {
    enum StatLayout {
        case horizontal
        case fitsWidth
    }

    private enum StatsAxis {
        case horizontal
        case vertical
    }

    let row: MatchSummaryViewModel.PlayerRow
    let layout: StatLayout
    var compactStats = false

    var body: some View {
        HStack(spacing: 0) {
            Rectangle()
                .fill(row.isWinner ? Brand.amber : Color.clear)
                .frame(width: 6)
            VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                HStack(spacing: 6) {
                    if row.isWinner {
                        Image(systemName: "crown.fill").font(.caption).foregroundStyle(Brand.amber)
                    }
                    Text(row.name)
                        .font(.headline)
                        .foregroundStyle(row.isWinner ? Brand.amber : Brand.textPrimary)
                        .lineLimit(1)
                }
                switch layout {
                case .horizontal:
                    stats(axis: .horizontal)
                case .fitsWidth:
                    ViewThatFits(in: .horizontal) {
                        stats(axis: .horizontal)
                        stats(axis: .vertical)
                    }
                }
            }
            .padding(compactStats ? DS.Spacing.s2 : DS.Spacing.s3)
            Spacer(minLength: 0)
        }
        .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
    }

    @ViewBuilder
    private func stats(axis: StatsAxis) -> some View {
        let spacing = compactStats ? DS.Spacing.s2 : DS.Spacing.s3
        switch axis {
        case .horizontal:
            HStack(spacing: spacing) {
                ForEach(row.stats, id: \.label) { stat in
                    StatChip(value: stat.value, label: stat.label, compact: compactStats)
                }
            }
        case .vertical:
            VStack(alignment: .leading, spacing: spacing) {
                ForEach(row.stats, id: \.label) { stat in
                    StatChip(value: stat.value, label: stat.label, compact: compactStats)
                }
            }
        }
    }

    private var accessibilitySummary: String {
        let stats = row.stats.map { "\($0.label) \($0.value)" }.joined(separator: ", ")
        let prefix = row.isWinner ? L10n.string("play.summary.player.winnerPrefix") : ""
        return L10n.format("play.summary.player.accessibilityFormat", prefix, row.name, stats)
    }
}

struct MatchSummaryAchievementsSection: View {
    let presentations: [AchievementUnlockPresentation]

    var body: some View {
        if !presentations.isEmpty {
            VStack(alignment: .leading, spacing: DS.Spacing.s3) {
                Text(L10n.string("achievements.summary.title"))
                    .font(.headline)
                    .foregroundStyle(Brand.textPrimary)
                ForEach(presentations) { presentation in
                    AchievementUnlockRow(presentation: presentation)
                }
            }
            .padding(DS.Spacing.s3)
            .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.md))
            .accessibilityIdentifier("matchSummaryAchievements")
        }
    }
}
