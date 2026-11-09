import Foundation

/// Orchestrates one camera scoring session: finds and locks onto the board, then
/// scores darts automatically as they land and reports when they are pulled.
/// Scored darts are handed to the match flow via `onDartDetected` — the match
/// engine stays the source of truth (spec §7).
@MainActor
final class VisionScoringViewModel: ObservableObject {
    enum Status: Equatable {
        case idle
        case requestingAccess
        case accessDenied
        case cameraUnavailable
        /// Searching for the board.
        case calibrating
        /// Player is dragging the calibration landmarks by hand.
        case adjusting
        /// Board locked; waiting for the scene to hold still to capture the empty board.
        case arming
        case ready
        case paused(VisionPauseReason)
    }

    /// Board wires to draw over the preview.
    struct BoardOverlay: Equatable {
        let controlPoints: BoardControlPoints
        let aspectRatio: Double
        let isLocked: Bool
    }

    @Published private(set) var status: Status = .idle
    @Published private(set) var hints: [VisionGuidanceHint] = []
    /// Stable-observation progress toward calibration lock, `0...1`.
    @Published private(set) var calibrationProgress: Double = 0
    @Published private(set) var fitQuality: Double = 0
    @Published private(set) var boardOverlay: BoardOverlay?
    /// Detections scored in the current visit, oldest first.
    @Published private(set) var visitDetections: [DetectedThrow] = []
    /// Tip of the latest detection (image width units), for the preview marker.
    @Published private(set) var lastTip: ImagePoint?
    /// A dart was seen but the match could not take it (not this player's turn, visit full).
    @Published private(set) var lastDetectionWasIgnored = false
    /// The darts were pulled and nothing has been thrown since. If the visit still
    /// holds darts at that point, some throws were probably not seen.
    @Published private(set) var boardClearedSinceLastDart = false

    let camera = VisionCameraService()
    /// Offers a detected dart to the match. Returns `false` when it was not accepted.
    var onDartDetected: ((DartInput, VisionThrowMetadata) -> Bool)?
    /// All darts were pulled from the board.
    var onBoardCleared: (() -> Void)?

    private var session = VisionScoringSession(policy: .automatic)
    private let logger: (any AppLogger)?
    private var analysisTask: Task<Void, Never>?

    /// Consecutive matching board detections required to lock calibration.
    private static let stableDetectionsRequired = 4
    /// Landmark travel (width units) tolerated between detections of a steady camera.
    private static let stabilityTolerance = 0.012
    // The board should be big enough to resolve trebles and fit in frame.
    private static let minimumBoardRadius = 0.10
    private static let maximumBoardRadius = 0.60
    /// Below this camera tilt, flights start hiding the tips.
    private static let minimumHelpfulTiltDegrees = 12.0
    /// Agreement falling below this share of its locked value means the camera moved.
    private static let driftAgreementRatio = 0.6
    private static let driftChecksRequired = 3

    private var stableDetections: [BoardDetection] = []
    private var aspectRatio = 16.0 / 9.0
    private var lockedAgreement: Double?
    private var lowAgreementStreak = 0
    private var adjustingPoints: BoardControlPoints?

    init(logger: (any AppLogger)? = nil) {
        self.logger = logger
    }

    // MARK: - Lifecycle

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

        session = VisionScoringSession(policy: .automatic)
        resetCalibrationState()
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

    func setVideoRotationAngle(_ angle: CGFloat) {
        camera.setVideoRotationAngle(angle)
    }

    private var isCameraRunning: Bool {
        switch status {
        case .idle, .requestingAccess, .accessDenied, .cameraUnavailable: return false
        default: return true
        }
    }

    // MARK: - Calibration actions

    /// Throws away the calibration and searches for the board again.
    func recalibrate() {
        guard isCameraRunning else { return }
        session.beginRecalibration()
        resetCalibrationState()
        boardOverlay = nil
        camera.startSearching()
        status = .calibrating
    }

