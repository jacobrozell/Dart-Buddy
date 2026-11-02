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

    private init(uncheckedValues values: [Double]) {
        self.values = values
    }

    public static let identity = PerspectiveTransform(uncheckedValues: [1, 0, 0, 0, 1, 0, 0, 0, 1])

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

    /// Direct linear transform from four image points to four board-plane points.
    /// `imagePoints` and `boardPoints` are paired in order. Returns nil when the
    /// quad is degenerate (too small, collinear, or self-intersecting).
    public static func homography(
        fromImagePoints imagePoints: [SIMD2<Double>],
        toBoardPoints boardPoints: [SIMD2<Double>]
    ) -> PerspectiveTransform? {
        guard imagePoints.count == 4, boardPoints.count == 4 else { return nil }
        guard isConvexQuad(imagePoints), isConvexQuad(boardPoints) else { return nil }

        var rows = [[Double]](repeating: [Double](repeating: 0, count: 8), count: 8)
        var rhs = [Double](repeating: 0, count: 8)
        for index in 0 ..< 4 {
            let image = imagePoints[index]
            let board = boardPoints[index]
            let row = index * 2
            rows[row] = [image.x, image.y, 1, 0, 0, 0, -board.x * image.x, -board.x * image.y]
            rhs[row] = board.x
            rows[row + 1] = [0, 0, 0, image.x, image.y, 1, -board.y * image.x, -board.y * image.y]
            rhs[row + 1] = board.y
        }
        guard let solution = solveLinearSystem(rows, rhs) else { return nil }
        let transform = PerspectiveTransform(uncheckedValues: solution + [1])
        for index in 0 ..< 4 {
            guard let mapped = transform.apply(toImageX: imagePoints[index].x, imageY: imagePoints[index].y) else {
                return nil
            }
            let error = hypot(mapped.x - boardPoints[index].x, mapped.y - boardPoints[index].y)
            if error > 0.001 { return nil }
        }
        return transform
    }

    func inverted() -> PerspectiveTransform? {
        let m = values
        let a = m[0], b = m[1], c = m[2]
        let d = m[3], e = m[4], f = m[5]
        let g = m[6], h = m[7], i = m[8]
        let cofactor00 = e * i - f * h
        let cofactor01 = f * g - d * i
        let cofactor02 = d * h - e * g
        let determinant = a * cofactor00 + b * cofactor01 + c * cofactor02
        guard abs(determinant) > 1e-10 else { return nil }
        let inverseDeterminant = 1 / determinant
        return PerspectiveTransform(uncheckedValues: [
            cofactor00 * inverseDeterminant,
            (c * h - b * i) * inverseDeterminant,
            (b * f - c * e) * inverseDeterminant,
            cofactor01 * inverseDeterminant,
            (a * i - c * g) * inverseDeterminant,
            (c * d - a * f) * inverseDeterminant,
            cofactor02 * inverseDeterminant,
            (b * g - a * h) * inverseDeterminant,
            (a * e - b * d) * inverseDeterminant,
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

    private static func isConvexQuad(_ points: [SIMD2<Double>]) -> Bool {
        var sign = 0.0
        for index in 0 ..< 4 {
            let current = points[index]
            let next = points[(index + 1) % 4]
            let after = points[(index + 2) % 4]
            let cross = (next.x - current.x) * (after.y - next.y) - (next.y - current.y) * (after.x - next.x)
            if abs(cross) < 1e-8 { return false }
            if sign == 0 {
                sign = cross
            } else if cross * sign < 0 {
                return false
            }
        }
        return true
    }

    /// Gaussian elimination with partial pivoting. `matrix` is copied and row-reduced.
    private static func solveLinearSystem(_ matrix: [[Double]], _ rhs: [Double]) -> [Double]? {
        let count = rhs.count
        guard matrix.count == count, matrix.allSatisfy({ $0.count == count }) else { return nil }
        var rows = matrix
        var values = rhs
        for column in 0 ..< count {
            var pivotRow = column
            var pivotMagnitude = abs(rows[column][column])
            for row in (column + 1) ..< count where abs(rows[row][column]) > pivotMagnitude {
                pivotMagnitude = abs(rows[row][column])
                pivotRow = row
            }
            if pivotMagnitude < 1e-10 { return nil }
            if pivotRow != column {
                rows.swapAt(pivotRow, column)
                values.swapAt(pivotRow, column)
            }
            let diagonal = rows[column][column]
            for row in (column + 1) ..< count {
                let factor = rows[row][column] / diagonal
                if factor == 0 { continue }
                for index in column ..< count {
                    rows[row][index] -= factor * rows[column][index]
                }
                values[row] -= factor * values[column]
            }
        }
        var solution = [Double](repeating: 0, count: count)
        for row in stride(from: count - 1, through: 0, by: -1) {
            var sum = values[row]
            if row + 1 < count {
                for column in (row + 1) ..< count {
                    sum -= rows[row][column] * solution[column]
                }
            }
            if abs(rows[row][row]) < 1e-12 { return nil }
            solution[row] = sum / rows[row][row]
        }
        return solution
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
    /// Circle-fit calibrations compare later contour observations and pause on drift.
    /// A tapped homography does not: the contour fitter disagrees with a tilted board
    /// and would pause the session on the next frame.
    public let monitorsContourDrift: Bool

    /// Where a segment wire crosses the outer double wire, in tap order: 5|20, 13|6, 17|3,
    /// 8|11 (the DeepDarts points). A crossing is a visible corner; a segment's midpoint is not.
    public static let outerWireCalibrationCrossings: [(left: Int, right: Int)] = [(5, 20), (13, 6), (17, 3), (8, 11)]
    /// Board-plane positions of the crossings: y points up and a radius of `1` is the
    /// outer double wire. Each sits half a wedge (9°) anticlockwise of 20, 6, 3, and 11.
    public static let outerWireBoardPoints: [SIMD2<Double>] = [-9.0, 81, 171, 261].map { degrees in
        let radians = degrees * Double.pi / 180
        return SIMD2(sin(radians), cos(radians))
    }

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
        self.monitorsContourDrift = true
    }

    /// Locks a calibration from four tapped image points, in `outerWireCalibrationCrossings` order.
    public init?(
        outerWireImagePoints: [SIMD2<Double>],
        quality: CalibrationQuality,
        calibratedAt: Date = Date()
    ) {
        guard outerWireImagePoints.count == Self.outerWireBoardPoints.count,
              let transform = PerspectiveTransform.homography(
                fromImagePoints: outerWireImagePoints,
                toBoardPoints: Self.outerWireBoardPoints
              ),
              let inverse = transform.inverted(),
              let center = inverse.apply(toImageX: 0, imageY: 0),
              let top = inverse.apply(toImageX: 0, imageY: 1)
        else { return nil }
        let radius = hypot(top.x - center.x, top.y - center.y)
        guard radius > 0, center.x.isFinite, center.y.isFinite else { return nil }
        self.centerX = center.x
        self.centerY = center.y
        self.radius = radius
        self.segmentRotationDegrees = 0
        self.transform = transform
        self.quality = quality
        self.calibratedAt = calibratedAt
        self.monitorsContourDrift = false
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

    /// Board-plane radius (double-outer = 1) used for legacy proximity checks.
    public static let maxImpactRadius = 1.5

    /// How far from the board center (in board units) motion can still be a dart,
    /// including the surround and floor just below the board. Past this is ignored.
    public static let maxDetectionRadius = 2.5

    /// Typical tip-to-flight-center distance of a thrown steel-tip dart, in board units
    /// (outer double radius = 1, about 170 mm).
    public static let dartTipToFlightLength = 0.7

    /// Image vector (width units) from a dart's flight center to its tip at the board
    /// center. Darts stand out of the board toward the camera, so off-axis cameras see
    /// the flight displaced from the tip. Recovers the board pose from the homography
    /// with a pinhole camera of the given horizontal field of view.
    public func dartTipOffset(
        horizontalFieldOfViewDegrees fieldOfView: Double,
        aspectRatio: Double,
        dartLength: Double = Self.dartTipToFlightLength
    ) -> SIMD2<Double>? {
        guard fieldOfView > 0, fieldOfView < 180, aspectRatio > 0,
              let boardToImage = transform.inverted() else { return nil }
        let focal = 0.5 / tan(fieldOfView * Double.pi / 360)
        let principal = SIMD2(0.5, aspectRatio / 2)
        let m = boardToImage.values
        func cameraSpace(_ x: Double, _ y: Double, _ w: Double) -> SIMD3<Double> {
            SIMD3((x - principal.x * w) / focal, (y - principal.y * w) / focal, w)
        }
        func length(_ v: SIMD3<Double>) -> Double { (v * v).sum().squareRoot() }

        var axisX = cameraSpace(m[0], m[3], m[6])
        var axisY = cameraSpace(m[1], m[4], m[7])
        var center = cameraSpace(m[2], m[5], m[8])
        let scale = 2 / (length(axisX) + length(axisY))
        guard scale.isFinite, scale > 0 else { return nil }
        axisX *= scale
        axisY *= scale
        center *= scale
        if center.z < 0 {
            axisX = -axisX
            axisY = -axisY
            center = -center
        }
        var normal = SIMD3(
            axisX.y * axisY.z - axisX.z * axisY.y,
            axisX.z * axisY.x - axisX.x * axisY.z,
            axisX.x * axisY.y - axisX.y * axisY.x
        )
        let normalLength = length(normal)
        guard normalLength > 0 else { return nil }
        normal /= normalLength
        if (normal * center).sum() > 0 { normal = -normal }

        let flight = center + normal * dartLength
        guard flight.z > 0 else { return nil }
        func project(_ point: SIMD3<Double>) -> SIMD2<Double> {
            SIMD2(focal * point.x / point.z, focal * point.y / point.z) + principal
        }
        return project(center) - project(flight)
    }

    /// Whether an image point is close enough to the board to be a dart.
    public func isNearBoard(atImageX x: Double, imageY y: Double) -> Bool {
        guard let point = transform.apply(toImageX: x, imageY: y) else { return false }
        return point.radius <= Self.maxImpactRadius
    }

    /// Whether motion at this image point should be considered for dart detection.
    public func isWithinDetectionZone(atImageX x: Double, imageY y: Double) -> Bool {
        guard let point = transform.apply(toImageX: x, imageY: y) else { return false }
        return point.radius <= Self.maxDetectionRadius
    }

    /// Maps a normalized image point to the dart it scores under this calibration.
    /// Returns `nil` for points far outside the board area. Surround and near-miss
    /// throws map to a miss dart.
    public func dartInput(atImageX x: Double, imageY y: Double) -> DartInput? {
        guard let point = transform.apply(toImageX: x, imageY: y),
              point.radius <= Self.maxDetectionRadius else { return nil }
        return DartboardGeometry.dartInput(at: point)
    }
}
