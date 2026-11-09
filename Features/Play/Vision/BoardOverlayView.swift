import SwiftUI

/// Draws the calibrated board's wires over the camera preview so the player can
/// see at a glance whether the app's idea of the board matches the real one, plus
/// drag handles for nudging the four calibration landmarks by hand.
struct BoardOverlayView: View {
    let overlay: VisionScoringViewModel.BoardOverlay
    /// Tip of the most recent detection, in image width units.
    let lastTip: ImagePoint?
    let isAdjusting: Bool
    let onMoveLandmark: (Int, ImagePoint) -> Void

    private static let ringRadii = [
        DartboardGeometry.RingRadius.innerBull,
        DartboardGeometry.RingRadius.outerBull,
        DartboardGeometry.RingRadius.tripleInner,
        DartboardGeometry.RingRadius.tripleOuter,
        DartboardGeometry.RingRadius.doubleInner,
        DartboardGeometry.RingRadius.doubleOuter,
    ]
    private static let handleDiameter: CGFloat = 44

    var body: some View {
        GeometryReader { proxy in
            let mapping = AspectFillMapping(viewSize: proxy.size, aspectRatio: overlay.aspectRatio)
            ZStack {
                Canvas { context, _ in
                    draw(in: &context, mapping: mapping)
                }
                .allowsHitTesting(false)

                if isAdjusting {
                    ForEach(Array(overlay.controlPoints.ordered.enumerated()), id: \.offset) { index, point in
                        handle(index: index, at: mapping.viewPoint(for: point), mapping: mapping)
                    }
                }
            }
        }
        .accessibilityHidden(true)
    }

    private func handle(index: Int, at position: CGPoint, mapping: AspectFillMapping) -> some View {
        Circle()
            .fill(Color.white.opacity(0.25))
            .overlay(Circle().stroke(Color.white, lineWidth: 2))
            .overlay(Circle().fill(Color.yellow).frame(width: 6, height: 6))
            .frame(width: Self.handleDiameter, height: Self.handleDiameter)
            .contentShape(Circle())
            .position(position)
            .gesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .local)
                    .onChanged { value in
                        onMoveLandmark(index, mapping.imagePoint(for: value.location))
                    }
            )
    }

    private func draw(in context: inout GraphicsContext, mapping: AspectFillMapping) {
        guard let boardToImage = overlay.controlPoints.boardToImage else { return }
        func project(radius: Double, angle: Double) -> CGPoint? {
            let point = DartboardGeometry.point(radius: radius, angleDegrees: angle)
            return boardToImage.applyPoint(x: point.x, y: point.y).map(mapping.viewPoint(for:))
        }

        var wires = Path()
        for radius in Self.ringRadii {
            var started = false
            for step in 0 ... 72 {
                guard let point = project(radius: radius, angle: Double(step) * 5) else { continue }
                if started {
                    wires.addLine(to: point)
                } else {
                    wires.move(to: point)
                    started = true
                }
            }
        }
        for wedge in 0 ..< 20 {
            let angle = (Double(wedge) + 0.5) * DartboardGeometry.wedgeAngleDegrees
            guard let inner = project(radius: DartboardGeometry.RingRadius.outerBull, angle: angle),
                  let outer = project(radius: DartboardGeometry.RingRadius.doubleOuter, angle: angle) else { continue }
            wires.move(to: inner)
            wires.addLine(to: outer)
        }
        let color: Color = overlay.isLocked ? .green : .yellow
        let style = StrokeStyle(lineWidth: 1.5, dash: overlay.isLocked ? [] : [6, 4])
        context.stroke(wires, with: .color(color.opacity(0.9)), style: style)

        // Label the 20 so a wrong rotation guess is obvious.
        if let twenty = project(radius: 1.16, angle: 0) {
            context.draw(
                Text("20").font(.system(size: 17, weight: .bold)).foregroundColor(color),
                at: twenty
            )
        }

        if let lastTip {
            let center = mapping.viewPoint(for: lastTip)
            let marker = Path(ellipseIn: CGRect(x: center.x - 7, y: center.y - 7, width: 14, height: 14))
            context.stroke(marker, with: .color(.white), lineWidth: 3)
            context.stroke(marker, with: .color(.red), lineWidth: 1.5)
        }
    }
}
