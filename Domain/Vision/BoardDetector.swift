import Foundation

/// A dartboard located in a camera frame.
public struct BoardDetection: Equatable, Sendable {
    /// Landmark positions in image width units.
    public let controlPoints: BoardControlPoints
    /// Fraction of double/triple ring samples whose colour matches the board model, `0...1`.
    public let agreement: Double
    /// Whether the bull was found. Without it the centre falls back to the ellipse
    /// centre, which is slightly off for angled cameras.
    public let usedBullCenter: Bool
}

/// Finds a standard bristle dartboard in a colour frame with no user input.
///
/// The red and green scoring beds are the most distinctive thing on a board, so the
/// detector works from colour alone:
/// 1. classify saturated red/green pixels;
/// 2. take the outer edge of the largest ring-shaped blob (the double ring) and fit
///    an ellipse — the perspective image of the board's outer scoring circle;
/// 3. locate the bull, which is the image of the circle's centre. An ellipse plus the
///    image of its circle's centre fixes the board homography up to a spin about the
///    centre (pole–polar construction of two perpendicular diameters);
/// 4. resolve the spin from the red/green alternation around the double and triple
///    rings, taking the red wedge nearest the top of the image as the 20.
public enum BoardDetector {
    enum RingColor: UInt8 {
        case none = 0
        case red = 1
        case green = 2
    }

    static let boundaryBins = 180
    static let doubleRingSampleRadii = [0.963, 0.976, 0.989]
    static let tripleRingSampleRadii = [0.593, 0.606, 0.619]

    public static func detect(in frame: ColorFrame) -> BoardDetection? {
        let classes = classify(frame)
        var mask = [Bool](repeating: false, count: classes.count)
        for index in classes.indices where classes[index] != RingColor.none.rawValue {
            mask[index] = true
        }
        let dilated = dilate(mask, width: frame.width, height: frame.height)
        let minimumSize = max(40, frame.width * frame.height / 4000)
        let components = ConnectedComponents.find(
            mask: dilated,
            width: frame.width,
            height: frame.height,
            minimumSize: minimumSize
        )
        .sorted { $0.boundingArea > $1.boundingArea }
        .prefix(3)

        var best: BoardDetection?
        for component in components {
            guard let detection = detection(from: component, mask: mask, classes: classes, frame: frame) else {
                continue
            }
            if detection.agreement > (best?.agreement ?? 0) {
                best = detection
            }
        }
        return best
    }

    /// Colour agreement of an existing calibration against a new frame. Drops sharply
    /// when the camera or board has moved, so it doubles as a drift check.
    public static func agreement(of calibration: BoardCalibration, in frame: ColorFrame) -> Double {
        let classes = classify(frame)
        let signal = ringSignal(boardToImage: calibration.boardToImage, classes: classes, frame: frame)
        return correlation(signal: signal.values, phaseDegrees: -DartboardGeometry.wedgeAngleDegrees / 2)
            / Double(signal.maximum)
    }

    // MARK: - Colour classification

    static func classify(_ frame: ColorFrame) -> [UInt8] {
        var classes = [UInt8](repeating: 0, count: frame.width * frame.height)
        frame.rgb.withUnsafeBufferPointer { rgb in
            classes.withUnsafeMutableBufferPointer { out in
                for index in 0 ..< out.count {
                    out[index] = ringColor(
                        red: Int(rgb[index * 3]),
                        green: Int(rgb[index * 3 + 1]),
                        blue: Int(rgb[index * 3 + 2])
                    ).rawValue
                }
            }
        }
        return classes
    }

    /// Saturated red or green, tolerant of dim rooms and warm/cool white balance.
    static func ringColor(red: Int, green: Int, blue: Int) -> RingColor {
        let maximum = max(red, green, blue)
        let minimum = min(red, green, blue)
        let chroma = maximum - minimum
        // value > ~0.16 and saturation > ~0.38
        guard maximum > 40, chroma * 100 > maximum * 38 else { return .none }
        if maximum == red {
            // hue within about ±25° of pure red
            return abs(green - blue) * 100 <= chroma * 42 ? .red : .none
        }
        if maximum == green {
            // hue between about 75° and 175°
            let offset = (blue - red) * 100
            return offset >= -75 * chroma && offset <= 92 * chroma ? .green : .none
        }
        return .none
    }

