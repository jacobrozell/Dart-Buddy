import Foundation
import Testing
@testable import DartBuddy

private func calibratedSession(policy: VisionScoringPolicy = .assistive) -> VisionScoringSession {
    var session = VisionScoringSession(policy: policy)
    let calibration = BoardCalibration(
        centerX: 0.5,
        centerY: 0.5,
        radius: 0.3,
        quality: CalibrationQuality(fitConfidence: 0.9, brightness: 0.5, sharpness: 0.6)
    )!
    session.applyCalibration(calibration)
    session.beginVisit(capacity: 3)
    return session
}

/// Detection straight above center inside the triple ring (triple 20).
private func tripleTwentyCommand(
    for session: VisionScoringSession,
    confidence: Double,
    at timestamp: Date = Date()
) -> DetectThrowCommand {
    DetectThrowCommand(
        visionSessionId: session.id,
        imageX: 0.5,
        imageY: 0.5 - 0.606 * 0.3,
        confidence: confidence,
        frameTimestamp: timestamp
    )
}

@Test(.tags(.unit, .vision, .regression))
func sessionStartsCalibratingAndIgnoresDetections() {
    var session = VisionScoringSession()
    #expect(session.phase == .calibrating)
    let outcome = session.handle(tripleTwentyCommand(for: session, confidence: 0.8))
    #expect(outcome == .ignored(.sessionNotReady))
}

@Test(.tags(.unit, .vision, .regression))
func unacceptableCalibrationIsRejected() {
    var session = VisionScoringSession()
    let poor = BoardCalibration(
        centerX: 0.5,
        centerY: 0.5,
        radius: 0.3,
        quality: CalibrationQuality(fitConfidence: 0.4, brightness: 0.5, sharpness: 0.6)
    )!
    let applied = session.applyCalibration(poor)
    #expect(!applied)
    #expect(session.phase == .calibrating)
}

@Test(.tags(.unit, .vision, .regression))
func changesWellOffTheBoardAreIgnored() {
    var session = calibratedSession()
    // 2.7 board radii below center: past the miss zone.
    let offBoard = DetectThrowCommand(
        visionSessionId: session.id,
        imageX: 0.5,
        imageY: 1.3,
        confidence: 0.8,
        frameTimestamp: Date()
    )
    #expect(session.handle(offBoard) == .ignored(.unmappablePoint))
    #expect(session.visit.isEmpty)
}

@Test(.tags(.unit, .vision, .regression))
func surroundDetectionAddsMissToVisit() throws {
    var session = calibratedSession()
    let calibration = try #require(session.calibration)
    let inverse = try #require(calibration.transform.inverted())
    let image = try #require(inverse.apply(toImageX: 0, imageY: 1.25))
    let command = DetectThrowCommand(
        visionSessionId: session.id,
        imageX: image.x,
        imageY: image.y,
        confidence: 0.8,
        frameTimestamp: Date()
    )
    guard case let .proposed(detection) = session.handle(command) else {
        Issue.record("Expected miss proposal")
        return
    }
    #expect(detection.dart.isMiss)
    #expect(session.visit.count == 1)
}

@Test(.tags(.unit, .vision, .regression))
func assistivePolicyProposesInsteadOfAutoCommitting() throws {
    var session = calibratedSession()
    let outcome = session.handle(tripleTwentyCommand(for: session, confidence: 0.99))
    guard case let .proposed(detection) = outcome else {
        Issue.record("Expected proposal, got \(outcome)")
        return
    }
    #expect(detection.dart == DartInput(multiplier: .triple, segment: .oneToTwenty(20)))
    #expect(detection.visionConfidence == 0.99)
    #expect(session.visit.count == 1)
    #expect(session.visit[0].dart == detection.dart)
}

@Test(.tags(.unit, .vision, .regression))
func detectionsBelowConfidenceFloorAreDropped() {
    var session = calibratedSession()
    let outcome = session.handle(tripleTwentyCommand(for: session, confidence: 0.1))
    #expect(outcome == .ignored(.belowConfidenceFloor))
    #expect(session.visit.isEmpty)
}

