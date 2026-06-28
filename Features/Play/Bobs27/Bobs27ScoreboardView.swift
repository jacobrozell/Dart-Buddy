import SwiftUI

struct Bobs27ScoreboardView: View {
    struct Row: Identifiable {
        let id: UUID
        let name: String
        let score: Int
        let isActive: Bool
        let isLeading: Bool
        let isEliminated: Bool
        let colorToken: PlayerColorToken
    }

    let rows: [Row]

    var body: some View {
        VStack(spacing: DS.Spacing.s2) {
            ForEach(rows) { row in
                HStack {
                    Circle()
                        .fill(PlayerVisualViews.color(for: row.colorToken))
                        .frame(width: 10, height: 10)
                    Text(row.name)
                        .font(.subheadline.weight(row.isActive ? .bold : .regular))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .foregroundStyle(row.isEliminated ? Brand.textSecondary.opacity(0.5) : Brand.textPrimary)
                    Spacer()
                    Text(L10n.format("play.bobs27.scoreFormat", row.score))
                        .font(.title3.weight(.bold).monospacedDigit())
                        .foregroundStyle(row.isLeading ? Brand.green : Brand.textPrimary)
                }
                .padding(.horizontal, DS.Spacing.s3)
                .padding(.vertical, DS.Spacing.s2)
                .background(
                    row.isActive ? Brand.card.opacity(0.9) : Brand.card.opacity(0.45),
                    in: RoundedRectangle(cornerRadius: DS.Radius.sm)
                )
            }
        }
        .accessibilityIdentifier("bobs27_scoreboard")
    }
}
