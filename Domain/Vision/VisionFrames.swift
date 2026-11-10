import Foundation

/// A downsampled RGB frame (row-major, interleaved `r, g, b` bytes) used for board
/// detection. Pixel `(0, 0)` is the top-left corner of the upright image.
public struct ColorFrame: Sendable {
    public let width: Int
    public let height: Int
    public let rgb: [UInt8]

    public init?(width: Int, height: Int, rgb: [UInt8]) {
        guard width > 0, height > 0, rgb.count == width * height * 3 else { return nil }
        self.width = width
        self.height = height
        self.rgb = rgb
    }

    /// Frame height divided by width.
    public var aspectRatio: Double {
        Double(height) / Double(width)
    }
}

/// A square crop of the camera image, in width units, that the impact detector watches.
public struct ImageRegion: Codable, Equatable, Sendable {
    public let originX: Double
    public let originY: Double
    public let size: Double

    public init(originX: Double, originY: Double, size: Double) {
        self.originX = originX
        self.originY = originY
        self.size = size
    }

    /// Region covering the board plus room for darts leaning out past its edge.
    public static func around(_ calibration: BoardCalibration, radiusScale: Double = 1.45) -> ImageRegion {
        let points = (calibration.controlPoints?.ordered ?? [])
        let reach = points.map { $0.distance(to: ImagePoint(x: calibration.centerX, y: calibration.centerY)) }.max()
        let half = (reach ?? calibration.radius) * radiusScale
        return ImageRegion(originX: calibration.centerX - half, originY: calibration.centerY - half, size: half * 2)
    }

    /// Converts a point in region-normalised coordinates (`0...1`) to image width units.
    public func imagePoint(normalizedX: Double, normalizedY: Double) -> ImagePoint {
        ImagePoint(x: originX + normalizedX * size, y: originY + normalizedY * size)
    }
}

/// One sample of the watched region: luma and chroma planes in `0...1`, row-major.
/// Pixels that fall outside the camera image should repeat a constant value.
public struct ImpactFrame: Sendable {
    public let width: Int
    public let height: Int
    public let luma: [Float]
    public let cb: [Float]
    public let cr: [Float]

    public init?(width: Int, height: Int, luma: [Float], cb: [Float], cr: [Float]) {
        let count = width * height
        guard width > 0, height > 0, luma.count == count, cb.count == count, cr.count == count else { return nil }
        self.width = width
        self.height = height
        self.luma = luma
        self.cb = cb
        self.cr = cr
    }

    /// Greyscale convenience (neutral chroma).
    public init?(width: Int, height: Int, luma: [Float]) {
        let neutral = [Float](repeating: 0.5, count: max(0, width * height))
        self.init(width: width, height: height, luma: luma, cb: neutral, cr: neutral)
    }

    public var meanLuma: Float {
        luma.reduce(0, +) / Float(luma.count)
    }
}

/// 8-connected component labelling over a boolean mask.
enum ConnectedComponents {
    struct Component {
        var pixels: [Int] = []
        var minX = Int.max
        var minY = Int.max
        var maxX = Int.min
        var maxY = Int.min

        var boundingArea: Int {
            pixels.isEmpty ? 0 : (maxX - minX + 1) * (maxY - minY + 1)
        }
    }

    /// Returns every component with at least `minimumSize` pixels.
    static func find(mask: [Bool], width: Int, height: Int, minimumSize: Int = 1) -> [Component] {
        guard mask.count == width * height else { return [] }
        var visited = [Bool](repeating: false, count: mask.count)
        var components: [Component] = []
        var stack: [Int] = []
        for start in mask.indices where mask[start] && !visited[start] {
            var component = Component()
            visited[start] = true
            stack.append(start)
            while let index = stack.popLast() {
                let x = index % width
                let y = index / width
                component.pixels.append(index)
                component.minX = min(component.minX, x)
                component.maxX = max(component.maxX, x)
                component.minY = min(component.minY, y)
                component.maxY = max(component.maxY, y)
                for ny in max(0, y - 1) ... min(height - 1, y + 1) {
                    for nx in max(0, x - 1) ... min(width - 1, x + 1) {
                        let neighbour = ny * width + nx
                        if mask[neighbour], !visited[neighbour] {
                            visited[neighbour] = true
                            stack.append(neighbour)
                        }
                    }
                }
            }
            if component.pixels.count >= minimumSize {
                components.append(component)
            }
        }
        return components
    }
}