    static func dilate(_ mask: [Bool], width: Int, height: Int) -> [Bool] {
        var out = mask
        for y in 0 ..< height {
            for x in 0 ..< width where mask[y * width + x] {
                for ny in max(0, y - 1) ... min(height - 1, y + 1) {
                    for nx in max(0, x - 1) ... min(width - 1, x + 1) {
                        out[ny * width + nx] = true
                    }
                }
            }
        }
        return out
    }

    // MARK: - Ellipse + centre -> homography

    private static func detection(
        from component: ConnectedComponents.Component,
        mask: [Bool],
        classes: [UInt8],
        frame: ColorFrame
    ) -> BoardDetection? {
        let boundary = outerBoundary(of: component, mask: mask, frame: frame)
        guard boundary.count >= boundaryBins / 2,
              let ellipse = EllipseFit.fit(boundary, minimumInlierFraction: 0.6) else { return nil }
        let minorAxis = min(ellipse.semiAxisA, ellipse.semiAxisB)
        let majorAxis = max(ellipse.semiAxisA, ellipse.semiAxisB)
        guard minorAxis >= 12, minorAxis / majorAxis >= 0.3 else { return nil }

        let bull = bullCenter(ellipse: ellipse, classes: classes, frame: frame)
        let center = bull ?? ImagePoint(x: ellipse.centerX, y: ellipse.centerY)
        guard let diameters = ellipse.perpendicularDiameters(throughCircleCenter: center) else { return nil }

        // Pixel indices -> width units (a pixel's centre sits half a pixel past its index).
        let scale = 1.0 / Double(frame.width)
        let landmarks = diameters.map { ImagePoint(x: ($0.x + 0.5) * scale, y: ($0.y + 0.5) * scale) }
        guard let unrotated = PerspectiveTransform.mapping(
            from: BoardControlPoints.boardLandmarks,
            to: landmarks
        ) else { return nil }

        let signal = ringSignal(boardToImage: unrotated, classes: classes, frame: frame)
        let phase = bestPhase(signal: signal.values)
        let agreement = phase.correlation / Double(signal.maximum)
        guard agreement > 0.2,
              let twentyAngle = topmostRedWedgeAngle(phaseDegrees: phase.degrees, boardToImage: unrotated) else {
            return nil
        }

        let rotated = BoardControlPoints.boardLandmarks.compactMap { landmark -> ImagePoint? in
            let theta = twentyAngle * Double.pi / 180
            let x = landmark.x * cos(theta) + landmark.y * sin(theta)
            let y = landmark.y * cos(theta) - landmark.x * sin(theta)
            return unrotated.applyPoint(x: x, y: y)
        }
        guard let controlPoints = BoardControlPoints(ordered: rotated) else { return nil }
        return BoardDetection(controlPoints: controlPoints, agreement: agreement, usedBullCenter: bull != nil)
    }

