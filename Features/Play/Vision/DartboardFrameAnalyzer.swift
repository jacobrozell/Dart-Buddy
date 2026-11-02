import CoreVideo
import Foundation
import Vision

/// One analyzed camera frame: board fit (when contour detection ran), frame quality
/// metrics, and any confirmed dart impact candidate.
///
/// All coordinates use aspect-corrected "width units": x spans `0...1` across the
/// image width, y grows downward in the same physical scale (`0...height/width`).
/// This keeps radial distances isotropic so circle fits and segment mapping stay
/// accurate on non-square buffers.
struct VisionFrameAnalysis: Sendable {
    struct BoardObservation: Sendable {
        let centerX: Double
        let centerY: Double
        let radius: Double
        /// Circularity-based fit quality, `0...1`.
        let fitConfidence: Double
    }

    let board: BoardObservation?
    let brightness: Double
    let sharpness: Double
    let impact: ImpactDetector.Candidate?
    /// Buffer height divided by width; converts width units back to per-axis
    /// normalized coordinates for preview-layer display.
    let aspectRatio: Double
    let timestamp: Date
    let sceneMotion: Bool
}

/// Turns raw camera pixel buffers into `VisionFrameAnalysis` values. Board fit uses
/// `VNDetectContoursRequest` (run on a sampled cadence — contour detection is the
/// expensive step); impacts use the pure `ImpactDetector` over a downsampled luma grid.
/// Runs on the camera capture queue, never on the main thread.
final class DartboardFrameAnalyzer {
    static let gridSize = 64
    private static let contourFrameInterval = 8

    private var impactDetector = ImpactDetector()
    private var frameCount = 0
    private var lastBoardObservation: VisionFrameAnalysis.BoardObservation?
    private var tipOffset: SIMD2<Double>?
    /// Full-resolution copy of the frame behind the detector's current baseline.
    private var baselineLuma: LumaImage?
    private var currentLuma: LumaImage?

    /// Restricts impacts to `gridSize`² row-major cells; `nil` watches the whole frame.
    /// `tipOffset` is the flight-to-tip vector in per-axis normalized image units.
    func setImpactRegion(_ region: [Bool]?, tipOffset: SIMD2<Double>?) {
        impactDetector.setRegion(region, tipOffset: tipOffset)
        self.tipOffset = tipOffset
        baselineLuma = nil
    }

    func reset() {
        impactDetector.reset()
        frameCount = 0
        lastBoardObservation = nil
        tipOffset = nil
        baselineLuma = nil
    }

    func analyze(_ pixelBuffer: CVPixelBuffer) -> VisionFrameAnalysis? {
        guard let grid = Self.lumaGrid(from: pixelBuffer, size: Self.gridSize) else { return nil }
        let width = Double(CVPixelBufferGetWidth(pixelBuffer))
        let height = Double(CVPixelBufferGetHeight(pixelBuffer))
        guard width > 0, height > 0 else { return nil }
        let aspectRatio = height / width
        frameCount += 1

        if frameCount % Self.contourFrameInterval == 1 {
            lastBoardObservation = Self.detectBoard(in: pixelBuffer, aspectRatio: aspectRatio)
        }

        let generation = impactDetector.baselineGeneration
        let impact = impactDetector.process(grid).map { coarse in
            if let tip = refineTip(coarse, pixelBuffer: pixelBuffer) {
                return ImpactDetector.Candidate(
                    imageX: tip.x / width,
                    imageY: tip.y / width,
                    confidence: coarse.confidence,
                    clusterBounds: coarse.clusterBounds
                )
            }
            // The square luma grid samples the full buffer, so its per-axis normalized
            // point converts to width units by scaling y with the aspect ratio.
            return ImpactDetector.Candidate(
                imageX: coarse.imageX,
                imageY: coarse.imageY * aspectRatio,
                confidence: coarse.confidence,
                clusterBounds: coarse.clusterBounds
            )
        }
        if impactDetector.baselineGeneration != generation {
            Self.copyLuma(from: pixelBuffer, into: &baselineLuma)
        }

        return VisionFrameAnalysis(
            board: lastBoardObservation,
            brightness: grid.brightness,
            sharpness: Self.sharpness(of: grid),
            impact: impact,
            aspectRatio: aspectRatio,
            timestamp: Date(),
            sceneMotion: impactDetector.sawLargeMotion
        )
    }

    // MARK: - Full-resolution tip

    /// Diffs the pre-arrival and settled frames at full resolution around the coarse
    /// hit; returns the tip in buffer pixels, or `nil` to keep the coarse point.
    private func refineTip(_ coarse: ImpactDetector.Candidate, pixelBuffer: CVPixelBuffer) -> SIMD2<Double>? {
        guard let baselineLuma else { return nil }
        Self.copyLuma(from: pixelBuffer, into: &currentLuma)
        guard let currentLuma else { return nil }
        let width = Double(currentLuma.width)
        let height = Double(currentLuma.height)
        let margin = width / Double(Self.gridSize) * 1.5
        let bounds = coarse.clusterBounds
        var minX = bounds.x * width
        var minY = bounds.y * height
        var maxX = bounds.z * width
        var maxY = bounds.w * height
        let flightToTip = tipOffset.map { SIMD2($0.x * width, $0.y * height) }
        if let flightToTip {
            // A thin barrel may not register on the coarse grid; keep the expected tip in view.
            let tip = SIMD2((minX + maxX) / 2, (minY + maxY) / 2) + flightToTip
            minX = min(minX, tip.x)
            minY = min(minY, tip.y)
            maxX = max(maxX, tip.x)
            maxY = max(maxY, tip.y)
        }
        let roi = DartTipLocator.PixelRect(
            minX: Int(minX - margin),
            minY: Int(minY - margin),
            maxX: Int(maxX + margin),
            maxY: Int(maxY + margin)
        )
        return DartTipLocator.locateTip(baseline: baselineLuma, current: currentLuma, in: roi, flightToTip: flightToTip)
    }

