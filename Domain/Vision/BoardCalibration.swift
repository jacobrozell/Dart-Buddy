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

    public func apply(toImageX x: Double, imageY y: Double) -> BoardPoint? {
        applyPoint(x: x, y: y).map { BoardPoint(x: $0.x, y: $0.y) }
    }

    /// Applies the homography to an arbitrary plane point.
    public func applyPoint(x: Double, y: Double) -> ImagePoint? {
        let m = values
        let w = m[6] * x + m[7] * y + m[8]
        guard abs(w) > 1e-12 else { return nil }
        return ImagePoint(
            x: (m[0] * x + m[1] * y + m[2]) / w,
            y: (m[3] * x + m[4] * y + m[5]) / w
        )
    }

    /// Exact homography taking four source points to four destination points
    /// (no three collinear). Returns `nil` for degenerate configurations.
    public static func mapping(from source: [ImagePoint], to destination: [ImagePoint]) -> PerspectiveTransform? {
        guard source.count == 4, destination.count == 4 else { return nil }
        var matrix: [[Double]] = []
        var rhs: [Double] = []
        for index in 0 ..< 4 {
            let s = source[index]
            let d = destination[index]
            matrix.append([s.x, s.y, 1, 0, 0, 0, -d.x * s.x, -d.x * s.y])
            rhs.append(d.x)
            matrix.append([0, 0, 0, s.x, s.y, 1, -d.y * s.x, -d.y * s.y])
            rhs.append(d.y)
        }
        guard let h = LinearAlgebra.solve(matrix, rhs) else { return nil }
        let transform = PerspectiveTransform(uncheckedValues: h + [1])
        // Reject solutions that fail to reproduce the inputs (near-degenerate systems).
        for index in 0 ..< 4 {
            guard let mapped = transform.applyPoint(x: source[index].x, y: source[index].y),
                  abs(mapped.x - destination[index].x) < 1e-6,
                  abs(mapped.y - destination[index].y) < 1e-6 else { return nil }
        }
        return transform
    }

    /// Inverse homography, or `nil` when the matrix is singular.
    public func inverted() -> PerspectiveTransform? {
        guard let inverse = LinearAlgebra.invert3x3(values) else { return nil }
        return PerspectiveTransform(uncheckedValues: inverse)
    }
}

/// A point in aspect-corrected image "width units": x spans `0...1` across the
/// image width and y grows downward in the same physical scale.
public struct ImagePoint: Codable, Equatable, Sendable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }

    public func distance(to other: ImagePoint) -> Double {
        ((x - other.x) * (x - other.x) + (y - other.y) * (y - other.y)).squareRoot()
    }
}

/// Image positions of four known board landmarks: where the outer edge of the
/// double ring crosses the middle of the 20 (top), 6 (right), 3 (bottom) and
/// 11 (left) wedges. Four points fully determine the board homography, so this is
/// both the output of auto-detection and what the manual fine-tune handles edit.
public struct BoardControlPoints: Codable, Equatable, Sendable {
    public var top: ImagePoint
    public var right: ImagePoint
    public var bottom: ImagePoint
    public var left: ImagePoint

    public init(top: ImagePoint, right: ImagePoint, bottom: ImagePoint, left: ImagePoint) {
        self.top = top
        self.right = right
        self.bottom = bottom
        self.left = left
    }

    /// Board-plane positions matching `ordered`.
    public static let boardLandmarks = [
        ImagePoint(x: 0, y: 1), ImagePoint(x: 1, y: 0), ImagePoint(x: 0, y: -1), ImagePoint(x: -1, y: 0),
    ]

    public var ordered: [ImagePoint] { [top, right, bottom, left] }

    public init?(ordered points: [ImagePoint]) {
        guard points.count == 4 else { return nil }
        self.init(top: points[0], right: points[1], bottom: points[2], left: points[3])
    }

    /// Homography taking board-plane points to image points.
    public var boardToImage: PerspectiveTransform? {
        PerspectiveTransform.mapping(from: Self.boardLandmarks, to: ordered)
    }

    /// Control points for the same camera view with the board numbering rotated by
    /// whole wedges (positive = clockwise), used to fix a wrong "20" guess.
    public func rotated(byWedges wedges: Int) -> BoardControlPoints? {
        guard let boardToImage else { return nil }
        let theta = Double(wedges) * DartboardGeometry.wedgeAngleDegrees * Double.pi / 180
        let rotated = Self.boardLandmarks.compactMap { landmark -> ImagePoint? in
            // Clockwise rotation in a y-up plane.
            let x = landmark.x * cos(theta) + landmark.y * sin(theta)
            let y = landmark.y * cos(theta) - landmark.x * sin(theta)
            return boardToImage.applyPoint(x: x, y: y)
        }
        return BoardControlPoints(ordered: rotated)
    }

    /// Averages several observations of the same board (temporal smoothing).
    public static func average(_ samples: [BoardControlPoints]) -> BoardControlPoints? {
        guard !samples.isEmpty else { return nil }
        let count = Double(samples.count)
        let points = (0 ..< 4).map { index in
            ImagePoint(
                x: samples.map { $0.ordered[index].x }.reduce(0, +) / count,
                y: samples.map { $0.ordered[index].y }.reduce(0, +) / count
            )
        }
        return BoardControlPoints(ordered: points)
    }

    /// Largest landmark displacement between two observations, in width units.
    public func maxDisplacement(from other: BoardControlPoints) -> Double {
        zip(ordered, other.ordered).map { $0.distance(to: $1) }.max() ?? 0
    }
}

