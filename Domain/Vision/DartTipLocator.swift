import Foundation

/// A full-resolution 8-bit luma image, row-major with no row padding.
public struct LumaImage: Sendable {
    public let width: Int
    public let height: Int
    public var pixels: [UInt8]

    public init?(width: Int, height: Int, pixels: [UInt8]) {
        guard width > 0, height > 0, pixels.count == width * height else { return nil }
        self.width = width
        self.height = height
        self.pixels = pixels
    }
}

/// Finds a dart's tip at full resolution once the coarse `ImpactDetector` has flagged
/// an arrival (Autodarts-style: low-res motion, then full-res localization). Diffs the
/// pre-arrival and settled frames inside a region of interest, keeps the largest blob,
/// fits a line to it, and returns the end of the line the tip is on.
public enum DartTipLocator {
    public struct PixelRect: Equatable, Sendable {
        public var minX: Int
        public var minY: Int
        public var maxX: Int
        public var maxY: Int

        public init(minX: Int, minY: Int, maxX: Int, maxY: Int) {
            self.minX = minX
            self.minY = minY
            self.maxX = maxX
            self.maxY = maxY
        }
    }

    public struct Configuration: Sendable {
        /// Per-pixel luma delta (0...255) that counts as changed.
        public var pixelChangeThreshold: UInt8 = 28
        /// Smallest blob that can be a dart.
        public var minimumBlobPixels = 24
        /// Below this length-to-width ratio the blob is not a line (flight only, or a
        /// dart pointing at the camera), so the tip comes from the pose offset instead.
        public var minimumElongation = 2.0
        /// Fraction of the expected flight-to-tip length the blob must span to be
        /// treated as the whole dart.
        public var wholeDartSpanFraction = 0.6
        /// Minimum |cos| between the blob axis and the expected dart direction for
        /// that direction to pick the tip end.
        public var directionAgreement = 0.5

        public init() {}
    }

    /// Returns the tip in pixel coordinates, or `nil` when no dart-sized change is found.
    /// `flightToTip` is the expected vector (pixels) from the flight center to the tip,
    /// from the camera pose; without it the narrow end of the blob is taken as the tip.
    public static func locateTip(
        baseline: LumaImage,
        current: LumaImage,
        in roi: PixelRect,
        flightToTip: SIMD2<Double>?,
        configuration: Configuration = Configuration()
    ) -> SIMD2<Double>? {
        guard baseline.width == current.width, baseline.height == current.height else { return nil }
        let rect = PixelRect(
            minX: max(0, roi.minX),
            minY: max(0, roi.minY),
            maxX: min(current.width - 1, roi.maxX),
            maxY: min(current.height - 1, roi.maxY)
        )
        guard rect.maxX > rect.minX, rect.maxY > rect.minY else { return nil }

        let blob = largestChangedBlob(baseline: baseline, current: current, in: rect, threshold: configuration.pixelChangeThreshold)
        guard blob.count >= configuration.minimumBlobPixels else { return nil }

        // Principal axis of the blob.
        var mean = SIMD2<Double>(0, 0)
        for point in blob { mean += point }
        mean /= Double(blob.count)
        var xx = 0.0, xy = 0.0, yy = 0.0
        for point in blob {
            let d = point - mean
            xx += d.x * d.x
            xy += d.x * d.y
            yy += d.y * d.y
        }
        let half = (xx + yy) / 2
        let spread = (((xx - yy) / 2) * ((xx - yy) / 2) + xy * xy).squareRoot()
        let major = half + spread
        let minor = max(half - spread, 1e-9)
        let elongation = (major / minor).squareRoot()
        let angle = 0.5 * atan2(2 * xy, xx - yy)
        var axis = SIMD2(cos(angle), sin(angle))

        let expectedLength = flightToTip.map { ($0 * $0).sum().squareRoot() } ?? 0
        guard elongation >= configuration.minimumElongation else {
            return flightToTip.map { mean + $0 } ?? mean
        }

        var low = Double.infinity
        var high = -Double.infinity
        for point in blob {
            let along = ((point - mean) * axis).sum()
            low = min(low, along)
            high = max(high, along)
        }
        let span = high - low
        if let flightToTip, expectedLength > 0, span < configuration.wholeDartSpanFraction * expectedLength {
            // Only the flight changed enough to register.
            return mean + flightToTip
        }

        if let flightToTip, expectedLength > 0,
           abs((axis * flightToTip).sum()) / expectedLength >= configuration.directionAgreement {
            if (axis * flightToTip).sum() < 0 { axis = -axis }
        } else {
            // Narrow end is the barrel/tip; the flight end carries more pixels.
            let quarter = span / 4
            var highEnd = 0
            var lowEnd = 0
            for point in blob {
                let along = ((point - mean) * axis).sum()
                if along >= high - quarter { highEnd += 1 }
                if along <= low + quarter { lowEnd += 1 }
            }
            if highEnd > lowEnd { axis = -axis }
        }

        var tipAlong = -Double.infinity
        for point in blob {
            tipAlong = max(tipAlong, ((point - mean) * axis).sum())
        }
        return mean + axis * tipAlong
    }

    /// 8-connected flood fill over thresholded |current - baseline|; returns the largest blob's pixel centers.
    private static func largestChangedBlob(
        baseline: LumaImage,
        current: LumaImage,
        in rect: PixelRect,
        threshold: UInt8
    ) -> [SIMD2<Double>] {
        let roiWidth = rect.maxX - rect.minX + 1
        let roiHeight = rect.maxY - rect.minY + 1
        var changed = [Bool](repeating: false, count: roiWidth * roiHeight)
        for y in 0 ..< roiHeight {
            let row = (rect.minY + y) * current.width + rect.minX
            for x in 0 ..< roiWidth {
                let a = current.pixels[row + x]
                let b = baseline.pixels[row + x]
                changed[y * roiWidth + x] = (a > b ? a - b : b - a) >= threshold
            }
        }

        var visited = [Bool](repeating: false, count: changed.count)
        var best: [Int] = []
        var stack: [Int] = []
        for start in changed.indices where changed[start] && !visited[start] {
            var component: [Int] = []
            visited[start] = true
            stack.append(start)
            while let index = stack.popLast() {
                component.append(index)
                let x = index % roiWidth
                let y = index / roiWidth
                for dy in -1 ... 1 {
                    for dx in -1 ... 1 where dx != 0 || dy != 0 {
                        let nx = x + dx
                        let ny = y + dy
                        guard nx >= 0, ny >= 0, nx < roiWidth, ny < roiHeight else { continue }
                        let neighbor = ny * roiWidth + nx
                        if changed[neighbor], !visited[neighbor] {
                            visited[neighbor] = true
                            stack.append(neighbor)
                        }
                    }
                }
            }
            if component.count > best.count { best = component }
        }
        return best.map { index in
            SIMD2(Double(rect.minX + index % roiWidth) + 0.5, Double(rect.minY + index / roiWidth) + 0.5)
        }
    }
}
