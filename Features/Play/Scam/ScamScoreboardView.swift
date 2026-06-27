import SwiftUI

struct ScamScoreboardView: View {
    struct Row: Identifiable {
        let id: UUID
        let name: String
        let totalScore: Int
        let isActive: Bool
        let isLeading: Bool
        let roleLabel: String?
        let colorToken: PlayerColorToken
    }

    let rows: [Row]

    var body: some View {
        VStack(spacing: DS.Spacing.s2) {
            ForEach(rows) { row in
                HStack(spacing: DS.Spacing.s3) {
                    Circle()
                        .fill(PlayerVisualViews.color(for: row.colorToken))
                        .frame(width: 10, height: 10)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(row.name)
                            .font(.subheadline.weight(row.isActive ? .bold : .regular))
                            .lineLimit(1)
                        if let roleLabel = row.roleLabel, row.isActive {
                            Text(roleLabel)
                                .font(.caption2.weight(.semibold))
                                .foregroundStyle(Brand.amber)
                        }
                    }
                    Spacer()
                    Text("\(row.totalScore)")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(row.isLeading ? Brand.green : Brand.textPrimary)
                }
                .padding(.horizontal, DS.Spacing.s3)
                .padding(.vertical, DS.Spacing.s2)
                .background(
                    row.isActive ? Brand.card.opacity(0.95) : Brand.card.opacity(0.45),
                    in: RoundedRectangle(cornerRadius: DS.Radius.sm)
                )
                .overlay {
                    if row.isLeading {
                        RoundedRectangle(cornerRadius: DS.Radius.sm)
                            .strokeBorder(Brand.green.opacity(0.45), lineWidth: 1)
                    }
                }
            }
        }
    }
}
