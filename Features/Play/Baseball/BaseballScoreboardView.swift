import SwiftUI

struct BaseballScoreboardView: View {
    enum VisitRunsKind: Equatable {
        case inning
        case playoffRound
    }

    struct Row: Identifiable {
        let id: UUID
        let name: String
        let cumulativeRuns: Int
        let visitRuns: Int?
        let visitRunsKind: VisitRunsKind?
        let isActive: Bool
        let isLeading: Bool
        let colorToken: PlayerColorToken
    }

    let rows: [Row]
    let showsVisitRunsColumn: Bool

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
                    if showsVisitRunsColumn, let visitRuns = row.visitRuns, let kind = row.visitRunsKind {
                        Text(visitRunsDisplayText(visitRuns, kind: kind))
                            .font(.caption)
                            .foregroundStyle(Brand.textSecondary)
                    }
                    Text("\(row.cumulativeRuns)")
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

    private func visitRunsDisplayText(_ runs: Int, kind: VisitRunsKind) -> String {
        switch kind {
        case .inning:
            L10n.format("play.baseball.thisInningFormat", runs)
        case .playoffRound:
            L10n.format("play.baseball.playoffRoundFormat", runs)
        }
    }

    private func rowAccessibilityLabel(_ row: Row) -> String {
        var parts = [row.name, L10n.format("play.baseball.totalRunsAccessibilityFormat", row.cumulativeRuns)]
        if let visitRuns = row.visitRuns, let kind = row.visitRunsKind {
            switch kind {
            case .inning:
                parts.append(L10n.format("play.baseball.thisInningAccessibilityFormat", visitRuns))
            case .playoffRound:
                parts.append(L10n.format("play.baseball.playoffRoundAccessibilityFormat", visitRuns))
            }
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
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .ignore)
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
}
