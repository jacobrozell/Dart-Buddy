import SwiftUI

/// Template E — course-progress display for Grand National.
/// Shows the 20-segment anticlockwise course per player with their current hurdle
/// highlighted.  Eliminated players are shown with a visual "fell" state.
struct GrandNationalCourseStripView: View {
    struct Row: Identifiable {
        let id: UUID
        let name: String
        /// Current segment index in `grandNationalCourseOrder` (0…19).
        let segmentIndex: Int
        /// Number of full laps completed so far.
        let lapsCompleted: Int
        /// Total laps required to win.
        let requiredLaps: Int
        let isActive: Bool
        let isEliminated: Bool
        let colorToken: PlayerColorToken
    }

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    let rows: [Row]

    private var usesLandscapeLayout: Bool {
        GameplayLayout.usesLandscapeMatchScoringLayout(verticalSizeClass: verticalSizeClass)
    }

    var body: some View {
        VStack(spacing: usesLandscapeLayout ? DS.Spacing.s4 : DS.Spacing.s3) {
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                VStack(alignment: .leading, spacing: DS.Spacing.s2) {
                    playerHeader(row: row)
                    if !row.isEliminated {
                        chipTrail(row: row)
                    }
                }
                .padding(.horizontal, usesLandscapeLayout ? DS.Spacing.s4 : DS.Spacing.s3)
                .padding(.vertical, usesLandscapeLayout ? DS.Spacing.s3 : DS.Spacing.s2)
                .background(
                    rowBackground(row: row),
                    in: RoundedRectangle(cornerRadius: DS.Radius.sm)
                )
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(rowAccessibilityLabel(row))
                .accessibilityIdentifier("grandNational_course_row_\(index)")
            }
        }
    }

    // MARK: - Subviews

    private func playerHeader(row: Row) -> some View {
        HStack(spacing: DS.Spacing.s2) {
            Circle()
                .fill(rowPlayerColor(row: row))
                .frame(
                    width: usesLandscapeLayout ? 12 : 10,
                    height: usesLandscapeLayout ? 12 : 10
                )
            Text(row.name)
                .font(usesLandscapeLayout
                    ? .body.weight(row.isActive ? .bold : .regular)
                    : .subheadline.weight(row.isActive ? .bold : .regular))
                .foregroundStyle(row.isEliminated ? Brand.textSecondary : Brand.textPrimary)
                .strikethrough(row.isEliminated)
                .lineLimit(1)
            Spacer()
            statusLabel(row: row)
        }
    }

    @ViewBuilder
    private func statusLabel(row: Row) -> some View {
        if row.isEliminated {
            Text(L10n.string("play.grandNational.fellAtHurdle"))
                .font(usesLandscapeLayout ? .caption.weight(.semibold) : .caption2.weight(.semibold))
                .foregroundStyle(Brand.textSecondary)
        } else if row.lapsCompleted >= row.requiredLaps {
            Text(L10n.string("play.grandNational.announce.finished"))
                .font(usesLandscapeLayout ? .caption.weight(.semibold) : .caption2.weight(.semibold))
                .foregroundStyle(Brand.green)
        } else {
            let hurdle = grandNationalCourseOrder[row.segmentIndex % grandNationalCourseOrder.count]
            Text(L10n.format("play.grandNational.hurdleFormat", hurdle))
                .font(usesLandscapeLayout ? .caption.weight(.semibold) : .caption2.weight(.semibold))
                .foregroundStyle(row.isActive ? Brand.green : Brand.textSecondary)
        }
    }

    private func chipTrail(row: Row) -> some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: chipsPerRow),
            spacing: 4
        ) {
            ForEach(0 ..< grandNationalCourseOrder.count, id: \.self) { idx in
                chipView(for: idx, row: row)
            }
        }
    }

    private func chipView(for idx: Int, row: Row) -> some View {
        let label = "\(grandNationalCourseOrder[idx])"
        let isDone = idx < row.segmentIndex
        let isCurrent = idx == row.segmentIndex
        let chipColor: Color = isDone
            ? Brand.green
            : (isCurrent ? Brand.amber : Brand.textSecondary.opacity(0.25))
        return Text(label)
            .font(.system(size: 10, weight: isCurrent ? .bold : .regular, design: .monospaced))
            .foregroundStyle(isDone || isCurrent ? Brand.background : Brand.textSecondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .background(chipColor, in: RoundedRectangle(cornerRadius: 4))
            .overlay {
                if isCurrent {
                    RoundedRectangle(cornerRadius: 4).stroke(Brand.green, lineWidth: 1.5)
                }
            }
            .accessibilityHidden(true)
    }

    // MARK: - Accessibility

    private func rowAccessibilityLabel(_ row: Row) -> String {
        if row.isEliminated {
            return "\(row.name), \(L10n.string("play.grandNational.playerEliminated"))"
        }
        if row.lapsCompleted >= row.requiredLaps {
            return "\(row.name), \(L10n.string("play.grandNational.announce.finished"))"
        }
        let hurdle = grandNationalCourseOrder[row.segmentIndex % grandNationalCourseOrder.count]
        var parts = [
            row.name,
            L10n.format(
                "play.grandNational.coursePositionAccessibilityFormat",
                hurdle,
                row.lapsCompleted + 1
            )
        ]
        if row.isActive { parts.append(L10n.string("common.active")) }
        return parts.joined(separator: ", ")
    }

    // MARK: - Styling helpers

    private func rowPlayerColor(row: Row) -> Color {
        row.isEliminated
            ? Brand.textSecondary.opacity(0.4)
            : PlayerVisualViews.color(for: row.colorToken)
    }

    private func rowBackground(row: Row) -> Color {
        if row.isEliminated { return Brand.card.opacity(0.5) }
        return row.isActive ? Brand.cardElevated : Brand.card
    }

    private var chipsPerRow: Int {
        usesLandscapeLayout ? 20 : 10
    }
}
