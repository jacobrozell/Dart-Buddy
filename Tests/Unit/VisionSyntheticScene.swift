import Foundation
@testable import DartBuddy

/// Synthetic camera + dartboard renderer for vision tests: a pinhole camera looking
/// at a regulation board from a chosen angle, with optional darts sticking out of
/// the face. Lets the detection pipeline be checked end to end against ground truth.
struct SyntheticCamera {
    let focalLength: Double
    let aspectRatio: Double
    /// Board axes (x right, y up, z towards the thrower) and origin in camera space.
    let axisX: SIMD3<Double>
    let axisY: SIMD3<Double>
    let axisZ: SIMD3<Double>
    let origin: SIMD3<Double>

    /// - Parameters:
    ///   - yawDegrees: camera placed to the side (positive = board turned about the vertical axis).
    ///   - pitchDegrees: camera placed above/below.
    ///   - rollDegrees: camera rotated about its optical axis.
    ///   - distance: board centre depth in board radii.
    ///   - centerX/centerY: where the board centre lands in the image (width units).
    init(
        yawDegrees: Double = 0,
        pitchDegrees: Double = 0,
        rollDegrees: Double = 0,
        distance: Double = 5,
        focalLength: Double = 0.9,
        aspectRatio: Double = 9.0 / 16.0,
        centerX: Double = 0.5,
        centerY: Double? = nil
    ) {
        func rotate(_ v: SIMD3<Double>) -> SIMD3<Double> {
            let yaw = yawDegrees * Double.pi / 180
            let pitch = pitchDegrees * Double.pi / 180
            let roll = rollDegrees * Double.pi / 180
            // yaw about camera y
            var p = SIMD3(v.x * cos(yaw) + v.z * sin(yaw), v.y, -v.x * sin(yaw) + v.z * cos(yaw))
            // pitch about camera x
            p = SIMD3(p.x, p.y * cos(pitch) - p.z * sin(pitch), p.y * sin(pitch) + p.z * cos(pitch))
            // roll about camera z
            return SIMD3(p.x * cos(roll) - p.y * sin(roll), p.x * sin(roll) + p.y * cos(roll), p.z)
        }
        self.focalLength = focalLength
        self.aspectRatio = aspectRatio
        axisX = rotate(SIMD3(1, 0, 0))
        axisY = rotate(SIMD3(0, -1, 0))
        axisZ = rotate(SIMD3(0, 0, -1))
        let cy = centerY ?? aspectRatio / 2
        origin = SIMD3(
            (centerX - 0.5) * distance / focalLength,
            (cy - aspectRatio / 2) * distance / focalLength,
            distance
        )
    }

    func project(x: Double, y: Double, height: Double = 0) -> ImagePoint {
        let p = axisX * x + axisY * y + axisZ * height + origin
        return ImagePoint(x: focalLength * p.x / p.z + 0.5, y: focalLength * p.y / p.z + aspectRatio / 2)
    }

    var controlPoints: BoardControlPoints {
        BoardControlPoints(
            top: project(x: 0, y: 1),
            right: project(x: 1, y: 0),
            bottom: project(x: 0, y: -1),
            left: project(x: -1, y: 0)
        )
    }

    func calibration(fitConfidence: Double = 0.95) -> BoardCalibration? {
        BoardCalibration(
            controlPoints: controlPoints,
            imageAspectRatio: aspectRatio,
            quality: CalibrationQuality(fitConfidence: fitConfidence, brightness: 0.5, sharpness: 0.8)
        )
    }
}

/// A dart stuck in the board, in board units.
struct SyntheticDart {
    var tipX: Double
    var tipY: Double
    /// Sideways lean of the dart as offsets of the flight from straight-out.
    var leanX: Double = 0
    var leanY: Double = 0.12
    var length: Double = 0.85

    func point(at fraction: Double) -> (x: Double, y: Double, height: Double) {
        let reach = length * fraction
        return (tipX + leanX * fraction, tipY + leanY * fraction, reach)
    }
}

enum SyntheticScene {
    typealias RGB = (r: Double, g: Double, b: Double)

    static let wall: RGB = (120, 112, 100)
    static let surround: RGB = (24, 24, 26)
    static let black: RGB = (30, 30, 32)
    static let cream: RGB = (222, 206, 168)
    static let red: RGB = (196, 34, 44)
    static let green: RGB = (22, 128, 70)

    static func boardColor(at point: BoardPoint) -> RGB {
        let radius = point.radius
        if radius > 1.33 { return wall }
        if radius > DartboardGeometry.RingRadius.doubleOuter { return surround }
        if radius <= DartboardGeometry.RingRadius.innerBull { return red }
        if radius <= DartboardGeometry.RingRadius.outerBull { return green }
        let angle = DartboardGeometry.angleDegrees(of: point)
        let wedge = Int(((angle + 9).truncatingRemainder(dividingBy: 360)) / 18) % 20
        let isRedWedge = DartboardGeometry.ringIsRed(wedgeIndex: wedge)
        let inRing = (radius >= DartboardGeometry.RingRadius.tripleInner && radius <= DartboardGeometry.RingRadius.tripleOuter)
            || radius >= DartboardGeometry.RingRadius.doubleInner
        if inRing { return isRedWedge ? red : green }
        return isRedWedge ? black : cream
    }

