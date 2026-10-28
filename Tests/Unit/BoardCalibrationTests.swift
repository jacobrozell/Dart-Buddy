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
func homographyRecoversKnownPerspective() throws {
    let original = try #require(PerspectiveTransform(values: [
        2.2, 0.15, -1.05,
        0.05, -2.1, 0.95,
        0.25, 0.1, 1,
    ]))
    let inverse = try #require(original.inverted())
    let imagePoints = try BoardCalibration.outerWireBoardPoints.map { board in
        let image = try #require(inverse.apply(toImageX: board.x, imageY: board.y))
        return SIMD2(image.x, image.y)
    }
    let recovered = try #require(PerspectiveTransform.homography(
        fromImagePoints: imagePoints,
        toBoardPoints: BoardCalibration.outerWireBoardPoints
    ))
    let probeImage = try #require(inverse.apply(toImageX: 0.2, imageY: 0.55))
    let expected = try #require(original.apply(toImageX: probeImage.x, imageY: probeImage.y))
    let actual = try #require(recovered.apply(toImageX: probeImage.x, imageY: probeImage.y))
    #expect(abs(actual.x - expected.x) < 1e-5)
    #expect(abs(actual.y - expected.y) < 1e-5)
}

@Test(.tags(.unit, .vision, .regression))
func homographyRejectsCollinearPoints() {
    let collinear = [
        SIMD2(0.2, 0.2),
        SIMD2(0.4, 0.4),
        SIMD2(0.6, 0.6),
        SIMD2(0.8, 0.8),
    ]
    #expect(PerspectiveTransform.homography(
        fromImagePoints: collinear,
        toBoardPoints: BoardCalibration.outerWireBoardPoints
    ) == nil)
}

@Test(.tags(.unit, .vision, .regression))
func tappedOuterWireCalibrationScoresBullAndDoubleTwenty() throws {
    let center = SIMD2(0.5, 0.62)
    let top = SIMD2(0.5, 0.20)
    let right = SIMD2(0.78, 0.62)
    let bottom = SIMD2(0.5, 0.88)
    let left = SIMD2(0.22, 0.62)
    let calibration = try #require(BoardCalibration(
        outerWireImagePoints: [top, right, bottom, left],
        quality: acceptableQuality
    ))
    #expect(!calibration.monitorsContourDrift)
    let bull = try #require(calibration.dartInput(atImageX: center.x, imageY: center.y))
    #expect(bull == DartInput(multiplier: .single, segment: .innerBull))
    // Mid-treble on the 20, mapped back through the inverse so the check is not on the wire.
    let inverse = try #require(calibration.transform.inverted())
    let tripleImage = try #require(inverse.apply(toImageX: 0, imageY: 0.606))
    let tripleTwenty = try #require(calibration.dartInput(atImageX: tripleImage.x, imageY: tripleImage.y))
    #expect(tripleTwenty == DartInput(multiplier: .triple, segment: .oneToTwenty(20)))
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
