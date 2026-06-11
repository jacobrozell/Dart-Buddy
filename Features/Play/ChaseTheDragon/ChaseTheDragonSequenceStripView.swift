import SwiftUI

/// Displays each player's progress through the dragon sequence.
struct ChaseTheDragonSequenceStripView: View {
    struct Row: Identifiable {
        let id: UUID
        let name: String
        /// Number of sequence steps completed across all laps.
        let completedSteps: Int
        /// Total steps required to finish the match (stepsPerLap × laps).
        let totalSteps: Int
        /// Display label for the step the player is currently aiming at.
        let currentStepLabel: String
        let isActive: Bool
        let isLeading: Bool
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
                                ? .body.weight(row.isActive || row.isLeading ? .bold : .regular)
                                : .subheadline.weight(row.isActive || row.isLeading ? .bold : .regular))
                            .foregroundStyle(Brand.textPrimary)
                            .lineLimit(1)
                        Text(row.currentStepLabel)
                            .font(usesLandscapeLayout ? .caption : .caption2)
                            .foregroundStyle(row.isActive ? Brand.amber : Brand.textSecondary)
                    }
                    if row.isLeading {
                        Text(L10n.string("play.chaseTheDragon.leading"))
                            .font(usesLandscapeLayout ? .caption.weight(.semibold) : .caption2.weight(.semibold))
                            .foregroundStyle(Brand.green)
                    }
                    Spacer()
                    DragonProgressBar(
                        completedSteps: row.completedSteps,
                        totalSteps: row.totalSteps,
                        isActive: row.isActive
                    )
                    .frame(width: usesLandscapeLayout ? 80 : 60)
                    Text("\(row.completedSteps)/\(row.totalSteps)")
                        .font(usesLandscapeLayout ? .subheadline.weight(.bold) : .caption.weight(.bold))
                        .foregroundStyle(row.isActive ? Brand.green : Brand.textPrimary)
                        .monospacedDigit()
                }
                .padding(.horizontal, usesLandscapeLayout ? DS.Spacing.s4 : DS.Spacing.s3)
                .padding(.vertical, usesLandscapeLayout ? DS.Spacing.s3 : DS.Spacing.s2)
                .background(
                    row.isActive ? Brand.cardElevated : Brand.card,
                    in: RoundedRectangle(cornerRadius: DS.Radius.sm)
                )
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(rowAccessibilityLabel(row))
                .accessibilityIdentifier("chaseTheDragon_sequence_row_\(index)")
            }
        }
    }

    private func rowAccessibilityLabel(_ row: Row) -> String {
        var parts = [
            row.name,
            L10n.format("play.chaseTheDragon.sequenceProgressFormat", row.completedSteps, row.totalSteps),
            row.currentStepLabel,
        ]
        if row.isActive { parts.append(L10n.string("common.active")) }
        if row.isLeading { parts.append(L10n.string("play.chaseTheDragon.leading")) }
        return parts.joined(separator: ", ")
    }
}

// MARK: - Dragon progress bar

/// Compact horizontal bar showing proportion of the sequence completed.
private struct DragonProgressBar: View {
    let completedSteps: Int
    let totalSteps: Int
    let isActive: Bool

    private var fraction: Double {
        guard totalSteps > 0 else { return 0 }
        return min(1.0, Double(completedSteps) / Double(totalSteps))
    }

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Brand.textSecondary.opacity(0.2))
                RoundedRectangle(cornerRadius: 3)
                    .fill(isActive ? Brand.green : Brand.textSecondary.opacity(0.6))
                    .frame(width: geo.size.width * fraction)
            }
        }
        .frame(height: 6)
        .accessibilityHidden(true)
    }
}
