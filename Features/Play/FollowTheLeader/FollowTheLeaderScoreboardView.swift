import SwiftUI

struct FollowTheLeaderScoreboardView: View {
    struct Row: Identifiable {
        let id: UUID
        let name: String
        let lives: Int
        let startingLives: Int
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
                        Text(L10n.string("play.followTheLeader.playerEliminated"))
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Brand.red)
                    } else {
                        LivesPipsView(total: row.startingLives, remaining: row.lives)
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
            }
        }
    }
}

private struct LivesPipsView: View {
    let total: Int
    let remaining: Int

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0 ..< total, id: \.self) { index in
                Image(systemName: index < remaining ? "heart.fill" : "heart")
                    .font(.caption2)
                    .foregroundStyle(index < remaining ? Brand.red : Brand.textSecondary.opacity(0.35))
            }
        }
        .accessibilityLabel(L10n.format("play.followTheLeader.livesRemainingFormat", remaining))
    }
}
