import Foundation
import Testing
@testable import DartBuddy

private let acceptableQuality = CalibrationQuality(fitConfidence: 0.9, brightness: 0.5, sharpness: 0.6)

@Test(.tags(.unit, .vision, .regression))
func circleFitMapsCenterToOrigin() throws {
    let transform = try #require(PerspectiveTransform.circleFit(centerX: 0.5, centerY: 0.4, radius: 0.25))
    let mapped = try #require(transform.apply(toImageX: 0.5, imageY: 0.4))
    #expect(abs(mapped.x) < 0.0001)
    #expect(abs(mapped.y) < 0.0001)
}

@Test(.tags(.unit, .vision, .regression))
func circleFitFlipsImageYSoUpIsPositive() throws {
    let transform = try #require(PerspectiveTransform.circleFit(centerX: 0.5, centerY: 0.4, radius: 0.25))
    // Image point above center (smaller y) should map to board "up" (positive y).
    let above = try #require(transform.apply(toImageX: 0.5, imageY: 0.15))
    #expect(abs(above.x) < 0.0001)
    #expect(abs(above.y - 1.0) < 0.0001)
    // Image point at the right edge of the board maps to (1, 0).
    let right = try #require(transform.apply(toImageX: 0.75, imageY: 0.4))
    #expect(abs(right.x - 1.0) < 0.0001)
    #expect(abs(right.y) < 0.0001)
}

@Test(.tags(.unit, .vision, .regression))
func circleFitCorrectsSegmentRotation() throws {
    // Board rotated 90° clockwise in the image: the 20 wedge points image-right,
    // so the image-right edge must map back to board "up".
    let transform = try #require(
        PerspectiveTransform.circleFit(centerX: 0.5, centerY: 0.5, radius: 0.25, rotationDegrees: 90)
    )
    let right = try #require(transform.apply(toImageX: 0.75, imageY: 0.5))
    #expect(abs(right.x) < 0.0001)
    #expect(abs(right.y - 1.0) < 0.0001)
}

@Test(.tags(.unit, .vision, .regression))
func circleFitRejectsNonPositiveRadius() {
    #expect(PerspectiveTransform.circleFit(centerX: 0.5, centerY: 0.5, radius: 0) == nil)
}

@Test(.tags(.unit, .vision, .regression))
func calibrationScoresDartsFromImagePoints() throws {
    let calibration = try #require(BoardCalibration(
        centerX: 0.5,
        centerY: 0.5,
        radius: 0.3,
        quality: acceptableQuality
    ))
    // Image point straight above center inside the triple ring → triple 20.
    let dart = try #require(calibration.dartInput(atImageX: 0.5, imageY: 0.5 - 0.606 * 0.3))
    #expect(dart == DartInput(multiplier: .triple, segment: .oneToTwenty(20)))
}

@Test(.tags(.unit, .vision, .regression))
func qualityGateRejectsPoorFitBrightnessOrBlur() {
    #expect(acceptableQuality.isAcceptable)
    #expect(!CalibrationQuality(fitConfidence: 0.5, brightness: 0.5, sharpness: 0.6).isAcceptable)
    #expect(!CalibrationQuality(fitConfidence: 0.9, brightness: 0.1, sharpness: 0.6).isAcceptable)
    #expect(!CalibrationQuality(fitConfidence: 0.9, brightness: 0.5, sharpness: 0.1).isAcceptable)
}

@Test(.tags(.unit, .vision, .regression))
func driftDetectionRespectsTolerances() throws {
    let calibration = try #require(BoardCalibration(
        centerX: 0.5,
        centerY: 0.5,
        radius: 0.3,
        quality: acceptableQuality
    ))
    #expect(!calibration.hasDrifted(observedCenterX: 0.51, observedCenterY: 0.5, observedRadius: 0.3))
    #expect(calibration.hasDrifted(observedCenterX: 0.56, observedCenterY: 0.5, observedRadius: 0.3))
    #expect(calibration.hasDrifted(observedCenterX: 0.5, observedCenterY: 0.5, observedRadius: 0.35))
}
