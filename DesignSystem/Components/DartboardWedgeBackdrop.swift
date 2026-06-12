import SwiftUI

/// Subtle radial wedge texture for brand moments (launch splash, empty states).
struct DartboardWedgeBackdrop: View {
    @Environment(\.colorScheme) private var colorScheme

    private let segmentCount = 20

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = max(size.width, size.height) * 0.72
            let wedgeAngle = (2 * .pi) / CGFloat(segmentCount)

            for index in 0..<segmentCount {
                let start = CGFloat(index) * wedgeAngle - .pi / 2
                let end = start + wedgeAngle
                var path = Path()
                path.move(to: center)
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: .radians(start),
                    endAngle: .radians(end),
                    clockwise: false
                )
                path.closeSubpath()

                let fillColor = index.isMultiple(of: 2) ? Brand.red : Brand.green
                context.fill(path, with: .color(fillColor.opacity(segmentOpacity)))
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var segmentOpacity: Double {
        colorScheme == .dark ? 0.07 : 0.035
    }
}
