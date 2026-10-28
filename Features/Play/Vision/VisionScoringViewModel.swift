import Foundation

/// Orchestrates one camera scoring session (Phase A, assistive): the player taps four
/// outer-wire points to lock a homography, then dart detection proposals are confirmed
/// or dismissed. Confirmed darts are handed to the match flow via `onDartConfirmed` —
/// the match engine stays the source of truth (spec §7).
@MainActor
final class VisionScoringViewModel: ObservableObject {
    enum Status: Equatable {
        case idle
        case requestingAccess
        case accessDenied
        case cameraUnavailable
        case calibrating
        case ready
        case paused(VisionPauseReason)
    }

    /// Board circle in analysis width units plus the frame aspect ratio needed to
    /// convert back to capture-device coordinates for the preview overlay.
    struct BoardOverlay: Equatable {
        let centerX: Double
        let centerY: Double
        let radius: Double
        let aspectRatio: Double
        let isLocked: Bool
    }

    /// A calibration tap in the same width-unit space the impact detector uses.
    struct CalibrationTap: Equatable {
        let imageX: Double
        let imageY: Double
    }

    @Published private(set) var status: Status = .idle
    @Published private(set) var hints: [VisionGuidanceHint] = []
    /// Tapped outer-wire points, in `BoardCalibration.outerWireCalibrationSegments` order.
    @Published private(set) var calibrationTaps: [CalibrationTap] = []
    /// Buffer height divided by width. Zero until the first analyzed frame.
    @Published private(set) var previewAspectRatio: Double = 0
    @Published private(set) var proposal: DetectedThrow?
    /// Exact, changed, and dismissed counts for this camera session.
    @Published private(set) var tally = VisionDetectionTally()

    let camera = VisionCameraService()
    var onDartConfirmed: ((DartInput, VisionThrowMetadata) -> Void)?

    private var session = VisionScoringSession(policy: .assistive)
    private let logger: (any AppLogger)?
    private var analysisTask: Task<Void, Never>?

    private var latestQuality = CalibrationQuality(fitConfidence: 0, brightness: 0, sharpness: 0)

    /// Segment number the next tap should land on. Stays on the last segment until the lock succeeds.
    var nextCalibrationSegment: Int {
        let segments = BoardCalibration.outerWireCalibrationSegments
        let index = min(calibrationTaps.count, segments.count - 1)
        return segments[index]
    }

    var canUndoCalibrationTap: Bool {
        status == .calibrating && !calibrationTaps.isEmpty
    }

    init(logger: (any AppLogger)? = nil) {
        self.logger = logger
    }

    func start() async {
        guard analysisTask == nil else { return }
        status = .requestingAccess
        guard await VisionCameraService.requestAccess() else {
            status = .accessDenied
            return
        }
        do {
            try camera.start()
        } catch {
            status = .cameraUnavailable
            return
        }

        session = VisionScoringSession(policy: .assistive)
        status = .calibrating
        logger?.info(
            .vision,
            eventName: "vision_session_started",
            message: "Vision scoring session started",
            metadata: ["vision_session_id": session.id.uuidString]
        )
        let stream = camera.analysisStream()
        analysisTask = Task { [weak self] in
            for await analysis in stream {
                guard !Task.isCancelled else { return }
                self?.handle(analysis)
            }
        }
    }

    func stop() {
        analysisTask?.cancel()
        analysisTask = nil
        camera.stop()
        if status != .accessDenied, status != .cameraUnavailable {
            status = .idle
        }
    }

    func recalibrate() {
        session.beginRecalibration()
        calibrationTaps = []
        proposal = nil
        camera.resetAnalyzer()
        if status != .idle, status != .accessDenied, status != .cameraUnavailable {
            status = .calibrating
        }
    }

    /// Records a tap in width-unit image coordinates. Four taps, in segment order, solve the homography.
    func registerCalibrationTap(imageX: Double, imageY: Double) {
        guard status == .calibrating, session.phase == .calibrating else { return }
        guard previewAspectRatio > 0, imageX.isFinite, imageY.isFinite else { return }
        guard calibrationTaps.count < BoardCalibration.outerWireCalibrationSegments.count else { return }
        calibrationTaps.append(CalibrationTap(imageX: imageX, imageY: imageY))
        tryLockManualCalibration()
    }

    func undoCalibrationTap() {
        guard canUndoCalibrationTap else { return }
        calibrationTaps.removeLast()
    }