    /// Starts manual fine-tuning from the current calibration (or the latest
    /// detection, or a centred guess when the board was never found).
    func beginAdjusting() {
        guard isCameraRunning, status != .adjusting else { return }
        let start = session.calibration?.controlPoints
            ?? stableDetections.last?.controlPoints
            ?? boardOverlay?.controlPoints
            ?? Self.defaultControlPoints(aspectRatio: aspectRatio)
        session.beginRecalibration()
        resetCalibrationState()
        camera.startSearching()
        adjustingPoints = start
        boardOverlay = BoardOverlay(controlPoints: start, aspectRatio: aspectRatio, isLocked: false)
        status = .adjusting
    }

    /// Moves one landmark (0 = top/20, 1 = right/6, 2 = bottom/3, 3 = left/11).
    func moveLandmark(_ index: Int, to point: ImagePoint) {
        guard status == .adjusting, var points = adjustingPoints?.ordered, points.indices.contains(index) else { return }
        points[index] = point
        // Ignore positions that would fold the board over itself.
        guard let updated = BoardControlPoints(ordered: points), updated.boardToImage != nil else { return }
        adjustingPoints = updated
        boardOverlay = BoardOverlay(controlPoints: updated, aspectRatio: aspectRatio, isLocked: false)
    }

    /// Spins the numbering by one wedge when the wrong segment was taken for the 20.
    func rotateNumbering(clockwise: Bool) {
        guard status == .adjusting,
              let rotated = adjustingPoints?.rotated(byWedges: clockwise ? 1 : -1) else { return }
        adjustingPoints = rotated
        boardOverlay = BoardOverlay(controlPoints: rotated, aspectRatio: aspectRatio, isLocked: false)
    }

    func finishAdjusting() {
        guard status == .adjusting, let points = adjustingPoints else { return }
        adjustingPoints = nil
        // A hand-placed calibration is trusted as-is.
        if !lock(controlPoints: points, agreement: 1, source: "manual") {
            status = .calibrating
        }
    }

    /// Keeps the current calibration after a drift warning.
    func resumeAfterDrift() {
        guard status == .paused(.calibrationDrift) else { return }
        session.resumeFromDriftPause()
        lockedAgreement = nil
        lowAgreementStreak = 0
        status = .ready
    }

    // MARK: - Visit bookkeeping

    /// The match started a new visit (or the visit was edited by hand).
    func syncVisit(dartCount: Int) {
        if dartCount == 0 {
            visitDetections = []
            lastDetectionWasIgnored = false
            boardClearedSinceLastDart = false
        } else if visitDetections.count > dartCount {
            visitDetections = Array(visitDetections.prefix(dartCount))
        }
    }

    /// Whether the dart at this position in the visit was scored with low confidence.
    func needsReview(visitIndex: Int, dart: DartInput) -> Bool {
        guard visitDetections.indices.contains(visitIndex) else { return false }
        let detection = visitDetections[visitIndex]
        return detection.needsReview && detection.dart == dart
    }

    // MARK: - Frame handling

    private func handle(_ analysis: VisionFrameAnalysis) {
        if abs(analysis.aspectRatio - aspectRatio) > 0.01 {
            // The device rotated: image coordinates changed under any calibration.
            aspectRatio = analysis.aspectRatio
            if session.calibration != nil || status == .adjusting {
                adjustingPoints = nil
                recalibrate()
            }
        }

        switch status {
        case .calibrating:
            handleSearch(analysis)
        case .arming:
            if analysis.isArmed {
                status = .ready
                handleTracking(analysis)
            }
        case .ready:
            handleTracking(analysis)
        default:
            break
        }
        updateHints(analysis: analysis)
    }

