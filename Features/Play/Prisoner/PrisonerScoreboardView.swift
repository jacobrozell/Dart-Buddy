import SwiftUI

struct PrisonerScoreboardView: View {
    struct Row: Identifiable, Equatable {
        let id: UUID
        let name: String
        let progressIndex: Int
        let sequenceLength: Int
        let pool: Int
        let isActive: Bool
        let colorToken: PlayerColorToken
        let hasFinished: Bool
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
                            .font(.subheadline.weight(row.isActive ? .bold : .regular))
                            .foregroundStyle(Brand.textPrimary)
                        if row.hasFinished {
                            Text(L10n.string("play.prisoner.completed"))
                                .font(.caption)
                                .foregroundStyle(Brand.green)
                        } else {
                            Text(L10n.format("play.prisoner.targetProgressFormat", row.progressIndex + 1, row.sequenceLength))
                                .font(.caption)
                                .foregroundStyle(Brand.textSecondary)
                        }
                    }
                    Spacer()
                    Text(L10n.format("play.prisoner.dartPoolFormat", row.pool))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(row.isActive ? Brand.green : Brand.textSecondary)
                        .accessibilityLabel(L10n.format("play.prisoner.dartPoolFormat", row.pool))
                }
                .padding(.vertical, DS.Spacing.s1)
                .padding(.horizontal, DS.Spacing.s2)
                .background(row.isActive ? Brand.green.opacity(0.12) : Color.clear, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
            }
        }
    }
}
