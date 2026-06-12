import SwiftUI

/// Scoreboard for the Sudden Death game mode.
///
/// Displays per-round totals, cumulative totals, and elimination status for each
/// player.  Players at risk (lowest round total so far) are highlighted in amber;
/// eliminated players are shown with a strikethrough in a muted colour.
struct SuddenDeathScoreboardView: View {
    struct Row: Identifiable {
        let id: UUID
        let name: String
        /// Total for the current round (may include a live preview for the active player).
        let roundTotal: Int
        /// Sum of all round totals across completed rounds.
        let cumulativeTotal: Int
        let isActive: Bool
        let isEliminated: Bool
        /// `true` when this player is currently tied for the lowest round total and
        /// could be eliminated at round end.
        let isAtRisk: Bool
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
                rowView(row, index: index)
            }
        }
    }

    @ViewBuilder
    private func rowView(_ row: Row, index: Int) -> some View {
        HStack(spacing: DS.Spacing.s3) {
            Circle()
                .fill(PlayerVisualViews.color(for: row.colorToken))
                .frame(
                    width: usesLandscapeLayout ? 12 : 10,
                    height: usesLandscapeLayout ? 12 : 10
                )

            if row.isEliminated {
                Text(row.name)
                    .font(usesLandscapeLayout ? .body : .subheadline)
                    .strikethrough()
                    .foregroundStyle(Brand.textSecondary.opacity(0.55))
                    .lineLimit(1)
            } else {
                Text(row.name)
                    .font(usesLandscapeLayout
                          ? .body.weight(row.isActive ? .bold : .regular)
                          : .subheadline.weight(row.isActive ? .bold : .regular))
                    .foregroundStyle(Brand.textPrimary)
                    .lineLimit(1)
            }

            if row.isAtRisk && !row.isEliminated {
                Image(systemName: "exclamationmark.circle.fill")
                    .font(usesLandscapeLayout ? .caption : .caption2)
                    .foregroundStyle(Brand.amber)
                    .accessibilityHidden(true)
            }

            Spacer()

            // Round total column.
            if !row.isEliminated {
                Text(L10n.format("play.suddenDeath.thisRoundFormat", row.roundTotal))
                    .font(usesLandscapeLayout ? .subheadline : .caption)
                    .foregroundStyle(row.isAtRisk ? Brand.amber : Brand.textSecondary)
            }

            // Cumulative total.
            Text(row.isEliminated
                 ? L10n.string("play.suddenDeath.eliminatedLabel")
                 : "\(row.cumulativeTotal)")
                .font(usesLandscapeLayout ? .title2.weight(.bold) : .title3.weight(.bold))
                .foregroundStyle(
                    row.isEliminated ? Brand.textSecondary.opacity(0.55)
                    : row.isActive ? Brand.green
                    : Brand.textPrimary
                )
        }
        .padding(.horizontal, usesLandscapeLayout ? DS.Spacing.s4 : DS.Spacing.s3)
        .padding(.vertical, usesLandscapeLayout ? DS.Spacing.s3 : DS.Spacing.s2)
        .background(
            row.isActive ? Brand.cardElevated : Brand.card,
            in: RoundedRectangle(cornerRadius: DS.Radius.sm)
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(rowAccessibilityLabel(row))
        .accessibilityIdentifier("suddenDeath_scoreboard_row_\(index)")
    }

    private func rowAccessibilityLabel(_ row: Row) -> String {
        var parts: [String] = [row.name]
        if row.isEliminated {
            parts.append(L10n.string("play.suddenDeath.eliminatedLabel"))
        } else {
            parts.append(L10n.format("play.suddenDeath.totalPointsAccessibilityFormat", row.cumulativeTotal))
            parts.append(L10n.format("play.suddenDeath.thisRoundAccessibilityFormat", row.roundTotal))
            if row.isActive {
                parts.append(L10n.string("common.active"))
            }
            if row.isAtRisk {
                parts.append(L10n.string("play.suddenDeath.atRiskAccessibilityLabel"))
            }
        }
        return parts.joined(separator: ", ")
    }
}
