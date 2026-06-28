import SwiftUI

/// Tappable dartboard entry surface: tap the zone where the dart landed (double and
/// triple rings are widened for touch) to append a dart to the current visit. Shares
/// the `enteredDarts` / `selectedMultiplier` bindings with the number pads so screens
/// can swap presentation without touching scoring flow. Geometry lives in
/// `BoardHitResolver` (unit-tested, no SwiftUI).
struct VisualDartboardInput: View {
    @Binding var enteredDarts: [DartInput]
    @Binding var selectedMultiplier: DartMultiplier
    /// Segments that score in the current mode (Cricket: 15–20). Non-scoring wedges
    /// stay tappable — a real dart at 7 in Cricket is still a thrown dart — but render dimmed.
    var scoringSegments: Set<Int>? = nil
    var maxDarts: Int = 3
    var showsVisitPreview: Bool = true
    /// Cricket-style manual submit; X01 auto-submits and passes `nil`.
    var canSubmit: Bool = false
    var onSubmit: (() -> Void)? = nil
    let onUndoTurn: () -> Void

    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric(relativeTo: .caption) private var visitSlotMinHeight: CGFloat = 34
    @State private var hitFlash: HitFlash?
    @State private var hitFlashTask: Task<Void, Never>?

    private struct HitFlash: Equatable {
        let label: String
        let location: CGPoint
    }

    private var usesLandscapeCompactLayout: Bool {
        GameplayLayout.usesLandscapeMatchScoringLayout(verticalSizeClass: verticalSizeClass)
    }

    private var boardMaxHeight: CGFloat {
        usesLandscapeCompactLayout
            ? VisualDartboardMetrics.landscapeBoardMaxHeight
            : VisualDartboardMetrics.portraitBoardMaxHeight
    }

    private var controlKeyMinHeight: CGFloat {
        usesLandscapeCompactLayout ? 36 : 44
    }

    var body: some View {
        VStack(spacing: ScoringPadStyle.compactSpacing) {
            if showsVisitPreview {
                visitPreview
            }
            board
            controlRow
        }
        .fixedSize(horizontal: false, vertical: true)
        .onDisappear { hitFlashTask?.cancel() }
    }

