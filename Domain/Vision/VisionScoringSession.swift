import Foundation

/// Confidence policy for vision detections (spec §3, §8).
/// Phase A ships with auto-commit disabled: every detection is proposed for
/// confirm/edit. Phase B flips `autoCommitEnabled` with a tuned threshold.
public struct VisionScoringPolicy: Equatable, Sendable {
    /// Detections below this confidence are dropped without a proposal.
    public let proposalConfidenceFloor: Double
    public let autoCommitEnabled: Bool
    public let autoCommitConfidenceThreshold: Double

    public init(
        proposalConfidenceFloor: Double = 0.35,
        autoCommitEnabled: Bool = false,
        autoCommitConfidenceThreshold: Double = 0.92
    ) {
        self.proposalConfidenceFloor = proposalConfidenceFloor
        self.autoCommitEnabled = autoCommitEnabled
        self.autoCommitConfidenceThreshold = autoCommitConfidenceThreshold
    }

    public static let assistive = VisionScoringPolicy()
}

public enum VisionSessionPhase: Equatable, Sendable {
    case calibrating
    case ready
    case paused(VisionPauseReason)
}

public enum VisionPauseReason: Equatable, Sendable {
    case calibrationDrift
    case userPaused
}

public enum DetectionOutcome: Equatable, Sendable {
    case proposed(DetectedThrow)
    case autoCommitted(DetectedThrow)
    case ignored(IgnoredReason)

    public enum IgnoredReason: Equatable, Sendable {
        case sessionNotReady
        case sessionMismatch
        case belowConfidenceFloor
        case visitClosed
        case unmappablePoint
        case duplicate
    }
}

/// State machine for one camera scoring session. The match engine stays the source
/// of truth — this type only turns raw detections into proposals/commits and tracks
/// calibration health (spec §7, §8). Pure value type so it is fully unit-testable.
public struct VisionScoringSession: Equatable, Sendable {
    public let id: UUID
    public let policy: VisionScoringPolicy
    public private(set) var phase: VisionSessionPhase
    public private(set) var calibration: BoardCalibration?
    public private(set) var visit: [VisitDart] = []
    public private(set) var visitStatus: VisionVisitStatus = .collecting
    public private(set) var visitCapacity = 3

    /// A second report this soon at nearly the same board spot is a dart settling or
    /// drooping after impact, not a new throw.
    public static let duplicateWindow: TimeInterval = 1.0
    /// Board-plane distance (outer double radius = 1, about 14 mm) for the duplicate check.
    public static let duplicateBoardDistance = 0.08

    public init(id: UUID = UUID(), policy: VisionScoringPolicy = .assistive) {
        self.id = id
        self.policy = policy
        self.phase = .calibrating
    }

    // MARK: - Visit

    public mutating func beginVisit(capacity: Int) {
        visit = []
        visitCapacity = min(max(capacity, 0), 3)
        visitStatus = visitCapacity > 0 ? .collecting : .reviewing
    }

    /// Called on takeout, "Done throwing", or when the match says the visit is over.
    /// Automatic closes skip an empty visit; the player can close one by hand when
    /// every dart missed the camera.
    public mutating func closeVisit(evenIfEmpty: Bool = false) {
        guard evenIfEmpty || !visit.isEmpty else { return }
        visitStatus = .reviewing
    }

    public mutating func resumeCollecting() {
        guard visit.count < visitCapacity else { return }
        visitStatus = .collecting
    }

    @discardableResult
    public mutating func editDart(id: UUID, to dart: DartInput) -> Bool {
        guard let index = visit.firstIndex(where: { $0.id == id }) else { return false }
        visit[index].dart = dart
        return true
    }

    @discardableResult
    public mutating func removeDart(id: UUID) -> VisitDart? {
        guard let index = visit.firstIndex(where: { $0.id == id }) else { return nil }
        return visit.remove(at: index)
    }

