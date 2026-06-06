import SwiftUI

struct ShanghaiScoreboardView: View {
    struct Row: Identifiable {
        let id: UUID
        let name: String
        let cumulativePoints: Int
        let roundPoints: Int?
        let isActive: Bool
        let isLeading: Bool
        let colorToken: PlayerColorToken
    }

    let rows: [Row]
    let showsRoundPointsColumn: Bool

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
                        Text(L10n.string("play.shanghai.leading"))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Brand.green)
                    }
                    Spacer()
                    if showsRoundPointsColumn, let roundPoints = row.roundPoints {
                        Text(L10n.format("play.shanghai.thisRoundFormat", roundPoints))
                            .font(.caption)
                            .foregroundStyle(Brand.textSecondary)
                    }
                    Text("\(row.cumulativePoints)")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(row.isActive ? Brand.green : Brand.textPrimary)
                }
                .padding(.horizontal, DS.Spacing.s3)
                .padding(.vertical, DS.Spacing.s2)
                .background(row.isActive ? Brand.cardElevated : Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(rowAccessibilityLabel(row))
                .accessibilityIdentifier("shanghai_scoreboard_row_\(index)")
            }
        }
    }

    private func rowAccessibilityLabel(_ row: Row) -> String {
        var parts = [row.name, L10n.format("play.shanghai.totalPointsAccessibilityFormat", row.cumulativePoints)]
        if let roundPoints = row.roundPoints {
            parts.append(L10n.format("play.shanghai.thisRoundAccessibilityFormat", roundPoints))
        }
        if row.isActive {
            parts.append(L10n.string("common.active"))
        }
        if row.isLeading {
            parts.append(L10n.string("play.shanghai.leading"))
        }
        return parts.joined(separator: ", ")
    }
}

struct RoundProgressStrip: View {
    let roundCount: Int
    let currentRound: Int
    let isExtraRound: Bool

    var body: some View {
        let totalDots = max(roundCount, currentRound)
        HStack(spacing: 6) {
            ForEach(1 ... totalDots, id: \.self) { round in
                Circle()
                    .fill(fillColor(for: round))
                    .frame(width: 10, height: 10)
                    .overlay {
                        if round == currentRound {
                            Circle().stroke(Brand.green, lineWidth: 2)
                        }
                    }
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(roundStripAccessibilityLabel(totalDots: totalDots))
    }

    private func roundStripAccessibilityLabel(totalDots: Int) -> String {
        var label = L10n.format(
            "play.shanghai.roundStrip.accessibilityFormat",
            currentRound,
            totalDots,
            currentRound
        )
        if isExtraRound {
            label += ", \(L10n.string("play.shanghai.extraRound"))"
        }
        return label
    }

    private func fillColor(for round: Int) -> Color {
        if round < currentRound { return Brand.green }
        if round == currentRound { return Brand.amber }
        return Brand.textSecondary.opacity(0.35)
    }
}
