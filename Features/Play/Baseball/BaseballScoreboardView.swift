import SwiftUI

struct BaseballScoreboardView: View {
    struct Row: Identifiable {
        let id: UUID
        let name: String
        let cumulativeRuns: Int
        let runsThisInning: Int?
        let isActive: Bool
        let isLeading: Bool
        let colorToken: PlayerColorToken
    }

    let rows: [Row]
    let showsThisInningColumn: Bool

    var body: some View {
        VStack(spacing: DS.Spacing.s2) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                HStack(spacing: DS.Spacing.s3) {
                    Circle()
                        .fill(PlayerVisualViews.color(for: row.colorToken))
                        .frame(width: 10, height: 10)
                    Text(row.name)
                        .font(.subheadline.weight(row.isActive || row.isLeading ? .bold : .regular))
                        .foregroundStyle(Brand.textPrimary)
                        .lineLimit(1)
                    if row.isLeading {
                        Text(L10n.string("play.baseball.leading"))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Brand.green)
                    }
                    Spacer()
                    if showsThisInningColumn, let inningRuns = row.runsThisInning {
                        Text(L10n.format("play.baseball.thisInningFormat", inningRuns))
                            .font(.caption)
                            .foregroundStyle(Brand.textSecondary)
                    }
                    Text(L10n.format("play.baseball.totalRunsFormat", row.cumulativeRuns))
                        .font(.title3.weight(.bold))
                        .foregroundStyle(row.isActive ? Brand.green : Brand.textPrimary)
                }
                .padding(.horizontal, DS.Spacing.s3)
                .padding(.vertical, DS.Spacing.s2)
                .background(row.isActive ? Brand.cardElevated : Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(rowAccessibilityLabel(row))
                .accessibilityIdentifier("baseball_scoreboard_row_\(index)")
            }
        }
    }

    private func rowAccessibilityLabel(_ row: Row) -> String {
        var parts = [row.name, L10n.format("play.baseball.totalRunsFormat", row.cumulativeRuns)]
        if let inningRuns = row.runsThisInning {
            parts.append(L10n.format("play.baseball.thisInningFormat", inningRuns))
        }
        if row.isLeading {
            parts.append(L10n.string("play.baseball.leading"))
        }
        return parts.joined(separator: ", ")
    }
}

struct InningProgressStrip: View {
    let inningCount: Int
    let currentInning: Int
    let isExtraInning: Bool

    var body: some View {
        let totalDots = max(inningCount, currentInning)
        HStack(spacing: 6) {
            ForEach(1 ... totalDots, id: \.self) { inning in
                Circle()
                    .fill(fillColor(for: inning))
                    .frame(width: 10, height: 10)
                    .overlay {
                        if inning == currentInning {
                            Circle().stroke(Brand.green, lineWidth: 2)
                        }
                    }
                    .accessibilityLabel(inningAccessibilityLabel(inning))
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            L10n.format(
                "play.baseball.inningStrip.accessibilityFormat",
                currentInning,
                totalDots,
                currentInning
            )
        )
    }

    private func fillColor(for inning: Int) -> Color {
        if inning < currentInning { return Brand.green }
        if inning == currentInning { return Brand.amber }
        return Brand.textSecondary.opacity(0.35)
    }

    private func inningAccessibilityLabel(_ inning: Int) -> String {
        if inning < currentInning {
            return L10n.format("play.baseball.inningStrip.completedFormat", inning)
        }
        if inning == currentInning {
            return L10n.format("play.baseball.inningStrip.currentFormat", inning)
        }
        return L10n.format("play.baseball.inningStrip.upcomingFormat", inning)
    }
}
