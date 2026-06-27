import SwiftUI

struct TicTacToeGridView: View {
    let cells: [TicTacToeCellTarget]
    let grid: [TicTacToeSide?]
    let winningLine: [Int]?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: DS.Spacing.s1), count: 3)

    var body: some View {
        LazyVGrid(columns: columns, spacing: DS.Spacing.s1) {
            ForEach(0 ..< cells.count, id: \.self) { index in
                cellView(index: index)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("tic_tac_toe_grid")
    }

    @ViewBuilder
    private func cellView(index: Int) -> some View {
        let target = cells[index]
        let claim = grid[index]
        let isWinning = winningLine?.contains(index) == true
        VStack(spacing: 4) {
            Text(cellTargetLabel(for: target))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Brand.textSecondary)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(claim.map(\.marker) ?? " ")
                .font(.title2.weight(.bold))
                .foregroundStyle(markerColor(for: claim, isWinning: isWinning))
                .accessibilityHidden(claim == nil)
        }
        .frame(maxWidth: .infinity, minHeight: 72)
        .padding(.vertical, DS.Spacing.s1)
        .background(
            RoundedRectangle(cornerRadius: DS.Radius.sm)
                .fill(backgroundColor(for: claim, isWinning: isWinning))
        )
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.sm)
                .strokeBorder(
                    isWinning ? Brand.green.opacity(0.8) : Brand.textSecondary.opacity(0.2),
                    lineWidth: isWinning ? 2 : 1
                )
        )
        .accessibilityLabel(cellAccessibilityLabel(index: index, target: target, claim: claim))
    }

    private func cellTargetLabel(for target: TicTacToeCellTarget) -> String {
        if let segment = target.localizationFormatArgument {
            return L10n.format(target.localizationKey, segment)
        }
        return L10n.string(target.localizationKey)
    }

    private func markerColor(for claim: TicTacToeSide?, isWinning: Bool) -> Color {
        guard let claim else { return Brand.textSecondary.opacity(0.25) }
        if isWinning { return Brand.green }
        return claim == .x ? Brand.amber : Brand.green
    }

    private func backgroundColor(for claim: TicTacToeSide?, isWinning: Bool) -> Color {
        if isWinning { return Brand.green.opacity(0.18) }
        if claim != nil { return Brand.card.opacity(0.9) }
        return Brand.card.opacity(0.45)
    }

    private func cellAccessibilityLabel(
        index: Int,
        target: TicTacToeCellTarget,
        claim: TicTacToeSide?
    ) -> String {
        let targetLabel = cellTargetLabel(for: target)
        if let claim {
            return L10n.format(
                "play.ticTacToe.cellClaimedAccessibilityFormat",
                index + 1,
                targetLabel,
                L10n.string(claim.localizationKey)
            )
        }
        return L10n.format("play.ticTacToe.cellOpenAccessibilityFormat", index + 1, targetLabel)
    }
}
