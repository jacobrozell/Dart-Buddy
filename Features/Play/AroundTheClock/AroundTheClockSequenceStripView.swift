import SwiftUI

/// Template E — sequence-progress display for Around the Clock.
/// Shows a chip trail (1–20 + optional bull) per player with their current position highlighted.
struct AroundTheClockSequenceStripView: View {
    struct Row: Identifiable {
        let id: UUID
        let name: String
        /// Current `targetIndex` (0 = aiming at 1; 20 = aiming at bull; sequenceLength = complete).
        let targetIndex: Int
        /// Total targets in this match's sequence (20 or 21 with bull finish).
        let sequenceLength: Int
        let isActive: Bool
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
                    chipTrail(row: row)
                }
                .padding(.horizontal, usesLandscapeLayout ? DS.Spacing.s4 : DS.Spacing.s3)
                .padding(.vertical, usesLandscapeLayout ? DS.Spacing.s3 : DS.Spacing.s2)
                .background(row.isActive ? Brand.cardElevated : Brand.card,
                            in: RoundedRectangle(cornerRadius: DS.Radius.sm))
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(rowAccessibilityLabel(row))
                .accessibilityIdentifier("aroundTheClock_sequence_row_\(index)")
            }
        }
    }

    // MARK: - Subviews

    private func playerHeader(row: Row) -> some View {
        HStack(spacing: DS.Spacing.s2) {
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
                .foregroundStyle(Brand.textPrimary)
                .lineLimit(1)
            Spacer()
            if row.targetIndex < row.sequenceLength {
                let target = row.targetIndex < 20 ? row.targetIndex + 1 : 25
                Text(L10n.format("play.aroundTheClock.currentTargetFormat", target))
                    .font(usesLandscapeLayout ? .caption.weight(.semibold) : .caption2.weight(.semibold))
                    .foregroundStyle(row.isActive ? Brand.green : Brand.textSecondary)
            } else {
                Text(L10n.string("play.aroundTheClock.announce.complete"))
                    .font(usesLandscapeLayout ? .caption.weight(.semibold) : .caption2.weight(.semibold))
                    .foregroundStyle(Brand.green)
            }
        }
    }

    private func chipTrail(row: Row) -> some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: chipsPerRow),
            spacing: 4
        ) {
            ForEach(0 ..< row.sequenceLength, id: \.self) { idx in
                chipView(for: idx, row: row)
            }
        }
    }

    private func chipView(for idx: Int, row: Row) -> some View {
        let label = idx < 20 ? "\(idx + 1)" : "B"
        let isDone = idx < row.targetIndex
        let isCurrent = idx == row.targetIndex
        let chipColor: Color = isDone ? Brand.green : (isCurrent ? Brand.amber : Brand.textSecondary.opacity(0.25))
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
        let completedCount = row.targetIndex
        let totalCount = row.sequenceLength
        if row.targetIndex >= row.sequenceLength {
            return L10n.format(
                "play.aroundTheClock.sequenceProgressFormat",
                row.name,
                totalCount,
                totalCount
            ) + ", \(L10n.string("play.aroundTheClock.announce.complete"))"
        }
        let currentTarget = row.targetIndex < 20 ? row.targetIndex + 1 : 25
        let progressPart = L10n.format(
            "play.aroundTheClock.sequenceProgressFormat",
            row.name,
            completedCount,
            totalCount
        )
        let targetPart = L10n.format("play.aroundTheClock.currentTargetFormat", currentTarget)
        var parts = [progressPart, targetPart]
        if row.isActive {
            parts.append(L10n.string("common.active"))
        }
        return parts.joined(separator: ", ")
    }

    // MARK: - Layout helpers

    private var chipsPerRow: Int {
        // 20 chips fit in 10 columns of 2 rows; 21 in 11×2 — keep consistent width.
        usesLandscapeLayout ? 21 : 10
    }
}