    private func handleSearch(_ analysis: VisionFrameAnalysis) {
        guard analysis.didSearchForBoard else { return }
        guard let board = analysis.board,
              board.agreement >= CalibrationQuality.minimumFitConfidence,
              let radius = Self.radius(of: board.controlPoints),
              (Self.minimumBoardRadius ... Self.maximumBoardRadius).contains(radius) else {
            stableDetections = []
            calibrationProgress = 0
            fitQuality = analysis.board?.agreement ?? 0
            boardOverlay = analysis.board.map {
                BoardOverlay(controlPoints: $0.controlPoints, aspectRatio: aspectRatio, isLocked: false)
            }
            return
        }

        if let last = stableDetections.last,
           board.controlPoints.maxDisplacement(from: last.controlPoints) > Self.stabilityTolerance {
            stableDetections = []
        }
        stableDetections.append(board)
        fitQuality = board.agreement
        calibrationProgress = min(1, Double(stableDetections.count) / Double(Self.stableDetectionsRequired))
        boardOverlay = BoardOverlay(controlPoints: board.controlPoints, aspectRatio: aspectRatio, isLocked: false)

        guard stableDetections.count >= Self.stableDetectionsRequired,
              let averaged = BoardControlPoints.average(stableDetections.map(\.controlPoints)) else { return }
        let agreement = stableDetections.map(\.agreement).reduce(0, +) / Double(stableDetections.count)
        if !lock(controlPoints: averaged, agreement: agreement, source: "auto") {
            stableDetections = []
            calibrationProgress = 0
        }
    }

    @discardableResult
    private func lock(controlPoints: BoardControlPoints, agreement: Double, source: String) -> Bool {
        // Brightness/blur only drive hints: the colour agreement already proves the
        // board is readable, and a dark surround makes mean brightness misleading.
        let quality = CalibrationQuality(
            fitConfidence: agreement,
            brightness: CalibrationQuality.minimumBrightness,
            sharpness: CalibrationQuality.minimumSharpness
        )
        guard let calibration = BoardCalibration(
            controlPoints: controlPoints,
            imageAspectRatio: aspectRatio,
            quality: quality
        ), session.applyCalibration(calibration) else { return false }

        stableDetections = []
        calibrationProgress = 1
        fitQuality = agreement
        lockedAgreement = nil
        lowAgreementStreak = 0
        visitDetections = []
        lastTip = nil
        boardOverlay = BoardOverlay(controlPoints: controlPoints, aspectRatio: aspectRatio, isLocked: true)
        camera.startTracking(calibration)
        status = .arming
        logger?.info(
            .vision,
            eventName: "vision_calibration_locked",
            message: "Board calibration locked",
            metadata: [
                "vision_session_id": session.id.uuidString,
                "fit_confidence": String(format: "%.3f", agreement),
                "source": source,
                "tilt_degrees": String(format: "%.1f", calibration.pose?.tiltDegrees ?? -1),
            ]
        )
        return true
    }

    private func handleTracking(_ analysis: VisionFrameAnalysis) {
        if let agreement = analysis.calibrationAgreement, checkForDrift(agreement: agreement) {
            return
        }
        switch analysis.event {
        case let .dart(impact):
            handleImpact(impact, timestamp: analysis.timestamp)
        case .boardCleared:
            lastTip = nil
            boardClearedSinceLastDart = true
            logger?.info(
                .vision,
                eventName: "vision_board_cleared",
                message: "Darts removed from the board",
                metadata: ["vision_session_id": session.id.uuidString]
            )
            onBoardCleared?()
        case nil:
            break
        }
    }

