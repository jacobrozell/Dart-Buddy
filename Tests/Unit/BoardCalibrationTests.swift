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

// MARK: - Perspective calibration

@Test(.tags(.unit, .vision, .regression))
func fourPointMappingReproducesCorrespondences() throws {
    let source = [ImagePoint(x: 0, y: 1), ImagePoint(x: 1, y: 0), ImagePoint(x: 0, y: -1), ImagePoint(x: -1, y: 0)]
    let destination = [
        ImagePoint(x: 0.52, y: 0.11), ImagePoint(x: 0.74, y: 0.3), ImagePoint(x: 0.49, y: 0.47), ImagePoint(x: 0.21, y: 0.27),
    ]
    let transform = try #require(PerspectiveTransform.mapping(from: source, to: destination))
    for (from, to) in zip(source, destination) {
        let mapped = try #require(transform.applyPoint(x: from.x, y: from.y))
        #expect(mapped.distance(to: to) < 1e-9)
    }
    let inverse = try #require(transform.inverted())
    let roundTrip = try #require(inverse.applyPoint(x: 0.74, y: 0.3))
    #expect(roundTrip.distance(to: ImagePoint(x: 1, y: 0)) < 1e-9)
}

@Test(.tags(.unit, .vision, .regression))
func fourPointMappingRejectsCollinearPoints() {
    let source = [ImagePoint(x: 0, y: 1), ImagePoint(x: 1, y: 0), ImagePoint(x: 0, y: -1), ImagePoint(x: -1, y: 0)]
    let line = [ImagePoint(x: 0, y: 0), ImagePoint(x: 0.1, y: 0.1), ImagePoint(x: 0.2, y: 0.2), ImagePoint(x: 0.3, y: 0.3)]
    #expect(PerspectiveTransform.mapping(from: source, to: line) == nil)
}

@Test(.tags(.unit, .vision, .regression))
func perspectiveCalibrationScoresAngledBoard() throws {
    let camera = SyntheticCamera(yawDegrees: 35, pitchDegrees: -20, distance: 5.5)
    let calibration = try #require(camera.calibration())
    for wedge in 0 ..< 20 {
        for radius in [0.3, 0.606, 0.78, 0.976] {
            let point = DartboardGeometry.point(radius: radius, angleDegrees: Double(wedge) * 18)
            let image = camera.project(x: point.x, y: point.y)
            #expect(calibration.dartInput(atImageX: image.x, imageY: image.y) == DartboardGeometry.dartInput(at: point))
        }
    }
    let bull = camera.project(x: 0, y: 0)
    #expect(abs(calibration.centerX - bull.x) < 1e-9)
    #expect(abs(calibration.centerY - bull.y) < 1e-9)
}

@Test(.tags(.unit, .vision, .regression))
func controlPointsRotateByWholeWedges() throws {
    let camera = SyntheticCamera(yawDegrees: 20, distance: 6)
    let rotated = try #require(camera.controlPoints.rotated(byWedges: 1))
    let calibration = try #require(BoardCalibration(
        controlPoints: rotated,
        imageAspectRatio: camera.aspectRatio,
        quality: acceptableQuality
    ))
    // What used to be the middle of the 1 wedge is now read as the 20.
    let formerOne = DartboardGeometry.point(radius: 0.8, angleDegrees: 18)
    let image = camera.project(x: formerOne.x, y: formerOne.y)
    #expect(calibration.dartInput(atImageX: image.x, imageY: image.y) == DartInput(multiplier: .single, segment: .oneToTwenty(20)))
    let back = try #require(rotated.rotated(byWedges: -1))
    #expect(back.maxDisplacement(from: camera.controlPoints) < 1e-9)
}

@Test(.tags(.unit, .vision, .regression))
func poseRecoversCameraTiltAndPredictsFlightPosition() throws {
    let camera = SyntheticCamera(yawDegrees: 30, pitchDegrees: -15, distance: 5.5)
    let calibration = try #require(camera.calibration())
    let pose = try #require(calibration.pose)
    #expect(pose.hasMeasuredFocalLength)
    #expect(abs(pose.focalLength - camera.focalLength) < 0.01)
    #expect(pose.tiltDegrees > 25)
    // A point 0.85 board radii out of the face projects where the true camera puts it.
    let predicted = try #require(pose.project(x: 0.3, y: -0.4, height: 0.85))
    #expect(predicted.distance(to: camera.project(x: 0.3, y: -0.4, height: 0.85)) < 1e-3)
}

@Test(.tags(.unit, .vision, .regression))
func poseFallsBackToTypicalLensWhenHeadOn() throws {
    let calibration = try #require(SyntheticCamera().calibration())
    let pose = try #require(calibration.pose)
    #expect(!pose.hasMeasuredFocalLength)
    #expect(pose.tiltDegrees < 2)
}

@Test(.tags(.unit, .vision, .regression))
func boundaryMarginMeasuresDistanceToNearestWire() {
    // Middle of the treble bed: 4 mm of ring either side.
    let treble = DartboardGeometry.point(radius: 103.0 / 170.0, angleDegrees: 0)
    #expect(abs(DartboardGeometry.boundaryMargin(at: treble) * 170 - 4) < 0.01)
    // On a wedge wire.
    let wire = DartboardGeometry.point(radius: 0.8, angleDegrees: 9)
    #expect(DartboardGeometry.boundaryMargin(at: wire) < 1e-9)
    // Dead centre: the inner bull wire is 6.35 mm away.
    #expect(abs(DartboardGeometry.boundaryMargin(at: BoardPoint(x: 0, y: 0)) * 170 - 6.35) < 0.01)
}
