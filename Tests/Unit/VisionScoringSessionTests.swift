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
    return session
}

/// Detection straight above center inside the triple ring (triple 20).
private func tripleTwentyCommand(for session: VisionScoringSession, confidence: Double) -> DetectThrowCommand {
    DetectThrowCommand(
        visionSessionId: session.id,
        imageX: 0.5,
        imageY: 0.5 - 0.606 * 0.3,
        confidence: confidence,
        frameTimestamp: Date()
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
    #expect(!session.applyCalibration(poor))
    #expect(session.phase == .calibrating)
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
    #expect(session.pendingProposal == detection)
}

@Test(.tags(.unit, .vision, .regression))
func detectionsBelowConfidenceFloorAreDropped() {
    var session = calibratedSession()
    let outcome = session.handle(tripleTwentyCommand(for: session, confidence: 0.1))
    #expect(outcome == .ignored(.belowConfidenceFloor))
    #expect(session.pendingProposal == nil)
}

@Test(.tags(.unit, .vision, .regression))
func autoCommitRequiresEnabledPolicyAndThreshold() {
    let policy = VisionScoringPolicy(autoCommitEnabled: true, autoCommitConfidenceThreshold: 0.92)
    var session = calibratedSession(policy: policy)

    // Never silently auto-score below the threshold (spec §8): proposes instead.
    let belowThreshold = session.handle(tripleTwentyCommand(for: session, confidence: 0.7))
    guard case .proposed = belowThreshold else {
        Issue.record("Expected proposal below threshold, got \(belowThreshold)")
        return
    }
    session.handle(RejectDetectedThrowCommand(detectedThrowId: session.pendingProposal!.id))

    let aboveThreshold = session.handle(tripleTwentyCommand(for: session, confidence: 0.95))
    guard case .autoCommitted = aboveThreshold else {
        Issue.record("Expected auto-commit above threshold, got \(aboveThreshold)")
        return
    }
    #expect(session.pendingProposal == nil)
}

@Test(.tags(.unit, .vision, .regression))
func secondDetectionIgnoredWhileProposalPending() {
    var session = calibratedSession()
    _ = session.handle(tripleTwentyCommand(for: session, confidence: 0.8))
    let outcome = session.handle(tripleTwentyCommand(for: session, confidence: 0.8))
    #expect(outcome == .ignored(.proposalPending))
}

@Test(.tags(.unit, .vision, .regression))
func confirmReturnsDartWithVisionConfirmedMetadata() throws {
    var session = calibratedSession()
    guard case let .proposed(detection) = session.handle(tripleTwentyCommand(for: session, confidence: 0.8)) else {
        Issue.record("Expected proposal")
        return
    }
    let confirmed = try #require(session.handle(ConfirmDetectedThrowCommand(detectedThrowId: detection.id)))
    #expect(confirmed.dart == detection.dart)
    #expect(confirmed.metadata.inputMethod == .visionConfirmed)
    #expect(confirmed.metadata.visionConfidence == 0.8)
    #expect(confirmed.metadata.visionSessionId == session.id)
    #expect(session.pendingProposal == nil)
}

@Test(.tags(.unit, .vision, .regression))
func confirmAppliesUserCorrection() throws {
    var session = calibratedSession()
    guard case let .proposed(detection) = session.handle(tripleTwentyCommand(for: session, confidence: 0.8)) else {
        Issue.record("Expected proposal")
        return
    }
    let corrected = DartInput(multiplier: .single, segment: .oneToTwenty(5))
    let confirmed = try #require(
        session.handle(ConfirmDetectedThrowCommand(detectedThrowId: detection.id, correctedDart: corrected))
    )
    #expect(confirmed.dart == corrected)
}

@Test(.tags(.unit, .vision, .regression))
func staleConfirmAndRejectAreNoOps() {
    var session = calibratedSession()
    _ = session.handle(tripleTwentyCommand(for: session, confidence: 0.8))
    #expect(session.handle(ConfirmDetectedThrowCommand(detectedThrowId: UUID())) == nil)
    #expect(!session.handle(RejectDetectedThrowCommand(detectedThrowId: UUID())))
    #expect(session.pendingProposal != nil)
}

@Test(.tags(.unit, .vision, .regression))
func rejectClearsProposalAndAllowsNewDetections() {
    var session = calibratedSession()
    guard case let .proposed(detection) = session.handle(tripleTwentyCommand(for: session, confidence: 0.8)) else {
        Issue.record("Expected proposal")
        return
    }
    #expect(session.handle(RejectDetectedThrowCommand(detectedThrowId: detection.id)))
    guard case .proposed = session.handle(tripleTwentyCommand(for: session, confidence: 0.8)) else {
        Issue.record("Expected a fresh proposal after reject")
        return
    }
}

@Test(.tags(.unit, .vision, .regression))
func driftPausesSessionAndDropsPendingProposal() {
    var session = calibratedSession()
    _ = session.handle(tripleTwentyCommand(for: session, confidence: 0.8))
    #expect(session.observeBoard(centerX: 0.6, centerY: 0.5, radius: 0.3))
    #expect(session.phase == .paused(.calibrationDrift))
    #expect(session.pendingProposal == nil)
    #expect(session.handle(tripleTwentyCommand(for: session, confidence: 0.8)) == .ignored(.sessionNotReady))
}

@Test(.tags(.unit, .vision, .regression))
func smallBoardMovementDoesNotPause() {
    var session = calibratedSession()
    #expect(!session.observeBoard(centerX: 0.51, centerY: 0.5, radius: 0.3))
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
func userPauseAndResume() {
    var session = calibratedSession()
    session.pauseByUser()
    #expect(session.phase == .paused(.userPaused))
    session.resumeFromUserPause()
    #expect(session.phase == .ready)
}
