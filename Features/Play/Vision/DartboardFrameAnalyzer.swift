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
}

/// Turns raw camera pixel buffers into `VisionFrameAnalysis` values. Board fit uses
/// `VNDetectContoursRequest` (run on a sampled cadence — contour detection is the
/// expensive step); impacts use the pure `ImpactDetector` over a downsampled luma grid.
/// Runs on the camera capture queue, never on the main thread.
final class DartboardFrameAnalyzer {
    private static let gridSize = 64
    private static let contourFrameInterval = 8

    private var impactDetector = ImpactDetector()
    private var frameCount = 0
    private var lastBoardObservation: VisionFrameAnalysis.BoardObservation?

    func reset() {
        impactDetector.reset()
        frameCount = 0
        lastBoardObservation = nil
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

        // The square luma grid samples the full buffer, so its per-axis normalized
        // centroid converts to width units by scaling y with the aspect ratio.
        let impact = impactDetector.process(grid).map {
            ImpactDetector.Candidate(
                imageX: $0.imageX,
                imageY: $0.imageY * aspectRatio,
                confidence: $0.confidence
            )
        }

        return VisionFrameAnalysis(
            board: lastBoardObservation,
            brightness: grid.brightness,
            sharpness: Self.sharpness(of: grid),
            impact: impact,
            aspectRatio: aspectRatio,
            timestamp: Date()
        )
    }

    // MARK: - Luma extraction

    /// Samples the luma plane of a 420f/BGRA buffer down to a `size`x`size` grid.
    static func lumaGrid(from pixelBuffer: CVPixelBuffer, size: Int) -> LumaGrid? {
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
        for gridY in 0 ..< size {
            let sourceY = gridY * height / size + height / (size * 2)
            for gridX in 0 ..< size {
                let sourceX = gridX * width / size + width / (size * 2)
                values[gridY * size + gridX] = Double(luma[sourceY * bytesPerRow + sourceX]) / 255.0
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
