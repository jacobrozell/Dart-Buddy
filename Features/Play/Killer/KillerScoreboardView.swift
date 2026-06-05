import SwiftUI

struct KillerScoreboardView: View {
    struct Row: Identifiable {
        let id: UUID
        let name: String
        let assignedNumber: Int?
        let lives: Int
        let isKiller: Bool
        let isEliminated: Bool
        let isActive: Bool
        let colorToken: PlayerColorToken
    }

    let rows: [Row]

    var body: some View {
        VStack(spacing: DS.Spacing.s2) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                HStack(spacing: DS.Spacing.s3) {
                    Circle()
                        .fill(PlayerVisualViews.color(for: row.colorToken))
                        .frame(width: 10, height: 10)
                    Text(row.name)
                        .font(.subheadline.weight(row.isActive ? .bold : .regular))
                        .foregroundStyle(row.isEliminated ? Brand.textSecondary : Brand.textPrimary)
                        .lineLimit(1)
                        .strikethrough(row.isEliminated)
                    if let number = row.assignedNumber {
                        Text("\(number)")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Brand.textSecondary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Brand.cardElevated, in: Capsule())
                    }
                    if row.isKiller, !row.isEliminated {
                        Label(L10n.string("play.killer.killerBadge"), systemImage: "scope")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Brand.red)
                            .labelStyle(.titleAndIcon)
                    }
                    Spacer()
                    LivesPipsView(lives: row.lives, isEliminated: row.isEliminated)
                }
                .padding(.horizontal, DS.Spacing.s3)
                .padding(.vertical, DS.Spacing.s2)
                .background(row.isActive ? Brand.cardElevated : Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
                .opacity(row.isEliminated ? 0.55 : 1)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(rowAccessibilityLabel(row))
                .accessibilityIdentifier("killer_scoreboard_row_\(index)")
            }
        }
    }

    private func rowAccessibilityLabel(_ row: Row) -> String {
        var parts = [row.name]
        if let number = row.assignedNumber {
            parts.append(L10n.format("play.killer.numberAccessibilityFormat", number))
        }
        parts.append(L10n.format("play.killer.livesAccessibilityFormat", row.lives))
        if row.isKiller, !row.isEliminated {
            parts.append(L10n.string("play.killer.killerBadge"))
        }
        if row.isEliminated {
            parts.append(L10n.string("play.killer.eliminated"))
        }
        return parts.joined(separator: ", ")
    }
}

private struct LivesPipsView: View {
    let lives: Int
    let isEliminated: Bool

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0 ..< max(lives, 0), id: \.self) { _ in
                Image(systemName: "heart.fill")
                    .font(.caption2)
                    .foregroundStyle(isEliminated ? Brand.textSecondary : Brand.red)
            }
            if lives == 0 {
                Text("0")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Brand.textSecondary)
            }
        }
        .accessibilityHidden(true)
    }
}
