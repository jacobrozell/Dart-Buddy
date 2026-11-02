import SwiftUI

/// Example board for calibration: shows the four outer-wire crossing tap points, filling
/// the ones already tapped and ringing the next one.
struct CalibrationTapGuide: View {
    let completedTaps: Int

    var body: some View {
        ZStack {
            DartboardFace(scoringSegments: nil)
            Canvas { context, size in
                let layout = VisualDartboardMetrics.layout(in: size)
                let outer = layout.playableRadius
                let ringRect = CGRect(
                    x: layout.center.x - outer,
                    y: layout.center.y - outer,
                    width: outer * 2,
                    height: outer * 2
                )
                context.stroke(Path(ellipseIn: ringRect), with: .color(.white), lineWidth: 3)

                for (step, boardPoint) in BoardCalibration.outerWireBoardPoints.enumerated() {
                    let angle = atan2(boardPoint.x, boardPoint.y)
                    let point = CGPoint(
                        x: layout.center.x + outer * CGFloat(sin(angle)),
                        y: layout.center.y - outer * CGFloat(cos(angle))
                    )
                    let isNext = step == completedTaps
                    let isDone = step < completedTaps
                    let radius: CGFloat = isNext ? 11 : 8
                    let halo = radius + 2
                    context.stroke(
                        Path(ellipseIn: CGRect(x: point.x - halo, y: point.y - halo, width: halo * 2, height: halo * 2)),
                        with: .color(.black),
                        lineWidth: 2
                    )
                    let dot = Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2))
                    if isDone {
                        context.fill(dot, with: .color(Brand.green))
                    } else if isNext {
                        context.fill(dot, with: .color(.white))
                        context.stroke(dot, with: .color(Brand.green), lineWidth: 3)
                    } else {
                        context.fill(dot, with: .color(.black.opacity(0.8)))
                        context.stroke(dot, with: .color(.white), lineWidth: 2)
                    }
                    let label = context.resolve(
                        Text("\(step + 1)")
                            .font(.caption2.weight(.heavy).monospacedDigit())
                            .foregroundColor(isNext ? .black : .white)
                    )
                    context.draw(label, at: point)
                }
            }
        }
        .frame(width: 168, height: 168)
        .padding(DS.Spacing.s2)
        .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: DS.Radius.sm))
    }
}
