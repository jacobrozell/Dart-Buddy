import SwiftUI

struct TicTacToeScoreboardView: View {
    struct Row: Identifiable {
        let id: UUID
        let name: String
        let side: TicTacToeSide
        let claims: Int
        let isActive: Bool
        let isWinner: Bool
        let colorToken: PlayerColorToken
    }

    let rows: [Row]

    var body: some View {
        VStack(spacing: DS.Spacing.s2) {
            ForEach(rows) { row in
                HStack(spacing: DS.Spacing.s2) {
                    Circle()
                        .fill(PlayerVisualViews.color(for: row.colorToken))
                        .frame(width: 10, height: 10)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(row.name)
                            .font(.subheadline.weight(row.isActive ? .bold : .medium))
                            .foregroundStyle(row.isActive ? Brand.textPrimary : Brand.textSecondary)
                        Text(L10n.string(row.side.localizationKey))
                            .font(.caption2)
                            .foregroundStyle(Brand.textSecondary)
                    }
                    Spacer()
                    Text(L10n.format("play.ticTacToe.claimsFormat", row.claims))
                        .font(.subheadline.weight(.semibold).monospacedDigit())
                        .foregroundStyle(row.isWinner ? Brand.green : Brand.textPrimary)
                }
                .padding(DS.Spacing.s2)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.sm)
                        .fill(row.isActive ? Brand.card.opacity(0.95) : Brand.card.opacity(0.45))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: DS.Radius.sm)
                        .strokeBorder(row.isActive ? Brand.green.opacity(0.5) : Color.clear, lineWidth: 1)
                )
            }
        }
        .accessibilityIdentifier("tic_tac_toe_scoreboard")
    }
}