    // MARK: - Luma extraction

    /// Copies the full-resolution luma plane, reusing `image`'s storage when the size matches.
    static func copyLuma(from pixelBuffer: CVPixelBuffer, into image: inout LumaImage?) {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }
        guard CVPixelBufferIsPlanar(pixelBuffer),
              let base = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0) else {
            image = nil
            return
        }
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
        let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
        if image?.width != width || image?.height != height {
            image = LumaImage(width: width, height: height, pixels: [UInt8](repeating: 0, count: width * height))
        }
        image?.pixels.withUnsafeMutableBytes { destination in
            guard let target = destination.baseAddress else { return }
            for row in 0 ..< height {
                memcpy(target + row * width, base + row * bytesPerRow, width)
            }
        }
    }

    /// Samples the luma plane of a 420f/BGRA buffer down to a `size`x`size` grid.
    /// Each cell averages a sub-grid of pixels so sensor noise and sub-pixel shake
    /// along wedge edges don't read as change.
    static func lumaGrid(from pixelBuffer: CVPixelBuffer, size: Int, samplesPerAxis: Int = 4) -> LumaGrid? {
        CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly) }

        let format = CVPixelBufferGetPixelFormatType(pixelBuffer)
        let isBiPlanar = format == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
            || format == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
        guard isBiPlanar else { return nil }
        guard let base = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0) else { return nil }

        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
        let bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
        guard width >= size, height >= size else { return nil }

        let luma = base.assumingMemoryBound(to: UInt8.self)
        var values = [Double](repeating: 0, count: size * size)
        let sampleSpan = size * samplesPerAxis
        let sampleCount = Double(samplesPerAxis * samplesPerAxis) * 255.0
        for gridY in 0 ..< size {
            for gridX in 0 ..< size {
                var sum = 0
                for sampleY in 0 ..< samplesPerAxis {
                    let sourceY = ((gridY * samplesPerAxis + sampleY) * 2 + 1) * height / (sampleSpan * 2)
                    for sampleX in 0 ..< samplesPerAxis {
                        let sourceX = ((gridX * samplesPerAxis + sampleX) * 2 + 1) * width / (sampleSpan * 2)
                        sum += Int(luma[sourceY * bytesPerRow + sourceX])
                    }
                }
                values[gridY * size + gridX] = Double(sum) / sampleCount
            }
        }
        return LumaGrid(width: size, height: size, values: values)
    }

    /// Mean absolute horizontal gradient as a cheap focus/motion-blur proxy, scaled
    /// so a sharp dartboard frame (high wedge contrast) lands near `1.0`.
    static func sharpness(of grid: LumaGrid) -> Double {
        var total = 0.0
        var count = 0
        for y in 0 ..< grid.height {
            for x in 1 ..< grid.width {
                total += abs(grid.values[y * grid.width + x] - grid.values[y * grid.width + x - 1])
                count += 1
            }
        }
        guard count > 0 else { return 0 }
        return min(1.0, (total / Double(count)) / 0.08)
    }

    // MARK: - Board contour fit

    static func detectBoard(in pixelBuffer: CVPixelBuffer, aspectRatio: Double) -> VisionFrameAnalysis.BoardObservation? {
        let request = VNDetectContoursRequest()
        request.contrastAdjustment = 1.5
        request.maximumImageDimension = 512
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        guard (try? handler.perform([request])) != nil,
              let contours = request.results?.first else { return nil }

        var best: VisionFrameAnalysis.BoardObservation?
        for index in 0 ..< contours.topLevelContourCount {
            let contour = contours.topLevelContours[index]
            guard let observation = boardObservation(from: contour.normalizedPoints, aspectRatio: aspectRatio) else {
                continue
            }
            if observation.fitConfidence > (best?.fitConfidence ?? 0), observation.radius > 0.1 {
                best = observation
            }
        }
        return best
    }

    /// Fits a circle to a contour and scores it by circularity (`4πA / P²`).
    /// Vision uses per-axis normalized, bottom-left-origin coordinates: y flips into
    /// image orientation and scales by the aspect ratio into isotropic width units
    /// before fitting, so a physical circle actually fits a circle here.
    static func boardObservation(from points: [SIMD2<Float>], aspectRatio: Double) -> VisionFrameAnalysis.BoardObservation? {
        guard points.count >= 8, aspectRatio > 0 else { return nil }
        let corrected = points.map { point in
            SIMD2<Double>(Double(point.x), (1.0 - Double(point.y)) * aspectRatio)
        }

        var area = 0.0
        var perimeter = 0.0
        var sumX = 0.0
        var sumY = 0.0
        for index in corrected.indices {
            let current = corrected[index]
            let next = corrected[(index + 1) % corrected.count]
            area += current.x * next.y - next.x * current.y
            perimeter += ((next.x - current.x) * (next.x - current.x)
                + (next.y - current.y) * (next.y - current.y)).squareRoot()
            sumX += current.x
            sumY += current.y
        }
        area = abs(area) / 2
        guard area > 0, perimeter > 0 else { return nil }

        let circularity = min(1.0, 4 * Double.pi * area / (perimeter * perimeter))
        let radius = (area / Double.pi).squareRoot()
        return VisionFrameAnalysis.BoardObservation(
            centerX: sumX / Double(corrected.count),
            centerY: sumY / Double(corrected.count),
            radius: radius,
            fitConfidence: circularity
        )
    }
}