    /// Renders the scene. `brightness` scales all colours (dim rooms); `darts` are drawn on top.
    static func render(
        camera: SyntheticCamera,
        width: Int,
        darts: [SyntheticDart] = [],
        brightness: Double = 1
    ) -> ColorFrame {
        let height = Int((Double(width) * camera.aspectRatio).rounded())
        guard let boardToImage = camera.controlPoints.boardToImage,
              let imageToBoard = boardToImage.inverted() else {
            fatalError("Synthetic camera produced a degenerate homography")
        }
        let boardRadiusPixels = camera.project(x: 0, y: 0).distance(to: camera.project(x: 1, y: 0)) * Double(width)
        let segments = darts.map { dartSegments($0, camera: camera, width: width, boardRadiusPixels: boardRadiusPixels) }

        var rgb = [UInt8](repeating: 0, count: width * height * 3)
        let samples = [0.25, 0.75]
        for py in 0 ..< height {
            for px in 0 ..< width {
                var r = 0.0, g = 0.0, b = 0.0
                for sy in samples {
                    for sx in samples {
                        let x = (Double(px) + sx) / Double(width)
                        let y = (Double(py) + sy) / Double(width)
                        var color = imageToBoard.apply(toImageX: x, imageY: y).map(boardColor(at:)) ?? wall
                        for dart in segments {
                            for part in dart {
                                let alpha = part.coverage(x: x * Double(width), y: y * Double(width))
                                if alpha > 0 {
                                    color = (
                                        color.r + (part.color.r - color.r) * alpha,
                                        color.g + (part.color.g - color.g) * alpha,
                                        color.b + (part.color.b - color.b) * alpha
                                    )
                                }
                            }
                        }
                        r += color.r
                        g += color.g
                        b += color.b
                    }
                }
                let index = (py * width + px) * 3
                rgb[index] = UInt8(max(0, min(255, r / 4 * brightness)))
                rgb[index + 1] = UInt8(max(0, min(255, g / 4 * brightness)))
                rgb[index + 2] = UInt8(max(0, min(255, b / 4 * brightness)))
            }
        }
        guard let frame = ColorFrame(width: width, height: height, rgb: rgb) else {
            fatalError("Synthetic frame has inconsistent dimensions")
        }
        return frame
    }

    struct Capsule {
        let ax: Double, ay: Double, bx: Double, by: Double
        let halfWidth: Double
        let color: RGB

        func coverage(x: Double, y: Double) -> Double {
            let dx = bx - ax
            let dy = by - ay
            let lengthSquared = dx * dx + dy * dy
            let t = lengthSquared > 0 ? max(0, min(1, ((x - ax) * dx + (y - ay) * dy) / lengthSquared)) : 0
            let cx = ax + t * dx
            let cy = ay + t * dy
            let distance = ((x - cx) * (x - cx) + (y - cy) * (y - cy)).squareRoot()
            return max(0, min(1, halfWidth - distance + 0.5))
        }
    }

    /// Point, barrel, shaft and flight as projected capsules (pixel coordinates).
    private static func dartSegments(
        _ dart: SyntheticDart,
        camera: SyntheticCamera,
        width: Int,
        boardRadiusPixels: Double
    ) -> [Capsule] {
        func pixel(_ fraction: Double) -> ImagePoint {
            let p = dart.point(at: fraction)
            let image = camera.project(x: p.x, y: p.y, height: p.height)
            return ImagePoint(x: image.x * Double(width), y: image.y * Double(width))
        }
        let parts: [(Double, Double, Double, RGB)] = [
            (0.0, 0.16, 0.008, (165, 165, 172)), // point
            (0.16, 0.48, 0.022, (150, 152, 160)), // barrel
            (0.48, 0.74, 0.013, (60, 60, 66)), // shaft
            (0.74, 1.0, 0.07, (40, 90, 210)), // flight
        ]
        return parts.map { start, end, halfWidth, color in
            let a = pixel(start)
            let b = pixel(end)
            return Capsule(ax: a.x, ay: a.y, bx: b.x, by: b.y, halfWidth: max(0.6, halfWidth * boardRadiusPixels), color: color)
        }
    }

    /// Crops a region of a colour frame into the luma/chroma grid the impact detector consumes.
    static func impactFrame(from frame: ColorFrame, region: ImageRegion, size: Int) -> ImpactFrame {
        var luma = [Float](repeating: 0.1, count: size * size)
        var cb = [Float](repeating: 0.5, count: size * size)
        var cr = [Float](repeating: 0.5, count: size * size)
        for gy in 0 ..< size {
            for gx in 0 ..< size {
                let point = region.imagePoint(
                    normalizedX: (Double(gx) + 0.5) / Double(size),
                    normalizedY: (Double(gy) + 0.5) / Double(size)
                )
                let px = Int(point.x * Double(frame.width))
                let py = Int(point.y * Double(frame.width))
                guard px >= 0, py >= 0, px < frame.width, py < frame.height else { continue }
                let index = (py * frame.width + px) * 3
                let r = Double(frame.rgb[index]) / 255
                let g = Double(frame.rgb[index + 1]) / 255
                let b = Double(frame.rgb[index + 2]) / 255
                let y = 0.299 * r + 0.587 * g + 0.114 * b
                luma[gy * size + gx] = Float(y)
                cb[gy * size + gx] = Float(0.5 + (b - y) * 0.564)
                cr[gy * size + gx] = Float(0.5 + (r - y) * 0.713)
            }
        }
        guard let result = ImpactFrame(width: size, height: size, luma: luma, cb: cb, cr: cr) else {
            fatalError("Synthetic impact frame has inconsistent dimensions")
        }
        return result
    }
}
