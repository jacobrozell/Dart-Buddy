import SwiftUI

/// Scoreboard for English Cricket showing runs and wickets per player per innings.
struct EnglishCricketScoreboardView: View {
    struct Row: Identifiable {
        let id: UUID
        let name: String
        let totalRuns: Int
        let runsThisInnings: Int
        /// Non-nil for the current bowler; represents wickets remaining before innings ends.
        let wicketsRemaining: Int?
        let isBatter: Bool
        let isBowler: Bool
        let isActiveTurn: Bool
        let colorToken: PlayerColorToken
    }

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    let rows: [Row]

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

                    VStack(alignment: .leading, spacing: 2) {
                        Text(row.name)
                            .font(usesLandscapeLayout
                                ? .body.weight(row.isActiveTurn ? .bold : .regular)
                                : .subheadline.weight(row.isActiveTurn ? .bold : .regular))
                            .foregroundStyle(Brand.textPrimary)
                            .lineLimit(1)
                        roleBadge(for: row)
                    }

                    Spacer()

                    if let wickets = row.wicketsRemaining {
                        VStack(alignment: .trailing, spacing: 1) {
                            Text(L10n.format("play.englishCricket.wicketsRemainingFormat", wickets))
                                .font(usesLandscapeLayout ? .caption : .caption2)
                                .foregroundStyle(Brand.amber)
                        }
                    }

                    VStack(alignment: .trailing, spacing: 1) {
                        Text(L10n.format("play.englishCricket.runsFormat", row.totalRuns))
                            .font(usesLandscapeLayout ? .title2.weight(.bold) : .title3.weight(.bold))
                            .foregroundStyle(row.isActiveTurn ? Brand.green : Brand.textPrimary)
                        if row.runsThisInnings > 0 {
                            Text(L10n.format("play.englishCricket.visitRunsFormat", row.runsThisInnings))
                                .font(usesLandscapeLayout ? .caption : .caption2)
                                .foregroundStyle(Brand.textSecondary)
                        }
                    }
                }
                .padding(.horizontal, usesLandscapeLayout ? DS.Spacing.s4 : DS.Spacing.s3)
                .padding(.vertical, usesLandscapeLayout ? DS.Spacing.s3 : DS.Spacing.s2)
                .background(
                    row.isActiveTurn ? Brand.cardElevated : Brand.card,
                    in: RoundedRectangle(cornerRadius: DS.Radius.sm)
                )
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(rowAccessibilityLabel(row))
                .accessibilityIdentifier("englishCricket_scoreboard_row_\(index)")
            }
        }
    }

    @ViewBuilder
    private func roleBadge(for row: Row) -> some View {
        if row.isBatter {
            Text(L10n.string("play.englishCricket.role.batter"))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Brand.green)
        } else if row.isBowler {
            Text(L10n.string("play.englishCricket.role.bowler"))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Brand.amber)
        }
    }

    private func rowAccessibilityLabel(_ row: Row) -> String {
        var parts = [row.name]
        if row.isBatter {
            parts.append(L10n.string("play.englishCricket.role.batter"))
        } else if row.isBowler {
            parts.append(L10n.string("play.englishCricket.role.bowler"))
        }
        parts.append(L10n.format("play.englishCricket.runsFormat", row.totalRuns))
        if let wickets = row.wicketsRemaining {
            parts.append(L10n.format("play.englishCricket.wicketsRemainingFormat", wickets))
        }
        if row.isActiveTurn {
            parts.append(L10n.string("common.active"))
        }
        return parts.joined(separator: ", ")
    }
}
