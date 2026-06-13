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
        /// Impact centroid in normalized image coordinates (`0...1`, y down).
        public let imageX: Double
        public let imageY: Double
        public let confidence: Double
    }

    public struct Configuration: Sendable {
        /// Per-cell luma delta that counts as "changed".
        public var cellChangeThreshold = 0.14
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

        public init() {}
    }

    private let configuration: Configuration
    private var baseline: LumaGrid?
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
        defer { previous = grid }

        if cooldownRemaining > 0 {
            cooldownRemaining -= 1
            return nil
        }

        let frameIsStill = isStill(grid, comparedTo: previous)
        guard let baseline, baseline.width == grid.width, baseline.height == grid.height else {
            captureBaselineIfStable(grid, frameIsStill: frameIsStill)
            return nil
        }

        let changed = changedCells(in: grid, against: baseline)
        if changed.isEmpty {
            resetCandidate()
            return nil
        }
        if Double(changed.count) / Double(grid.values.count) > configuration.motionCellFraction {
            // Large change: a hand or body in frame. Re-stabilize before trusting diffs again.
            self.baseline = nil
            stillStreak = 0
            resetCandidate()
            return nil
        }
        guard frameIsStill else {
            resetCandidate()
            return nil
        }

        let centroid = centroid(of: changed, width: grid.width, height: grid.height)
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
        let candidate = Candidate(
            imageX: centroid.x,
            imageY: centroid.y,
            confidence: confidence(clusterSizes: candidateClusterSizes, gridCellCount: grid.values.count)
        )
        resetCandidate()
        return candidate
    }

    /// Forgets all state, e.g. after recalibration.
    public mutating func reset() {
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

    private func centroid(of indices: [Int], width: Int, height: Int) -> (x: Double, y: Double) {
        var sumX = 0.0
        var sumY = 0.0
        for index in indices {
            sumX += (Double(index % width) + 0.5) / Double(width)
            sumY += (Double(index / width) + 0.5) / Double(height)
        }
        let count = Double(indices.count)
        return (sumX / count, sumY / count)
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