    /// Farthest ring pixel in each direction from the blob's middle, refined to
    /// sub-pixel precision: points on the outer edge of the double ring.
    private static func outerBoundary(
        of component: ConnectedComponents.Component,
        mask: [Bool],
        frame: ColorFrame
    ) -> [ImagePoint] {
        let width = frame.width
        let centerX = Double(component.minX + component.maxX) / 2
        let centerY = Double(component.minY + component.maxY) / 2
        var farthest = [Double](repeating: -1, count: boundaryBins)
        var farthestIndex = [Int](repeating: 0, count: boundaryBins)
        // The component was labelled on the dilated mask; only original pixels mark the edge.
        for index in component.pixels where mask[index] {
            let dx = Double(index % width) - centerX
            let dy = Double(index / width) - centerY
            let distanceSquared = dx * dx + dy * dy
            let turn = (atan2(dy, dx) + Double.pi) / (2 * Double.pi)
            let bin = min(boundaryBins - 1, Int(turn * Double(boundaryBins)))
            if distanceSquared > farthest[bin] {
                farthest[bin] = distanceSquared
                farthestIndex[bin] = index
            }
        }

        func chroma(x: Double, y: Double) -> Double? {
            let px = Int(x.rounded())
            let py = Int(y.rounded())
            guard px >= 0, py >= 0, px < frame.width, py < frame.height else { return nil }
            let base = (py * frame.width + px) * 3
            let r = Int(frame.rgb[base])
            let g = Int(frame.rgb[base + 1])
            let b = Int(frame.rgb[base + 2])
            return Double(max(r, g, b) - min(r, g, b))
        }

        var points: [ImagePoint] = []
        for bin in 0 ..< boundaryBins where farthest[bin] > 0 {
            let x = Double(farthestIndex[bin] % width)
            let y = Double(farthestIndex[bin] / width)
            let distance = farthest[bin].squareRoot()
            let ux = (x - centerX) / distance
            let uy = (y - centerY) / distance
            // The colourful ring fades into the dark surround over a pixel or two.
            // Summing the fractional "ring coverage" of the edge pixels places the
            // boundary far more precisely than the last classified pixel alone.
            var offset = 0.5
            if let inside = chroma(x: x - ux * 2.5, y: y - uy * 2.5), inside > 20,
               let outside = chroma(x: x + ux * 3.5, y: y + uy * 3.5), inside - outside > 15 {
                var coverage = 0.0
                for step in 0 ... 2 {
                    let sample = chroma(x: x + ux * Double(step), y: y + uy * Double(step)) ?? outside
                    coverage += min(1, max(0, (sample - outside) / (inside - outside)))
                }
                offset = coverage - 0.5
            }
            points.append(ImagePoint(x: x + ux * offset, y: y + uy * offset))
        }
        return points
    }

    /// Centroid of the red/green bull near the middle of the ellipse (pixel coordinates).
    private static func bullCenter(ellipse: EllipseFit.Ellipse, classes: [UInt8], frame: ColorFrame) -> ImagePoint? {
        let reach = max(ellipse.semiAxisA, ellipse.semiAxisB) * 0.24
        let minX = max(0, Int(ellipse.centerX - reach))
        let maxX = min(frame.width - 1, Int(ellipse.centerX + reach))
        let minY = max(0, Int(ellipse.centerY - reach))
        let maxY = min(frame.height - 1, Int(ellipse.centerY + reach))
        guard minX <= maxX, minY <= maxY else { return nil }

        func centroid(around center: ImagePoint, limit: Double) -> (point: ImagePoint, count: Int)? {
            var sumX = 0.0
            var sumY = 0.0
            var count = 0
            for y in minY ... maxY {
                for x in minX ... maxX where classes[y * frame.width + x] != RingColor.none.rawValue {
                    let rho = ellipse.normalizedRadius(
                        x: Double(x) - center.x + ellipse.centerX,
                        y: Double(y) - center.y + ellipse.centerY
                    )
                    if rho <= limit {
                        sumX += Double(x)
                        sumY += Double(y)
                        count += 1
                    }
                }
            }
            guard count > 0 else { return nil }
            return (ImagePoint(x: sumX / Double(count), y: sumY / Double(count)), count)
        }

        let ellipseCenter = ImagePoint(x: ellipse.centerX, y: ellipse.centerY)
        guard let coarse = centroid(around: ellipseCenter, limit: 0.2),
              let fine = centroid(around: coarse.point, limit: 0.125) else { return nil }
        let bullRatio = DartboardGeometry.RingRadius.outerBull
        let expected = Double.pi * ellipse.semiAxisA * ellipse.semiAxisB * bullRatio * bullRatio
        guard Double(fine.count) >= max(5, expected * 0.3) else { return nil }
        return fine.point
    }

    // MARK: - Ring colour signal

