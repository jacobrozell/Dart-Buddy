import SwiftUI

/// Sequential mark-board for American Cricket.
///
/// Shows all seven targets (20→15→bull) in a fixed vertical stack.
/// The **active target row** is highlighted; closed targets are dimmed.
/// Reuses `CricketMarkCell` for consistent mark glyphs.
struct AmericanCricketBoardView: View {
    struct Column: Identifiable {
        let id: UUID
        let name: String
        /// Marks dictionary keyed by `CricketTarget.rawValue`.
        let marks: [String: Int]
        let score: Int
        let isActive: Bool
        let colorToken: PlayerColorToken
        /// The current active target index so each column can highlight the correct row.
        let activeTargetIndex: Int

        var accessibilitySummary: String {
            L10n.format("play.cricket.column.accessibilityFormat", name, score)
        }
    }

    let columns: [Column]
    var activeColumnScrollID: UUID?

    @ScaledMetric(relativeTo: .body) private var playerColumnWidth: CGFloat = 84
    @ScaledMetric(relativeTo: .body) private var targetColumnWidth: CGFloat = 28
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var sizing: CricketBoardSizing {
        CricketBoardSizing.resolve(
            verticalSizeClass: verticalSizeClass,
            dynamicTypeSize: dynamicTypeSize
        )
    }

    private let targets = americanCricketTargets