@Test(.tags(.unit, .vision, .regression))
func autoCommitRequiresEnabledPolicyAndThreshold() {
    let policy = VisionScoringPolicy(autoCommitEnabled: true, autoCommitConfidenceThreshold: 0.92)
    var session = calibratedSession(policy: policy)

    let belowThreshold = session.handle(tripleTwentyCommand(for: session, confidence: 0.7))
    guard case .proposed = belowThreshold else {
        Issue.record("Expected proposal below threshold, got \(belowThreshold)")
        return
    }
    _ = session.removeDart(id: session.visit[0].id)

    let aboveThreshold = session.handle(tripleTwentyCommand(for: session, confidence: 0.95))
    guard case .autoCommitted = aboveThreshold else {
        Issue.record("Expected auto-commit above threshold, got \(aboveThreshold)")
        return
    }
    #expect(session.visit.count == 1)
}

@Test(.tags(.unit, .vision, .regression))
func detectionAddsDartToVisit() {
    var session = calibratedSession()
    _ = session.handle(tripleTwentyCommand(for: session, confidence: 0.8))
    #expect(session.visit.count == 1)
    #expect(session.visitStatus == .collecting)
}

@Test(.tags(.unit, .vision, .regression))
func visitClosesWhenFull() {
    var session = calibratedSession()
    let start = Date()
    for index in 0 ..< 3 {
        let throwTime = start.addingTimeInterval(Double(index) * 2)
        _ = session.handle(tripleTwentyCommand(for: session, confidence: 0.8, at: throwTime))
    }
    #expect(session.visitStatus == .reviewing)
    let fourth = session.handle(tripleTwentyCommand(for: session, confidence: 0.8, at: start.addingTimeInterval(6)))
    #expect(fourth == .ignored(.visitClosed))
    #expect(session.visit.count == 3)
}

@Test(.tags(.unit, .vision, .regression))
func beginVisitWithZeroCapacityIgnoresDetections() {
    var session = calibratedSession()
    session.beginVisit(capacity: 0)
    #expect(session.visitStatus == .reviewing)
    let outcome = session.handle(tripleTwentyCommand(for: session, confidence: 0.8))
    #expect(outcome == .ignored(.visitClosed))
}

@Test(.tags(.unit, .vision, .regression))
func closeVisitIgnoredWhenEmpty() {
    var session = calibratedSession()
    session.closeVisit()
    #expect(session.visitStatus == .collecting)
    session.closeVisit(evenIfEmpty: true)
    #expect(session.visitStatus == .reviewing)
}

@Test(.tags(.unit, .vision, .regression))
func settlingDartIsNotCountedTwice() {
    var session = calibratedSession()
    let first = tripleTwentyCommand(for: session, confidence: 0.8)
    _ = session.handle(first)
    let settle = DetectThrowCommand(
        visionSessionId: session.id,
        imageX: first.imageX + 0.002,
        imageY: first.imageY,
        confidence: 0.8,
        frameTimestamp: first.frameTimestamp.addingTimeInterval(0.4)
    )
    #expect(session.handle(settle) == .ignored(.duplicate))

    let grouped = DetectThrowCommand(
        visionSessionId: session.id,
        imageX: first.imageX + 0.002,
        imageY: first.imageY,
        confidence: 0.8,
        frameTimestamp: first.frameTimestamp.addingTimeInterval(2)
    )
    guard case .proposed = session.handle(grouped) else {
        Issue.record("A later dart in the same spot is a new throw")
        return
    }
    #expect(session.visit.count == 2)
}

@Test(.tags(.unit, .vision, .regression))
func keepThrowingResumesWhenRoom() {
    var session = calibratedSession()
    _ = session.handle(tripleTwentyCommand(for: session, confidence: 0.8))
    session.closeVisit()
    #expect(session.visitStatus == .reviewing)
    session.resumeCollecting()
    #expect(session.visitStatus == .collecting)
}

@Test(.tags(.unit, .vision, .regression))
func editAndRemoveIgnoreUnknownIds() {
    var session = calibratedSession()
    _ = session.handle(tripleTwentyCommand(for: session, confidence: 0.8))
    let id = session.visit[0].id
    let unknownEdit = session.editDart(id: UUID(), to: DartInput(multiplier: .single, segment: .oneToTwenty(1)))
    #expect(!unknownEdit)
    let unknownRemove = session.removeDart(id: UUID())
    #expect(unknownRemove == nil)
    #expect(session.visit.count == 1)
    let corrected = DartInput(multiplier: .single, segment: .oneToTwenty(5))
    let didEdit = session.editDart(id: id, to: corrected)
    #expect(didEdit)
    #expect(session.visit[0].dart == corrected)
    let removed = session.removeDart(id: id)
    #expect(removed != nil)
    #expect(session.visit.isEmpty)
}

