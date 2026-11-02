import Foundation

/// Orchestrates one camera scoring session (Phase A, assistive): the player taps four
/// outer-wire points to lock a homography, then dart detections fill a visit tray for
/// review and submit. Confirmed visits are handed to the match flow via
/// `onVisitSubmitted` — the match engine stays the source of truth (spec §7).
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
    /// Tapped outer-wire points, in `BoardCalibration.outerWireCalibrationCrossings` order.
    @Published private(set) var calibrationTaps: [CalibrationTap] = []
    /// Buffer height divided by width. Zero until the first analyzed frame.
    @Published private(set) var previewAspectRatio: Double = 0
    @Published private(set) var visit: [VisitDart] = []
    @Published private(set) var visitStatus: VisionVisitStatus = .collecting
    @Published private(set) var dartsAllowed = 0
    /// Exact, changed, and dismissed counts for this camera session.
    @Published private(set) var tally = VisionDetectionTally()

    let camera = VisionCameraService()
    var visitEnds: ([DartInput]) -> Bool = { $0.count >= 3 }
    var onDartDetected: ((DartInput) -> Void)?
    var onVisitSubmitted: (([DartInput]) -> Void)?

    private var session = VisionScoringSession(policy: .assistive)
    private let logger: (any AppLogger)?
    private var analysisTask: Task<Void, Never>?
    private var turnKey: String?
    private var takeout = TakeoutDetector()
    /// Takeout only counts after a dart lands in this stint of throwing, so walking
    /// back to the oche after "Keep throwing" does not close the visit again.
    private var takeoutArmed = false

    private var latestQuality = CalibrationQuality(fitConfidence: 0, brightness: 0, sharpness: 0)

    var visitCapacity: Int { session.visitCapacity }

    /// Wire crossing the next tap should land on. Stays on the last one until the lock succeeds.
    var nextCalibrationCrossing: (left: Int, right: Int) {
        let crossings = BoardCalibration.outerWireCalibrationCrossings
        return crossings[min(calibrationTaps.count, crossings.count - 1)]
    }

    var canUndoCalibrationTap: Bool {
        status == .calibrating && !calibrationTaps.isEmpty
    }

    var visitHasEnded: Bool { visitEnds(visit.map(\.dart)) }

    var missingDartCount: Int {
        visitHasEnded ? 0 : max(0, session.visitCapacity - visit.count)
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
        camera.setImagingLocked(false)

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
        camera.resetAnalyzer()
        camera.setImagingLocked(false)
        if status != .idle, status != .accessDenied, status != .cameraUnavailable {
            status = .calibrating
        }
        syncVisit()
    }

    /// `turnKey` identifies the match turn; a new key drops any tray left from the last one.
    func updateTurn(dartsAllowed: Int, turnKey: String?) {
        self.dartsAllowed = dartsAllowed
        let turnChanged = turnKey != self.turnKey
        self.turnKey = turnKey
        if turnChanged || dartsAllowed == 0 || session.visit.isEmpty {
            if !session.visit.isEmpty {
                logger?.info(
                    .vision,
                    eventName: "vision_visit_discarded",
                    message: "Camera visit cleared because the turn changed",
                    metadata: ["dart_count": String(session.visit.count)]
                )
            }
            startNewVisit(capacity: dartsAllowed)
        }
        syncVisit()
    }

    private func startNewVisit(capacity: Int) {
        session.beginVisit(capacity: capacity)
        takeout.reset()
        takeoutArmed = false
    }

    /// Records a tap in width-unit image coordinates. Four taps, in segment order, solve the homography.
    func registerCalibrationTap(imageX: Double, imageY: Double) {
        guard status == .calibrating, session.phase == .calibrating else { return }
        guard previewAspectRatio > 0, imageX.isFinite, imageY.isFinite else { return }
        guard calibrationTaps.count < BoardCalibration.outerWireCalibrationCrossings.count else { return }
        calibrationTaps.append(CalibrationTap(imageX: imageX, imageY: imageY))
        tryLockManualCalibration()
    }

    func undoCalibrationTap() {
        guard canUndoCalibrationTap else { return }
        calibrationTaps.removeLast()
    }

    func doneThrowing() {
        guard dartsAllowed > 0 else { return }
        session.closeVisit(evenIfEmpty: true)
        syncVisit()
    }

    func keepThrowing() {
        guard !visitHasEnded else { return }
        session.resumeCollecting()
        takeout.reset()
        takeoutArmed = false
        syncVisit()
    }

    func editDart(id: UUID, to dart: DartInput) {
        session.editDart(id: id, to: dart)
        syncVisit()
    }

    func removeDart(id: UUID) {
        if let removed = session.removeDart(id: id), removed.detection != nil {
            tally.recordDismissal()
        }
        syncVisit()
    }

    func addDart(_ dart: DartInput) {
        guard session.addManualDart(dart) else { return }
        tally.recordAddedByHand()
        if visitEnds(session.visit.map(\.dart)) {
            session.closeVisit()
        }
        syncVisit()
    }

    func submitVisit() {
        guard dartsAllowed > 0 else { return }
        let missing = missingDartCount
        let submitted = session.submitVisit()
        takeout.reset()
        takeoutArmed = false
        for entry in submitted {
            guard let detection = entry.detection else { continue }
            tally.recordConfirmation(detected: detection.dart, submitted: entry.dart)
        }
        var darts = submitted.map(\.dart)
        let miss = DartInput(multiplier: .single, segment: .miss, isMiss: true)
        if missing > 0 {
            darts.append(contentsOf: Array(repeating: miss, count: missing))
        }
        logger?.info(
            .vision,
            eventName: "vision_visit_submitted",
            message: "Vision visit submitted",
            metadata: [
                "dart_count": String(darts.count),
                "missing_as_miss": String(missing),
                "vision_session_id": session.id.uuidString,
            ]
        )
        onVisitSubmitted?(darts)
        syncVisit()
    }

    private func syncVisit() {
        visit = session.visit
        visitStatus = session.visitStatus
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
        let crossings = BoardCalibration.outerWireCalibrationCrossings
        guard session.phase == .calibrating, calibrationTaps.count == crossings.count else { return }
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
        camera.setImagingLocked(true)
        // Analyzer cells are per-axis normalized; calibration math is in width units.
        let tipOffset = calibration.dartTipOffset(
            horizontalFieldOfViewDegrees: camera.horizontalFieldOfView,
            aspectRatio: previewAspectRatio
        ).map { SIMD2($0.x, $0.y / previewAspectRatio) }
        camera.setImpactRegion(impactRegion(for: calibration), tipOffset: tipOffset)
        status = .ready
        logger?.info(
            .vision,
            eventName: "vision_calibration_locked",
            message: "Board calibration locked from outer-wire taps",
            metadata: [
                "vision_session_id": session.id.uuidString,
                "calibration": "manual_homography",
                "tip_offset": tipOffset.map { String(format: "%.3f,%.3f", $0.x, $0.y) } ?? "none",
            ]
        )
    }

    /// Analyzer grid cells that sit on or near the calibrated board.
    private func impactRegion(for calibration: BoardCalibration) -> [Bool] {
        let size = DartboardFrameAnalyzer.gridSize
        return (0 ..< size * size).map { index in
            calibration.isWithinDetectionZone(
                atImageX: (Double(index % size) + 0.5) / Double(size),
                imageY: (Double(index / size) + 0.5) / Double(size) * previewAspectRatio
            )
        }
    }

    private func handleDetection(analysis: VisionFrameAnalysis) {
        if let board = analysis.board,
           session.observeBoard(centerX: board.centerX, centerY: board.centerY, radius: board.radius) {
            status = .paused(.calibrationDrift)
            syncVisit()
            logger?.warning(
                .vision,
                eventName: "vision_calibration_drift",
                message: "Calibration drift detected; session paused",
                metadata: ["vision_session_id": session.id.uuidString]
            )
            return
        }

        let sustainedMotion = takeout.observe(sceneMotion: analysis.sceneMotion)
        if sustainedMotion, takeoutArmed, !session.visit.isEmpty, session.visitStatus == .collecting {
            session.closeVisit()
            takeout.reset()
            takeoutArmed = false
            syncVisit()
            logger?.info(
                .vision,
                eventName: "vision_visit_takeout",
                message: "Sustained motion detected; visit closed for review",
                metadata: ["vision_session_id": session.id.uuidString]
            )
        }

        guard let impact = analysis.impact else { return }
        let command = DetectThrowCommand(
            visionSessionId: session.id,
            imageX: impact.imageX,
            imageY: impact.imageY,
            confidence: impact.confidence,
            frameTimestamp: analysis.timestamp
        )
        switch session.handle(command) {
        case let .proposed(detection), let .autoCommitted(detection):
            onDartDetected?(detection.dart)
            takeout.reset()
            takeoutArmed = true
            if visitEnds(session.visit.map(\.dart)) {
                session.closeVisit()
            }
            syncVisit()
            logger?.info(
                .vision,
                eventName: "vision_throw_detected",
                message: "Dart detection proposed",
                metadata: detection.metadata(inputMethod: .visionAuto).loggingMetadata
            )
        case let .ignored(reason):
            if reason != .visitClosed {
                logger?.debug(
                    .vision,
                    eventName: "vision_throw_ignored",
                    message: "Detection ignored",
                    metadata: ["reason": String(describing: reason)]
                )
            }
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
        if session.phase == .calibrating, calibrationTaps.count == BoardCalibration.outerWireCalibrationCrossings.count {
            updated.append(.holdSteady)
        }
        if updated != hints {
            hints = updated
        }
    }
}
