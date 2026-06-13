import Foundation

/// A 3x3 homography applied to homogeneous image points `(x, y, 1)` that maps
/// camera image coordinates into board-plane coordinates (see `BoardPoint`).
public struct PerspectiveTransform: Codable, Equatable, Sendable {
    /// Row-major matrix values: `[m00, m01, m02, m10, m11, m12, m20, m21, m22]`.
    public let values: [Double]

    public init?(values: [Double]) {
        guard values.count == 9 else { return nil }
        self.values = values
    }

    public static let identity = PerspectiveTransform(values: [1, 0, 0, 0, 1, 0, 0, 0, 1])!

    /// Similarity transform built from a circle fit: translates the board center to the
    /// origin, scales the detected radius to `1.0`, and removes the segment-orientation
    /// rotation so the 20 wedge points up. Image y grows downward, so the y axis flips.
    public static func circleFit(
        centerX: Double,
        centerY: Double,
        radius: Double,
        rotationDegrees: Double = 0
    ) -> PerspectiveTransform? {
        guard radius > 0 else { return nil }
        let scale = 1.0 / radius
        let theta = rotationDegrees * Double.pi / 180.0
        let cosT = cos(theta)
        let sinT = sin(theta)
        // rotate(theta) * flipY * scale * translate(-center)
        return PerspectiveTransform(values: [
            cosT * scale, sinT * scale, -(cosT * centerX + sinT * centerY) * scale,
            sinT * scale, -cosT * scale, -(sinT * centerX - cosT * centerY) * scale,
            0, 0, 1,
        ])
    }

    public func apply(toImageX x: Double, imageY y: Double) -> BoardPoint? {
        let m = values
        let w = m[6] * x + m[7] * y + m[8]
        guard abs(w) > .ulpOfOne else { return nil }
        return BoardPoint(
            x: (m[0] * x + m[1] * y + m[2]) / w,
            y: (m[3] * x + m[4] * y + m[5]) / w
        )
    }
}

/// Live measurements that gate whether calibration (or an individual frame) is usable.
public struct CalibrationQuality: Codable, Equatable, Sendable {
    /// How well the detected contour matches a circle, `0...1`.
    public let fitConfidence: Double
    /// Mean luminance of the frame, `0...1`.
    public let brightness: Double
    /// Focus/motion-blur proxy, `0...1` (higher is sharper).
    public let sharpness: Double

    public init(fitConfidence: Double, brightness: Double, sharpness: Double) {
        self.fitConfidence = fitConfidence
        self.brightness = brightness
        self.sharpness = sharpness
    }

    public static let minimumFitConfidence = 0.8
    public static let minimumBrightness = 0.18
    public static let minimumSharpness = 0.35

    public var isAcceptable: Bool {
        fitConfidence >= Self.minimumFitConfidence
            && brightness >= Self.minimumBrightness
            && sharpness >= Self.minimumSharpness
    }
}

/// Output of the guided calibration workflow (spec §5): board center, radius,
/// segment orientation reference, and the perspective transform used for scoring.
public struct BoardCalibration: Codable, Equatable, Sendable {
    /// Board center in normalized image coordinates (`0...1` on both axes).
    public let centerX: Double
    public let centerY: Double
    /// Board radius (outer double edge) in normalized image width units.
    public let radius: Double
    /// Clockwise rotation of the 20 wedge away from straight up, in degrees.
    public let segmentRotationDegrees: Double
    public let transform: PerspectiveTransform
    public let quality: CalibrationQuality
    public let calibratedAt: Date

    public init?(
        centerX: Double,
        centerY: Double,
        radius: Double,
        segmentRotationDegrees: Double = 0,
        quality: CalibrationQuality,
        calibratedAt: Date = Date()
    ) {
        guard let transform = PerspectiveTransform.circleFit(
            centerX: centerX,
            centerY: centerY,
            radius: radius,
            rotationDegrees: segmentRotationDegrees
        ) else { return nil }
        self.centerX = centerX
        self.centerY = centerY
        self.radius = radius
        self.segmentRotationDegrees = segmentRotationDegrees
        self.transform = transform
        self.quality = quality
        self.calibratedAt = calibratedAt
    }

    /// Drift tolerances before the session must pause and recalibrate (spec §8).
    public static let driftCenterTolerance = 0.04
    public static let driftRadiusTolerance = 0.06

    /// Whether a fresh board observation has moved beyond tolerance from this calibration.
    public func hasDrifted(observedCenterX: Double, observedCenterY: Double, observedRadius: Double) -> Bool {
        let dx = observedCenterX - centerX
        let dy = observedCenterY - centerY
        if (dx * dx + dy * dy).squareRoot() > Self.driftCenterTolerance { return true }
        return abs(observedRadius - radius) > Self.driftRadiusTolerance * radius
    }

    /// Maps a normalized image point to the dart it scores under this calibration.
    public func dartInput(atImageX x: Double, imageY y: Double) -> DartInput? {
        transform.apply(toImageX: x, imageY: y).map(DartboardGeometry.dartInput(at:))
    }
}