@Test(.tags(.unit, .vision, .regression))
func addManualDartRespectsCapacity() {
    var session = calibratedSession()
    let dart = DartInput(multiplier: .single, segment: .oneToTwenty(20))
    let first = session.addManualDart(dart)
    #expect(first)
    #expect(session.visit.count == 1)
    #expect(session.visit[0].detection == nil)
    for _ in 1 ..< 3 {
        let added = session.addManualDart(dart)
        #expect(added)
    }
    let overflow = session.addManualDart(dart)
    #expect(!overflow)
}

@Test(.tags(.unit, .vision, .regression))
func submitReturnsEditedDartsAndResets() {
    var session = calibratedSession()
    _ = session.handle(tripleTwentyCommand(for: session, confidence: 0.8))
    let id = session.visit[0].id
    let corrected = DartInput(multiplier: .single, segment: .oneToTwenty(5))
    session.editDart(id: id, to: corrected)
    let submitted = session.submitVisit()
    #expect(submitted.count == 1)
    #expect(submitted[0].dart == corrected)
    #expect(session.visit.isEmpty)
    #expect(session.visitStatus == .collecting)
}

@Test(.tags(.unit, .vision, .regression))
func driftClosesVisitButKeepsDarts() {
    var session = calibratedSession()
    _ = session.handle(tripleTwentyCommand(for: session, confidence: 0.8))
    let driftPaused = session.observeBoard(centerX: 0.6, centerY: 0.5, radius: 0.3)
    #expect(driftPaused)
    #expect(session.phase == .paused(.calibrationDrift))
    #expect(session.visit.count == 1)
    #expect(session.visitStatus == .reviewing)
    let afterDrift = session.handle(tripleTwentyCommand(for: session, confidence: 0.8))
    #expect(afterDrift == .ignored(.sessionNotReady))
}

@Test(.tags(.unit, .vision, .regression))
func recalibrationKeepsVisit() {
    var session = calibratedSession()
    _ = session.handle(tripleTwentyCommand(for: session, confidence: 0.8))
    session.beginRecalibration()
    #expect(session.phase == .calibrating)
    #expect(session.visit.count == 1)
}

@Test(.tags(.unit, .vision, .regression))
func detectionStoresImagePoint() throws {
    var session = calibratedSession()
    let command = tripleTwentyCommand(for: session, confidence: 0.8)
    guard case let .proposed(detection) = session.handle(command) else {
        Issue.record("Expected proposal")
        return
    }
    #expect(detection.imageX == command.imageX)
    #expect(detection.imageY == command.imageY)
}

@Test(.tags(.unit, .vision, .regression))
func manualHomographyIgnoresContourDrift() throws {
    var session = VisionScoringSession()
    let calibration = try #require(BoardCalibration(
        outerWireImagePoints: [
            SIMD2(0.5, 0.2),
            SIMD2(0.8, 0.5),
            SIMD2(0.5, 0.8),
            SIMD2(0.2, 0.5),
        ],
        quality: CalibrationQuality(fitConfidence: 1, brightness: 0.5, sharpness: 0.6)
    ))
    let applied = session.applyCalibration(calibration)
    #expect(applied)
    let drifted = session.observeBoard(centerX: 0.9, centerY: 0.9, radius: 0.9)
    #expect(!drifted)
    #expect(session.phase == .ready)
}

@Test(.tags(.unit, .vision, .regression))
func smallBoardMovementDoesNotPause() {
    var session = calibratedSession()
    let smallMove = session.observeBoard(centerX: 0.51, centerY: 0.5, radius: 0.3)
    #expect(!smallMove)
    #expect(session.phase == .ready)
}

@Test(.tags(.unit, .vision, .regression))
func recalibrationReturnsToCalibratingPhase() {
    var session = calibratedSession()
    session.beginRecalibration()
    #expect(session.phase == .calibrating)
    #expect(session.calibration == nil)
}

@Test(.tags(.unit, .vision, .regression))
func detectionForDifferentSessionIsIgnored() {
    var session = calibratedSession()
    let foreign = DetectThrowCommand(
        visionSessionId: UUID(),
        imageX: 0.5,
        imageY: 0.3,
        confidence: 0.8,
        frameTimestamp: Date()
    )
    #expect(session.handle(foreign) == .ignored(.sessionMismatch))
}

