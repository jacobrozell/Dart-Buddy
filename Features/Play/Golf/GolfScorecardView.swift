import SwiftUI

/// Hole-by-hole scorecard for a Golf match.
///
/// Player names sit in a fixed leading column; hole columns scroll horizontally so
/// progress dots stay aligned with stroke cells regardless of name length.
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
    let currentHole: Int

    private var usesLandscapeLayout: Bool {
        GameplayLayout.usesLandscapeMatchScoringLayout(verticalSizeClass: verticalSizeClass)
    }

    private var rowSpacing: CGFloat {
        usesLandscapeLayout ? DS.Spacing.s3 : DS.Spacing.s2
    }

    var body: some View {
        VStack(alignment: .leading, spacing: usesLandscapeLayout ? DS.Spacing.s2 : DS.Spacing.s1) {
            strokeLegend
            scorecardGrid
        }
    }

    // MARK: - Grid

    private var scorecardGrid: some View {
        HStack(alignment: .top, spacing: DS.Spacing.s2) {
            nameColumn
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: rowSpacing) {
                    holesHeaderRow
                    ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                        scoresRow(row, index: index)
                    }
                }
            }
        }
        .accessibilityIdentifier("golf_scorecard")
    }

    // MARK: - Name column

    private var nameColumn: some View {
        VStack(alignment: .leading, spacing: rowSpacing) {
            Text(L10n.string("play.golf.scorecard.playerHeader"))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Brand.textSecondary)
                .frame(width: nameColumnWidth, height: headerRowHeight, alignment: .leading)

            ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                playerNameCell(row, index: index)
            }
        }
    }

    // MARK: - Scrollable hole grid

    private var holesHeaderRow: some View {
        HStack(spacing: 0) {
            ForEach(1 ... courseLength, id: \.self) { hole in
                holeHeaderCell(hole)
            }

            Text(L10n.string("play.golf.scorecard.totalHeader"))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Brand.textSecondary)
                .frame(width: totalColumnWidth, alignment: .trailing)
        }
        .frame(height: headerRowHeight, alignment: .bottom)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(
            L10n.format("play.golf.holeStrip.accessibilityFormat", currentHole, courseLength)
        )
        .accessibilityIdentifier("golf_hole_strip")
    }

    private func holeHeaderCell(_ hole: Int) -> some View {
        VStack(spacing: 4) {
            Text("\(hole)")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(hole == currentHole ? Brand.amber : Brand.textSecondary)
            Circle()
                .fill(progressFillColor(for: hole))
                .frame(width: 8, height: 8)
                .overlay {
                    if hole == currentHole {
                        Circle().stroke(Brand.green, lineWidth: 1.5)
                    }
                }
        }
        .frame(width: holeColumnWidth)
        .accessibilityHidden(true)
    }

    @ViewBuilder
    private func scoresRow(_ row: PlayerRow, index: Int) -> some View {
        HStack(spacing: 0) {
            ForEach(Array(row.holeStrokes.enumerated()), id: \.offset) { holeIndex, strokes in
                strokeCell(strokes, holeNumber: holeIndex + 1, isActiveHole: holeIndex + 1 == currentHole && row.isActive)
            }

            Text(row.runningTotal > 0
                ? L10n.format("play.golf.scorecard.totalFormat", row.runningTotal)
                : "—")
                .font(usesLandscapeLayout
                    ? .subheadline.weight(.bold)
                    : .callout.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(row.isActive ? Brand.green : Brand.textPrimary)
                .frame(width: totalColumnWidth, alignment: .trailing)
        }
        .frame(minHeight: playerRowHeight, alignment: .center)
        .padding(.horizontal, usesLandscapeLayout ? DS.Spacing.s3 : DS.Spacing.s2)
        .padding(.vertical, usesLandscapeLayout ? DS.Spacing.s3 : DS.Spacing.s2)
        .background(row.isActive ? Brand.cardElevated : Brand.card,
                    in: RoundedRectangle(cornerRadius: DS.Radius.sm))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(rowAccessibilityLabel(row))
        .accessibilityIdentifier("golf_scoreboard_row_\(index)")
    }

    private func playerNameCell(_ row: PlayerRow, index: Int) -> some View {
        VStack(alignment: .leading, spacing: 2) {
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
                    .minimumScaleFactor(0.75)
            }
            if row.isLeading {
                Text(L10n.string("play.golf.leading"))
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Brand.green)
            }
        }
        .frame(width: nameColumnWidth, alignment: .leading)
        .frame(minHeight: playerRowHeight, alignment: .leading)
        .padding(.vertical, usesLandscapeLayout ? DS.Spacing.s3 : DS.Spacing.s2)
        .background(row.isActive ? Brand.cardElevated : Brand.card,
                    in: RoundedRectangle(cornerRadius: DS.Radius.sm))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(rowAccessibilityLabel(row))
        .accessibilityIdentifier("golf_scoreboard_name_\(index)")
    }

    @ViewBuilder
    private func strokeCell(_ strokes: Int?, holeNumber: Int, isActiveHole: Bool) -> some View {
        Group {
            if let strokes {
                Text("\(strokes)")
                    .font(usesLandscapeLayout ? .subheadline : .caption)
                    .monospacedDigit()
                    .foregroundStyle(strokeColor(strokes))
            } else {
                Text("·")
                    .font(usesLandscapeLayout ? .subheadline : .caption)
                    .foregroundStyle(Brand.textSecondary.opacity(isActiveHole ? 0.65 : 0.35))
            }
        }
        .frame(width: holeColumnWidth, alignment: .center)
    }

    // MARK: - Stroke legend

    private var strokeLegend: some View {
        Text(L10n.string("play.golf.strokeLegend"))
            .font(.caption2)
            .foregroundStyle(Brand.textSecondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .accessibilityLabel(L10n.string("play.golf.strokeLegend.accessibility"))
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

    private var nameColumnWidth: CGFloat { usesLandscapeLayout ? 108 : 92 }
    private var holeColumnWidth: CGFloat { courseLength <= 9 ? 28 : 22 }
    private var totalColumnWidth: CGFloat { 36 }
    private var headerRowHeight: CGFloat { 34 }
    private var playerRowHeight: CGFloat { usesLandscapeLayout ? 44 : 40 }

    private func progressFillColor(for hole: Int) -> Color {
        if hole < currentHole { return Brand.green }
        if hole == currentHole { return Brand.amber }
        return Brand.textSecondary.opacity(0.35)
    }

    private func strokeColor(_ strokes: Int) -> Color {
        switch strokes {
        case 1: return Brand.green
        case 2: return Brand.amber
        case 3: return Brand.textPrimary
        default: return Brand.textSecondary
        }
    }
}

// MARK: - Stroke helpers

enum GolfStrokePresentation {
    static func label(for strokes: Int) -> String {
        switch strokes {
        case 1: return L10n.string("play.golf.stroke.double")
        case 2: return L10n.string("play.golf.stroke.triple")
        case 3: return L10n.string("play.golf.stroke.single")
        default: return L10n.string("play.golf.stroke.miss")
        }
    }

    static func color(for strokes: Int) -> Color {
        switch strokes {
        case 1: return Brand.green
        case 2: return Brand.amber
        case 3: return Brand.textPrimary
        default: return Brand.textSecondary
        }
    }
}

// MARK: - Stroke label badge

/// Compact badge used in the match screen to show the label for a stroke value.
struct GolfStrokeBadge: View {
    let strokes: Int

    var body: some View {
        Text(GolfStrokePresentation.label(for: strokes))
            .font(.caption.weight(.semibold))
            .foregroundStyle(GolfStrokePresentation.color(for: strokes))
            .padding(.horizontal, DS.Spacing.s2)
            .padding(.vertical, 2)
            .background(GolfStrokePresentation.color(for: strokes).opacity(0.15), in: Capsule())
            .accessibilityLabel(
                L10n.format(
                    "play.golf.strokeAccessibilityFormat",
                    strokes,
                    GolfStrokePresentation.label(for: strokes)
                )
            )
    }
}
