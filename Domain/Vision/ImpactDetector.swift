import Foundation

/// A downsampled grayscale frame in row-major order with values in `0...1`.
public struct LumaGrid: Equatable, Sendable {
    public let width: Int
    public let height: Int
    public let values: [Double]

    public init?(width: Int, height: Int, values: [Double]) {
        guard width > 0, height > 0, values.count == width * height else { return nil }
        self.width = width
        self.height = height
        self.values = values
    }

    public var brightness: Double {
        values.reduce(0, +) / Double(values.count)
    }
}

/// Baseline-vs-frame differencing dart impact detector (spec §6 baseline approach:
/// no Core ML required). A baseline is captured once the scene holds still; a small,
/// stationary cluster of changed cells that persists across frames is reported as a
/// dart impact, while large frame-wide changes (a player retrieving darts) reset the
/// baseline instead. Pure value type so the heuristic is unit-testable.
public struct ImpactDetector: Sendable {
    public struct Candidate: Equatable, Sendable {
        /// Impact point (the dart tip when a tip offset is set, otherwise the cluster
        /// centroid) in normalized image coordinates (`0...1`, y down).
        public let imageX: Double
        public let imageY: Double
        public let confidence: Double
        /// Bounding box of the changed cells (normalized `minX, minY, maxX, maxY`), for
        /// full-resolution refinement.
        public let clusterBounds: SIMD4<Double>
    }

    public struct Configuration: Sendable {
        /// Per-cell luma delta that counts as "changed".
        public var cellChangeThreshold = 0.1
        /// Changed-cell fraction above which the change is scene motion, not a dart.
        public var motionCellFraction = 0.06
        /// Still frames required before (re)capturing the baseline.
        public var stableFramesRequired = 5
        /// Frames a candidate cluster must persist at the same spot before reporting.
        public var persistenceFramesRequired = 3
        /// Max centroid travel (normalized) between frames for a cluster to count as stationary.
        public var centroidStabilityTolerance = 0.03
        /// Frames to ignore after reporting an impact.
        public var cooldownFrames = 8
        /// Fewest changed cells that can be a dart; a lone cell is sensor noise.
        public var minimumClusterCells = 2
        /// Max distance (normalized) of any changed cell from the centroid. Wider,
        /// scattered change is an exposure or focus shift, not a dart.
        public var maxClusterSpread = 0.15
        /// Fraction of the expected dart length a cluster must span along the dart
        /// axis to count as the whole dart rather than just the flight.
        public var wholeDartSpanFraction = 0.6

        public init() {}
    }