    /// Samples the double and triple rings every half degree (clockwise from the
    /// model's top): +1 per red sample, -1 per green.
    private static func ringSignal(
        boardToImage: PerspectiveTransform,
        classes: [UInt8],
        frame: ColorFrame
    ) -> (values: [Int], maximum: Int) {
        let steps = 720
        let radii = doubleRingSampleRadii + tripleRingSampleRadii
        var values = [Int](repeating: 0, count: steps)
        let width = Double(frame.width)
        for step in 0 ..< steps {
            let angle = Double(step) * 0.5
            var total = 0
            for radius in radii {
                let boardPoint = DartboardGeometry.point(radius: radius, angleDegrees: angle)
                guard let image = boardToImage.applyPoint(x: boardPoint.x, y: boardPoint.y) else { continue }
                let x = Int((image.x * width).rounded(.down))
                let y = Int((image.y * width).rounded(.down))
                guard x >= 0, y >= 0, x < frame.width, y < frame.height else { continue }
                switch classes[y * frame.width + x] {
                case RingColor.red.rawValue: total += 1
                case RingColor.green.rawValue: total -= 1
                default: break
                }
            }
            values[step] = total
        }
        return (values, steps * radii.count)
    }

    /// Correlation with a red/green square wave whose red half-period starts at `phaseDegrees`.
    private static func correlation(signal: [Int], phaseDegrees: Double) -> Double {
        let period = DartboardGeometry.wedgeAngleDegrees * 2
        var total = 0
        for step in signal.indices {
            var offset = (Double(step) * 0.5 - phaseDegrees).truncatingRemainder(dividingBy: period)
            if offset < 0 { offset += period }
            total += offset < period / 2 ? signal[step] : -signal[step]
        }
        return Double(total)
    }

    private static func bestPhase(signal: [Int]) -> (degrees: Double, correlation: Double) {
        let step = 0.25
        let period = DartboardGeometry.wedgeAngleDegrees * 2
        let count = Int(period / step)
        let values = (0 ..< count).map { correlation(signal: signal, phaseDegrees: Double($0) * step) }
        var bestIndex = 0
        for index in values.indices where values[index] > values[bestIndex] {
            bestIndex = index
        }
        // The correlation peak is a triangle; interpolate its apex between samples.
        let before = values[(bestIndex + count - 1) % count]
        let after = values[(bestIndex + 1) % count]
        let peak = values[bestIndex]
        let drop = peak - min(before, after)
        let shift = drop > 0 ? 0.5 * (after - before) / drop : 0
        return ((Double(bestIndex) + shift) * step, peak)
    }

    /// Among the ten red wedges, the angle (in the unrotated model) of the one that
    /// appears highest in the image: the 20 on an upright board.
    private static func topmostRedWedgeAngle(phaseDegrees: Double, boardToImage: PerspectiveTransform) -> Double? {
        guard let center = boardToImage.applyPoint(x: 0, y: 0) else { return nil }
        var best: (angle: Double, upness: Double)?
        for wedge in 0 ..< 10 {
            let angle = phaseDegrees + DartboardGeometry.wedgeAngleDegrees / 2
                + Double(wedge) * DartboardGeometry.wedgeAngleDegrees * 2
            let boardPoint = DartboardGeometry.point(radius: 0.976, angleDegrees: angle)
            guard let image = boardToImage.applyPoint(x: boardPoint.x, y: boardPoint.y) else { continue }
            let length = image.distance(to: center)
            guard length > 0 else { continue }
            let upness = (center.y - image.y) / length
            if upness > (best?.upness ?? -Double.infinity) {
                best = (angle, upness)
            }
        }
        return best?.angle
    }
}

/// Least-squares ellipse fitting and the projective geometry needed to turn an
/// ellipse (the image of a circle) into a homography.
enum EllipseFit {
    /// Conic `a·x² + b·x·y + c·y² + d·x + e·y + f = 0` describing an ellipse.
    struct Ellipse {
        let a: Double
        let b: Double
        let c: Double
        let d: Double
        let e: Double
        let f: Double
        let centerX: Double
        let centerY: Double
        let semiAxisA: Double
        let semiAxisB: Double
        /// Conic value at the centre (negative, since the interior is negative).
        private let centerValue: Double