    var body: some View {
        GeometryReader { geometry in
            let layout = CricketBoardColumnLayout.resolve(
                availableWidth: geometry.size.width,
                playerCount: columns.count,
                minimumPlayerColumnWidth: playerColumnWidth,
                targetColumnWidth: targetColumnWidth
            )
            boardContent(layout: layout, sizing: sizing)
                .frame(width: geometry.size.width, alignment: .topLeading)
        }
        .frame(height: sizing.boardBodyHeight)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Brand.card)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm))
    }

    @ViewBuilder
    private func boardContent(layout: CricketBoardColumnLayout, sizing: CricketBoardSizing) -> some View {
        HStack(alignment: .top, spacing: 0) {
            AmericanCricketTargetColumn(
                targets: targets,
                width: targetColumnWidth,
                sizing: sizing,
                activeTargetIndex: columns.first?.activeTargetIndex ?? 0
            )
            .fixedSize(horizontal: true, vertical: false)

            if layout.scrollsHorizontally, let columnWidth = layout.fixedPlayerColumnWidth {
                scrollingPlayerColumns(width: columnWidth, sizing: sizing)
            } else {
                distributedPlayerColumns(sizing: sizing)
            }
        }
    }

    private func distributedPlayerColumns(sizing: CricketBoardSizing) -> some View {
        HStack(spacing: 0) {
            ForEach(columns) { column in
                AmericanCricketPlayerColumn(
                    column: column,
                    width: nil,
                    sizing: sizing,
                    targets: targets
                )
                .frame(maxWidth: .infinity)
                .id(column.id)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func scrollingPlayerColumns(width columnWidth: CGFloat, sizing: CricketBoardSizing) -> some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: columns.count > 3) {
                HStack(spacing: 0) {
                    ForEach(columns) { column in
                        AmericanCricketPlayerColumn(
                            column: column,
                            width: columnWidth,
                            sizing: sizing,
                            targets: targets
                        )
                        .frame(width: columnWidth)
                        .id(column.id)
                    }
                }
                .scrollTargetLayout()
            }
            .onChange(of: activeColumnScrollID) { _, newID in
                guard let newID else { return }
                if reduceMotion {
                    proxy.scrollTo(newID, anchor: .center)
                } else {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        proxy.scrollTo(newID, anchor: .center)
                    }
                }
            }
            .onAppear {
                if let activeColumnScrollID {
                    proxy.scrollTo(activeColumnScrollID, anchor: .center)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: - Target column (left-hand labels)

struct AmericanCricketTargetColumn: View {
    let targets: [CricketTarget]
    let width: CGFloat
    let sizing: CricketBoardSizing
    let activeTargetIndex: Int

    var body: some View {
        VStack(spacing: 0) {
            Color.clear.frame(width: width, height: sizing.headerHeight)
            ForEach(Array(targets.enumerated()), id: \.element.rawValue) { index, target in
                let isActive = index == activeTargetIndex
                let isClosed = index < activeTargetIndex
                Text(label(for: target))
                    .font(.subheadline.weight(isActive ? .bold : .regular))
                    .monospacedDigit()
                    .foregroundStyle(isActive ? Brand.amber : (isClosed ? Brand.textSecondary.opacity(0.4) : Brand.textSecondary))
                    .frame(width: width, height: sizing.markRowHeight)
                    .background(isActive ? Brand.amber.opacity(0.08) : Color.clear)
                Divider().overlay(Brand.cardElevated)
            }
            Color.clear.frame(width: width, height: sizing.columnFooterHeight)
        }
    }

    private func label(for target: CricketTarget) -> String {
        target == .bull ? L10n.string("cricket.target.bull") : target.rawValue
    }
}

// MARK: - Player column

struct AmericanCricketPlayerColumn: View {
    let column: AmericanCricketBoardView.Column
    let width: CGFloat?
    let sizing: CricketBoardSizing
    let targets: [CricketTarget]

    var body: some View {
        VStack(spacing: 0) {
            columnHeader
            ForEach(Array(targets.enumerated()), id: \.element.rawValue) { index, target in
                let isActiveRow = index == column.activeTargetIndex
                let isClosedRow = index < column.activeTargetIndex
                let marks = column.marks[target.rawValue] ?? 0
                CricketMarkCell(
                    targetLabel: label(for: target),
                    marks: marks,
                    colorToken: column.colorToken,
                    isKnockedOut: isClosedRow
                )
                .modifier(AmericanCricketColumnWidthModifier(width: width, height: sizing.markRowHeight))
                .background(
                    isActiveRow && column.isActive
                        ? CricketBoardMetrics.activeColumnFill
                        : (isActiveRow ? Brand.amber.opacity(0.04) : Color.clear)
                )
                .opacity(isClosedRow ? CricketBoardMetrics.knockedOutOpacity : 1)
                Divider().overlay(Brand.cardElevated)
            }
            columnFooter
        }
        .background(column.isActive ? CricketBoardMetrics.activeColumnFill.opacity(0.15) : Color.clear)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(column.accessibilitySummary)
        .accessibilityIdentifier(column.isActive ? "americanCricket_column_active" : "americanCricket_column")
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
            if column.score > 0 {
                Text(L10n.format("play.americanCricket.pointsFormat", column.score))
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(Brand.textPrimary)
            } else {
                Text("0")
                    .font(.title3.weight(.heavy))
                    .foregroundStyle(Brand.textSecondary.opacity(0.5))
            }
            if column.isActive {
                Rectangle()
                    .fill(PlayerVisualViews.accentColor(token: column.colorToken))
                    .frame(height: 2)
            } else {
                Color.clear.frame(height: 2)
            }
        }
        .modifier(AmericanCricketColumnWidthModifier(width: width))
        .padding(.vertical, sizing == .landscapeCompact ? DS.Spacing.s1 : DS.Spacing.s2)
        .background(column.isActive ? CricketBoardMetrics.activeColumnFill : Color.clear)
    }

    private var columnFooter: some View {
        Text(L10n.format("play.cricket.column.footer.darts", 0))
            .font(.caption2.monospacedDigit())
            .foregroundStyle(Brand.textSecondary)
            .padding(.horizontal, 4)
            .padding(.vertical, sizing == .landscapeCompact ? DS.Spacing.s1 : DS.Spacing.s2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: sizing.columnFooterHeight, alignment: .topLeading)
    }

    private func label(for target: CricketTarget) -> String {
        target == .bull ? L10n.string("cricket.target.bull") : target.rawValue
    }
}

// MARK: - Width modifier

private struct AmericanCricketColumnWidthModifier: ViewModifier {
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
