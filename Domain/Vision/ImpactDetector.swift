import Foundation

/// Finds darts by comparing the watched board region against a reference image of
/// the board before the throw.
///
/// How it works:
/// - Once the scene holds still a reference is stored. Any later still frame is
///   differenced against it (luma + chroma, with global exposure compensation and
///   shadow attenuation).
/// - Changed pixels are grouped with hysteresis: strong differences seed a blob,
///   weaker connected differences extend it, so the thin, low-contrast point of the
///   dart stays attached to the obvious barrel and flight.
/// - A dart is a long thin blob. Its tip is one end of the blob's principal axis.
///   Which end is decided from camera pose (a dart sticks out of the board towards
///   the thrower, so the flight is displaced from the tip in a predictable image
///   direction) and from shape (the flight end is wider than the point).
/// - After a dart is reported the reference is replaced with the current frame, so
///   the next dart is isolated even when it lands touching the previous one.
/// - When the scene settles back to the empty-board reference, the darts have been
///   pulled and `boardCleared` is reported.
///
/// Pure value type: no camera or UI dependencies, so the whole pipeline is unit-tested
/// against synthetic frames.
public struct ImpactDetector: Sendable {
    public struct Impact: Equatable, Sendable {
        /// Estimated dart tip, in image width units when a region is configured,
        /// otherwise region-normalised (`0...1`).
        public let tip: ImagePoint
        /// The opposite (flight) end of the dart, same coordinates.
        public let tail: ImagePoint
        /// `0...1`; reflects how dart-like the blob was and how certain the tip end is.
        public let confidence: Double
    }

    public enum Event: Equatable, Sendable {
        case dart(Impact)
        /// All darts were removed from the board.
        case boardCleared
    }

    public struct Configuration: Sendable {
        /// Luma change between consecutive frames that counts as movement.
        public var motionPixelThreshold: Float = 0.07
        /// Fraction of moving pixels above which the frame is "in motion".
        public var motionFractionLimit = 0.003
        /// Still frames needed before the first reference is captured.
        public var stableFramesForReference = 8
        /// Still frames needed after movement before the scene is evaluated.
        public var settleFrames = 4
        /// While still, re-evaluate this often (catches changes too small to register as motion).
        public var reevaluateInterval = 8
        /// Difference that seeds a blob.
        public var seedThreshold: Float = 0.16
        /// Difference that extends a seeded blob.
        public var growThreshold: Float = 0.07
        /// Smallest dart blob, as a fraction of the region's pixels.
        public var minimumBlobFraction = 0.0004
        public var minimumSeedPixels = 6
        /// Largest dart blob, as a fraction of the region's pixels.
        public var maximumBlobFraction = 0.04
        /// Blobs reaching the edge of the region that are larger than this are arms, not darts.
        public var maximumBorderBlobFraction = 0.015
        /// Changed fraction above which the scene itself changed (lights, camera bump).
        public var sceneChangeFraction = 0.30
        /// Still frames of a changed scene before the references are rebuilt.
        public var sceneChangeRebaseFrames = 60
        /// Dart length (tip to flight) in board units, used to predict the flight position.
        public var dartLengthBoardUnits = 0.85
        /// Tips mapping farther than this from the board centre (board units) are not darts.
        public var maximumTipRadius = 1.45

        public init() {}
    }

    private let configuration: Configuration
    private var calibration: BoardCalibration?
    private var pose: BoardPose?
    private var region: ImageRegion?

