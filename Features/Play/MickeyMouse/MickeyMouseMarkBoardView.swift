import SwiftUI

/// Descending target strip for Mickey Mouse: shows targets 20→12 then bull,
/// with per-player mark glyphs and a highlight on the active target.
struct MickeyMouseMarkBoardView: View {
    struct Row: Identifiable {
        let id: UUID
        let name: String
        /// Marks for each target, indexed to match `MickeyMouseEngine.targets`.
        let marksByTarget: [Int]
        let isActive: Bool
        let colorToken: PlayerColorToken
    }

    let rows: [Row]
    let currentTargetIndex: Int

    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private var targets: [MickeyMouseTarget] { MickeyMouseEngine.targets }

    private var usesCompactLayout: Bool {
        GameplayLayout.usesLandscapeMatchScoringLayout(verticalSizeClass: verticalSizeClass)
    }

    var body: some View {
        VStack(spacing: 0) {
            headerRow
            ForEach(Array(targets.enumerated()), id: \.offset) { index, target in
                targetRow(target: target, index: index)
                if index < targets.count - 1 {
                    Divider().overlay(Brand.cardElevated)
                }
            }
        }
        .background(Brand.card)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm))
    }

    private var headerRow: some View {
        HStack(spacing: 0) {
            Text(L10n.string("play.mickeyMouse.markBoard.targetHeader"))
                .font(.caption2.weight(.semibold))
                .foregroundStyle(Brand.textSecondary)
                .frame(width: targetColumnWidth, alignment: .center)
            ForEach(rows) { row in
                Text(row.name)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(
                        row.isActive
                            ? PlayerVisualViews.accentColor(token: row.colorToken)
                            : Brand.textSecondary
                    )
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: headerHeight)
        .padding(.horizontal, DS.Spacing.s2)
        .background(Brand.cardElevated.opacity(0.4))
    }

    @ViewBuilder
    private func targetRow(target: MickeyMouseTarget, index: Int) -> some View {
        let isActive = index == currentTargetIndex
        let isClosed = isTargetClosedByAll(at: index)
        HStack(spacing: 0) {
            // Target label
            Text(target.displayLabel)
                .font(
                    isActive
                        ? .subheadline.weight(.bold)
                        : .subheadline.weight(.regular)
                )
                .monospacedDigit()
                .foregroundStyle(isActive ? Brand.amber : Brand.textSecondary)
                .frame(width: targetColumnWidth)

            // Per-player mark glyphs
            ForEach(rows) { row in
                let marks = index < row.marksByTarget.count ? row.marksByTarget[index] : 0
                CricketMarkCell(
                    targetLabel: target.accessibilityLabel,
                    marks: marks,
                    colorToken: row.colorToken,
                    isKnockedOut: isClosed
                )
                .frame(maxWidth: .infinity)
                .frame(height: rowHeight)
                .background(row.isActive && isActive ? Brand.cardElevated.opacity(0.4) : Color.clear)
            }
        }
        .padding(.horizontal, DS.Spacing.s2)
        .background(isActive ? Brand.amber.opacity(0.08) : Color.clear)
        .overlay(alignment: .leading) {
            if isActive {
                Rectangle()
                    .fill(Brand.amber)
                    .frame(width: 3)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(targetRowAccessibilityLabel(target: target, index: index, isActive: isActive))
        .accessibilityIdentifier(isActive ? "mickeyMouse_activeTarget" : "mickeyMouse_target_\(index)")
    }

    private func isTargetClosedByAll(at index: Int) -> Bool {
        guard !rows.isEmpty else { return false }
        return rows.allSatisfy { row in
            guard index < row.marksByTarget.count else { return false }
            return row.marksByTarget[index] >= MickeyMouseEngine.marksToClose
        }
    }

    private func targetRowAccessibilityLabel(
        target: MickeyMouseTarget,
        index: Int,
        isActive: Bool
    ) -> String {
        var parts: [String] = [target.accessibilityLabel]
        if isActive {
            parts.append(L10n.string("play.mickeyMouse.markBoard.activeTarget"))
        }
        for row in rows {
            let marks = index < row.marksByTarget.count ? row.marksByTarget[index] : 0
            let state: String
            switch marks {
            case 0: state = L10n.string("cricket.mark.open")
            case 1: state = L10n.string("cricket.mark.one")
            case 2: state = L10n.string("cricket.mark.two")
            default: state = L10n.string("cricket.mark.closed")
            }
            parts.append(L10n.format("cricket.mark.accessibilityFormat", row.name, state))
        }
        return parts.joined(separator: ", ")
    }

    // MARK: - Metrics

    private var targetColumnWidth: CGFloat { usesCompactLayout ? 24 : 28 }
    private var rowHeight: CGFloat { usesCompactLayout ? 28 : 34 }
    private var headerHeight: CGFloat { usesCompactLayout ? 28 : 36 }
}
