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
}
