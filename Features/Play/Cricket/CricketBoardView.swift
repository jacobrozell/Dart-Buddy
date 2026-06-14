import SwiftUI

enum CricketBoardMetrics {
    static let targetColumnWidth: CGFloat = 28
    static let playerColumnWidth: CGFloat = 84
    static let scrollIndicatorPlayerThreshold = 3
    static let markRowHeight: CGFloat = DS.Spacing.s2 * 4
    /// Footer region height (darts + MPR + vertical inset); matches `CricketBoardPlayerColumnFooter`.
    static let columnFooterHeight: CGFloat = 48
    static let headerHeight: CGFloat = 52
    static let activeColumnFill = Brand.cardElevated.opacity(0.35)
    static let knockedOutOpacity: Double = 0.42

    static var boardBodyHeight: CGFloat {
        CricketBoardSizing.standard.boardBodyHeight
    }
}

/// Row/header/footer sizing; landscape uses a denser grid so the full board fits on screen.
struct CricketBoardSizing: Equatable {
    let markRowHeight: CGFloat
    let headerHeight: CGFloat
    let columnFooterHeight: CGFloat

    static let standard = CricketBoardSizing(
        markRowHeight: CricketBoardMetrics.markRowHeight,
        headerHeight: CricketBoardMetrics.headerHeight,
        columnFooterHeight: CricketBoardMetrics.columnFooterHeight
    )

    static let landscapeCompact = CricketBoardSizing(
        markRowHeight: 28,
        headerHeight: 44,
        /// Darts + MPR row + vertical inset (padding lives inside this height).
        columnFooterHeight: 40
    )

    static func accessibility(dynamicTypeSize: DynamicTypeSize) -> CricketBoardSizing {
        let scale = DynamicTypeLayout.accessibilityScale(for: dynamicTypeSize)
        let captionLine = 14 * scale
        // Darts + MPR share one row at AX; optional sets line below.
        let footerContent = captionLine * 2.5 + DS.Spacing.s2 * 2
        return CricketBoardSizing(
            markRowHeight: max(44, CricketBoardMetrics.markRowHeight * scale),
            headerHeight: max(56, CricketBoardMetrics.headerHeight * scale),
            columnFooterHeight: max(68, footerContent)
        )
    }

    var boardBodyHeight: CGFloat {
        headerHeight
            + CGFloat(CricketTarget.allCases.count) * markRowHeight
            + columnFooterHeight
    }

    /// Grows mark rows so the board body fills `height` (landscape iPhone side-by-side layout).
    func scaledToFill(height: CGFloat) -> CricketBoardSizing {
        let current = boardBodyHeight
        guard height > current else { return self }
        let extraPerRow = (height - current) / CGFloat(CricketTarget.allCases.count)
        return CricketBoardSizing(
            markRowHeight: markRowHeight + extraPerRow,
            headerHeight: headerHeight,
            columnFooterHeight: columnFooterHeight
        )
    }

    /// Shrinks or grows rows so the board body fits `height` (iPad landscape).
    func scaledToFit(height: CGFloat) -> CricketBoardSizing {
        guard height > 0 else { return self }
        let current = boardBodyHeight
        if abs(height - current) < 0.5 { return self }
        if height > current { return scaledToFill(height: height) }

        let scale = height / current
        return CricketBoardSizing(
            markRowHeight: markRowHeight * scale,
            headerHeight: headerHeight * scale,
            columnFooterHeight: columnFooterHeight * scale
        )
    }

    static func resolve(
        verticalSizeClass: UserInterfaceSizeClass?,
        dynamicTypeSize: DynamicTypeSize
    ) -> CricketBoardSizing {
        if GameplayLayout.usesAccessibilityMatchScoringLayout(dynamicTypeSize: dynamicTypeSize) {
            return .accessibility(dynamicTypeSize: dynamicTypeSize)
        }
        if GameplayLayout.usesLandscapeMatchScoringLayout(verticalSizeClass: verticalSizeClass) {
            return .landscapeCompact
        }
        return .standard
    }
}

/// How player columns use horizontal space for the current board width.
struct CricketBoardColumnLayout: Equatable {
    let scrollsHorizontally: Bool
    let fixedPlayerColumnWidth: CGFloat?

