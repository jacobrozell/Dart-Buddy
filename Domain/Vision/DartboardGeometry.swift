import Foundation

/// A point in board-plane coordinates after calibration: the board center is the
/// origin and a distance of `1.0` equals the outer edge of the double ring.
public struct BoardPoint: Codable, Equatable, Sendable {
    public let x: Double
    public let y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    public var radius: Double {
        (x * x + y * y).squareRoot()
    }
}

/// Deterministic mapping from calibrated board-plane points to scored segments.
/// Ring radii follow the WDF tournament board (170 mm to the outer double edge).
public enum DartboardGeometry {
    /// Wedge values clockwise starting from the top (the 20 wedge).
    public static let segmentWheel = [20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5]

    /// Ring boundaries as fractions of the outer double-ring radius (170 mm).
    public enum RingRadius {
        public static let innerBull = 6.35 / 170.0
        public static let outerBull = 15.9 / 170.0
        public static let tripleInner = 99.0 / 170.0
        public static let tripleOuter = 107.0 / 170.0
        public static let doubleInner = 162.0 / 170.0
        public static let doubleOuter = 1.0
    }

    public static let wedgeAngleDegrees = 360.0 / 20.0

    /// Maps a calibrated board-plane point to the dart it scores.
    /// Points outside the double ring score as a miss.
    public static func dartInput(at point: BoardPoint) -> DartInput {
        let radius = point.radius
        if radius > RingRadius.doubleOuter {
            return DartInput(multiplier: .single, segment: .miss, isMiss: true)
        }
        if radius <= RingRadius.innerBull {
            return DartInput(multiplier: .single, segment: .innerBull)
        }
        if radius <= RingRadius.outerBull {
            return DartInput(multiplier: .single, segment: .outerBull)
        }

        let value = segmentValue(atAngleDegrees: angleDegrees(of: point))
        let multiplier: DartMultiplier
        if radius >= RingRadius.tripleInner && radius <= RingRadius.tripleOuter {
            multiplier = .triple
        } else if radius >= RingRadius.doubleInner {
            multiplier = .double
        } else {
            multiplier = .single
        }
        return DartInput(multiplier: multiplier, segment: .oneToTwenty(value))
    }

    /// Angle in degrees measured clockwise from the top of the board (center of the 20 wedge),
    /// normalized to `[0, 360)`. The y axis points up in board-plane coordinates.
    public static func angleDegrees(of point: BoardPoint) -> Double {
        let radians = atan2(point.x, point.y)
        let degrees = radians * 180.0 / .pi
        return degrees < 0 ? degrees + 360.0 : degrees
    }

    /// Wedge value for an angle measured clockwise from the top of the board.
    public static func segmentValue(atAngleDegrees angle: Double) -> Int {
        let shifted = (angle + wedgeAngleDegrees / 2).truncatingRemainder(dividingBy: 360.0)
        let normalized = shifted < 0 ? shifted + 360.0 : shifted
        let index = Int(normalized / wedgeAngleDegrees) % segmentWheel.count
        return segmentWheel[index]
    }

    /// Physical radius of the outer double edge, for converting board units to millimetres.
    public static let doubleOuterRadiusMM = 170.0

    /// Distance from a board-plane point to the nearest scoring boundary (ring wire or
    /// wedge wire), in board units. Small margins mean a slightly different tip
    /// estimate would score differently, so detections there deserve less confidence.
    public static func boundaryMargin(at point: BoardPoint) -> Double {
        let radius = point.radius
        let rings = [
            RingRadius.innerBull, RingRadius.outerBull, RingRadius.tripleInner,
            RingRadius.tripleOuter, RingRadius.doubleInner, RingRadius.doubleOuter,
        ]
        var margin = rings.map { abs(radius - $0) }.min() ?? 0
        // Wedge wires only matter between the bull and the outer double edge.
        if radius > RingRadius.outerBull, radius < RingRadius.doubleOuter {
            let angle = angleDegrees(of: point)
            let offset = (angle + wedgeAngleDegrees / 2).truncatingRemainder(dividingBy: wedgeAngleDegrees)
            let toWire = min(offset, wedgeAngleDegrees - offset) * Double.pi / 180
            margin = min(margin, radius * sin(toWire))
        }
        return margin
    }

    /// Board-plane point at a radius and an angle measured clockwise from the top.
    public static func point(radius: Double, angleDegrees: Double) -> BoardPoint {
        let radians = angleDegrees * Double.pi / 180
        return BoardPoint(x: radius * sin(radians), y: radius * cos(radians))
    }

    /// Whether the double/triple ring of the wedge at this clockwise index is red
    /// (the 20 wedge is index 0 and red; colours alternate around the board).
    public static func ringIsRed(wedgeIndex: Int) -> Bool {
        wedgeIndex % 2 == 0
    }
}
