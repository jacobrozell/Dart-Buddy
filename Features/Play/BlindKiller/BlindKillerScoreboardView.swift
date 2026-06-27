import SwiftUI

struct BlindKillerScoreboardView: View {
    struct Row: Identifiable {
        let id: UUID
        let name: String
        let isEliminated: Bool
        let isActive: Bool
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
                    Text(row.name)
                        .font(.subheadline.weight(row.isActive ? .semibold : .regular))
                        .foregroundStyle(row.isEliminated ? Brand.textSecondary : Brand.textPrimary)
                        .lineLimit(1)
                    Spacer()
                    if row.isEliminated {
                        Text(L10n.string("play.blindKiller.playerEliminated"))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Brand.red)
                    }
                }
                .padding(.horizontal, DS.Spacing.s3)
                .padding(.vertical, DS.Spacing.s2)
                .background(
                    row.isActive ? Brand.cardElevated : Brand.card,
                    in: RoundedRectangle(cornerRadius: DS.Radius.sm)
                )
                .overlay {
                    if row.isActive {
                        RoundedRectangle(cornerRadius: DS.Radius.sm)
                            .stroke(Brand.green.opacity(0.45), lineWidth: 1)
                    }
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(accessibilityLabel(for: row))
            }
        }
    }

    private func accessibilityLabel(for row: Row) -> String {
        var parts = [row.name]
        if row.isEliminated {
            parts.append(L10n.string("play.blindKiller.playerEliminated"))
        }
        return parts.joined(separator: ", ")
    }
}
