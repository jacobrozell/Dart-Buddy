import SwiftUI

struct CricketBoardTargetColumn: View {
    let width: CGFloat
    let sizing: CricketBoardSizing
    private let targets = CricketTarget.allCases

    var body: some View {
        VStack(spacing: 0) {
            Color.clear
                .frame(width: width, height: sizing.headerHeight)
            ForEach(targets, id: \.rawValue) { target in
                Text(label(for: target))
                    .font(.subheadline.weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(Brand.textSecondary)
                    .frame(width: width, height: sizing.markRowHeight)
                Divider().overlay(Brand.cardElevated)
            }
            Color.clear
                .frame(width: width, height: sizing.columnFooterHeight)
        }
    }

    private func label(for target: CricketTarget) -> String {
        target == .bull ? L10n.string("cricket.target.bull") : target.rawValue
    }
}

struct CricketBoardPlayerColumn: View {
    let column: CricketBoardView.Column
    /// Fixed width when scrolling; `nil` distributes with `maxWidth: .infinity`.
    let width: CGFloat?
    let sizing: CricketBoardSizing
    let allColumns: [CricketBoardView.Column]
    private let targets = CricketTarget.allCases

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(spacing: 0) {
            columnHeader
            ForEach(targets, id: \.rawValue) { target in
                let isKnockedOut = CricketBoardView.isTargetKnockedOut(columns: allColumns, target: target)
                CricketMarkCell(
                    targetLabel: label(for: target),
                    marks: column.marks[target.rawValue] ?? 0,
                    colorToken: column.colorToken,
                    isKnockedOut: isKnockedOut
                )
                .modifier(CricketBoardColumnWidthModifier(width: width, height: sizing.markRowHeight))
                .background(column.isActive ? CricketBoardMetrics.activeColumnFill : Color.clear)
                .opacity(isKnockedOut ? CricketBoardMetrics.knockedOutOpacity : 1)
                Divider().overlay(Brand.cardElevated)
            }
            CricketBoardPlayerColumnFooter(column: column, sizing: sizing)
        }
        .background(column.isActive ? CricketBoardMetrics.activeColumnFill.opacity(0.15) : Color.clear)
        .overlay {
            if column.isClosureHighlight {
                Rectangle()
                    .stroke(Brand.amber, lineWidth: 2)
            }
        }
        .scaleEffect(column.isClosureHighlight && !reduceMotion ? 1.03 : 1)
        .animation(
            reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.6),
            value: column.isClosureHighlight
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(column.accessibilitySummary)
        .accessibilityIdentifier(column.isActive ? "cricket_column_active" : "cricket_column")
    }

    private var columnHeader: some View {
        VStack(spacing: 2) {
            Text(column.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(
                    column.isActive
                        ? PlayerVisualViews.accentColor(token: column.colorToken)
                        : Brand.textPrimary
                )
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text("\(column.score)")
                .font(.title3.weight(.heavy))
                .foregroundStyle(Brand.textPrimary)
            if column.isActive {
                Rectangle()
                    .fill(PlayerVisualViews.accentColor(token: column.colorToken))
                    .frame(height: 2)
            } else {
                Color.clear.frame(height: 2)
            }
        }
        .modifier(CricketBoardColumnWidthModifier(width: width))
        .padding(.vertical, sizing == .landscapeCompact ? DS.Spacing.s1 : DS.Spacing.s2)
        .background(column.isActive ? CricketBoardMetrics.activeColumnFill : Color.clear)
    }

    private func label(for target: CricketTarget) -> String {
        target == .bull ? L10n.string("cricket.target.bull") : target.rawValue
    }
}

struct CricketBoardPlayerColumnFooter: View {
    let column: CricketBoardView.Column
    let sizing: CricketBoardSizing

    private var verticalPadding: CGFloat {
        sizing == .landscapeCompact ? DS.Spacing.s1 : DS.Spacing.s2
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(L10n.format("play.cricket.column.footer.darts", column.dartsThrown))
                .font(.caption2.monospacedDigit())
                .foregroundStyle(Brand.textPrimary)
                .accessibilityIdentifier(column.isActive ? "cricket_column_darts" : "")
            HStack(spacing: 4) {
                Image(systemName: "chart.bar.fill")
                    .font(.caption2)
                    .foregroundStyle(Brand.textSecondary)
                Text(String(format: "%.2f", column.marksPerRound))
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(Brand.textPrimary)
                    .accessibilityIdentifier(column.isActive ? "cricket_column_mpr" : "")
            }
            if column.setsEnabled {
                Text(L10n.format("play.cricket.column.footer.sets", column.setsWon))
                    .font(.caption2)
                    .foregroundStyle(Brand.textSecondary)
            }
        }
        .padding(.horizontal, 4)
        .padding(.vertical, verticalPadding)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: sizing.columnFooterHeight, alignment: .topLeading)
    }
}

/// iPhone landscape: targets as columns, active player only — uses width instead of height.
struct CricketTransposedBoardView: View {
    let column: CricketBoardView.Column
    let allColumns: [CricketBoardView.Column]

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var sizing: CricketBoardSizing {
        CricketBoardSizing.resolve(
            verticalSizeClass: verticalSizeClass,
            dynamicTypeSize: dynamicTypeSize
        )
    }

