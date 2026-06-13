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
        guard let dart = calibration.dartInput(atImageX: command.imageX, imageY: command.imageY) else {
            return .ignored(.unmappablePoint)
        }

        let detection = DetectedThrow(
            visionSessionId: id,
            dart: dart,
            visionConfidence: command.confidence,
            frameTimestamp: command.frameTimestamp
        )
        // Never silently auto-score below the threshold (spec §8).
        if policy.autoCommitEnabled && command.confidence >= policy.autoCommitConfidenceThreshold {
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