@Test(.tags(.unit, .vision, .regression))
func detectionTallyCountsExactChangedAndDismissed() {
    var tally = VisionDetectionTally()
    let detected = DartInput(multiplier: .triple, segment: .oneToTwenty(20))
    tally.recordConfirmation(detected: detected, submitted: detected)
    tally.recordConfirmation(
        detected: detected,
        submitted: DartInput(multiplier: .single, segment: .oneToTwenty(5))
    )
    tally.recordDismissal()
    tally.recordAddedByHand()
    #expect(tally.exact == 1)
    #expect(tally.changed == 1)
    #expect(tally.dismissed == 1)
    #expect(tally.addedByHand == 1)
    #expect(tally.scored == 2)
}

@Test(.tags(.unit, .vision, .regression))
func userPauseAndResume() {
    var session = calibratedSession()
    session.pauseByUser()
    #expect(session.phase == .paused(.userPaused))
    session.resumeFromUserPause()
    #expect(session.phase == .ready)
}

@Test(.tags(.unit, .vision, .regression))
func detectorFloorConfidenceIsStillProposed() {
    var session = calibratedSession()
    let outcome = session.handle(tripleTwentyCommand(for: session, confidence: 0.3))
    guard case .proposed = outcome else {
        Issue.record("A persisted cluster at the detector floor should reach the tray, got \(outcome)")
        return
    }
    #expect(session.visit.count == 1)
    let dropped = session.handle(tripleTwentyCommand(for: session, confidence: 0.29, at: Date().addingTimeInterval(2)))
    #expect(dropped == .ignored(.belowConfidenceFloor))
}

@Test(.tags(.unit, .vision, .regression))
func manualLockBypassesTheFrameQualityGate() throws {
    var session = VisionScoringSession()
    let dim = try #require(BoardCalibration(
        outerWireImagePoints: [
            SIMD2(0.5, 0.20),
            SIMD2(0.78, 0.62),
            SIMD2(0.5, 0.88),
            SIMD2(0.22, 0.62),
        ],
        quality: CalibrationQuality(fitConfidence: 1, brightness: 0.05, sharpness: 0.05)
    ))
    let rejected = session.applyCalibration(dim)
    let applied = session.applyCalibration(dim, enforcingQualityGate: false)
    #expect(!rejected)
    #expect(applied)
    #expect(session.phase == .ready)
}

@MainActor
@Test(.tags(.unit, .vision, .regression))
func captureStartKeepsDartsLeftInTheTurn() {
    let viewModel = VisionScoringViewModel()
    viewModel.updateTurn(dartsAllowed: 2, turnKey: "0-0-0-0")
    viewModel.prepareSessionForCapture()
    #expect(viewModel.visitCapacity == 2)
    let dart = DartInput(multiplier: .single, segment: .oneToTwenty(20))
    viewModel.addDart(dart)
    viewModel.addDart(dart)
    viewModel.addDart(dart)
    #expect(viewModel.visit.count == 2)
}

@MainActor
@Test(.tags(.unit, .vision, .regression))
func tapsBeforeTheFirstFrameAreIgnored() {
    let viewModel = VisionScoringViewModel()
    viewModel.updateTurn(dartsAllowed: 3, turnKey: "0-0-0-0")
    viewModel.prepareSessionForCapture()
    viewModel.registerCalibrationTap(imageX: 0.5, imageY: 0.2)
    #expect(viewModel.calibrationTaps.isEmpty)
    #expect(viewModel.previewAspectRatio == 0)
}

@MainActor
@Test(.tags(.unit, .vision, .regression))
func dimFrameStillLocksFourOuterWireTaps() {
    let viewModel = lockedCamera(brightness: 0.05, sharpness: 0.05)
    #expect(viewModel.status == .ready)
    #expect(viewModel.calibrationTaps.count == 4)
    #expect(!viewModel.calibrationRejected)
}

@MainActor
@Test(.tags(.unit, .vision, .regression))
func misalignedTapsDropTheLastPoint() {
    let viewModel = VisionScoringViewModel()
    viewModel.updateTurn(dartsAllowed: 3, turnKey: "0-0-0-0")
    viewModel.prepareSessionForCapture()
    viewModel.handle(visionFrame())
    for point in [SIMD2(0.2, 0.2), SIMD2(0.3, 0.3), SIMD2(0.4, 0.4), SIMD2(0.5, 0.5)] {
        viewModel.registerCalibrationTap(imageX: point.x, imageY: point.y)
    }
    #expect(viewModel.calibrationRejected)
    #expect(viewModel.calibrationTaps.count == 3)
    #expect(viewModel.status == .calibrating)
}

