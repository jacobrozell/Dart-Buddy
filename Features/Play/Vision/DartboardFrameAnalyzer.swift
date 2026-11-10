import CoreVideo
import Foundation

/// One analyzed camera frame.
///
/// All image coordinates use aspect-corrected "width units": x spans `0...1` across
/// the upright image width, y grows downward in the same physical scale
/// (`0...height/width`), so distances are isotropic on non-square buffers.
struct VisionFrameAnalysis: Sendable {
    /// Board found in this frame. Only set while searching, on frames where
    /// detection ran (`didSearchForBoard`).
    let board: BoardDetection?
    let didSearchForBoard: Bool
    /// How well the locked calibration still matches the scene; set periodically while tracking.
    let calibrationAgreement: Double?
    /// Dart landed / board cleared, while tracking.
    let event: ImpactDetector.Event?
    /// Whether the empty-board reference has been captured (tracking only).
    let isArmed: Bool
    let brightness: Double
    let sharpness: Double
    /// Buffer height divided by width.
    let aspectRatio: Double
    let timestamp: Date
}

/// Turns raw camera pixel buffers into `VisionFrameAnalysis` values.
///
/// - Searching: every few frames the buffer is downsampled to RGB and handed to
///   `BoardDetector`.
/// - Tracking: every frame the calibrated board region is resampled to a fixed-size
///   luma/chroma grid for `ImpactDetector`; the calibration is re-verified against
///   the scene about once a second so camera bumps are noticed.
///
/// Runs on the camera capture queue, never on the main thread. Not thread-safe:
/// all access must stay on that queue.
final class DartboardFrameAnalyzer {
    private enum Mode {
        case searching
        case tracking(BoardCalibration, ImageRegion)
    }

    /// Side of the square grid the impact detector sees (~1.5 mm of board per cell).
    private static let impactGridSize = 320
    /// Longest side of the frame handed to board detection.
    private static let colorFrameLongSide = 640
    private static let boardSearchFrameInterval = 5
    private static let agreementFrameInterval = 30
    private static let qualityGridSize = 48

    private var mode = Mode.searching
    private var impactDetector = ImpactDetector()
    private var frameCount = 0

    func startSearching() {
        mode = .searching
        impactDetector.reset()
        frameCount = 0
    }

    func startTracking(_ calibration: BoardCalibration) {
        let region = ImageRegion.around(calibration)
        impactDetector.configure(calibration: calibration, region: region)
        mode = .tracking(calibration, region)
        frameCount = 0
    }

    func analyze(_ pixelBuffer: CVPixelBuffer) -> VisionFrameAnalysis? {
        guard let planes = LockedPlanes(pixelBuffer) else { return nil }
        defer { planes.unlock() }
        frameCount += 1

        let quality = planes.quality(gridSize: Self.qualityGridSize)
        var board: BoardDetection?
        var didSearch = false
        var agreement: Double?
        var event: ImpactDetector.Event?

        switch mode {
        case .searching:
            if frameCount % Self.boardSearchFrameInterval == 1,
               let frame = planes.colorFrame(longSide: Self.colorFrameLongSide) {
                didSearch = true
                board = BoardDetector.detect(in: frame)
            }
        case let .tracking(calibration, region):
            if let frame = planes.impactFrame(region: region, gridSize: Self.impactGridSize) {
                event = impactDetector.process(frame)
            }
            if frameCount % Self.agreementFrameInterval == 0,
               let frame = planes.colorFrame(longSide: Self.colorFrameLongSide) {
                agreement = BoardDetector.agreement(of: calibration, in: frame)
            }
        }

        return VisionFrameAnalysis(
            board: board,
            didSearchForBoard: didSearch,
            calibrationAgreement: agreement,
            event: event,
            isArmed: impactDetector.isArmed,
            brightness: quality.brightness,
            sharpness: quality.sharpness,
            aspectRatio: Double(planes.height) / Double(planes.width),
            timestamp: Date()
        )
    }
}

