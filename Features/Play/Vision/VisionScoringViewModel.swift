import Foundation

/// Orchestrates one camera scoring session (Phase A, assistive): guided calibration,
/// then dart detection proposals the user confirms or dismisses. Confirmed darts are
/// handed to the match flow via `onDartConfirmed` — the match engine stays the
/// source of truth (spec §7).
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

    @Published private(set) var status: Status = .idle
    @Published private(set) var hints: [VisionGuidanceHint] = []
    /// Stable-observation progress toward calibration lock, `0...1`.
    @Published private(set) var calibrationProgress: Double = 0
    @Published private(set) var fitQuality: Double = 0
    @Published private(set) var boardOverlay: BoardOverlay?
    @Published private(set) var proposal: DetectedThrow?

    let camera = VisionCameraService()
    var onDartConfirmed: ((DartInput, VisionThrowMetadata) -> Void)?

    private var session = VisionScoringSession(policy: .assistive)
    private let logger: (any AppLogger)?
    private var analysisTask: Task<Void, Never>?

    /// Consecutive acceptable, stable board observations required to lock calibration.
    private static let stableObservationsRequired = 6
    private static let stabilityCenterTolerance = 0.02
    private static let stabilityRadiusTolerance = 0.03
    // Width-unit bounds: a 16:9 frame is ~0.56 width units tall, so the board can
    // fill most of the height at the top bound.
    private static let minimumBoardRadius = 0.12
    private static let maximumBoardRadius = 0.40

    private var stableObservations: [VisionFrameAnalysis.BoardObservation] = []
    private var latestQuality = CalibrationQuality(fitConfidence: 0, brightness: 0, sharpness: 0)

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
        stableObservations = []
        calibrationProgress = 0
        proposal = nil
        boardOverlay = nil
        camera.resetAnalyzer()
        if status != .idle, status != .accessDenied, status != .cameraUnavailable {
            status = .calibrating
        }
    }

    func confirmProposal(corrected: DartInput? = nil) {
        guard let proposal else { return }
        let command = ConfirmDetectedThrowCommand(detectedThrowId: proposal.id, correctedDart: corrected)
        guard let confirmed = session.handle(command) else { return }
        self.proposal = nil
        logger?.info(
            .vision,
            eventName: "vision_throw_confirmed",
            message: "Vision detection confirmed",
            metadata: confirmed.metadata.loggingMetadata
        )
        onDartConfirmed?(confirmed.dart, confirmed.metadata)
    }

    func rejectProposal() {
        guard let proposal else { return }
        session.handle(RejectDetectedThrowCommand(detectedThrowId: proposal.id))
        self.proposal = nil
        logger?.info(
            .vision,
            eventName: "vision_throw_rejected",
            message: "Vision detection rejected",
            metadata: proposal.metadata(inputMethod: .visionConfirmed).loggingMetadata
        )
    }

    // MARK: - Frame handling

    private func handle(_ analysis: VisionFrameAnalysis) {
        latestQuality = CalibrationQuality(
            fitConfidence: analysis.board?.fitConfidence ?? 0,
            brightness: analysis.brightness,
            sharpness: analysis.sharpness
        )
        fitQuality = latestQuality.fitConfidence
        updateHints(analysis: analysis)

        switch session.phase {
        case .calibrating:
            handleCalibration(analysis: analysis)
        case .ready:
            handleDetection(analysis: analysis)
        case .paused:
            break
        }
    }

    private func handleCalibration(analysis: VisionFrameAnalysis) {
        guard let board = analysis.board,
              latestQuality.isAcceptable,
              (Self.minimumBoardRadius ... Self.maximumBoardRadius).contains(board.radius) else {
            stableObservations = []
            calibrationProgress = 0
            boardOverlay = analysis.board.map {
                BoardOverlay(
                    centerX: $0.centerX,
                    centerY: $0.centerY,
                    radius: $0.radius,
                    aspectRatio: analysis.aspectRatio,
                    isLocked: false
                )
            }
            return
        }

        if let last = stableObservations.last, !isStable(board, comparedTo: last) {
            stableObservations = []
        }
        stableObservations.append(board)
        calibrationProgress = min(1, Double(stableObservations.count) / Double(Self.stableObservationsRequired))
        boardOverlay = BoardOverlay(
            centerX: board.centerX,
            centerY: board.centerY,
            radius: board.radius,
            aspectRatio: analysis.aspectRatio,
            isLocked: false
        )

        guard stableObservations.count >= Self.stableObservationsRequired else { return }
        lockCalibration(aspectRatio: analysis.aspectRatio)
    }

    private func lockCalibration(aspectRatio: Double) {
        let count = Double(stableObservations.count)
        let centerX = stableObservations.map(\.centerX).reduce(0, +) / count
        let centerY = stableObservations.map(\.centerY).reduce(0, +) / count
        let radius = stableObservations.map(\.radius).reduce(0, +) / count
        guard let calibration = BoardCalibration(
            centerX: centerX,
            centerY: centerY,
            radius: radius,
            quality: latestQuality
        ), session.applyCalibration(calibration) else {
            stableObservations = []
            calibrationProgress = 0
            return
        }
        stableObservations = []
        boardOverlay = BoardOverlay(
            centerX: centerX,
            centerY: centerY,
            radius: radius,
            aspectRatio: aspectRatio,
            isLocked: true
        )
        status = .ready
        logger?.info(
            .vision,
            eventName: "vision_calibration_locked",
            message: "Board calibration locked",
            metadata: [
                "vision_session_id": session.id.uuidString,
                "fit_confidence": String(format: "%.3f", calibration.quality.fitConfidence),
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
        if session.phase == .calibrating {
            if let board = analysis.board {
                if board.radius < Self.minimumBoardRadius {
                    updated.append(.moveCloser)
                } else if board.radius > Self.maximumBoardRadius {
                    updated.append(.moveFarther)
                } else if calibrationProgress > 0, calibrationProgress < 1 {
                    updated.append(.holdSteady)
                }
            } else {
                updated.append(.centerBoard)
            }
        }
        if updated != hints {
            hints = updated
        }
    }

    private func isStable(
        _ observation: VisionFrameAnalysis.BoardObservation,
        comparedTo previous: VisionFrameAnalysis.BoardObservation
    ) -> Bool {
        abs(observation.centerX - previous.centerX) <= Self.stabilityCenterTolerance
            && abs(observation.centerY - previous.centerY) <= Self.stabilityCenterTolerance
            && abs(observation.radius - previous.radius) <= Self.stabilityRadiusTolerance
    }
}