    static func resolve(
        availableWidth: CGFloat,
        playerCount: Int,
        minimumPlayerColumnWidth: CGFloat = CricketBoardMetrics.playerColumnWidth,
        targetColumnWidth: CGFloat = CricketBoardMetrics.targetColumnWidth,
        scrollThreshold: Int = CricketBoardMetrics.scrollIndicatorPlayerThreshold
    ) -> CricketBoardColumnLayout {
        guard playerCount > 0 else {
            return CricketBoardColumnLayout(scrollsHorizontally: false, fixedPlayerColumnWidth: minimumPlayerColumnWidth)
        }

        let playerArea = max(0, availableWidth - targetColumnWidth)
        let minimumTotal = minimumPlayerColumnWidth * CGFloat(playerCount)

        if playerCount > scrollThreshold || minimumTotal > playerArea {
            return CricketBoardColumnLayout(
                scrollsHorizontally: true,
                fixedPlayerColumnWidth: minimumPlayerColumnWidth
            )
        }

        return CricketBoardColumnLayout(scrollsHorizontally: false, fixedPlayerColumnWidth: nil)
    }
}

/// Cricket scoreboard: pinned target labels plus horizontally scrollable player columns.
struct CricketBoardView: View {
    struct Column: Identifiable {
        let id: UUID
        let name: String
        let score: Int
        let marks: [String: Int]
        let isActive: Bool
        let colorToken: PlayerColorToken
        let dartsThrown: Int
        let marksPerRound: Double
        let setsWon: Int
        let setsEnabled: Bool
        var isClosureHighlight: Bool = false

        var accessibilitySummary: String {
            var parts = [L10n.format("play.cricket.column.accessibilityFormat", name, score)]
            parts.append(L10n.format("play.cricket.column.footer.darts", dartsThrown))
            parts.append(L10n.format("play.cricket.column.accessibility.mprFormat", marksPerRound))
            if isActive {
                parts.append(L10n.string("play.x01.turn.active"))
            }
            return parts.joined(separator: ". ")
        }
    }

    let columns: [Column]
    var activeColumnScrollID: UUID?
    /// When true, mark rows grow to use the full scoreboard column height (iPhone landscape).
    var fillsAvailableHeight: Bool = false

    @ScaledMetric(relativeTo: .body) private var playerColumnWidth = CricketBoardMetrics.playerColumnWidth
    @ScaledMetric(relativeTo: .body) private var targetColumnWidth = CricketBoardMetrics.targetColumnWidth
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var sizing: CricketBoardSizing {
        CricketBoardSizing.resolve(
            verticalSizeClass: verticalSizeClass,
            dynamicTypeSize: dynamicTypeSize
        )
    }

    private var showsPlayerScrollIndicator: Bool {
        columns.count > CricketBoardMetrics.scrollIndicatorPlayerThreshold
    }

    var body: some View {
        GeometryReader { geometry in
            let effectiveSizing = fillsAvailableHeight
                ? sizing.scaledToFit(height: geometry.size.height)
                : sizing
            let layout = CricketBoardColumnLayout.resolve(
                availableWidth: geometry.size.width,
                playerCount: columns.count,
                minimumPlayerColumnWidth: playerColumnWidth,
                targetColumnWidth: targetColumnWidth
            )
            boardContent(layout: layout, sizing: effectiveSizing)
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
        }
        .frame(height: fillsAvailableHeight ? nil : sizing.boardBodyHeight)
        .frame(maxHeight: fillsAvailableHeight ? .infinity : nil)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Brand.card)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.sm))
    }

    @ViewBuilder
    private func boardContent(layout: CricketBoardColumnLayout, sizing: CricketBoardSizing) -> some View {
        HStack(alignment: .top, spacing: 0) {
            CricketBoardTargetColumn(width: targetColumnWidth, sizing: sizing)
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
                CricketBoardPlayerColumn(
                    column: column,
                    width: nil,
                    sizing: sizing,
                    allColumns: columns
                )
                .frame(maxWidth: .infinity)
                .id(column.id)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private func scrollingPlayerColumns(width columnWidth: CGFloat, sizing: CricketBoardSizing) -> some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: showsPlayerScrollIndicator) {
                HStack(spacing: 0) {
                    ForEach(columns) { column in
                        CricketBoardPlayerColumn(
                            column: column,
                            width: columnWidth,
                            sizing: sizing,
                            allColumns: columns
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

extension CricketBoardView {
    static var markTargetCount: Int { CricketTarget.allCases.count }

    static func isTargetKnockedOut(columns: [Column], target: CricketTarget) -> Bool {
        guard !columns.isEmpty else { return false }
        return columns.allSatisfy { ($0.marks[target.rawValue] ?? 0) >= 3 }
    }
}
