import Foundation

/// How a throw entered the scoring pipeline. Kept transport-agnostic per
/// `AutoScoringVisionSpec.md` §11 so manual, watch, and vision inputs share one model.
public enum ScoringInputMethod: String, Codable, Sendable {
    case manual
    case watch
    case visionAuto
    case visionConfirmed
}

/// A dart detection produced by the vision pipeline, awaiting confirmation or auto-commit.
public struct DetectedThrow: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let visionSessionId: UUID
    public let dart: DartInput
    public let visionConfidence: Double
    public let frameTimestamp: Date

    public init(
        id: UUID = UUID(),
        visionSessionId: UUID,
        dart: DartInput,
        visionConfidence: Double,
        frameTimestamp: Date
    ) {
        self.id = id
        self.visionSessionId = visionSessionId
        self.dart = dart
        self.visionConfidence = visionConfidence
        self.frameTimestamp = frameTimestamp
    }

    /// Metadata attached to scoring events fed by this detection (spec §7).
    public func metadata(inputMethod: ScoringInputMethod) -> VisionThrowMetadata {
        VisionThrowMetadata(
            inputMethod: inputMethod,
            visionConfidence: visionConfidence,
            visionSessionId: visionSessionId,
            frameTimestamp: frameTimestamp
        )
    }
}

/// Event metadata extension for vision-fed throws (spec §7).
public struct VisionThrowMetadata: Codable, Equatable, Sendable {
    public let inputMethod: ScoringInputMethod
    public let visionConfidence: Double?
    public let visionSessionId: UUID?
    public let frameTimestamp: Date?

    public init(
        inputMethod: ScoringInputMethod,
        visionConfidence: Double? = nil,
        visionSessionId: UUID? = nil,
        frameTimestamp: Date? = nil
    ) {
        self.inputMethod = inputMethod
        self.visionConfidence = visionConfidence
        self.visionSessionId = visionSessionId
        self.frameTimestamp = frameTimestamp
    }

    public var loggingMetadata: [String: String] {
        var fields = ["input_method": inputMethod.rawValue]
        if let visionConfidence {
            fields["vision_confidence"] = String(format: "%.3f", visionConfidence)
        }
        if let visionSessionId {
            fields["vision_session_id"] = visionSessionId.uuidString
        }
        if let frameTimestamp {
            fields["frame_timestamp"] = String(frameTimestamp.timeIntervalSince1970)
        }
        return fields
    }
}

// MARK: - Commands (spec §7)

/// A raw detection from the camera pipeline: an impact point in normalized image
/// coordinates plus the detector's confidence. The session maps it through calibration.
public struct DetectThrowCommand: Equatable, Sendable {
    public let visionSessionId: UUID
    public let imageX: Double
    public let imageY: Double
    public let confidence: Double
    public let frameTimestamp: Date

    public init(visionSessionId: UUID, imageX: Double, imageY: Double, confidence: Double, frameTimestamp: Date) {
        self.visionSessionId = visionSessionId
        self.imageX = imageX
        self.imageY = imageY
        self.confidence = confidence
        self.frameTimestamp = frameTimestamp
    }
}

public struct ConfirmDetectedThrowCommand: Equatable, Sendable {
    public let detectedThrowId: UUID
    /// Set when the user edited the proposed dart before accepting it.
    public let correctedDart: DartInput?

    public init(detectedThrowId: UUID, correctedDart: DartInput? = nil) {
        self.detectedThrowId = detectedThrowId
        self.correctedDart = correctedDart
    }
}

public struct RejectDetectedThrowCommand: Equatable, Sendable {
    public let detectedThrowId: UUID

    public init(detectedThrowId: UUID) {
        self.detectedThrowId = detectedThrowId
    }
}

// MARK: - Guidance

/// User-facing camera guidance hints surfaced during calibration and play (spec §5).
public enum VisionGuidanceHint: String, CaseIterable, Sendable {
    case centerBoard
    case moveCloser
    case moveFarther
    case tooDark
    case tooBlurry
    case holdSteady

    public var localizationKey: String {
        "vision.hint.\(rawValue)"
    }
}