/// Read access to the luma and chroma planes of a locked bi-planar 4:2:0 buffer.
private struct LockedPlanes {
    let pixelBuffer: CVPixelBuffer
    let width: Int
    let height: Int
    let luma: UnsafePointer<UInt8>
    let lumaBytesPerRow: Int
    let chroma: UnsafePointer<UInt8>
    let chromaBytesPerRow: Int
    let chromaWidth: Int
    let chromaHeight: Int

    init?(_ pixelBuffer: CVPixelBuffer) {
        let format = CVPixelBufferGetPixelFormatType(pixelBuffer)
        guard format == kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
            || format == kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
            CVPixelBufferGetPlaneCount(pixelBuffer) >= 2 else { return nil }
        guard CVPixelBufferLockBaseAddress(pixelBuffer, .readOnly) == kCVReturnSuccess else { return nil }
        guard let lumaBase = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0),
              let chromaBase = CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 1) else {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
            return nil
        }
        let width = CVPixelBufferGetWidthOfPlane(pixelBuffer, 0)
        let height = CVPixelBufferGetHeightOfPlane(pixelBuffer, 0)
        let chromaWidth = CVPixelBufferGetWidthOfPlane(pixelBuffer, 1)
        let chromaHeight = CVPixelBufferGetHeightOfPlane(pixelBuffer, 1)
        guard width >= 64, height >= 64, chromaWidth > 0, chromaHeight > 0 else {
            CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
            return nil
        }
        self.pixelBuffer = pixelBuffer
        self.width = width
        self.height = height
        self.luma = UnsafePointer(lumaBase.assumingMemoryBound(to: UInt8.self))
        self.lumaBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 0)
        self.chroma = UnsafePointer(chromaBase.assumingMemoryBound(to: UInt8.self))
        self.chromaBytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer, 1)
        self.chromaWidth = chromaWidth
        self.chromaHeight = chromaHeight
    }

    func unlock() {
        CVPixelBufferUnlockBaseAddress(pixelBuffer, .readOnly)
    }

    /// Luma at a pixel, clamped to the buffer.
    @inline(__always)
    private func lumaValue(x: Int, y: Int) -> Int {
        let cx = min(max(x, 0), width - 1)
        let cy = min(max(y, 0), height - 1)
        return Int(luma[cy * lumaBytesPerRow + cx])
    }

    /// Cb and Cr for a full-resolution pixel position, clamped to the buffer.
    @inline(__always)
    private func chromaValue(x: Int, y: Int) -> (cb: Int, cr: Int) {
        let cx = min(max(x * chromaWidth / width, 0), chromaWidth - 1)
        let cy = min(max(y * chromaHeight / height, 0), chromaHeight - 1)
        let offset = cy * chromaBytesPerRow + cx * 2
        return (Int(chroma[offset]), Int(chroma[offset + 1]))
    }

    /// Mean luma plus a focus/motion-blur proxy (mean horizontal gradient) from a coarse grid.
    func quality(gridSize: Int) -> (brightness: Double, sharpness: Double) {
        var total = 0
        var gradient = 0
        for gridY in 0 ..< gridSize {
            let y = gridY * height / gridSize + height / (gridSize * 2)
            var previous = 0
            for gridX in 0 ..< gridSize {
                let x = gridX * width / gridSize + width / (gridSize * 2)
                let value = lumaValue(x: x, y: y)
                total += value
                if gridX > 0 {
                    gradient += abs(value - previous)
                }
                previous = value
            }
        }
        let cells = Double(gridSize * gridSize)
        let brightness = Double(total) / cells / 255
        let meanGradient = Double(gradient) / Double(gridSize * (gridSize - 1)) / 255
        return (brightness, min(1, meanGradient / 0.08))
    }

    /// Downsampled RGB copy of the whole frame for board detection.
    func colorFrame(longSide: Int) -> ColorFrame? {
        let factor = max(1, Int((Double(max(width, height)) / Double(longSide)).rounded(.up)))
        let outWidth = width / factor
        let outHeight = height / factor
        guard outWidth > 0, outHeight > 0 else { return nil }
        var rgb = [UInt8](repeating: 0, count: outWidth * outHeight * 3)
        rgb.withUnsafeMutableBufferPointer { out in
            for oy in 0 ..< outHeight {
                let sy = oy * factor + factor / 2
                for ox in 0 ..< outWidth {
                    let sx = ox * factor + factor / 2
                    // Average a 2x2 luma patch to tame sensor noise.
                    let y = (lumaValue(x: sx, y: sy) + lumaValue(x: sx - 1, y: sy)
                        + lumaValue(x: sx, y: sy - 1) + lumaValue(x: sx - 1, y: sy - 1)) / 4
                    let c = chromaValue(x: sx, y: sy)
                    let cb = c.cb - 128
                    let cr = c.cr - 128
                    // Full-range YCbCr -> RGB in 10-bit fixed point.
                    let r = y + (1436 * cr) / 1024
                    let g = y - (352 * cb + 731 * cr) / 1024
                    let b = y + (1815 * cb) / 1024
                    let index = (oy * outWidth + ox) * 3
                    out[index] = UInt8(min(255, max(0, r)))
                    out[index + 1] = UInt8(min(255, max(0, g)))
                    out[index + 2] = UInt8(min(255, max(0, b)))
                }
            }
        }
        return ColorFrame(width: outWidth, height: outHeight, rgb: rgb)
    }

    /// Resamples a square image region (width units) to the impact detector's grid.
    func impactFrame(region: ImageRegion, gridSize: Int) -> ImpactFrame? {
        guard region.size > 0 else { return nil }
        let count = gridSize * gridSize
        var lumaOut = [Float](repeating: 0.1, count: count)
        var cbOut = [Float](repeating: 0.5, count: count)
        var crOut = [Float](repeating: 0.5, count: count)
        // Width units scale by the buffer width on both axes.
        let unit = Double(width)
        let cellPixels = region.size * unit / Double(gridSize)
        // Box-filter over each cell's footprint so thin dart parts are not skipped.
        let taps = min(3, max(1, Int(cellPixels.rounded())))
        let tapStep = cellPixels / Double(taps)
        let tapCount = Float(taps * taps) * 255

        lumaOut.withUnsafeMutableBufferPointer { lumaPointer in
            cbOut.withUnsafeMutableBufferPointer { cbPointer in
                crOut.withUnsafeMutableBufferPointer { crPointer in
                    for gridY in 0 ..< gridSize {
                        let top = (region.originY + Double(gridY) / Double(gridSize) * region.size) * unit
                        for gridX in 0 ..< gridSize {
                            let left = (region.originX + Double(gridX) / Double(gridSize) * region.size) * unit
                            let centerX = Int(left + cellPixels / 2)
                            let centerY = Int(top + cellPixels / 2)
                            // Cells outside the camera image keep their constant fill.
                            guard centerX >= 0, centerY >= 0, centerX < width, centerY < height else { continue }
                            var sum = 0
                            for tapY in 0 ..< taps {
                                let y = Int(top + (Double(tapY) + 0.5) * tapStep)
                                for tapX in 0 ..< taps {
                                    sum += lumaValue(x: Int(left + (Double(tapX) + 0.5) * tapStep), y: y)
                                }
                            }
                            let c = chromaValue(x: centerX, y: centerY)
                            let index = gridY * gridSize + gridX
                            lumaPointer[index] = Float(sum) / tapCount
                            cbPointer[index] = Float(c.cb) / 255
                            crPointer[index] = Float(c.cr) / 255
                        }
                    }
                }
            }
        }
        return ImpactFrame(width: gridSize, height: gridSize, luma: lumaOut, cb: cbOut, cr: crOut)
    }
}
