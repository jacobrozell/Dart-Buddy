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
        return CricketBoardSizing(
            markRowHeight: max(44, CricketBoardMetrics.markRowHeight * scale),
            headerHeight: max(56, CricketBoardMetrics.headerHeight * scale),
            columnFooterHeight: max(56, CricketBoardMetrics.columnFooterHeight * scale)
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
        .animation(MotionPolicy.standardAnimation(reduceMotion: reduceMotion), value: column.isActive)
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

extension CricketBoardView {
    static var markTargetCount: Int { CricketTarget.allCases.count }

    static func isTargetKnockedOut(columns: [Column], target: CricketTarget) -> Bool {
        guard !columns.isEmpty else { return false }
        return columns.allSatisfy { ($0.marks[target.rawValue] ?? 0) >= 3 }
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
        .motionMarkIncrementPulse(marks: marks)
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

/// Tap-to-mark input: tap a target to add a dart for the active player. The
/// sticky DOUBLE / TRIPLE modifiers add 2 / 3 marks in one tap (Bull doubles to
/// the inner bull). Auto-submits at three darts; manual submit ends a short visit.
struct CricketTapPad: View {
    @Binding var enteredDarts: [DartInput]
    @Binding var selectedMultiplier: DartMultiplier
    let canSubmit: Bool
    let onSubmit: () -> Void
    let onUndoTurn: () -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.matchLayoutPlayerCount) private var matchLayoutPlayerCount
    @ScaledMetric(relativeTo: .body) private var keyMinHeight: CGFloat = 52
    @ScaledMetric(relativeTo: .caption) private var visitSlotMinHeight: CGFloat = 34

    private var usesAccessibilityLayout: Bool {
        GameplayLayout.usesAccessibilityMatchScoringLayout(dynamicTypeSize: dynamicTypeSize)
    }

    private var usesLandscapeCompactLayout: Bool {
        !usesAccessibilityLayout
            && (
                GameplayLayout.usesLandscapeMatchScoringLayout(verticalSizeClass: verticalSizeClass)
                    || GameplayLayout.usesSideBySideBottomScoringRegion(
                        horizontalSizeClass: horizontalSizeClass,
                        verticalSizeClass: verticalSizeClass,
                        playerCount: matchLayoutPlayerCount
                    )
            )
    }

    /// iPhone landscape: pad spans the full width below the board, so keys lay out wide and
    /// short. iPad landscape keeps the narrow sidebar pad (`usesLandscapeCompactLayout`).
    private var usesLandscapeWideLayout: Bool {
        GameplayLayout.usesCricketFullWidthLandscapePad(
            horizontalSizeClass: horizontalSizeClass,
            verticalSizeClass: verticalSizeClass,
            playerCount: matchLayoutPlayerCount,
            dynamicTypeSize: dynamicTypeSize
        )
    }

    private var usesIPadSideBySidePad: Bool {
        false
    }

    private var padSpacing: CGFloat {
        if usesAccessibilityLayout {
            return ScoringPadStyle.accessibilitySpacing
        }
        if usesIPadSideBySidePad {
            return GameplayLayout.iPadSideBySidePadSpacing
        }
        if usesLandscapeCompactLayout {
            return usesLandscapeWideLayout ? 6 : 4
        }
        return ScoringPadStyle.compactSpacing
    }

    private var displayKeyMinHeight: CGFloat {
        if usesAccessibilityLayout {
            return min(keyMinHeight, 56)
        }
        if usesIPadSideBySidePad {
            return GameplayLayout.iPadSideBySidePadKeyMinHeight
        }
        if usesLandscapeWideLayout {
            return 44
        }
        if usesLandscapeCompactLayout {
            return 40
        }
        return min(keyMinHeight, 48)
    }

    private var displayBullMissKeyMinHeight: CGFloat {
        if usesAccessibilityLayout || usesIPadSideBySidePad {
            return displayKeyMinHeight
        }
        if usesLandscapeWideLayout {
            return 44
        }
        if usesLandscapeCompactLayout {
            return 36
        }
        return 44
    }

    private var displayVisitSlotMinHeight: CGFloat {
        if usesAccessibilityLayout {
            return min(visitSlotMinHeight, 40)
        }
        if usesIPadSideBySidePad {
            return 40
        }
        if usesLandscapeCompactLayout {
            return usesLandscapeWideLayout ? 30 : 28
        }
        return min(visitSlotMinHeight, 30)
    }

    private let numberRows: [[String]] = [
        ["20", "19", "18"],
        ["17", "16", "15"]
    ]

    private let accessibilitySegments: [Int] = [20, 19, 18, 17, 16, 15]

    var body: some View {
        if usesAccessibilityLayout {
            accessibilityPad
        } else if usesLandscapeWideLayout {
            landscapeWidePad
        } else if usesLandscapeCompactLayout {
            landscapeCompactPad
        } else {
            compactPad
        }
    }

    /// iPhone landscape full-width pad: one row of segments + bull/miss, then modifiers + enter.
    /// Laying keys out wide keeps the pad short so the board stays visible above it.
    private var landscapeWidePad: some View {
        VStack(spacing: padSpacing) {
            visitPreview
            HStack(spacing: padSpacing) {
                ForEach(accessibilitySegments, id: \.self) { segment in
                    numberKey(segment, title: String(segment))
                }
                bullKey()
                missKey()
            }
            HStack(spacing: padSpacing) {
                modifierKey(.double, identifier: "cricket_double")
                modifierKey(.triple, identifier: "cricket_triple")
                ScoringPadIconKey(
                    systemImage: "arrow.uturn.backward",
                    minHeight: displayKeyMinHeight,
                    accessibilityLabel: L10n.string("scoring.undoLastTurn"),
                    identifier: "cricket_undo",
                    action: undo
                )
                enterButton()
            }
        }
    }

    private var iPadSideBySidePad: some View {
        GeometryReader { geometry in
            landscapeCompactPad(keyHeight: iPadSideBySideKeyHeight(for: geometry.size.height))
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
        }
    }

    private func iPadSideBySideKeyHeight(for availableHeight: CGFloat) -> CGFloat {
        let gridRows = 4
        let visitHeight = displayVisitSlotMinHeight
        let controlHeight = GameplayLayout.iPadSideBySidePadKeyMinHeight
        let bullMissHeight = displayBullMissKeyMinHeight
        let spacingBudget = padSpacing * CGFloat(gridRows + 3)
        let overhead = visitHeight + bullMissHeight + controlHeight + controlHeight + spacingBudget
        let distributable = max(0, availableHeight - overhead)
        let grown = GameplayLayout.iPadSideBySidePadKeyMinHeight + (distributable / CGFloat(gridRows))
        return min(grown, GameplayLayout.iPadSideBySidePadKeyMaxHeight)
    }

    private func landscapeCompactPad(keyHeight: CGFloat? = nil) -> some View {
        let columns = [
            GridItem(.flexible(), spacing: padSpacing),
            GridItem(.flexible(), spacing: padSpacing)
        ]
        return VStack(spacing: padSpacing) {
            visitPreview
            LazyVGrid(columns: columns, spacing: padSpacing) {
                ForEach(accessibilitySegments, id: \.self) { segment in
                    numberKey(segment, title: String(segment), minHeight: keyHeight)
                }
            }
            bullMissRow(showSpacer: false, minHeight: keyHeight)
            controlRow(minHeight: keyHeight)
            enterButton(minHeight: keyHeight)
        }
    }

    private var landscapeCompactPad: some View {
        landscapeCompactPad(keyHeight: nil)
    }

    private var compactPad: some View {
        VStack(spacing: padSpacing) {
            visitPreview
            ForEach(numberRows, id: \.self) { row in
                HStack(spacing: padSpacing) {
                    ForEach(row, id: \.self) { value in
                        numberKey(Int(value) ?? 0, title: value)
                    }
                }
            }
            bullMissRow(showSpacer: true)
            controlRow()
            enterButton()
        }
    }

    private var accessibilityPad: some View {
        let columns = [
            GridItem(.flexible(), spacing: padSpacing),
            GridItem(.flexible(), spacing: padSpacing)
        ]
        return VStack(spacing: padSpacing) {
            visitPreview
            LazyVGrid(columns: columns, spacing: padSpacing) {
                ForEach(accessibilitySegments, id: \.self) { segment in
                    numberKey(segment, title: String(segment))
                }
            }
            bullMissRow(showSpacer: false)
            controlRow()
            enterButton()
        }
    }

    private func numberKey(_ segment: Int, title: String, minHeight: CGFloat? = nil) -> some View {
        ScoringPadKey(
            title: title,
            font: usesAccessibilityLayout || usesIPadSideBySidePad
                ? .title3.weight(.semibold)
                : .body.weight(.semibold),
            minHeight: minHeight ?? displayKeyMinHeight,
            accessibilityLabel: DartInput.padKeyAccessibilityLabel(
                segmentValue: segment,
                armedMultiplier: selectedMultiplier
            ),
            identifier: "cricket_\(title)",
            action: { appendNumber(segment) }
        )
    }

    @ViewBuilder
    private func bullMissRow(showSpacer: Bool, minHeight: CGFloat? = nil) -> some View {
        HStack(spacing: padSpacing) {
            bullKey(minHeight: minHeight)
            missKey(minHeight: minHeight)
            if showSpacer {
                Color.clear
                    .frame(maxWidth: .infinity, minHeight: displayBullMissKeyMinHeight)
                    .accessibilityHidden(true)
            }
        }
    }

    private func bullKey(minHeight: CGFloat? = nil) -> some View {
        ScoringPadKey(
            title: L10n.string("scoring.pad.bullLabel"),
            font: usesAccessibilityLayout || usesIPadSideBySidePad
                ? .title3.weight(.semibold)
                : .body.weight(.semibold),
            minHeight: minHeight ?? displayBullMissKeyMinHeight,
            accessibilityLabel: DartInput.padKeyAccessibilityLabel(segmentValue: 25, armedMultiplier: selectedMultiplier),
            identifier: "cricket_bull",
            action: appendBull
        )
    }

    private func missKey(minHeight: CGFloat? = nil) -> some View {
        ScoringPadKey(
            title: L10n.string("scoring.pad.missLabel"),
            font: usesAccessibilityLayout || usesIPadSideBySidePad
                ? .title3.weight(.semibold)
                : .body.weight(.semibold),
            minHeight: minHeight ?? displayBullMissKeyMinHeight,
            accessibilityLabel: DartInput.padKeyAccessibilityLabel(segmentValue: 0, armedMultiplier: .single),
            identifier: "cricket_miss",
            action: appendMiss
        )
    }

    private func controlRow(minHeight: CGFloat? = nil) -> some View {
        let keyHeight = minHeight ?? displayKeyMinHeight
        return HStack(spacing: padSpacing) {
            modifierKey(.double, identifier: "cricket_double", minHeight: keyHeight)
            modifierKey(.triple, identifier: "cricket_triple", minHeight: keyHeight)
            ScoringPadIconKey(
                systemImage: "arrow.uturn.backward",
                minHeight: keyHeight,
                accessibilityLabel: L10n.string("scoring.undoLastTurn"),
                identifier: "cricket_undo",
                action: undo
            )
        }
    }

    private func enterButton(minHeight: CGFloat? = nil) -> some View {
        let keyHeight = minHeight ?? displayKeyMinHeight
        return Button(action: onSubmit) {
            Text(L10n.scoringEnter)
                .font(usesAccessibilityLayout || usesIPadSideBySidePad
                    ? .title3.weight(.bold)
                    : .headline.weight(.bold))
                .foregroundStyle(canSubmit ? Brand.inkOnBright : Brand.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .frame(maxWidth: .infinity, minHeight: keyHeight)
                .background(canSubmit ? Brand.green : Brand.green.opacity(0.4), in: ScoringPadStyle.keyShape)
        }
        .disabled(!canSubmit)
        .accessibilityLabel(L10n.scoringEnter)
        .accessibilityIdentifier("cricket_enter")
    }

    @ViewBuilder
    private var visitPreview: some View {
        HStack(spacing: 6) {
            ForEach(0 ..< 3, id: \.self) { slot in
                Text(slot < enteredDarts.count ? dartLabel(enteredDarts[slot]) : "")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(Brand.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, minHeight: displayVisitSlotMinHeight)
                    .background(Brand.dartBox, in: ScoringPadStyle.visitSlotShape)
            }
        }
        .accessibilityHidden(true)
    }

    private func modifierKey(
        _ multiplier: DartMultiplier,
        identifier: String,
        minHeight: CGFloat? = nil
    ) -> some View {
        let keyHeight = minHeight ?? displayKeyMinHeight
        let title = ScoringPadLabels.modifierTitle(multiplier, dynamicTypeSize: dynamicTypeSize)
        let isSelected = selectedMultiplier == multiplier
        let background: Color = {
            switch multiplier {
            case .double:
                return isSelected ? Brand.amber : Brand.amber.opacity(0.55)
            case .triple:
                return isSelected ? Brand.orange : Brand.orange.opacity(0.55)
            case .single:
                return Brand.key
            }
        }()
        // Armed modifier = solid bright fill; dark ink stays legible in dark mode where white
        // would fail AA. Idle (dimmed) fill keeps adaptive text.
        let foreground: Color = (isSelected && multiplier != .single) ? Brand.inkOnBright : Brand.textPrimary
        return ScoringPadKey(
            title: title,
            background: background,
            foreground: foreground,
            font: usesAccessibilityLayout || usesIPadSideBySidePad
                ? .title3.weight(.bold)
                : .body.weight(.bold),
            minHeight: keyHeight,
            accessibilityLabel: multiplierAccessibilityLabel(multiplier),
            accessibilityHint: modifierHint(multiplier, isSelected: isSelected),
            isSelected: isSelected,
            identifier: identifier,
            action: { toggle(multiplier) }
        )
        .frame(maxWidth: .infinity)
    }

    private func multiplierAccessibilityLabel(_ multiplier: DartMultiplier) -> String {
        switch multiplier {
        case .single:
            return L10n.string("scoring.multiplier.single.accessibility")
        case .double:
            return L10n.string("scoring.multiplier.double.accessibility")
        case .triple:
            return L10n.string("scoring.multiplier.triple.accessibility")
        }
    }

    private func modifierHint(_ multiplier: DartMultiplier, isSelected: Bool) -> String? {
        guard isSelected else { return nil }
        switch multiplier {
        case .double:
            return L10n.string("scoring.pad.double.hint.armed")
        case .triple:
            return L10n.string("scoring.pad.triple.hint.armed")
        case .single:
            return nil
        }
    }

    private func appendNumber(_ value: Int) {
        guard enteredDarts.count < 3, (15 ... 20).contains(value) else { return }
        enteredDarts.append(DartInput(multiplier: selectedMultiplier, segment: .oneToTwenty(value)))
        selectedMultiplier = .single
    }

    private func appendBull() {
        guard enteredDarts.count < 3 else { return }
        let dart = selectedMultiplier == .double
            ? DartInput(multiplier: .single, segment: .innerBull)
            : DartInput(multiplier: .single, segment: .outerBull)
        enteredDarts.append(dart)
        selectedMultiplier = .single
    }

    private func appendMiss() {
        guard enteredDarts.count < 3 else { return }
        enteredDarts.append(DartInput(multiplier: .single, segment: .miss, isMiss: true))
        selectedMultiplier = .single
    }

    private func toggle(_ multiplier: DartMultiplier) {
        selectedMultiplier = selectedMultiplier == multiplier ? .single : multiplier
    }

    private func undo() {
        if enteredDarts.isEmpty {
            onUndoTurn()
        } else {
            enteredDarts.removeLast()
            selectedMultiplier = .single
        }
    }

    private func dartLabel(_ dart: DartInput) -> String {
        if dart.isMiss { return "—" }
        switch dart.segment {
        case let .oneToTwenty(value):
            switch dart.multiplier {
            case .single: return "\(value)"
            case .double: return "D\(value)"
            case .triple: return "T\(value)"
            }
        case .outerBull: return "B"
        case .innerBull: return "BB"
        case .miss: return "—"
        }
    }
}
