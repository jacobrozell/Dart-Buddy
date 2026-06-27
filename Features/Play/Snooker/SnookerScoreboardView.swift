import SwiftUI

struct SnookerScoreboardView: View {
    struct Row: Identifiable {
        let id: UUID
        let name: String
        let frameScore: Int
        let highestBreak: Int
        let isActive: Bool
        let isLeading: Bool
        let colorToken: PlayerColorToken
    }

    let rows: [Row]
    let breakPoints: Int

    var body: some View {
        VStack(spacing: DS.Spacing.s2) {
            if breakPoints > 0 {
                Text(L10n.format("play.snooker.breakScoreFormat", breakPoints))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Brand.amber)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("snooker_break_score")
            }
            ForEach(rows) { row in
                HStack(spacing: DS.Spacing.s2) {
                    Circle()
                        .fill(PlayerVisualViews.color(for: row.colorToken))
                        .frame(width: 10, height: 10)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(row.name)
                            .font(.subheadline.weight(row.isActive ? .bold : .medium))
                            .foregroundStyle(row.isActive ? Brand.textPrimary : Brand.textSecondary)
                        Text(L10n.format("play.snooker.highestBreakFormat", row.highestBreak))
                            .font(.caption2)
                            .foregroundStyle(Brand.textSecondary)
                    }
                    Spacer()
                    Text(L10n.format("play.snooker.frameScoreFormat", row.frameScore))
                        .font(.title3.weight(.bold).monospacedDigit())
                        .foregroundStyle(row.isLeading ? Brand.green : Brand.textPrimary)
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
        .accessibilityIdentifier("snooker_scoreboard")
    }
}
