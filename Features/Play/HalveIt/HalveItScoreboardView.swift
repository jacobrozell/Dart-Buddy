import SwiftUI

struct HalveItScoreboardView: View {
    struct Row: Identifiable {
        let id: UUID
        let name: String
        let total: Int
        let isActive: Bool
        let isLeading: Bool
        let colorToken: PlayerColorToken
    }

    let rows: [Row]
    let targetSegment: Int?

    var body: some View {
        VStack(spacing: DS.Spacing.s2) {
            if let targetSegment {
                Text(L10n.format("play.halveIt.roundTargetFormat", targetSegment))
                    .font(.headline.weight(.bold))
                    .foregroundStyle(Brand.amber)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .accessibilityIdentifier("halve_it_target")
            }
            ForEach(rows) { row in
                HStack {
                    Circle()
                        .fill(PlayerVisualViews.color(for: row.colorToken))
                        .frame(width: 10, height: 10)
                    Text(row.name)
                        .font(.subheadline.weight(row.isActive ? .bold : .regular))
                        .lineLimit(1)
                    Spacer()
                    Text("\(row.total)")
                        .font(.title3.weight(.bold))
                        .foregroundStyle(row.isLeading ? Brand.green : Brand.textPrimary)
                }
                .padding(.horizontal, DS.Spacing.s3)
                .padding(.vertical, DS.Spacing.s2)
                .background(
                    row.isActive ? Brand.card.opacity(0.9) : Brand.card.opacity(0.45),
                    in: RoundedRectangle(cornerRadius: DS.Radius.sm)
                )
                .overlay {
                    if row.isLeading {
                        RoundedRectangle(cornerRadius: DS.Radius.sm)
                            .strokeBorder(Brand.green.opacity(0.5), lineWidth: 1)
                    }
                }
            }
        }
    }
}
