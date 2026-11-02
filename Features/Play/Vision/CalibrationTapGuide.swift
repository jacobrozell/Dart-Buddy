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
                for (step, boardPoint) in BoardCalibration.outerWireBoardPoints.enumerated() {
                    let angle = atan2(boardPoint.x, boardPoint.y)
                    let point = CGPoint(
                        x: layout.center.x + layout.playableRadius * CGFloat(sin(angle)),
                        y: layout.center.y - layout.playableRadius * CGFloat(cos(angle))
                    )
                    let isNext = step == completedTaps
                    let radius: CGFloat = isNext ? 7 : 5
                    let dot = Path(ellipseIn: CGRect(x: point.x - radius, y: point.y - radius, width: radius * 2, height: radius * 2))
                    if step < completedTaps {
                        context.fill(dot, with: .color(Brand.green))
                    } else if isNext {
                        context.fill(dot, with: .color(.white))
                        context.stroke(dot, with: .color(Brand.green), lineWidth: 3)
                    } else {
                        context.stroke(dot, with: .color(.white), lineWidth: 2)
                    }
                }
            }
        }
        .frame(width: 132, height: 132)
        .padding(DS.Spacing.s2)
        .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: DS.Radius.sm))
    }
}