    private var reference: ImpactFrame?
    private var emptyReference: ImpactFrame?
    private var previous: ImpactFrame?
    private var stillStreak = 0
    /// Darts currently absorbed into `reference`.
    public private(set) var dartsOnBoard = 0

    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }

    /// Whether the empty-board reference has been captured and darts can be detected.
    public var isArmed: Bool { reference != nil }

    /// Ties the detector to a calibrated board so tips are reported in image
    /// coordinates and pose can disambiguate the tip end. Resets all references.
    public mutating func configure(calibration: BoardCalibration, region: ImageRegion) {
        self.calibration = calibration
        self.pose = calibration.pose
        self.region = region
        reset()
    }

    /// Forgets all references, e.g. after recalibration.
    public mutating func reset() {
        reference = nil
        emptyReference = nil
        previous = nil
        stillStreak = 0
        dartsOnBoard = 0
    }

    /// Feeds the next frame of the watched region.
    public mutating func process(_ frame: ImpactFrame) -> Event? {
        defer { previous = frame }
        guard let previous, previous.width == frame.width, previous.height == frame.height else {
            stillStreak = 0
            return nil
        }
        stillStreak = isStill(frame, comparedTo: previous) ? stillStreak + 1 : 0

        guard let reference, reference.width == frame.width, reference.height == frame.height else {
            if stillStreak >= configuration.stableFramesForReference {
                self.reference = frame
                emptyReference = frame
                dartsOnBoard = 0
            }
            return nil
        }

        let sinceSettled = stillStreak - configuration.settleFrames
        guard sinceSettled >= 0, sinceSettled % max(1, configuration.reevaluateInterval) == 0 else { return nil }
        return evaluate(frame, against: reference)
    }

    // MARK: - Evaluation

    private mutating func evaluate(_ frame: ImpactFrame, against reference: ImpactFrame) -> Event? {
        let difference = Self.difference(frame, reference)
        let pixelCount = frame.width * frame.height
        var changed = 0
        for value in difference where value >= configuration.growThreshold {
            changed += 1
        }

        if Double(changed) / Double(pixelCount) > configuration.sceneChangeFraction {
            // Lighting or the camera changed (or someone is standing in view). If it
            // persists, accept the new scene as the baseline rather than stay blind.
            if stillStreak >= configuration.sceneChangeRebaseFrames {
                self.reference = frame
                emptyReference = frame
                dartsOnBoard = 0
            }
            return nil
        }

        let blobs = blobs(in: difference, width: frame.width, height: frame.height)
        guard !blobs.isEmpty else {
            adaptReferences(to: frame, reference: reference)
            return nil
        }

        if dartsOnBoard > 0, let emptyReference {
            let againstEmpty = Self.difference(frame, emptyReference)
            if self.blobs(in: againstEmpty, width: frame.width, height: frame.height).isEmpty {
                self.reference = frame
                self.emptyReference = frame
                dartsOnBoard = 0
                return .boardCleared
            }
            // A blob that looks like the empty board is a dart being pulled, not thrown.
            if blobs.contains(where: { isRemoval($0, difference: difference, againstEmpty: againstEmpty) }) {
                self.reference = frame
                dartsOnBoard = max(0, dartsOnBoard - 1)
                return nil
            }
        }

        for blob in blobs {
            let fraction = Double(blob.pixels.count) / Double(pixelCount)
            let limit = blob.touchesBorder ? configuration.maximumBorderBlobFraction : configuration.maximumBlobFraction
            guard fraction <= limit,
                  let impact = impact(from: blob, width: frame.width, height: frame.height) else { continue }
            self.reference = frame
            dartsOnBoard += 1
            return .dart(impact)
        }
        return nil
    }

    /// Follows slow lighting drift while nothing dart-like is in view.
    private mutating func adaptReferences(to frame: ImpactFrame, reference: ImpactFrame) {
        let rate: Float = 0.15
        func blend(_ base: [Float], _ old: [Float], _ new: [Float]) -> [Float] {
            var out = base
            for index in out.indices {
                out[index] += rate * (new[index] - old[index])
            }
            return out
        }
        if let empty = emptyReference, dartsOnBoard > 0 {
            // Carry the same drift into the empty-board image without erasing the darts' absence.
            emptyReference = ImpactFrame(
                width: empty.width,
                height: empty.height,
                luma: blend(empty.luma, reference.luma, frame.luma),
                cb: blend(empty.cb, reference.cb, frame.cb),
                cr: blend(empty.cr, reference.cr, frame.cr)
            ) ?? empty
        }
        let updated = ImpactFrame(
            width: reference.width,
            height: reference.height,
            luma: blend(reference.luma, reference.luma, frame.luma),
            cb: blend(reference.cb, reference.cb, frame.cb),
            cr: blend(reference.cr, reference.cr, frame.cr)
        ) ?? reference
        self.reference = updated
        if dartsOnBoard == 0 {
            emptyReference = updated
        }
    }

    private func isStill(_ frame: ImpactFrame, comparedTo previous: ImpactFrame) -> Bool {
        // Every other pixel on both axes is plenty to notice movement.
        var moving = 0
        var sampled = 0
        frame.luma.withUnsafeBufferPointer { current in
            previous.luma.withUnsafeBufferPointer { last in
                var y = 0
                while y < frame.height {
                    var index = y * frame.width
                    let end = index + frame.width
                    while index < end {
                        if abs(current[index] - last[index]) > configuration.motionPixelThreshold {
                            moving += 1
                        }
                        sampled += 1
                        index += 2
                    }
                    y += 2
                }
            }
        }
        return Double(moving) <= configuration.motionFractionLimit * Double(sampled)
    }

    /// Per-pixel change magnitude between a frame and a reference.
    static func difference(_ frame: ImpactFrame, _ reference: ImpactFrame) -> [Float] {
        let count = frame.width * frame.height
        var out = [Float](repeating: 0, count: count)
        // Compensate global exposure changes (auto-exposure, a lamp dimming).
        let referenceMean = max(reference.meanLuma, 0.001)
        let gain = min(1.4, max(0.7, frame.meanLuma / referenceMean))
        frame.luma.withUnsafeBufferPointer { luma in
            reference.luma.withUnsafeBufferPointer { refLuma in
                frame.cb.withUnsafeBufferPointer { cb in
                    reference.cb.withUnsafeBufferPointer { refCb in
                        frame.cr.withUnsafeBufferPointer { cr in
                            reference.cr.withUnsafeBufferPointer { refCr in
                                out.withUnsafeMutableBufferPointer { result in
                                    for index in 0 ..< count {
                                        let expected = refLuma[index] * gain
                                        let lumaDelta = luma[index] - expected
                                        let chromaDelta = abs(cb[index] - refCb[index]) + abs(cr[index] - refCr[index])
                                        var value = abs(lumaDelta) + chromaDelta
                                        // A soft shadow darkens a little without shifting colour.
                                        if lumaDelta < 0, chromaDelta < 0.03, luma[index] > expected * 0.6 {
                                            value *= 0.5
                                        }
                                        result[index] = value
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return out
    }

    // MARK: - Blobs

    struct Blob {
        let pixels: [Int]
        let touchesBorder: Bool
    }

    /// Hysteresis blobs, largest first.
    private func blobs(in difference: [Float], width: Int, height: Int) -> [Blob] {
        var mask = [Bool](repeating: false, count: difference.count)
        var any = false
        for index in difference.indices where difference[index] >= configuration.growThreshold {
            mask[index] = true
            any = true
        }
        guard any else { return [] }
        let minimumSize = max(configuration.minimumSeedPixels, Int(configuration.minimumBlobFraction * Double(difference.count)))
        return ConnectedComponents.find(mask: mask, width: width, height: height, minimumSize: minimumSize)
            .filter { component in
                var seeds = 0
                for index in component.pixels where difference[index] >= configuration.seedThreshold {
                    seeds += 1
                    if seeds >= configuration.minimumSeedPixels { return true }
                }
                return false
            }
            .sorted { $0.pixels.count > $1.pixels.count }
            .map { component in
                Blob(
                    pixels: component.pixels,
                    touchesBorder: component.minX == 0 || component.minY == 0
                        || component.maxX == width - 1 || component.maxY == height - 1
                )
            }
    }

    private func isRemoval(_ blob: Blob, difference: [Float], againstEmpty: [Float]) -> Bool {
        var changedFromReference: Float = 0
        var changedFromEmpty: Float = 0
        for index in blob.pixels {
            changedFromReference += difference[index]
            changedFromEmpty += againstEmpty[index]
        }
        return changedFromEmpty < changedFromReference * 0.4
    }

    // MARK: - Tip localisation

    /// The two ends of a blob's principal axis plus shape statistics, in pixel coordinates.
    struct BlobAxis {
        let endA: ImagePoint
        let endB: ImagePoint
        let widthA: Double
        let widthB: Double
        /// Pixels in the last sliver of each end: a point ends in a few, a flight in many.
        let capA: Double
        let capB: Double
        let centroid: ImagePoint
        let elongation: Double

        func mapped(_ transform: (ImagePoint) -> ImagePoint) -> BlobAxis {
            BlobAxis(
                endA: transform(endA),
                endB: transform(endB),
                widthA: widthA,
                widthB: widthB,
                capA: capA,
                capB: capB,
                centroid: transform(centroid),
                elongation: elongation
            )
        }
    }

    static func axis(of pixels: [Int], width: Int) -> BlobAxis? {
        guard pixels.count >= 3 else { return nil }
        let count = Double(pixels.count)
        var meanX = 0.0
        var meanY = 0.0
        for index in pixels {
            meanX += Double(index % width)
            meanY += Double(index / width)
        }
        meanX /= count
        meanY /= count
        var sxx = 0.0
        var sxy = 0.0
        var syy = 0.0
        for index in pixels {
            let dx = Double(index % width) - meanX
            let dy = Double(index / width) - meanY
            sxx += dx * dx
            sxy += dx * dy
            syy += dy * dy
        }
        sxx /= count
        sxy /= count
        syy /= count
        let mean = (sxx + syy) / 2
        let spread = (((sxx - syy) / 2) * ((sxx - syy) / 2) + sxy * sxy).squareRoot()
        let major = mean + spread
        let minor = max(mean - spread, 1.0 / 12.0)
        let angle = 0.5 * atan2(2 * sxy, sxx - syy)
        let ux = cos(angle)
        let uy = sin(angle)

        var along = [Double](repeating: 0, count: pixels.count)
        var across = [Double](repeating: 0, count: pixels.count)
        var minimum = Double.infinity
        var maximum = -Double.infinity
        for (offset, index) in pixels.enumerated() {
            let dx = Double(index % width) - meanX
            let dy = Double(index / width) - meanY
            along[offset] = dx * ux + dy * uy
            across[offset] = -dx * uy + dy * ux
            minimum = min(minimum, along[offset])
            maximum = max(maximum, along[offset])
        }
        let length = maximum - minimum
        let band = max(1.5, length * 0.06)
        let third = length / 3

        func end(isLow: Bool) -> (point: ImagePoint, width: Double, cap: Double) {
            // Blur spreads the blob slightly past the object, so pull the end back in.
            let rawExtreme = isLow ? minimum : maximum
            let extreme = rawExtreme + (isLow ? 1 : -1) * min(0.75, length / 4)
            var tipAcross = 0.0
            var tipCount = 0.0
            var sum = 0.0
            var sumSquares = 0.0
            var thirdCount = 0.0
            for offset in along.indices {
                let distance = abs(along[offset] - rawExtreme)
                if distance <= band {
                    tipAcross += across[offset]
                    tipCount += 1
                }
                if distance <= third {
                    sum += across[offset]
                    sumSquares += across[offset] * across[offset]
                    thirdCount += 1
                }
            }
            let lateral = tipCount > 0 ? tipAcross / tipCount : 0
            let meanAcross = thirdCount > 0 ? sum / thirdCount : 0
            let variance = thirdCount > 0 ? max(0, sumSquares / thirdCount - meanAcross * meanAcross) : 0
            // +0.5 moves from pixel index to pixel centre.
            let point = ImagePoint(
                x: meanX + extreme * ux - lateral * uy + 0.5,
                y: meanY + extreme * uy + lateral * ux + 0.5
            )
            return (point, variance.squareRoot(), tipCount)
        }

        let low = end(isLow: true)
        let high = end(isLow: false)
        return BlobAxis(
            endA: low.point,
            endB: high.point,
            widthA: low.width,
            widthB: high.width,
            capA: low.cap,
            capB: high.cap,
            centroid: ImagePoint(x: meanX + 0.5, y: meanY + 0.5),
            elongation: (major / minor).squareRoot()
        )
    }

    /// Outer edge of the number ring, in board units (225 mm on a regulation board).
    static let boardSurroundRadius = 1.32

    private func impact(from blob: Blob, width: Int, height: Int) -> Impact? {
        guard let axis = Self.axis(of: blob.pixels, width: width) else { return nil }
        let region = self.region
        let imageAxis = axis.mapped { point in
            let normalizedX = point.x / Double(width)
            let normalizedY = point.y / Double(height)
            return region?.imagePoint(normalizedX: normalizedX, normalizedY: normalizedY)
                ?? ImagePoint(x: normalizedX, y: normalizedY)
        }

        let resolved = Self.resolveTip(
            axis: imageAxis,
            calibration: calibration,
            pose: pose,
            dartLength: configuration.dartLengthBoardUnits
        )

        if let calibration {
            guard let board = calibration.transform.apply(toImageX: resolved.tip.x, imageY: resolved.tip.y) else {
                return nil
            }
            // Far off the board, or something poking in from the edge of view: not a dart.
            if board.radius > configuration.maximumTipRadius { return nil }
            if blob.touchesBorder, board.radius > Self.boardSurroundRadius { return nil }
        }
        return Impact(tip: resolved.tip, tail: resolved.tail, confidence: resolved.confidence)
    }

    /// Chooses which end of a blob is the dart tip and how much to trust it.
    static func resolveTip(
        axis: BlobAxis,
        calibration: BoardCalibration?,
        pose: BoardPose?,
        dartLength: Double
    ) -> (tip: ImagePoint, tail: ImagePoint, confidence: Double) {
        let endA = axis.endA
        let endB = axis.endB
        let widthA = axis.widthA
        let widthB = axis.widthB
        let centroid = axis.centroid
        let elongation = axis.elongation
        let blobLength = endA.distance(to: endB)
        let widest = max(widthA, widthB)
        let widthStrength = widest > 0 ? abs(widthA - widthB) / widest : 0
        // The flight is the bulk of a dart's silhouette: it is wider than the point,
        // and it drags the blob's centre of mass towards its own end.
        let reachA = centroid.distance(to: endA)
        let reachB = centroid.distance(to: endB)
        let massStrength = blobLength > 0 ? abs(reachA - reachB) / blobLength : 0
        let largestCap = max(axis.capA, axis.capB)
        let capStrength = largestCap > 0 ? abs(axis.capA - axis.capB) / largestCap : 0
        let widthIsDecisive = elongation >= 1.6 && widthStrength >= 0.25
        let shapePrefersA: Bool
        if massStrength >= 0.1 {
            shapePrefersA = reachA >= reachB
        } else if widthIsDecisive {
            shapePrefersA = widthA <= widthB
        } else {
            shapePrefersA = axis.capA <= axis.capB
        }

        // Pose prior: if this end were the tip, where would the flight be?
        var posePrefersA: Bool?
        var poseAlignment = 0.0
        if let calibration, let pose, blobLength > 0 {
            func alignment(tip: ImagePoint, other: ImagePoint) -> (cosine: Double, predictedLength: Double)? {
                guard let board = calibration.transform.apply(toImageX: tip.x, imageY: tip.y),
                      let predicted = pose.project(x: board.x, y: board.y, height: dartLength) else { return nil }
                let px = predicted.x - tip.x
                let py = predicted.y - tip.y
                let predictedLength = (px * px + py * py).squareRoot()
                guard predictedLength > 0 else { return nil }
                let cosine = (px * (other.x - tip.x) + py * (other.y - tip.y)) / (predictedLength * blobLength)
                return (cosine, predictedLength)
            }
            if let a = alignment(tip: endA, other: endB), let b = alignment(tip: endB, other: endA) {
                let predictedLength = max(a.predictedLength, b.predictedLength)
                // Only trust the prior when the flight is predicted to sit well clear of the tip.
                if predictedLength >= blobLength * 0.3, predictedLength >= calibration.radius * 0.08 {
                    posePrefersA = a.cosine >= b.cosine
                    poseAlignment = max(a.cosine, b.cosine)
                }
            }
        }

        let shapeIsDecisive = massStrength >= 0.1 || widthIsDecisive || capStrength >= 0.4
        if let posePrefersA, poseAlignment >= 0.75 {
            // The blob points the way a dart should from this camera position.
            var confidence = 0.92
            if posePrefersA != shapePrefersA, shapeIsDecisive {
                confidence = 0.7 // shape disagrees about which end is the flight
            }
            if elongation < 1.6 { confidence = min(confidence, 0.6) }
            return (posePrefersA ? endA : endB, posePrefersA ? endB : endA, confidence)
        }
        if shapeIsDecisive {
            // Camera nearly head-on, or the dart leans hard: the wide end is the flight.
            var confidence = 0.5 + 0.3 * min(1, max(widthStrength / 0.5, massStrength / 0.2))
            if let posePrefersA, posePrefersA != shapePrefersA { confidence = min(confidence, 0.55) }
            if elongation < 1.6 { confidence = min(confidence, 0.6) }
            return (shapePrefersA ? endA : endB, shapePrefersA ? endB : endA, confidence)
        }
        if let posePrefersA {
            return (posePrefersA ? endA : endB, posePrefersA ? endB : endA, 0.5)
        }
        // Looking straight down the dart, the flight hides the tip; the middle is the best guess.
        return (centroid, centroid, 0.45)
    }
}