    private let targets = CricketTarget.allCases

    var body: some View {
        VStack(spacing: 0) {
            transposedHeader
            HStack(spacing: 0) {
                ForEach(targets, id: \.rawValue) { target in
                    transposedTargetColumn(target: target)
                }
            }
            CricketBoardPlayerColumnFooter(column: column, sizing: sizing)
        }
        .background(Brand.card)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm))
        .overlay {
            if column.isClosureHighlight {
                RoundedRectangle(cornerRadius: DS.Radius.sm)
                    .stroke(Brand.amber, lineWidth: 2)
            }
        }
        .scaleEffect(column.isClosureHighlight && !reduceMotion ? 1.02 : 1)
        .animation(
            reduceMotion ? nil : .spring(response: 0.35, dampingFraction: 0.6),
            value: column.isClosureHighlight
        )
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(column.accessibilitySummary)
        .accessibilityIdentifier("cricket_column_active")
    }

    private var transposedHeader: some View {
        VStack(spacing: 2) {
            Text(column.name)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(PlayerVisualViews.accentColor(token: column.colorToken))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Text("\(column.score)")
                .font(.title3.weight(.heavy))
                .foregroundStyle(Brand.textPrimary)
            Rectangle()
                .fill(PlayerVisualViews.accentColor(token: column.colorToken))
                .frame(height: 2)
        }
        .padding(.vertical, sizing == .landscapeCompact ? DS.Spacing.s1 : DS.Spacing.s2)
        .frame(maxWidth: .infinity)
        .background(CricketBoardMetrics.activeColumnFill)
    }

    private func transposedTargetColumn(target: CricketTarget) -> some View {
        let isKnockedOut = CricketBoardView.isTargetKnockedOut(columns: allColumns, target: target)
        return VStack(spacing: 0) {
            Text(label(for: target))
                .font(.caption2.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(Brand.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: sizing == .landscapeCompact ? 18 : 22)
            CricketMarkCell(
                targetLabel: label(for: target),
                marks: column.marks[target.rawValue] ?? 0,
                colorToken: column.colorToken,
                isKnockedOut: isKnockedOut
            )
            .frame(maxWidth: .infinity)
            .frame(height: sizing.markRowHeight)
            .background(CricketBoardMetrics.activeColumnFill)
            .opacity(isKnockedOut ? CricketBoardMetrics.knockedOutOpacity : 1)
            Divider().overlay(Brand.cardElevated)
        }
        .frame(maxWidth: .infinity)
    }

    private func label(for target: CricketTarget) -> String {
        target == .bull ? L10n.string("cricket.target.bull") : target.rawValue
    }
}

/// Standard cricket mark glyph: "/" for one, "X" for two, and a circled "X"
/// (closed) for three. Closed marks use the column player's identity color.
struct CricketMarkCell: View {
    let targetLabel: String
    let marks: Int
    let colorToken: PlayerColorToken
    var isKnockedOut: Bool = false

    private var tint: Color {
        if isKnockedOut {
            return Brand.textSecondary
        }
        return marks >= 3 ? PlayerVisualViews.accentColor(token: colorToken) : Brand.textPrimary
    }

    var body: some View {
        ZStack {
            if marks >= 1 {
                DiagonalStroke(downward: false).stroke(tint, style: .init(lineWidth: 2.5, lineCap: .round))
            }
            if marks >= 2 {
                DiagonalStroke(downward: true).stroke(tint, style: .init(lineWidth: 2.5, lineCap: .round))
            }
            if marks >= 3 {
                Circle().stroke(tint, lineWidth: 2.5)
            }
        }
        .frame(width: 26, height: 26)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityLabel(accessibilityLabel)
    }

    private var accessibilityLabel: String {
        let state: String
        switch marks {
        case 0: state = L10n.string("cricket.mark.open")
        case 1: state = L10n.string("cricket.mark.one")
        case 2: state = L10n.string("cricket.mark.two")
        default: state = L10n.string("cricket.mark.closed")
        }
        if isKnockedOut {
            return L10n.format("cricket.mark.knockedOutAccessibilityFormat", targetLabel, state)
        }
        return L10n.format("cricket.mark.accessibilityFormat", targetLabel, state)
    }
}

private struct CricketBoardColumnWidthModifier: ViewModifier {
    let width: CGFloat?
    var height: CGFloat?

    func body(content: Content) -> some View {
        if let width {
            if let height {
                content.frame(width: width, height: height)
            } else {
                content.frame(width: width)
            }
        } else if let height {
            content.frame(maxWidth: .infinity).frame(height: height)
        } else {
            content.frame(maxWidth: .infinity)
        }
    }
}

private struct DiagonalStroke: Shape {
    let downward: Bool

    func path(in rect: CGRect) -> Path {
        var path = Path()
        if downward {
            path.move(to: CGPoint(x: rect.minX, y: rect.minY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        } else {
            path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        }
        return path
    }
}