        init?(coefficients: [Double]) {
            guard coefficients.count == 6 else { return nil }
            // Normalise sign so the interior evaluates negative.
            let sign: Double = coefficients[0] < 0 ? -1 : 1
            let a = coefficients[0] * sign
            let b = coefficients[1] * sign
            let c = coefficients[2] * sign
            let d = coefficients[3] * sign
            let e = coefficients[4] * sign
            let f = coefficients[5] * sign
            let determinant = 4 * a * c - b * b
            guard determinant > 1e-12 else { return nil }
            let centerX = (b * e - 2 * c * d) / determinant
            let centerY = (b * d - 2 * a * e) / determinant
            let centerValue = a * centerX * centerX + b * centerX * centerY + c * centerY * centerY
                + d * centerX + e * centerY + f
            guard centerValue < 0 else { return nil }
            let mean = (a + c) / 2
            let spread = (((a - c) / 2) * ((a - c) / 2) + (b / 2) * (b / 2)).squareRoot()
            let lambdaSmall = mean - spread
            let lambdaLarge = mean + spread
            guard lambdaSmall > 0 else { return nil }
            self.a = a
            self.b = b
            self.c = c
            self.d = d
            self.e = e
            self.f = f
            self.centerX = centerX
            self.centerY = centerY
            self.semiAxisA = (-centerValue / lambdaSmall).squareRoot()
            self.semiAxisB = (-centerValue / lambdaLarge).squareRoot()
            self.centerValue = centerValue
        }

        func value(x: Double, y: Double) -> Double {
            a * x * x + b * x * y + c * y * y + d * x + e * y + f
        }

        /// Approximate distance from a point to the ellipse (Sampson distance).
        func distance(x: Double, y: Double) -> Double {
            let gradientX = 2 * a * x + b * y + d
            let gradientY = b * x + 2 * c * y + e
            let gradient = (gradientX * gradientX + gradientY * gradientY).squareRoot()
            return gradient > 0 ? abs(value(x: x, y: y)) / gradient : .infinity
        }

        /// Affine radius: 0 at the ellipse centre, 1 on the ellipse.
        func normalizedRadius(x: Double, y: Double) -> Double {
            let dx = x - centerX
            let dy = y - centerY
            return max(0, (a * dx * dx + b * dx * dy + c * dy * dy) / -centerValue).squareRoot()
        }

        /// Both crossings of the ellipse by the line through `point` along `direction`,
        /// ordered (forward, backward). `point` must lie inside the ellipse.
        func crossings(from point: ImagePoint, directionX: Double, directionY: Double) -> (ImagePoint, ImagePoint)? {
            let qa = a * directionX * directionX + b * directionX * directionY + c * directionY * directionY
            let qb = 2 * a * point.x * directionX + b * (point.x * directionY + point.y * directionX)
                + 2 * c * point.y * directionY + d * directionX + e * directionY
            let qc = value(x: point.x, y: point.y)
            let discriminant = qb * qb - 4 * qa * qc
            guard qa > 0, qc < 0, discriminant > 0 else { return nil }
            let root = discriminant.squareRoot()
            let forward = (-qb + root) / (2 * qa)
            let backward = (-qb - root) / (2 * qa)
            return (
                ImagePoint(x: point.x + forward * directionX, y: point.y + forward * directionY),
                ImagePoint(x: point.x + backward * directionX, y: point.y + backward * directionY)
            )
        }