    @discardableResult
    public mutating func addManualDart(_ dart: DartInput) -> Bool {
        guard visit.count < visitCapacity else { return false }
        visit.append(VisitDart(detection: nil, dart: dart))
        if visit.count >= visitCapacity {
            visitStatus = .reviewing
        }
        return true
    }

    public mutating func submitVisit() -> [VisitDart] {
        let submitted = visit
        beginVisit(capacity: visitCapacity)
        return submitted
    }

    // MARK: - Calibration lifecycle

    /// Applies a completed calibration. Rejected (returns `false`) when quality is
    /// below the acceptance gate, leaving the session in `.calibrating`.
    @discardableResult
    public mutating func applyCalibration(_ calibration: BoardCalibration) -> Bool {
        guard calibration.quality.isAcceptable else { return false }
        self.calibration = calibration
        phase = .ready
        return true
    }

    /// Feeds a fresh board observation; pauses the session when drift exceeds
    /// tolerance so play downgrades to manual until recalibration (spec §8).
    /// Returns `true` when drift paused the session.
    @discardableResult
    public mutating func observeBoard(centerX: Double, centerY: Double, radius: Double) -> Bool {
        guard phase == .ready, let calibration, calibration.monitorsContourDrift else { return false }
        guard calibration.hasDrifted(
            observedCenterX: centerX,
            observedCenterY: centerY,
            observedRadius: radius
        ) else { return false }
        phase = .paused(.calibrationDrift)
        closeVisit()
        return true
    }

    /// Drops the current calibration and returns to the guided calibration flow.
    public mutating func beginRecalibration() {
        calibration = nil
        phase = .calibrating
    }

    public mutating func pauseByUser() {
        guard phase == .ready else { return }
        phase = .paused(.userPaused)
    }

    public mutating func resumeFromUserPause() {
        guard phase == .paused(.userPaused), calibration != nil else { return }
        phase = .ready
    }

    // MARK: - Detection commands

    public mutating func handle(_ command: DetectThrowCommand) -> DetectionOutcome {
        guard command.visionSessionId == id else { return .ignored(.sessionMismatch) }
        guard phase == .ready, let calibration else { return .ignored(.sessionNotReady) }
        guard visitStatus == .collecting, visit.count < visitCapacity else { return .ignored(.visitClosed) }
        guard command.confidence >= policy.proposalConfidenceFloor else {
            return .ignored(.belowConfidenceFloor)
        }
        guard let dart = calibration.dartInput(atImageX: command.imageX, imageY: command.imageY) else {
            return .ignored(.unmappablePoint)
        }
        if isDuplicate(command, calibration: calibration) {
            return .ignored(.duplicate)
        }

        let detection = DetectedThrow(
            visionSessionId: id,
            dart: dart,
            visionConfidence: command.confidence,
            frameTimestamp: command.frameTimestamp,
            imageX: command.imageX,
            imageY: command.imageY
        )
        visit.append(VisitDart(id: detection.id, detection: detection, dart: detection.dart))
        if visit.count >= visitCapacity {
            visitStatus = .reviewing
        }
        // Never silently auto-score below the threshold (spec §8).
        if policy.autoCommitEnabled && command.confidence >= policy.autoCommitConfidenceThreshold {
            return .autoCommitted(detection)
        }
        return .proposed(detection)
    }

    private func isDuplicate(_ command: DetectThrowCommand, calibration: BoardCalibration) -> Bool {
        guard let point = calibration.transform.apply(toImageX: command.imageX, imageY: command.imageY) else {
            return false
        }
        return visit.contains { entry in
            guard let detection = entry.detection,
                  let imageX = detection.imageX,
                  let imageY = detection.imageY,
                  abs(command.frameTimestamp.timeIntervalSince(detection.frameTimestamp)) < Self.duplicateWindow,
                  let previous = calibration.transform.apply(toImageX: imageX, imageY: imageY) else {
                return false
            }
            return hypot(point.x - previous.x, point.y - previous.y) < Self.duplicateBoardDistance
        }
    }
}