    private func handleImpact(_ impact: ImpactDetector.Impact, timestamp: Date) {
        let command = DetectThrowCommand(
            visionSessionId: session.id,
            imageX: impact.tip.x,
            imageY: impact.tip.y,
            confidence: impact.confidence,
            frameTimestamp: timestamp
        )
        guard case let .autoCommitted(detection) = session.handle(command) else { return }
        lastTip = impact.tip
        boardClearedSinceLastDart = false
        let metadata = detection.metadata(inputMethod: .visionAuto)
        let accepted = onDartDetected?(detection.dart, metadata) ?? false
        lastDetectionWasIgnored = !accepted
        if accepted {
            visitDetections.append(detection)
        }
        var fields = metadata.loggingMetadata
        fields["needs_review"] = detection.needsReview ? "true" : "false"
        fields["accepted"] = accepted ? "true" : "false"
        logger?.info(
            .vision,
            eventName: "vision_throw_detected",
            message: "Dart detected and scored",
            metadata: fields
        )
    }

    /// Returns `true` when drift paused the session.
    private func checkForDrift(agreement: Double) -> Bool {
        guard let baseline = lockedAgreement else {
            // First measurement after locking is the reference for this calibration.
            lockedAgreement = agreement
            return false
        }
        if agreement >= baseline * Self.driftAgreementRatio {
            lowAgreementStreak = 0
            // Follow slow improvements (e.g. lights coming on) but never chase a drop.
            lockedAgreement = max(baseline, agreement)
            return false
        }
        lowAgreementStreak += 1
        guard lowAgreementStreak >= Self.driftChecksRequired else { return false }
        lowAgreementStreak = 0
        session.pauseForDrift()
        status = .paused(.calibrationDrift)
        logger?.warning(
            .vision,
            eventName: "vision_calibration_drift",
            message: "Calibration drift detected; session paused",
            metadata: ["vision_session_id": session.id.uuidString]
        )
        return true
    }

    private func updateHints(analysis: VisionFrameAnalysis) {
        var updated: [VisionGuidanceHint] = []
        switch status {
        case .calibrating:
            if let board = analysis.board, let radius = Self.radius(of: board.controlPoints) {
                if radius < Self.minimumBoardRadius {
                    updated.append(.moveCloser)
                } else if radius > Self.maximumBoardRadius {
                    updated.append(.moveFarther)
                } else if calibrationProgress > 0, calibrationProgress < 1 {
                    updated.append(.holdSteady)
                }
            } else if analysis.didSearchForBoard {
                updated.append(.centerBoard)
            } else {
                // Keep the previous search hint between detection frames.
                updated = hints.filter { $0 != .tooDark && $0 != .tooBlurry }
            }
            if analysis.brightness < CalibrationQuality.minimumBrightness {
                updated.append(.tooDark)
            } else if analysis.sharpness < CalibrationQuality.minimumSharpness {
                updated.append(.tooBlurry)
            }
        case .arming:
            updated.append(.clearBoard)
        case .ready:
            if let tilt = session.calibration?.pose?.tiltDegrees, tilt < Self.minimumHelpfulTiltDegrees {
                updated.append(.angleCamera)
            }
        default:
            break
        }
        if updated != hints {
            hints = updated
        }
    }

    private func resetCalibrationState() {
        stableDetections = []
        calibrationProgress = 0
        fitQuality = 0
        lockedAgreement = nil
        lowAgreementStreak = 0
        adjustingPoints = nil
        visitDetections = []
        lastTip = nil
        lastDetectionWasIgnored = false
        boardClearedSinceLastDart = false
    }

    private static func radius(of controlPoints: BoardControlPoints) -> Double? {
        guard let center = controlPoints.boardToImage?.applyPoint(x: 0, y: 0) else { return nil }
        return controlPoints.ordered.map { $0.distance(to: center) }.reduce(0, +) / 4
    }

    private static func defaultControlPoints(aspectRatio: Double) -> BoardControlPoints {
        let centerY = aspectRatio / 2
        let radius = 0.3 * min(1, aspectRatio)
        return BoardControlPoints(
            top: ImagePoint(x: 0.5, y: centerY - radius),
            right: ImagePoint(x: 0.5 + radius, y: centerY),
            bottom: ImagePoint(x: 0.5, y: centerY + radius),
            left: ImagePoint(x: 0.5 - radius, y: centerY)
        )
    }
}