    private let configuration: Configuration
    /// Cells allowed to report an impact (row-major, same size as the grid). `nil` means the whole frame.
    private var region: [Bool]?
    /// Expected vector (normalized grid units) from a dart's flight center to its tip.
    private var tipOffset: SIMD2<Double>?
    private var baseline: LumaGrid? {
        didSet { if baseline != nil { baselineGeneration &+= 1 } }
    }
    /// Changes whenever a new baseline frame is adopted, so callers can keep a matching
    /// full-resolution copy of the pre-arrival frame.
    public private(set) var baselineGeneration = 0
    public private(set) var sawLargeMotion = false
    private var previous: LumaGrid?
    private var stillStreak = 0
    private var candidateCentroid: (x: Double, y: Double)?
    private var candidateStreak = 0
    private var candidateClusterSizes: [Int] = []
    private var cooldownRemaining = 0

    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }

    /// Feeds the next frame; returns a candidate when a new stationary impact is confirmed.
    public mutating func process(_ grid: LumaGrid) -> Candidate? {
        sawLargeMotion = false
        defer { previous = grid }

        if cooldownRemaining > 0 {
            cooldownRemaining -= 1
            return nil
        }

        let frameIsStill = isStill(grid, comparedTo: previous)
        sawLargeMotion = previous != nil && !frameIsStill
        guard let baseline, baseline.width == grid.width, baseline.height == grid.height else {
            captureBaselineIfStable(grid, frameIsStill: frameIsStill)
            return nil
        }

        let allChanged = changedCells(in: grid, against: baseline)
        if Double(allChanged.count) / Double(grid.values.count) > configuration.motionCellFraction {
            // Large change: a hand or body in frame. Re-stabilize before trusting diffs again.
            sawLargeMotion = true
            self.baseline = nil
            stillStreak = 0
            resetCandidate()
            return nil
        }
        let changed = region.map { region in allChanged.filter { $0 < region.count && region[$0] } } ?? allChanged
        if changed.isEmpty {
            resetCandidate()
            // Roll the baseline forward so slow exposure and lighting drift never
            // accumulates into a fake impact; only an abrupt arrival diffs against it.
            if frameIsStill { self.baseline = grid }
            return nil
        }
        guard frameIsStill else {
            resetCandidate()
            return nil
        }

        let centroid = centroid(of: changed, width: grid.width, height: grid.height)
        guard changed.count >= configuration.minimumClusterCells,
              isCompact(changed, around: centroid, width: grid.width, height: grid.height) else {
            resetCandidate()
            self.baseline = grid
            return nil
        }
        if let existing = candidateCentroid,
           abs(existing.x - centroid.x) <= configuration.centroidStabilityTolerance,
           abs(existing.y - centroid.y) <= configuration.centroidStabilityTolerance {
            candidateStreak += 1
        } else {
            candidateStreak = 1
            candidateClusterSizes = []
        }
        candidateCentroid = centroid
        candidateClusterSizes.append(changed.count)

        guard candidateStreak >= configuration.persistenceFramesRequired else { return nil }

        // Absorb the dart into the baseline so the next throw diffs cleanly.
        self.baseline = grid
        cooldownRemaining = configuration.cooldownFrames
        let point = tipOffset.map { tipPoint(of: changed, centroid: centroid, offset: $0, width: grid.width, height: grid.height) }
            ?? centroid
        let candidate = Candidate(
            imageX: point.x,
            imageY: point.y,
            confidence: confidence(clusterSizes: candidateClusterSizes, gridCellCount: grid.values.count),
            clusterBounds: bounds(of: changed, width: grid.width, height: grid.height)
        )
        resetCandidate()
        return candidate
    }

    /// Limits impacts to `region` cells (row-major, grid-sized); `nil` watches the whole frame.
    /// `tipOffset` is the flight-center-to-tip vector in normalized grid units; with it,
    /// impacts report the tip instead of the cluster centroid.
    public mutating func setRegion(_ region: [Bool]?, tipOffset: SIMD2<Double>? = nil) {
        self.region = region
        self.tipOffset = tipOffset
        baseline = nil
        stillStreak = 0
        resetCandidate()
    }

    /// Forgets all state, e.g. after recalibration.
    public mutating func reset() {
        region = nil
        tipOffset = nil
        baseline = nil
        previous = nil
        stillStreak = 0
        cooldownRemaining = 0
        resetCandidate()
    }

    // MARK: - Internals

    private mutating func captureBaselineIfStable(_ grid: LumaGrid, frameIsStill: Bool) {
        stillStreak = frameIsStill ? stillStreak + 1 : 0
        if stillStreak >= configuration.stableFramesRequired {
            baseline = grid
        }
    }

    private func isStill(_ grid: LumaGrid, comparedTo previous: LumaGrid?) -> Bool {
        guard let previous, previous.width == grid.width, previous.height == grid.height else {
            return false
        }
        let changed = changedCells(in: grid, against: previous)
        return Double(changed.count) / Double(grid.values.count) <= configuration.motionCellFraction
    }

    private func changedCells(in grid: LumaGrid, against reference: LumaGrid) -> [Int] {
        var indices: [Int] = []
        for index in grid.values.indices
        where abs(grid.values[index] - reference.values[index]) >= configuration.cellChangeThreshold {
            indices.append(index)
        }
        return indices
    }

    private func cellCenter(_ index: Int, width: Int, height: Int) -> (x: Double, y: Double) {
        ((Double(index % width) + 0.5) / Double(width), (Double(index / width) + 0.5) / Double(height))
    }

    private func centroid(of indices: [Int], width: Int, height: Int) -> (x: Double, y: Double) {
        var sumX = 0.0
        var sumY = 0.0
        for index in indices {
            let cell = cellCenter(index, width: width, height: height)
            sumX += cell.x
            sumY += cell.y
        }
        let count = Double(indices.count)
        return (sumX / count, sumY / count)
    }

    private func bounds(of indices: [Int], width: Int, height: Int) -> SIMD4<Double> {
        let columns = indices.map { $0 % width }
        let rows = indices.map { $0 / width }
        return SIMD4(
            Double(columns.min() ?? 0) / Double(width),
            Double(rows.min() ?? 0) / Double(height),
            Double((columns.max() ?? 0) + 1) / Double(width),
            Double((rows.max() ?? 0) + 1) / Double(height)
        )
    }

    private func isCompact(_ indices: [Int], around centroid: (x: Double, y: Double), width: Int, height: Int) -> Bool {
        indices.allSatisfy { index in
            let cell = cellCenter(index, width: width, height: height)
            return abs(cell.x - centroid.x) <= configuration.maxClusterSpread
                && abs(cell.y - centroid.y) <= configuration.maxClusterSpread
        }
    }

    /// The flight is the biggest, brightest change, so the centroid sits on it, not the tip.
    /// When the cluster spans most of a dart along the flight-to-tip axis, its far end is the
    /// tip; when only the flight registered, step one expected dart length from its center.
    private func tipPoint(
        of indices: [Int],
        centroid: (x: Double, y: Double),
        offset: SIMD2<Double>,
        width: Int,
        height: Int
    ) -> (x: Double, y: Double) {
        let length = (offset.x * offset.x + offset.y * offset.y).squareRoot()
        guard length > 0 else { return centroid }
        let axis = (x: offset.x / length, y: offset.y / length)
        var nearest = Double.infinity
        var farthest = -Double.infinity
        var tip = centroid
        for index in indices {
            let cell = cellCenter(index, width: width, height: height)
            let along = (cell.x - centroid.x) * axis.x + (cell.y - centroid.y) * axis.y
            nearest = min(nearest, along)
            if along > farthest {
                farthest = along
                tip = cell
            }
        }
        if farthest - nearest >= configuration.wholeDartSpanFraction * length {
            return tip
        }
        return (centroid.x + offset.x, centroid.y + offset.y)
    }

    /// Smaller, consistently sized clusters look like a dart; sprawling or erratic
    /// clusters earn less confidence. Output stays in `0.3...0.9` for Phase A so
    /// detections always route through the proposal flow, never auto-commit.
    private func confidence(clusterSizes: [Int], gridCellCount: Int) -> Double {
        guard let largest = clusterSizes.max(), largest > 0 else { return 0.3 }
        let sizeFraction = Double(largest) / Double(gridCellCount)
        let sizeScore = max(0, 1 - sizeFraction / 0.02)
        let smallest = Double(clusterSizes.min() ?? largest)
        let consistencyScore = smallest / Double(largest)
        return min(0.9, max(0.3, 0.3 + 0.4 * sizeScore + 0.2 * consistencyScore))
    }

    private mutating func resetCandidate() {
        candidateCentroid = nil
        candidateStreak = 0
        candidateClusterSizes = []
    }
}