/// Small dense linear-algebra helpers for calibration math.
enum LinearAlgebra {
    /// Solves `matrix * x = rhs` by Gaussian elimination with partial pivoting.
    static func solve(_ matrix: [[Double]], _ rhs: [Double]) -> [Double]? {
        let n = rhs.count
        guard matrix.count == n, matrix.allSatisfy({ $0.count == n }) else { return nil }
        var a = matrix
        var b = rhs
        for column in 0 ..< n {
            var pivot = column
            for row in (column + 1) ..< n where abs(a[row][column]) > abs(a[pivot][column]) {
                pivot = row
            }
            guard abs(a[pivot][column]) > 1e-12 else { return nil }
            if pivot != column {
                a.swapAt(pivot, column)
                b.swapAt(pivot, column)
            }
            for row in (column + 1) ..< n {
                let factor = a[row][column] / a[column][column]
                guard factor != 0 else { continue }
                for k in column ..< n {
                    a[row][k] -= factor * a[column][k]
                }
                b[row] -= factor * b[column]
            }
        }
        var x = [Double](repeating: 0, count: n)
        for row in stride(from: n - 1, through: 0, by: -1) {
            var sum = b[row]
            for k in (row + 1) ..< n {
                sum -= a[row][k] * x[k]
            }
            x[row] = sum / a[row][row]
        }
        return x.allSatisfy(\.isFinite) ? x : nil
    }

    /// Inverse of a row-major 3x3 matrix via the adjugate.
    static func invert3x3(_ m: [Double]) -> [Double]? {
        guard m.count == 9 else { return nil }
        let c00 = m[4] * m[8] - m[5] * m[7]
        let c01 = m[5] * m[6] - m[3] * m[8]
        let c02 = m[3] * m[7] - m[4] * m[6]
        let det = m[0] * c00 + m[1] * c01 + m[2] * c02
        let scale = m.map { abs($0) }.max() ?? 0
        guard scale > 0, abs(det) > 1e-14 * scale * scale * scale else { return nil }
        let inverse = [
            c00, m[2] * m[7] - m[1] * m[8], m[1] * m[5] - m[2] * m[4],
            c01, m[0] * m[8] - m[2] * m[6], m[2] * m[3] - m[0] * m[5],
            c02, m[1] * m[6] - m[0] * m[7], m[0] * m[4] - m[1] * m[3],
        ].map { $0 / det }
        return inverse.allSatisfy(\.isFinite) ? inverse : nil
    }
}

/// Live measurements that gate whether calibration (or an individual frame) is usable.
public struct CalibrationQuality: Codable, Equatable, Sendable {
    /// How well the calibrated board model explains the frame, `0...1`. For detected
    /// boards this is the red/green ring colour agreement (see `BoardDetector`).
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

    public static let minimumFitConfidence = 0.6
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
    /// Image (width units) -> board plane.
    public let transform: PerspectiveTransform
    /// Board plane -> image (width units).
    public let boardToImage: PerspectiveTransform
    /// Frame height divided by width; locates the principal point for pose recovery.
    public let imageAspectRatio: Double
    public let quality: CalibrationQuality
    public let calibratedAt: Date

    public init?(
        centerX: Double,
        centerY: Double,
        radius: Double,
        segmentRotationDegrees: Double = 0,
        imageAspectRatio: Double = 9.0 / 16.0,
        quality: CalibrationQuality,
        calibratedAt: Date = Date()
    ) {
        guard let transform = PerspectiveTransform.circleFit(
            centerX: centerX,
            centerY: centerY,
            radius: radius,
            rotationDegrees: segmentRotationDegrees
        ), let boardToImage = transform.inverted() else { return nil }
        self.centerX = centerX
        self.centerY = centerY
        self.radius = radius
        self.segmentRotationDegrees = segmentRotationDegrees
        self.transform = transform
        self.boardToImage = boardToImage
        self.imageAspectRatio = imageAspectRatio
        self.quality = quality
        self.calibratedAt = calibratedAt
    }

    /// Full perspective calibration from four board landmarks (auto-detected or
    /// hand-placed). Handles cameras that view the board from an angle.
    public init?(
        controlPoints: BoardControlPoints,
        imageAspectRatio: Double,
        quality: CalibrationQuality,
        calibratedAt: Date = Date()
    ) {
        guard imageAspectRatio > 0,
              let boardToImage = controlPoints.boardToImage,
              let transform = boardToImage.inverted(),
              let center = boardToImage.applyPoint(x: 0, y: 0) else { return nil }
        let radius = controlPoints.ordered.map { $0.distance(to: center) }.reduce(0, +) / 4
        guard radius > 0, radius.isFinite else { return nil }
        self.centerX = center.x
        self.centerY = center.y
        self.radius = radius
        self.segmentRotationDegrees = 0
        self.transform = transform
        self.boardToImage = boardToImage
        self.imageAspectRatio = imageAspectRatio
        self.quality = quality
        self.calibratedAt = calibratedAt
    }

    /// The four landmark image positions implied by this calibration.
    public var controlPoints: BoardControlPoints? {
        BoardControlPoints(ordered: BoardControlPoints.boardLandmarks.compactMap {
            boardToImage.applyPoint(x: $0.x, y: $0.y)
        })
    }

    /// Projects a board-plane point into the image (width units).
    public func imagePoint(for point: BoardPoint) -> ImagePoint? {
        boardToImage.applyPoint(x: point.x, y: point.y)
    }

    /// Camera pose relative to the board, for reasoning about where a dart's
    /// barrel and flight (which stick out of the board plane) appear in the image.
    public var pose: BoardPose? {
        BoardPose(boardToImage: boardToImage, imageAspectRatio: imageAspectRatio)
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
