import Foundation

/// Confidence policy for vision detections (spec §3, §8).
/// - `assistive` (Phase A): every detection is proposed for confirm/edit.
/// - `automatic` (Phase B): detections score immediately; uncertain ones are still
///   scored (so a throw is never lost mid-visit) but flagged `needsReview`, so the
///   player is never *silently* given a doubtful score.
public struct VisionScoringPolicy: Equatable, Sendable {
    public enum LowConfidenceBehavior: Equatable, Sendable {
        /// Hold the detection as a pending proposal until confirmed or rejected.
        case propose
        /// Score it now, flagged for review.
        case commitFlagged
    }

    /// Detections below this confidence are dropped without a proposal.
    public let proposalConfidenceFloor: Double
    public let autoCommitEnabled: Bool
    public let autoCommitConfidenceThreshold: Double
    public let lowConfidenceBehavior: LowConfidenceBehavior
    /// Tips closer than this to a wire (millimetres) lose confidence, bottoming out
    /// at `wireMinimumConfidenceFactor` on the wire itself.
    public let wireCautionDistanceMM: Double
    public let wireMinimumConfidenceFactor: Double

    public init(
        proposalConfidenceFloor: Double = 0.35,
        autoCommitEnabled: Bool = false,
        autoCommitConfidenceThreshold: Double = 0.92,
        lowConfidenceBehavior: LowConfidenceBehavior = .propose,
        wireCautionDistanceMM: Double = 0,
        wireMinimumConfidenceFactor: Double = 0.6
    ) {
        self.proposalConfidenceFloor = proposalConfidenceFloor
        self.autoCommitEnabled = autoCommitEnabled
        self.autoCommitConfidenceThreshold = autoCommitConfidenceThreshold
        self.lowConfidenceBehavior = lowConfidenceBehavior
        self.wireCautionDistanceMM = wireCautionDistanceMM
        self.wireMinimumConfidenceFactor = wireMinimumConfidenceFactor
    }

    public static let assistive = VisionScoringPolicy()

    public static let automatic = VisionScoringPolicy(
        proposalConfidenceFloor: 0.3,
        autoCommitEnabled: true,
        autoCommitConfidenceThreshold: 0.7,
        lowConfidenceBehavior: .commitFlagged,
        wireCautionDistanceMM: 4
    )

    /// Scales raw detector confidence by how close the tip is to a scoring boundary.
    public func adjustedConfidence(_ confidence: Double, at point: BoardPoint) -> Double {
        guard wireCautionDistanceMM > 0 else { return confidence }
        let marginMM = DartboardGeometry.boundaryMargin(at: point) * DartboardGeometry.doubleOuterRadiusMM
        let closeness = max(0, min(1, 1 - marginMM / wireCautionDistanceMM))
        return confidence * (1 - closeness * (1 - wireMinimumConfidenceFactor))
    }
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
        case proposalPending
        case unmappablePoint
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
    public private(set) var pendingProposal: DetectedThrow?

    public init(id: UUID = UUID(), policy: VisionScoringPolicy = .assistive) {
        self.id = id
        self.policy = policy
        self.phase = .calibrating
    }

    // MARK: - Calibration lifecycle

    /// Applies a completed calibration. Rejected (returns `false`) when quality is
    /// below the acceptance gate, leaving the session in `.calibrating`.
    @discardableResult
    public mutating func applyCalibration(_ calibration: BoardCalibration) -> Bool {
        guard calibration.quality.isAcceptable else { return false }
        self.calibration = calibration
        pendingProposal = nil
        phase = .ready
        return true
    }

    /// Feeds a fresh board observation; pauses the session when drift exceeds
    /// tolerance so play downgrades to manual until recalibration (spec §8).
    /// Returns `true` when drift paused the session.
    @discardableResult
    public mutating func observeBoard(centerX: Double, centerY: Double, radius: Double) -> Bool {
        guard phase == .ready, let calibration else { return false }
        guard calibration.hasDrifted(
            observedCenterX: centerX,
            observedCenterY: centerY,
            observedRadius: radius
        ) else { return false }
        phase = .paused(.calibrationDrift)
        pendingProposal = nil
        return true
    }

    /// Drops the current calibration and returns to the guided calibration flow.
    public mutating func beginRecalibration() {
        calibration = nil
        pendingProposal = nil
        phase = .calibrating
    }

    /// Pauses scoring because the board no longer lines up with the calibration.
    public mutating func pauseForDrift() {
        guard phase == .ready else { return }
        phase = .paused(.calibrationDrift)
        pendingProposal = nil
    }

    /// Resumes after a drift pause when the player chooses to keep the calibration.
    public mutating func resumeFromDriftPause() {
        guard phase == .paused(.calibrationDrift), calibration != nil else { return }
        phase = .ready
    }

    public mutating func pauseByUser() {
        guard phase == .ready else { return }
        phase = .paused(.userPaused)
        pendingProposal = nil
    }

    public mutating func resumeFromUserPause() {
        guard phase == .paused(.userPaused), calibration != nil else { return }
        phase = .ready
    }

    // MARK: - Detection commands

    public mutating func handle(_ command: DetectThrowCommand) -> DetectionOutcome {
        guard command.visionSessionId == id else { return .ignored(.sessionMismatch) }
        guard phase == .ready, let calibration else { return .ignored(.sessionNotReady) }
        guard pendingProposal == nil else { return .ignored(.proposalPending) }
        guard command.confidence >= policy.proposalConfidenceFloor else {
            return .ignored(.belowConfidenceFloor)
        }
        guard let point = calibration.transform.apply(toImageX: command.imageX, imageY: command.imageY) else {
            return .ignored(.unmappablePoint)
        }
        let confidence = policy.adjustedConfidence(command.confidence, at: point)
        let isConfident = confidence >= policy.autoCommitConfidenceThreshold

        let detection = DetectedThrow(
            visionSessionId: id,
            dart: DartboardGeometry.dartInput(at: point),
            visionConfidence: confidence,
            frameTimestamp: command.frameTimestamp,
            boardPoint: point,
            needsReview: policy.autoCommitEnabled && !isConfident
        )
        // Never silently auto-score below the threshold (spec §8): doubtful throws
        // are either held for confirmation or scored with a visible review flag.
        if policy.autoCommitEnabled, isConfident || policy.lowConfidenceBehavior == .commitFlagged {
            return .autoCommitted(detection)
        }
        pendingProposal = detection
        return .proposed(detection)
    }

    /// Confirms the pending proposal, returning the dart (corrected if the user edited it)
    /// and the metadata to attach to the scoring event. Returns `nil` for stale ids.
    public mutating func handle(_ command: ConfirmDetectedThrowCommand) -> (dart: DartInput, metadata: VisionThrowMetadata)? {
        guard let proposal = pendingProposal, proposal.id == command.detectedThrowId else { return nil }
        pendingProposal = nil
        let dart = command.correctedDart ?? proposal.dart
        return (dart, proposal.metadata(inputMethod: .visionConfirmed))
    }

    /// Rejects the pending proposal. Returns `false` for stale ids.
    @discardableResult
    public mutating func handle(_ command: RejectDetectedThrowCommand) -> Bool {
        guard let proposal = pendingProposal, proposal.id == command.detectedThrowId else { return false }
        pendingProposal = nil
        return true
    }
}
