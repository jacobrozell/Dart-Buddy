import SwiftUI

/// Combined scoreboard showing lives remaining and sequence progress for each player.
struct NineLivesScoreboardView: View {
    struct Row: Identifiable {
        let id: UUID
        let name: String
        let lives: Int
        let startingLives: Int
        let targetIndex: Int
        let isActive: Bool
        let isEliminated: Bool
        let hasCompleted: Bool
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

                    Text(row.name)
                        .font(usesLandscapeLayout
                              ? .body.weight(row.isActive ? .bold : .regular)
                              : .subheadline.weight(row.isActive ? .bold : .regular))
                        .foregroundStyle(row.isEliminated ? Brand.textSecondary : Brand.textPrimary)
                        .lineLimit(1)

                    if row.isEliminated {
                        Text(L10n.string("play.nineLives.playerEliminated"))
                            .font(usesLandscapeLayout ? .caption.weight(.semibold) : .caption2.weight(.semibold))
                            .foregroundStyle(Brand.textSecondary)
                    } else if row.hasCompleted {
                        Text(L10n.string("play.nineLives.completed"))
                            .font(usesLandscapeLayout ? .caption.weight(.semibold) : .caption2.weight(.semibold))
                            .foregroundStyle(Brand.green)
                    }

                    Spacer()

                    if !row.isEliminated {
                        // Sequence progress: target number
                        Text(L10n.format("play.nineLives.targetProgressFormat", min(row.targetIndex + 1, 20), 20))
                            .font(usesLandscapeLayout ? .subheadline : .caption)
                            .foregroundStyle(Brand.textSecondary)
                            .accessibilityHidden(true)
                    }

                    // Lives display: text + heart icon (not color-only per accessibility rules)
                    livesView(for: row)
                }
                .padding(.horizontal, usesLandscapeLayout ? DS.Spacing.s4 : DS.Spacing.s3)
                .padding(.vertical, usesLandscapeLayout ? DS.Spacing.s3 : DS.Spacing.s2)
                .background(
                    row.isActive ? Brand.cardElevated : Brand.card,
                    in: RoundedRectangle(cornerRadius: DS.Radius.sm)
                )
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(rowAccessibilityLabel(row))
                .accessibilityIdentifier("nineLives_scoreboard_row_\(index)")
            }
        }
    }

    @ViewBuilder
    private func livesView(for row: Row) -> some View {
        if row.isEliminated {
            HStack(spacing: 2) {
                Image(systemName: "heart.slash")
                    .font(usesLandscapeLayout ? .subheadline : .caption)
                    .foregroundStyle(Brand.textSecondary)
                Text("0")
                    .font(usesLandscapeLayout ? .title2.weight(.bold) : .title3.weight(.bold))
                    .foregroundStyle(Brand.textSecondary)
            }
        } else {
            HStack(spacing: 2) {
                Image(systemName: "heart.fill")
                    .font(usesLandscapeLayout ? .subheadline : .caption)
                    .foregroundStyle(row.isActive ? Brand.green : Brand.textPrimary)
                Text("\(row.lives)")
                    .font(usesLandscapeLayout ? .title2.weight(.bold) : .title3.weight(.bold))
                    .foregroundStyle(row.isActive ? Brand.green : Brand.textPrimary)
            }
        }
    }

    private func rowAccessibilityLabel(_ row: Row) -> String {
        var parts = [row.name]
        if row.isEliminated {
            parts.append(L10n.string("play.nineLives.playerEliminated"))
        } else {
            parts.append(
                L10n.format("play.nineLives.livesRemainingFormat", row.lives)
            )
            parts.append(
                L10n.format("play.nineLives.targetProgressFormat", min(row.targetIndex + 1, 20), 20)
            )
        }
        if row.isActive {
            parts.append(L10n.string("common.active"))
        }
        return parts.joined(separator: ", ")
    }
}

/// Horizontal strip showing 1–20 sequence progress for a single player.
struct NineLivesSequenceStrip: View {
    let targetIndex: Int
    let isEliminated: Bool

    var body: some View {
        HStack(spacing: 4) {
            ForEach(1 ... 20, id: \.self) { segment in
                segmentDot(segment: segment)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(stripAccessibilityLabel)
        .accessibilityHidden(isEliminated)
    }

    @ViewBuilder
    private func segmentDot(segment: Int) -> some View {
        let isDone = segment <= targetIndex
        let isCurrent = segment == targetIndex + 1

        Circle()
            .fill(dotFill(isDone: isDone, isCurrent: isCurrent))
            .frame(width: 8, height: 8)
            .overlay {
                if isCurrent {
                    Circle().stroke(Brand.amber, lineWidth: 1.5)
                }
            }
    }

    private func dotFill(isDone: Bool, isCurrent: Bool) -> Color {
        if isDone { return Brand.green }
        if isCurrent { return Brand.amber }
        return Brand.textSecondary.opacity(0.35)
    }

    private var stripAccessibilityLabel: String {
        L10n.format("play.nineLives.targetProgressFormat", min(targetIndex + 1, 20), 20)
    }
}
