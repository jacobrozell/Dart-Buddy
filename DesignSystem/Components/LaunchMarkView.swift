import SwiftUI

/// Minimal dartboard mark for launch and brand moments. Uses the same ring geometry as
/// gameplay boards so the icon reads as a real board at small sizes.
struct LaunchMarkView: View {
    var body: some View {
        Canvas { context, size in
            let side = min(size.width, size.height)
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let boardRadius = side * 0.46
            let playableRadius = boardRadius * 0.88

            let backing = Path(
                ellipseIn: CGRect(
                    x: center.x - boardRadius,
                    y: center.y - boardRadius,
                    width: boardRadius * 2,
                    height: boardRadius * 2
                )
            )
            context.fill(backing, with: .color(Brand.card))

            drawWedges(
                context: context,
                center: center,
                playableRadius: playableRadius
            )
            drawBulls(
                context: context,
                center: center,
                playableRadius: playableRadius
            )

            let rim = backing.strokedPath(StrokeStyle(lineWidth: 1.5))
            context.stroke(rim, with: .color(Brand.cardElevated))
        }
        .aspectRatio(1, contentMode: .fit)
        .accessibilityHidden(true)
    }

    private func drawWedges(
        context: GraphicsContext,
        center: CGPoint,
        playableRadius: CGFloat
    ) {
        let wedgeCount = BoardHitResolver.segmentOrder.count
        let wedgeAngle = 2 * Double.pi / Double(wedgeCount)

        for index in 0..<wedgeCount {
            let start = Double(index) * wedgeAngle - wedgeAngle / 2
            let end = start + wedgeAngle
            let isDarkWedge = index.isMultiple(of: 2)

            for band in zoneBands() {
                var path = annularSector(
                    center: center,
                    playableRadius: playableRadius,
                    startAngle: start,
                    endAngle: end,
                    innerFraction: band.start,
                    outerFraction: band.end
                )
                let fill: Color = band.isAccentRing
                    ? (isDarkWedge ? Brand.red : Brand.green)
                    : (isDarkWedge ? Brand.dartBox : Brand.key)
                context.fill(path, with: .color(fill))

                path = path.strokedPath(StrokeStyle(lineWidth: 0.35))
                context.fill(path, with: .color(Brand.cardElevated.opacity(0.65)))
            }
        }
    }

    private func drawBulls(
        context: GraphicsContext,
        center: CGPoint,
        playableRadius: CGFloat
    ) {
        let outer = circlePath(
            center: center,
            playableRadius: playableRadius,
            fraction: BoardHitResolver.RingBounds.outerBull
        )
        context.fill(outer, with: .color(Brand.green))

        let inner = circlePath(
            center: center,
            playableRadius: playableRadius,
            fraction: BoardHitResolver.RingBounds.innerBull
        )
        context.fill(inner, with: .color(Brand.red))
    }

    private func zoneBands() -> [(start: Double, end: Double, isAccentRing: Bool)] {
        [
            (BoardHitResolver.RingBounds.outerBull, BoardHitResolver.RingBounds.innerSingleEnd, false),
            (BoardHitResolver.RingBounds.innerSingleEnd, BoardHitResolver.RingBounds.tripleEnd, true),
            (BoardHitResolver.RingBounds.tripleEnd, BoardHitResolver.RingBounds.outerSingleEnd, false),
            (BoardHitResolver.RingBounds.outerSingleEnd, BoardHitResolver.RingBounds.doubleEnd, true)
        ]
    }

    private func annularSector(
        center: CGPoint,
        playableRadius: CGFloat,
        startAngle: Double,
        endAngle: Double,
        innerFraction: Double,
        outerFraction: Double
    ) -> Path {
        let start = Angle(radians: startAngle - .pi / 2)
        let end = Angle(radians: endAngle - .pi / 2)
        let innerRadius = playableRadius * CGFloat(innerFraction)
        let outerRadius = playableRadius * CGFloat(outerFraction)
        var path = Path()
        path.addArc(center: center, radius: outerRadius, startAngle: start, endAngle: end, clockwise: false)
        path.addArc(center: center, radius: innerRadius, startAngle: end, endAngle: start, clockwise: true)
        path.closeSubpath()
        return path
    }

    private func circlePath(
        center: CGPoint,
        playableRadius: CGFloat,
        fraction: Double
    ) -> Path {
        let radius = playableRadius * CGFloat(fraction)
        return Path(
            ellipseIn: CGRect(
                x: center.x - radius,
                y: center.y - radius,
                width: radius * 2,
                height: radius * 2
            )
        )
    }
}

#if DEBUG
#Preview("Launch Mark") {
    LaunchMarkView()
        .frame(width: 120, height: 120)
        .padding()
        .background(Brand.background)
}
#endif