@MainActor
@Test(.tags(.unit, .vision, .regression))
func submitCountsExactChangedAndDismissed() {
    let viewModel = lockedCamera()
    let start = Date()
    viewModel.handle(visionFrame(impact: impact(x: 0.5, y: 0.54), at: start))
    #expect(viewModel.visit.count == 1)
    viewModel.submitVisit()
    #expect(viewModel.tally.exact == 1)
    #expect(viewModel.tally.changed == 0)
    #expect(viewModel.tally.dismissed == 0)

    viewModel.handle(visionFrame(impact: impact(x: 0.5, y: 0.54), at: start.addingTimeInterval(3)))
    viewModel.handle(visionFrame(impact: impact(x: 0.5, y: 0.32), at: start.addingTimeInterval(5)))
    #expect(viewModel.visit.count == 2)
    let first = viewModel.visit[0].id
    let second = viewModel.visit[1]
    let rewritten = second.dart == DartInput(multiplier: .single, segment: .oneToTwenty(5))
        ? DartInput(multiplier: .triple, segment: .oneToTwenty(20))
        : DartInput(multiplier: .single, segment: .oneToTwenty(5))
    viewModel.editDart(id: second.id, to: rewritten)
    viewModel.removeDart(id: first)
    viewModel.submitVisit()
    #expect(viewModel.tally.exact == 1)
    #expect(viewModel.tally.changed == 1)
    #expect(viewModel.tally.dismissed == 1)
}

@MainActor
@Test(.tags(.unit, .vision, .regression))
func sameSpotSettleDoesNotAddASecondDart() {
    let viewModel = lockedCamera()
    let start = Date()
    viewModel.handle(visionFrame(impact: impact(x: 0.5, y: 0.54), at: start))
    viewModel.handle(visionFrame(impact: impact(x: 0.5, y: 0.545), at: start.addingTimeInterval(0.4)))
    #expect(viewModel.visit.count == 1)
}

@MainActor
@Test(.tags(.unit, .vision, .regression))
func turnChangeCountsUnreviewedDetectionsAsDismissed() {
    let viewModel = lockedCamera()
    viewModel.handle(visionFrame(impact: impact(x: 0.5, y: 0.54)))
    #expect(viewModel.visit.count == 1)
    viewModel.updateTurn(dartsAllowed: 3, turnKey: "0-0-1-0")
    #expect(viewModel.tally.dismissed == 1)
    #expect(viewModel.tally.exact == 0)
    #expect(viewModel.visit.isEmpty)
    viewModel.updateTurn(dartsAllowed: 3, turnKey: "0-0-1-0")
    #expect(viewModel.tally.dismissed == 1)
}

@MainActor
@Test(.tags(.unit, .vision, .regression))
func handAddedDartIsNotAnExactDetection() {
    let viewModel = lockedCamera()
    viewModel.addDart(DartInput(multiplier: .single, segment: .oneToTwenty(20)))
    #expect(viewModel.visit.count == 1)
    viewModel.submitVisit()
    #expect(viewModel.tally.exact == 0)
    #expect(viewModel.tally.changed == 0)
    #expect(viewModel.tally.dismissed == 0)
    #expect(viewModel.tally.addedByHand == 1)
}

@MainActor
private func lockedCamera(brightness: Double = 0.5, sharpness: Double = 0.8) -> VisionScoringViewModel {
    let viewModel = VisionScoringViewModel()
    viewModel.updateTurn(dartsAllowed: 3, turnKey: "0-0-0-0")
    viewModel.prepareSessionForCapture()
    viewModel.handle(visionFrame(brightness: brightness, sharpness: sharpness))
    for point in [SIMD2(0.5, 0.20), SIMD2(0.78, 0.62), SIMD2(0.5, 0.88), SIMD2(0.22, 0.62)] {
        viewModel.registerCalibrationTap(imageX: point.x, imageY: point.y)
    }
    return viewModel
}

private func visionFrame(
    brightness: Double = 0.5,
    sharpness: Double = 0.8,
    impact: ImpactDetector.Candidate? = nil,
    at timestamp: Date = Date(),
    sceneMotion: Bool = false
) -> VisionFrameAnalysis {
    VisionFrameAnalysis(
        board: nil,
        brightness: brightness,
        sharpness: sharpness,
        impact: impact,
        aspectRatio: 0.5625,
        timestamp: timestamp,
        sceneMotion: sceneMotion
    )
}

private func impact(x: Double, y: Double, confidence: Double = 0.8) -> ImpactDetector.Candidate {
    ImpactDetector.Candidate(
        imageX: x,
        imageY: y,
        confidence: confidence,
        clusterBounds: SIMD4(0.4, 0.4, 0.6, 0.6)
    )
}
