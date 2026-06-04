import SwiftUI

struct BaseballLineScoreView: View {
    let lineScore: BaseballLineScore

    private let playerColumnWidth: CGFloat = 96
    private let inningColumnWidth: CGFloat = 28
    private let totalColumnWidth: CGFloat = 36

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.s2) {
            Text(L10n.string("history.detail.lineScore"))
                .font(.title2.weight(.bold))
                .foregroundStyle(Brand.textPrimary)
                .accessibilityAddTraits(.isHeader)

            ScrollView(.horizontal, showsIndicators: false) {
                VStack(spacing: 0) {
                    headerRow
                    ForEach(Array(lineScore.rows.enumerated()), id: \.element.id) { index, row in
                        playerRow(row, index: index)
                    }
                }
            }
            .accessibilityIdentifier("history_baseball_line_score")

            if lineScore.playoffTurnCount > 0 {
                Text(L10n.string("history.lineScore.playoffNote"))
                    .font(.caption)
                    .foregroundStyle(Brand.textSecondary)
            }
        }
    }

    private var headerRow: some View {
        HStack(spacing: DS.Spacing.s1) {
            Text(L10n.string("history.lineScore.playerColumn"))
                .frame(width: playerColumnWidth, alignment: .leading)
            ForEach(lineScore.inningColumns, id: \.self) { inning in
                Text("\(inning)")
                    .frame(width: inningColumnWidth, alignment: .trailing)
            }
            Text(L10n.string("history.lineScore.totalColumn"))
                .frame(width: totalColumnWidth, alignment: .trailing)
        }
        .font(.caption.weight(.semibold))
        .foregroundStyle(Brand.textSecondary)
        .padding(.horizontal, DS.Spacing.s2)
        .padding(.vertical, DS.Spacing.s2)
    }

    private func playerRow(_ row: BaseballLineScore.PlayerRow, index: Int) -> some View {
        HStack(spacing: DS.Spacing.s1) {
            Text(row.name)
                .lineLimit(1)
                .frame(width: playerColumnWidth, alignment: .leading)
            ForEach(lineScore.inningColumns, id: \.self) { inning in
                let runs = row.runsByInning[inning] ?? 0
                Text(runs > 0 ? "\(runs)" : "–")
                    .frame(width: inningColumnWidth, alignment: .trailing)
            }
            Text("\(row.total)")
                .font(.subheadline.weight(.semibold))
                .frame(width: totalColumnWidth, alignment: .trailing)
        }
        .font(.subheadline)
        .foregroundStyle(Brand.textPrimary)
        .padding(.horizontal, DS.Spacing.s2)
        .padding(.vertical, DS.Spacing.s2)
        .background(index.isMultiple(of: 2) ? Color.clear : Brand.cardElevated.opacity(0.4))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(rowAccessibilityLabel(row))
    }

    private func rowAccessibilityLabel(_ row: BaseballLineScore.PlayerRow) -> String {
        let inningParts = lineScore.inningColumns.map { inning in
            let runs = row.runsByInning[inning] ?? 0
            return L10n.format("history.lineScore.inningRunsFormat", inning, runs)
        }.joined(separator: ", ")
        return L10n.format(
            "history.lineScore.rowAccessibilityFormat",
            row.name,
            inningParts,
            row.total
        )
    }
}
