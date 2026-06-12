import SwiftUI

struct FiftyOneByFivesScoreboardView: View {
    struct Row: Identifiable {
        let id: UUID
        let name: String
        let cumulativePoints: Int
        let targetPoints: Int
        let isActive: Bool
        let isLeading: Bool
        let colorToken: PlayerColorToken
    }

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    let rows: [Row]
    /// Hint text shown below the scoreboard reminding players of the divisibility rule.
    let divisibilityHint: String

    private var usesLandscapeLayout: Bool {
        GameplayLayout.usesLandscapeMatchScoringLayout(verticalSizeClass: verticalSizeClass)
    }

    var body: some View {
        VStack(spacing: usesLandscapeLayout ? DS.Spacing.s3 : DS.Spacing.s2) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                HStack(spacing: DS.Spacing.s3) {
                    Circle()
                        .fill(PlayerVisualViews.color(for: row.colorToken))
                        .frame(
                            width: usesLandscapeLayout ? 12 : 10,
                            height: usesLandscapeLayout ? 12 : 10
                        )
                    Text(row.name)
                        .font(usesLandscapeLayout
                            ? .body.weight(row.isActive || row.isLeading ? .bold : .regular)
                            : .subheadline.weight(row.isActive || row.isLeading ? .bold : .regular))
                        .foregroundStyle(Brand.textPrimary)
                        .lineLimit(1)
                    if row.isLeading {
                        Text(L10n.string("play.fiftyOneByFives.leading"))
                            .font(usesLandscapeLayout
                                ? .caption.weight(.semibold)
                                : .caption2.weight(.semibold))
                            .foregroundStyle(Brand.green)
                    }
                    Spacer()
                    // Running points with target context
                    Text(
                        L10n.format(
                            "play.fiftyOneByFives.runningScoreFormat",
                            row.cumulativePoints,
                            row.targetPoints
                        )
                    )
                    .font(usesLandscapeLayout ? .title2.weight(.bold) : .title3.weight(.bold))
                    .foregroundStyle(row.isActive ? Brand.green : Brand.textPrimary)
                }
                .padding(
                    .horizontal,
                    usesLandscapeLayout ? DS.Spacing.s4 : DS.Spacing.s3
                )
                .padding(
                    .vertical,
                    usesLandscapeLayout ? DS.Spacing.s3 : DS.Spacing.s2
                )
                .background(
                    row.isActive ? Brand.cardElevated : Brand.card,
                    in: RoundedRectangle(cornerRadius: DS.Radius.sm)
                )
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(rowAccessibilityLabel(row))
                .accessibilityIdentifier("fiftyOneByFives_scoreboard_row_\(index)")
            }

            Text(divisibilityHint)
                .font(usesLandscapeLayout ? .caption.weight(.semibold) : .caption2.weight(.semibold))
                .foregroundStyle(Brand.amber)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, usesLandscapeLayout ? DS.Spacing.s4 : DS.Spacing.s3)
                .accessibilityIdentifier("fiftyOneByFives_divisibility_hint")
        }
    }

    private func rowAccessibilityLabel(_ row: Row) -> String {
        var parts = [
            row.name,
            L10n.format(
                "play.fiftyOneByFives.runningScoreFormat",
                row.cumulativePoints,
                row.targetPoints
            ),
        ]
        if row.isActive {
            parts.append(L10n.string("common.active"))
        }
        if row.isLeading {
            parts.append(L10n.string("play.fiftyOneByFives.leading"))
        }
        return parts.joined(separator: ", ")
    }
}
