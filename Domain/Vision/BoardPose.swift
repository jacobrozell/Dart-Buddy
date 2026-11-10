import Foundation

/// Camera pose relative to the dartboard, recovered from the board homography.
///
/// The homography alone maps points *on* the board face. A dart sticks out of the
/// face towards the thrower, so finding which end of a detected dart is the tip
/// needs to know how that out-of-plane direction projects into the image. Pose is
/// decomposed assuming square pixels and a centred principal point; the focal
/// length comes from the homography's orthogonality constraints, falling back to a
/// typical phone lens when the camera faces the board almost head-on (where those
/// constraints degenerate, and where the exact value barely matters).
public struct BoardPose: Equatable, Sendable {
    /// Focal length in image width units.
    public let focalLength: Double
    /// Whether the focal length was measured (vs. the typical-lens fallback).
    public let hasMeasuredFocalLength: Bool
    /// Angle between the camera's optical axis and the board normal, in degrees.
    public let tiltDegrees: Double

    private let principalX: Double
    private let principalY: Double
    // Board axes (x right, y up, z out of the face) and origin in camera coordinates.
    private let axisX: SIMD3<Double>
    private let axisY: SIMD3<Double>
    private let axisZ: SIMD3<Double>
    private let origin: SIMD3<Double>

    /// Horizontal field of view assumed along the frame's long side when the focal
    /// length cannot be measured (iPhone wide camera in video mode).
    static let fallbackLongSideFieldOfViewDegrees = 62.0

    public init?(boardToImage: PerspectiveTransform, imageAspectRatio: Double) {
        guard imageAspectRatio > 0 else { return nil }
        let m = boardToImage.values
        let cx = 0.5
        let cy = imageAspectRatio / 2
        // Columns of the homography with the principal point moved to the origin.
        let h1 = SIMD3(m[0] - cx * m[6], m[3] - cy * m[6], m[6])
        let h2 = SIMD3(m[1] - cx * m[7], m[4] - cy * m[7], m[7])
        let h3 = SIMD3(m[2] - cx * m[8], m[5] - cy * m[8], m[8])

        let longSide = max(1, imageAspectRatio)
        let fallback = 0.5 * longSide / tan(Self.fallbackLongSideFieldOfViewDegrees * Double.pi / 360)
        var focal = fallback
        var measured = false
        // r1·r2 = 0 and |r1| = |r2| each give an estimate of f²; use the better conditioned.
        let scale = (h1.x * h1.x + h1.y * h1.y + h2.x * h2.x + h2.y * h2.y) / 2
        let orthoDenominator = h1.z * h2.z
        let normDenominator = h1.z * h1.z - h2.z * h2.z
        var focalSquared: Double?
        if abs(orthoDenominator) >= abs(normDenominator), abs(orthoDenominator) > 1e-4 * scale {
            focalSquared = -(h1.x * h2.x + h1.y * h2.y) / orthoDenominator
        } else if abs(normDenominator) > 1e-4 * scale {
            focalSquared = (h2.x * h2.x + h2.y * h2.y - h1.x * h1.x - h1.y * h1.y) / normDenominator
        }
        if let focalSquared, focalSquared.isFinite, focalSquared > 0 {
            let candidate = focalSquared.squareRoot()
            if candidate > fallback * 0.45, candidate < fallback * 3 {
                focal = candidate
                measured = true
            }
        }

        var r1 = SIMD3(h1.x / focal, h1.y / focal, h1.z)
        var r2 = SIMD3(h2.x / focal, h2.y / focal, h2.z)
        var translation = SIMD3(h3.x / focal, h3.y / focal, h3.z)
        let lambda = (Self.length(r1) + Self.length(r2)) / 2
        guard lambda > 1e-9, lambda.isFinite else { return nil }
        // The board must sit in front of the camera (positive depth).
        let sign: Double = translation.z < 0 ? -1 : 1
        r1 /= lambda * sign
        r2 /= lambda * sign
        translation /= lambda * sign
        guard translation.z > 1e-6 else { return nil }

        // Orthonormalise (r1, r2 are only approximately orthogonal with a fallback focal length).
        let x = Self.normalized(r1)
        let yRaw = r2 - x * Self.dot(x, r2)
        guard Self.length(yRaw) > 1e-9 else { return nil }
        let y = Self.normalized(yRaw)
        var z = Self.cross(x, y)
        // The face normal points from the board towards the camera.
        if Self.dot(z, translation) > 0 { z = -z }

        self.focalLength = focal
        self.hasMeasuredFocalLength = measured
        self.principalX = cx
        self.principalY = cy
        self.axisX = x
        self.axisY = y
        self.axisZ = z
        self.origin = translation
        let viewDirection = Self.normalized(translation)
        let cosine = min(1, max(-1, -Self.dot(z, viewDirection)))
        self.tiltDegrees = acos(cosine) * 180 / Double.pi
    }

    /// Projects a point given in board units (`1.0` = double-ring radius) where
    /// `height` is the distance out of the board face towards the thrower.
    public func project(x: Double, y: Double, height: Double) -> ImagePoint? {
        let p = axisX * x + axisY * y + axisZ * height + origin
        guard p.z > 1e-6 else { return nil }
        return ImagePoint(
            x: focalLength * p.x / p.z + principalX,
            y: focalLength * p.y / p.z + principalY
        )
    }

    private static func dot(_ a: SIMD3<Double>, _ b: SIMD3<Double>) -> Double {
        a.x * b.x + a.y * b.y + a.z * b.z
    }

    private static func cross(_ a: SIMD3<Double>, _ b: SIMD3<Double>) -> SIMD3<Double> {
        SIMD3(a.y * b.z - a.z * b.y, a.z * b.x - a.x * b.z, a.x * b.y - a.y * b.x)
    }

    private static func length(_ a: SIMD3<Double>) -> Double {
        dot(a, a).squareRoot()
    }

    private static func normalized(_ a: SIMD3<Double>) -> SIMD3<Double> {
        a / length(a)
    }
}