    private var visitPreview: some View {
        HStack(spacing: 6) {
            ForEach(0 ..< maxDarts, id: \.self) { slot in
                Text(slot < enteredDarts.count ? enteredDarts[slot].compactDisplayLabel : "")
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(Brand.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .frame(maxWidth: .infinity, minHeight: min(visitSlotMinHeight, 30))
                    .scoringPadVisitSlotStyle(minHeight: min(visitSlotMinHeight, 30))
            }
        }
        .accessibilityHidden(true)
        .accessibilityIdentifier("board_visit_preview")
    }

    private var board: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .frame(maxHeight: boardMaxHeight)
            .frame(maxWidth: .infinity)
            .overlay {
                GeometryReader { geometry in
                    let side = min(geometry.size.width, geometry.size.height)
                    ZStack {
                        DartboardFace(scoringSegments: scoringSegments)
                            .frame(width: side, height: side)
                        if let hitFlash {
                            hitFlashLabel(hitFlash)
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .contentShape(Rectangle())
                    .gesture(
                        SpatialTapGesture().onEnded { value in
                            handleTap(at: value.location, in: geometry.size)
                        }
                    )
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(L10n.string("scoring.board.accessibility"))
            .accessibilityHint(L10n.string("scoring.board.accessibilityHint"))
            .accessibilityIdentifier("board_input_root")
    }

    private func hitFlashLabel(_ flash: HitFlash) -> some View {
        Text(flash.label)
            .font(.caption.weight(.heavy).monospacedDigit())
            .foregroundStyle(Brand.inkOnBright)
            .padding(.horizontal, DS.Spacing.s2)
            .padding(.vertical, 2)
            .background(Brand.amber, in: Capsule())
            .position(flash.location)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .transition(reduceMotion ? .identity : .opacity)
    }

    private var controlRow: some View {
        HStack(spacing: ScoringPadStyle.compactSpacing) {
            ScoringPadKey(
                title: L10n.string("scoring.pad.missLabel"),
                minHeight: controlKeyMinHeight,
                accessibilityLabel: L10n.string("scoring.segment.miss.accessibility"),
                identifier: "board_miss",
                action: appendMiss
            )
            ScoringPadIconKey(
                systemImage: "arrow.uturn.backward",
                minHeight: controlKeyMinHeight,
                accessibilityLabel: L10n.string("scoring.undoLastTurn"),
                identifier: "board_undo",
                action: undo
            )
            if let onSubmit {
                Button(action: onSubmit) {
                    Text(L10n.scoringEnter)
                        .font(.headline.weight(.bold))
                        .foregroundStyle(canSubmit ? Brand.inkOnBright : Brand.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .frame(maxWidth: .infinity, minHeight: controlKeyMinHeight)
                        .background(canSubmit ? Brand.green : Brand.green.opacity(0.4), in: ScoringPadStyle.keyShape)
                }
                .disabled(!canSubmit)
                .accessibilityLabel(L10n.scoringEnter)
                .accessibilityIdentifier("board_enter")
            }
        }
    }

    private func handleTap(at location: CGPoint, in size: CGSize) {
        guard enteredDarts.count < maxDarts else { return }
        let layout = VisualDartboardMetrics.layout(in: size)
        guard let dart = BoardHitResolver.dartInput(
            x: location.x,
            y: location.y,
            centerX: layout.center.x,
            centerY: layout.center.y,
            radius: layout.playableRadius
        ) else { return }
        enteredDarts.append(dart)
        selectedMultiplier = .single
        flashHit(label: dart.compactDisplayLabel, at: location)
    }

    private func appendMiss() {
        guard enteredDarts.count < maxDarts else { return }
        enteredDarts.append(DartInput(multiplier: .single, segment: .miss, isMiss: true))
        selectedMultiplier = .single
    }

    private func undo() {
        if enteredDarts.isEmpty {
            onUndoTurn()
        } else {
            enteredDarts.removeLast()
            selectedMultiplier = .single
        }
    }

    private func flashHit(label: String, at location: CGPoint) {
        hitFlashTask?.cancel()
        withAnimation(MotionPolicy.fastAnimation(reduceMotion: reduceMotion)) {
            hitFlash = HitFlash(label: label, location: location)
        }
        hitFlashTask = Task {
            try? await Task.sleep(nanoseconds: VisualDartboardMetrics.hitFlashNanoseconds)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                withAnimation(MotionPolicy.fastAnimation(reduceMotion: reduceMotion)) {
                    hitFlash = nil
                }
            }
        }
    }
}

/// Match-header button that flips between number pad and visual dartboard entry for the
/// current match only; the lasting default lives in Settings → During Play.
struct DartEntryPresentationToggle: View {
    let presentation: DartEntryPresentation
    let onToggle: () -> Void

    @Environment(\.matchHeaderChromeButtonSize) private var chromeButtonSize

    var body: some View {
        Button(action: onToggle) {
            Image(systemName: presentation == .numberPad ? "target" : "square.grid.3x3")
                .font(.headline.weight(.bold))
                .foregroundStyle(Brand.green)
                .frame(width: chromeButtonSize, height: chromeButtonSize)
                .background(Brand.card, in: RoundedRectangle(cornerRadius: DS.Radius.sm))
        }
        .accessibilityLabel(
            presentation == .numberPad
                ? L10n.string("scoring.presentation.switchToBoard")
                : L10n.string("scoring.presentation.switchToPad")
        )
        .accessibilityIdentifier("match_dartEntryPresentationToggle")
    }
}

/// Sizing constants and the shared face/hit geometry for the visual dartboard.
enum VisualDartboardMetrics {
    static let portraitBoardMaxHeight: CGFloat = 330
    static let landscapeBoardMaxHeight: CGFloat = 200
    /// Fraction of the half-size kept for the playable circle; the rest is the number ring.
    static let playableRadiusFraction: CGFloat = 0.86
    /// Wedge number labels sit centered in the margin outside the double ring.
    static let numberRingRadiusFraction: CGFloat = 0.93
    static let hitFlashNanoseconds: UInt64 = 600_000_000

    struct Layout {
        let center: CGPoint
        let boardRadius: CGFloat
        let playableRadius: CGFloat
    }

    static func layout(in size: CGSize) -> Layout {
        let boardRadius = min(size.width, size.height) / 2
        return Layout(
            center: CGPoint(x: size.width / 2, y: size.height / 2),
            boardRadius: boardRadius,
            playableRadius: boardRadius * playableRadiusFraction
        )
    }
}

/// Canvas rendering of the board face: 20 wedges × 4 ring zones, bull circles, and the
/// number ring. Zone boundaries mirror `BoardHitResolver.RingBounds` so what the player
/// sees is exactly what a tap resolves to.
private struct DartboardFace: View {
    let scoringSegments: Set<Int>?

    var body: some View {
        Canvas { context, size in
            let layout = VisualDartboardMetrics.layout(in: size)
            drawWedges(context: context, layout: layout)
            drawBulls(context: context, layout: layout)
            drawNumbers(context: context, layout: layout)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func zoneBands() -> [(start: Double, end: Double, isAccentRing: Bool)] {
        [
            (BoardHitResolver.RingBounds.outerBull, BoardHitResolver.RingBounds.innerSingleEnd, false),
            (BoardHitResolver.RingBounds.innerSingleEnd, BoardHitResolver.RingBounds.tripleEnd, true),
            (BoardHitResolver.RingBounds.tripleEnd, BoardHitResolver.RingBounds.outerSingleEnd, false),
            (BoardHitResolver.RingBounds.outerSingleEnd, BoardHitResolver.RingBounds.doubleEnd, true)
        ]
    }

    private func drawWedges(context: GraphicsContext, layout: VisualDartboardMetrics.Layout) {
        let wedgeCount = BoardHitResolver.segmentOrder.count
        let wedgeAngle = 2 * Double.pi / Double(wedgeCount)
        for (index, value) in BoardHitResolver.segmentOrder.enumerated() {
            // Angles measured clockwise from 12 o'clock; wedges centered on their spoke.
            let start = Double(index) * wedgeAngle - wedgeAngle / 2
            let end = start + wedgeAngle
            let isDarkWedge = index.isMultiple(of: 2)
            let dimmed = !isScoring(value)
            for band in zoneBands() {
                var path = annularSector(
                    layout: layout,
                    startAngle: start,
                    endAngle: end,
                    innerFraction: band.start,
                    outerFraction: band.end
                )
                let fill: Color = band.isAccentRing
                    ? (isDarkWedge ? Brand.red : Brand.green)
                    : (isDarkWedge ? Brand.dartBox : Brand.key)
                context.fill(path, with: .color(fill.opacity(dimmed ? 0.3 : 1)))
                path = path.strokedPath(StrokeStyle(lineWidth: 0.5))
                context.fill(path, with: .color(Brand.cardElevated))
            }
        }
    }

    private func drawBulls(context: GraphicsContext, layout: VisualDartboardMetrics.Layout) {
        let dimmed = scoringSegments != nil && !(scoringSegments?.contains(25) ?? true)
        let outer = circlePath(layout: layout, fraction: BoardHitResolver.RingBounds.outerBull)
        context.fill(outer, with: .color(Brand.green.opacity(dimmed ? 0.3 : 1)))
        let inner = circlePath(layout: layout, fraction: BoardHitResolver.RingBounds.innerBull)
        context.fill(inner, with: .color(Brand.red.opacity(dimmed ? 0.3 : 1)))
    }

    private func drawNumbers(context: GraphicsContext, layout: VisualDartboardMetrics.Layout) {
        let wedgeCount = BoardHitResolver.segmentOrder.count
        let wedgeAngle = 2 * Double.pi / Double(wedgeCount)
        let radius = layout.boardRadius * VisualDartboardMetrics.numberRingRadiusFraction
        for (index, value) in BoardHitResolver.segmentOrder.enumerated() {
            let angle = Double(index) * wedgeAngle
            let position = CGPoint(
                x: layout.center.x + radius * CGFloat(sin(angle)),
                y: layout.center.y - radius * CGFloat(cos(angle))
            )
            let label = Text(String(value))
                .font(.caption2.weight(.bold).monospacedDigit())
                .foregroundColor(isScoring(value) ? Brand.textSecondary : Brand.textSecondary.opacity(0.4))
            context.draw(context.resolve(label), at: position)
        }
    }

    private func isScoring(_ value: Int) -> Bool {
        guard let scoringSegments else { return true }
        return scoringSegments.contains(value)
    }

    private func annularSector(
        layout: VisualDartboardMetrics.Layout,
        startAngle: Double,
        endAngle: Double,
        innerFraction: Double,
        outerFraction: Double
    ) -> Path {
        // Convert clockwise-from-top angles to the standard from-+x convention Path expects.
        let start = Angle(radians: startAngle - .pi / 2)
        let end = Angle(radians: endAngle - .pi / 2)
        let innerRadius = layout.playableRadius * CGFloat(innerFraction)
        let outerRadius = layout.playableRadius * CGFloat(outerFraction)
        var path = Path()
        path.addArc(center: layout.center, radius: outerRadius, startAngle: start, endAngle: end, clockwise: false)
        path.addArc(center: layout.center, radius: innerRadius, startAngle: end, endAngle: start, clockwise: true)
        path.closeSubpath()
        return path
    }

    private func circlePath(layout: VisualDartboardMetrics.Layout, fraction: Double) -> Path {
        let radius = layout.playableRadius * CGFloat(fraction)
        return Path(
            ellipseIn: CGRect(
                x: layout.center.x - radius,
                y: layout.center.y - radius,
                width: radius * 2,
                height: radius * 2
            )
        )
    }
}