    func confirmProposal(corrected: DartInput? = nil) {
        guard let proposal else { return }
        let command = ConfirmDetectedThrowCommand(detectedThrowId: proposal.id, correctedDart: corrected)
        guard let confirmed = session.handle(command) else { return }
        tally.recordConfirmation(detected: proposal.dart, submitted: confirmed.dart)
        logOutcome(
            status: confirmed.dart == proposal.dart ? "exact" : "changed",
            detected: proposal.dart,
            corrected: confirmed.dart,
            confidence: proposal.visionConfidence
        )
        self.proposal = nil
        onDartConfirmed?(confirmed.dart, confirmed.metadata)
    }

    func rejectProposal() {
        guard let proposal else { return }
        session.handle(RejectDetectedThrowCommand(detectedThrowId: proposal.id))
        tally.recordDismissal()
        logOutcome(
            status: "dismissed",
            detected: proposal.dart,
            corrected: nil,
            confidence: proposal.visionConfidence
        )
        self.proposal = nil
    }

    private func logOutcome(
        status: String,
        detected: DartInput,
        corrected: DartInput?,
        confidence: Double
    ) {
        var metadata = [
            "status": status,
            "detectedScore": detected.compactDisplayLabel,
            "visionConfidence": String(format: "%.3f", confidence),
            "visionExact": String(tally.exact),
            "visionChanged": String(tally.changed),
            "visionDismissed": String(tally.dismissed),
        ]
        if let corrected, corrected != detected {
            metadata["correctedScore"] = corrected.compactDisplayLabel
        }
        logger?.info(
            .vision,
            eventName: "vision_detection_outcome",
            message: "Vision detection \(status)",
            metadata: metadata
        )
    }

    // MARK: - Frame handling

    private func handle(_ analysis: VisionFrameAnalysis) {
        previewAspectRatio = analysis.aspectRatio
        latestQuality = CalibrationQuality(
            fitConfidence: analysis.board?.fitConfidence ?? 0,
            brightness: analysis.brightness,
            sharpness: analysis.sharpness
        )
        updateHints(analysis: analysis)

        switch session.phase {
        case .calibrating:
            tryLockManualCalibration()
        case .ready:
            handleDetection(analysis: analysis)
        case .paused:
            break
        }
    }

    private func tryLockManualCalibration() {
        let segments = BoardCalibration.outerWireCalibrationSegments
        guard session.phase == .calibrating, calibrationTaps.count == segments.count else { return }
        let quality = CalibrationQuality(
            fitConfidence: 1,
            brightness: latestQuality.brightness,
            sharpness: latestQuality.sharpness
        )
        guard quality.isAcceptable else { return }
        let imagePoints = calibrationTaps.map { SIMD2($0.imageX, $0.imageY) }
        guard let calibration = BoardCalibration(outerWireImagePoints: imagePoints, quality: quality),
              session.applyCalibration(calibration) else {
            calibrationTaps.removeLast()
            return
        }
        status = .ready
        logger?.info(
            .vision,
            eventName: "vision_calibration_locked",
            message: "Board calibration locked from outer-wire taps",
            metadata: [
                "vision_session_id": session.id.uuidString,
                "calibration": "manual_homography",
            ]
        )
    }

    private func handleDetection(analysis: VisionFrameAnalysis) {
        if let board = analysis.board,
           session.observeBoard(centerX: board.centerX, centerY: board.centerY, radius: board.radius) {
            // Drift beyond tolerance pauses scoring; the user recalibrates or plays manually (spec §8).
            proposal = nil
            status = .paused(.calibrationDrift)
            logger?.warning(
                .vision,
                eventName: "vision_calibration_drift",
                message: "Calibration drift detected; session paused",
                metadata: ["vision_session_id": session.id.uuidString]
            )
            return
        }

        guard let impact = analysis.impact else { return }
        let command = DetectThrowCommand(
            visionSessionId: session.id,
            imageX: impact.imageX,
            imageY: impact.imageY,
            confidence: impact.confidence,
            frameTimestamp: analysis.timestamp
        )
        if case let .proposed(detection) = session.handle(command) {
            proposal = detection
            logger?.info(
                .vision,
                eventName: "vision_throw_detected",
                message: "Dart detection proposed",
                metadata: detection.metadata(inputMethod: .visionAuto).loggingMetadata
            )
        }
    }

    private func updateHints(analysis: VisionFrameAnalysis) {
        var updated: [VisionGuidanceHint] = []
        if analysis.brightness < CalibrationQuality.minimumBrightness {
            updated.append(.tooDark)
        }
        if analysis.sharpness < CalibrationQuality.minimumSharpness {
            updated.append(.tooBlurry)
        }
        if session.phase == .calibrating, calibrationTaps.count == BoardCalibration.outerWireCalibrationSegments.count {
            updated.append(.holdSteady)
        }
        if updated != hints {
            hints = updated
        }
    }
}
