import SwiftUI

/// Scoreboard showing each player's phase banner and goal tally for Football.
struct FootballScoreboardView: View {
    struct Row: Identifiable {
        let id: UUID
        let name: String
        let goals: Int
        let goalsToWin: Int
        let phase: FootballPhase
        let isActive: Bool
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
                            .font(
                                usesLandscapeLayout
                                    ? .body.weight(row.isActive ? .bold : .regular)
                                    : .subheadline.weight(row.isActive ? .bold : .regular)
                            )
                            .foregroundStyle(Brand.textPrimary)
                            .lineLimit(1)

                        Text(phaseBadgeLabel(row.phase))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(row.phase == .kickoff ? Brand.amber : Brand.green)
                            .accessibilityIdentifier("football_phase_\(index)")
                    }

                    Spacer()

                    VStack(alignment: .trailing, spacing: 2) {
                        Text(L10n.format("play.football.goalsFormat", row.goals))
                            .font(usesLandscapeLayout ? .title2.weight(.bold) : .title3.weight(.bold))
                            .foregroundStyle(row.isActive ? Brand.green : Brand.textPrimary)
                        Text(L10n.format("play.football.goalsTotalFormat", row.goalsToWin))
                            .font(.caption2)
                            .foregroundStyle(Brand.textSecondary)
                    }
                }
                .padding(.horizontal, usesLandscapeLayout ? DS.Spacing.s4 : DS.Spacing.s3)
                .padding(.vertical, usesLandscapeLayout ? DS.Spacing.s3 : DS.Spacing.s2)
                .background(
                    row.isActive ? Brand.cardElevated : Brand.card,
                    in: RoundedRectangle(cornerRadius: DS.Radius.sm)
                )
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(rowAccessibilityLabel(row))
                .accessibilityIdentifier("football_scoreboard_row_\(index)")
            }
        }
    }

    private func phaseBadgeLabel(_ phase: FootballPhase) -> String {
        switch phase {
        case .kickoff: L10n.string("phase.kickoff")
        case .scoring: L10n.string("phase.scoring")
        }
    }

    private func rowAccessibilityLabel(_ row: Row) -> String {
        var parts = [
            row.name,
            phaseBadgeLabel(row.phase),
            L10n.format("play.football.goalsFormat", row.goals)
        ]
        if row.isActive {
            parts.append(L10n.string("common.active"))
        }
        return parts.joined(separator: ", ")
    }
}
