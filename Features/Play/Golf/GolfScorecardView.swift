import SwiftUI

/// Hole-by-hole scorecard for a Golf match.
///
/// Displays a row per player showing each hole's stroke count and running total.
/// Stroke values are rendered as numbers with accessibility labels — not color-only.
struct GolfScorecardView: View {
    struct PlayerRow: Identifiable {
        let id: UUID
        let name: String
        /// Stroke count per hole, indexed 0…(courseLength-1). `nil` = hole not yet played.
        let holeStrokes: [Int?]
        let runningTotal: Int
        let isActive: Bool
        let isLeading: Bool
        let colorToken: PlayerColorToken
    }

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    let rows: [PlayerRow]
    let courseLength: Int

    private var usesLandscapeLayout: Bool {
        GameplayLayout.usesLandscapeMatchScoringLayout(verticalSizeClass: verticalSizeClass)
    }

    var body: some View {
        VStack(spacing: usesLandscapeLayout ? DS.Spacing.s3 : DS.Spacing.s2) {
            holeHeaderRow
            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                playerRow(row, index: index)
            }
        }
    }

    // MARK: - Header

    private var holeHeaderRow: some View {
        HStack(spacing: 0) {
            Text(L10n.string("play.golf.scorecard.playerHeader"))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Brand.textSecondary)
                .frame(minWidth: 70, alignment: .leading)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(1 ... courseLength, id: \.self) { hole in
                        Text(L10n.format("play.golf.scorecard.holeHeader", hole))
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(Brand.textSecondary)
                            .frame(width: holeColumnWidth, alignment: .center)
                    }
                    Text(L10n.string("play.golf.scorecard.totalHeader"))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(Brand.textSecondary)
                        .frame(width: totalColumnWidth, alignment: .trailing)
                }
            }
        }
        .padding(.horizontal, usesLandscapeLayout ? DS.Spacing.s4 : DS.Spacing.s3)
        .accessibilityHidden(true)
    }

    // MARK: - Player row

    @ViewBuilder
    private func playerRow(_ row: PlayerRow, index: Int) -> some View {
        HStack(spacing: 0) {
            // Player name + color indicator
            HStack(spacing: DS.Spacing.s2) {
                Circle()
                    .fill(PlayerVisualViews.color(for: row.colorToken))
                    .frame(width: 8, height: 8)
                Text(row.name)
                    .font(usesLandscapeLayout
                        ? .body.weight(row.isActive || row.isLeading ? .bold : .regular)
                        : .subheadline.weight(row.isActive || row.isLeading ? .bold : .regular))
                    .foregroundStyle(Brand.textPrimary)
                    .lineLimit(1)
            }
            .frame(minWidth: 70, alignment: .leading)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(Array(row.holeStrokes.enumerated()), id: \.offset) { _, strokes in
                        strokeCell(strokes)
                    }
                    // Running total
                    Text(row.runningTotal > 0
                        ? L10n.format("play.golf.scorecard.totalFormat", row.runningTotal)
                        : "—")
                        .font(usesLandscapeLayout
                            ? .subheadline.weight(.bold)
                            : .callout.weight(.bold))
                        .foregroundStyle(row.isActive ? Brand.green : Brand.textPrimary)
                        .frame(width: totalColumnWidth, alignment: .trailing)
                }
            }

            if row.isLeading {
                Text(L10n.string("play.golf.leading"))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Brand.green)
                    .padding(.leading, DS.Spacing.s2)
            }
        }
        .padding(.horizontal, usesLandscapeLayout ? DS.Spacing.s4 : DS.Spacing.s3)
        .padding(.vertical, usesLandscapeLayout ? DS.Spacing.s3 : DS.Spacing.s2)
        .background(row.isActive ? Brand.cardElevated : Brand.card,
                    in: RoundedRectangle(cornerRadius: DS.Radius.sm))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(rowAccessibilityLabel(row))
        .accessibilityIdentifier("golf_scoreboard_row_\(index)")
    }

    @ViewBuilder
    private func strokeCell(_ strokes: Int?) -> some View {
        if let strokes {
            Text("\(strokes)")
                .font(usesLandscapeLayout ? .subheadline : .caption)
                .foregroundStyle(strokeColor(strokes))
                .frame(width: holeColumnWidth, alignment: .center)
        } else {
            Text("·")
                .font(usesLandscapeLayout ? .subheadline : .caption)
                .foregroundStyle(Brand.textSecondary.opacity(0.4))
                .frame(width: holeColumnWidth, alignment: .center)
        }
    }

    // MARK: - Accessibility

    private func rowAccessibilityLabel(_ row: PlayerRow) -> String {
        var parts = [row.name]
        for (index, strokes) in row.holeStrokes.enumerated() {
            let hole = index + 1
            if let strokes {
                parts.append(L10n.format("play.golf.scorecard.holeAccessibilityFormat", hole, strokes))
            }
        }
        parts.append(L10n.format("play.golf.scorecard.totalAccessibilityFormat", row.runningTotal))
        if row.isActive {
            parts.append(L10n.string("common.active"))
        }
        if row.isLeading {
            parts.append(L10n.string("play.golf.leading"))
        }
        return parts.joined(separator: ", ")
    }

    // MARK: - Layout constants

    private var holeColumnWidth: CGFloat { courseLength <= 9 ? 28 : 22 }
    private var totalColumnWidth: CGFloat { 44 }

    private func strokeColor(_ strokes: Int) -> Color {
        switch strokes {
        case 1: return Brand.green       // double
        case 2: return Brand.amber       // triple
        case 3: return Brand.textPrimary // single
        default: return Brand.textSecondary // miss (5)
        }
    }
}

// MARK: - Hole progress strip

/// Horizontal dot strip showing completed, current, and upcoming holes.
struct HoleProgressStrip: View {
    let courseLength: Int
    let currentHole: Int

    var body: some View {
        HStack(spacing: 6) {
            ForEach(1 ... courseLength, id: \.self) { hole in
                Circle()
                    .fill(fillColor(for: hole))
                    .frame(width: 10, height: 10)
                    .overlay {
                        if hole == currentHole {
                            Circle().stroke(Brand.green, lineWidth: 2)
                        }
                    }
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            L10n.format("play.golf.holeStrip.accessibilityFormat", currentHole, courseLength)
        )
    }

    private func fillColor(for hole: Int) -> Color {
        if hole < currentHole { return Brand.green }
        if hole == currentHole { return Brand.amber }
        return Brand.textSecondary.opacity(0.35)
    }
}

// MARK: - Stroke label badge

/// Compact badge used in the match screen to show the label for a stroke value.
struct GolfStrokeBadge: View {
    let strokes: Int

    var body: some View {
        Text(strokeLabel)
            .font(.caption.weight(.semibold))
            .foregroundStyle(strokeColor)
            .padding(.horizontal, DS.Spacing.s2)
            .padding(.vertical, 2)
            .background(strokeColor.opacity(0.15), in: Capsule())
            .accessibilityLabel(L10n.format("play.golf.strokeAccessibilityFormat", strokes, strokeLabel))
    }

    private var strokeLabel: String {
        switch strokes {
        case 1: return L10n.string("play.golf.stroke.double")
        case 2: return L10n.string("play.golf.stroke.triple")
        case 3: return L10n.string("play.golf.stroke.single")
        default: return L10n.string("play.golf.stroke.miss")
        }
    }

    private var strokeColor: Color {
        switch strokes {
        case 1: return Brand.green
        case 2: return Brand.amber
        case 3: return Brand.textPrimary
        default: return Brand.textSecondary
        }
    }
}
