import Foundation

/// Pure geometry for the visual dartboard input: maps a tap point to a `DartInput`.
///
/// The board is modelled on the unit circle (radius 1). Ring bands are deliberately
/// wider than a regulation board so double/triple zones stay tappable on phones —
/// the board is an input control, not a scale drawing.
public enum BoardHitResolver {
    /// Wedge values clockwise from the top (20 centered at 12 o'clock).
    public static let segmentOrder = [20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5]

    public enum Ring: Equatable, Sendable {
        case innerBull
        case outerBull
        case innerSingle
        case triple
        case outerSingle
        case double
        case outsideBoard
    }

    /// Normalized ring boundaries (fractions of the board radius). Exaggerated
    /// double/triple bands keep each zone comfortably tappable.
    public enum RingBounds {
        public static let innerBull = 0.07
        public static let outerBull = 0.16
        public static let innerSingleEnd = 0.47
        public static let tripleEnd = 0.62
        public static let outerSingleEnd = 0.85
        public static let doubleEnd = 1.0
    }

    public static func ring(forNormalizedRadius radius: Double) -> Ring {
        switch radius {
        case ..<0:
            return .outsideBoard
        case ..<RingBounds.innerBull:
            return .innerBull
        case ..<RingBounds.outerBull:
            return .outerBull
        case ..<RingBounds.innerSingleEnd:
            return .innerSingle
        case ..<RingBounds.tripleEnd:
            return .triple
        case ..<RingBounds.outerSingleEnd:
            return .outerSingle
        case ...RingBounds.doubleEnd:
            return .double
        default:
            return .outsideBoard
        }
    }

    /// Wedge value for an angle measured clockwise from 12 o'clock, in radians.
    public static func segmentValue(forAngle angle: Double) -> Int {
        let twoPi = 2 * Double.pi
        var normalized = angle.truncatingRemainder(dividingBy: twoPi)
        if normalized < 0 { normalized += twoPi }
        let wedgeAngle = twoPi / Double(segmentOrder.count)
        // Wedges are centered on their spoke, so the 20 wedge spans ±half a wedge around the top.
        let index = Int(((normalized + wedgeAngle / 2) / wedgeAngle).rounded(.down)) % segmentOrder.count
        return segmentOrder[index]
    }

    /// Resolves a tap at `(x, y)` on a board centered at `(centerX, centerY)` with `radius`.
    /// Returns `nil` when the tap lands outside the playable circle (no dart is recorded;
    /// misses are entered with the explicit miss key).
    public static func dartInput(
        x: Double,
        y: Double,
        centerX: Double,
        centerY: Double,
        radius: Double
    ) -> DartInput? {
        guard radius > 0 else { return nil }
        let dx = x - centerX
        let dy = y - centerY
        let normalizedRadius = (dx * dx + dy * dy).squareRoot() / radius
        let hitRing = ring(forNormalizedRadius: normalizedRadius)
        switch hitRing {
        case .outsideBoard:
            return nil
        case .innerBull:
            return DartInput(multiplier: .single, segment: .innerBull)
        case .outerBull:
            return DartInput(multiplier: .single, segment: .outerBull)
        case .innerSingle, .triple, .outerSingle, .double:
            // atan2 measures counterclockwise from +x; convert to clockwise from 12 o'clock.
            let angle = atan2(dx, -dy)
            let value = segmentValue(forAngle: angle)
            let multiplier: DartMultiplier = switch hitRing {
            case .triple: .triple
            case .double: .double
            default: .single
            }
            return DartInput(multiplier: multiplier, segment: .oneToTwenty(value))
        }
    }
}