        /// Image positions of the ends of two perpendicular diameters of the circle
        /// this ellipse is the image of, given the image of the circle's centre.
        /// Returned in board order top, right, bottom, left for an arbitrary spin,
        /// with the handedness of a board viewed from the front.
        ///
        /// A chord through the centre's image is the image of a diameter. Tangents at
        /// a diameter's ends are parallel on the board, so in the image they meet on
        /// the vanishing line at the pole of that chord; the line from the centre's
        /// image to the pole is the image of the perpendicular diameter.
        func perpendicularDiameters(throughCircleCenter center: ImagePoint) -> [ImagePoint]? {
            guard value(x: center.x, y: center.y) < 0,
                  let first = crossings(from: center, directionX: 1, directionY: 0) else { return nil }
            // Homogeneous line through the first diameter's ends.
            let p = first.0
            let q = first.1
            let line = [p.y - q.y, q.x - p.x, p.x * q.y - q.x * p.y]
            let conic = [a, b / 2, d / 2, b / 2, c, e / 2, d / 2, e / 2, f]
            guard let inverse = LinearAlgebra.invert3x3(conic) else { return nil }
            let pole = [
                inverse[0] * line[0] + inverse[1] * line[1] + inverse[2] * line[2],
                inverse[3] * line[0] + inverse[4] * line[1] + inverse[5] * line[2],
                inverse[6] * line[0] + inverse[7] * line[1] + inverse[8] * line[2],
            ]
            // Direction from the centre towards the pole (valid for poles at infinity too).
            var directionX = pole[0] - pole[2] * center.x
            var directionY = pole[1] - pole[2] * center.y
            let length = (directionX * directionX + directionY * directionY).squareRoot()
            guard length > 0, length.isFinite else { return nil }
            directionX /= length
            directionY /= length
            guard let second = crossings(from: center, directionX: directionX, directionY: directionY) else {
                return nil
            }
            // Treat `first.0` as board +x ("right"). Board +y ("top") is the end of the
            // second diameter lying counter-clockwise on the board, which is clockwise
            // on screen because image y points down.
            let rightX = first.0.x - center.x
            let rightY = first.0.y - center.y
            let cross = rightX * (second.0.y - center.y) - rightY * (second.0.x - center.x)
            let top = cross < 0 ? second.0 : second.1
            let bottom = cross < 0 ? second.1 : second.0
            return [top, first.0, bottom, first.1]
        }
    }

    /// Fits an ellipse to edge points, iteratively discarding outliers (clutter,
    /// occlusions). Returns `nil` when too few points agree on one ellipse.
    static func fit(_ points: [ImagePoint], minimumInlierFraction: Double) -> Ellipse? {
        guard points.count >= 8 else { return nil }
        var inliers = points
        var ellipse: Ellipse?
        for _ in 0 ..< 5 {
            guard inliers.count >= 8, let current = fitOnce(inliers) else { return nil }
            ellipse = current
            let distances = points.map { current.distance(x: $0.x, y: $0.y) }
            let sorted = distances.sorted()
            let median = sorted[sorted.count / 2]
            let tolerance = max(1.0, median * 3)
            let kept = zip(points, distances).filter { $0.1 <= tolerance }.map(\.0)
            if kept.count == inliers.count { break }
            inliers = kept
        }
        guard let ellipse, Double(inliers.count) >= minimumInlierFraction * Double(points.count) else { return nil }
        return ellipse
    }

    /// Algebraic least squares on centred, scaled points with the constant fixed.
    private static func fitOnce(_ points: [ImagePoint]) -> Ellipse? {
        let count = Double(points.count)
        let meanX = points.map(\.x).reduce(0, +) / count
        let meanY = points.map(\.y).reduce(0, +) / count
        let scale = points.map { $0.distance(to: ImagePoint(x: meanX, y: meanY)) }.reduce(0, +) / count
        guard scale > 0 else { return nil }

        var normal = [[Double]](repeating: [Double](repeating: 0, count: 5), count: 5)
        var rhs = [Double](repeating: 0, count: 5)
        for point in points {
            let x = (point.x - meanX) / scale
            let y = (point.y - meanY) / scale
            let row = [x * x, x * y, y * y, x, y]
            for i in 0 ..< 5 {
                rhs[i] += row[i]
                for j in 0 ..< 5 {
                    normal[i][j] += row[i] * row[j]
                }
            }
        }
        guard let solution = LinearAlgebra.solve(normal, rhs) else { return nil }
        // a'x'² + b'x'y' + c'y'² + d'x' + e'y' - 1 = 0 with x' = (x - meanX) / scale.
        let a = solution[0] / (scale * scale)
        let b = solution[1] / (scale * scale)
        let c = solution[2] / (scale * scale)
        let d = solution[3] / scale - 2 * a * meanX - b * meanY
        let e = solution[4] / scale - b * meanX - 2 * c * meanY
        let f = a * meanX * meanX + b * meanX * meanY + c * meanY * meanY
            - solution[3] / scale * meanX - solution[4] / scale * meanY - 1
        return Ellipse(coefficients: [a, b, c, d, e, f])
    }
}
