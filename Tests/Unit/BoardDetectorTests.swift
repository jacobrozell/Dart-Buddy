import Foundation
import Testing
@testable import DartBuddy

/// Board points spread over every bed, kept clear of wires so tiny calibration
/// error cannot flip the expected score.
private func scoringProbePoints() -> [BoardPoint] {
    var points: [BoardPoint] = [BoardPoint(x: 0, y: 0)]
    let radii = [0.065, 0.3, 0.606, 0.78, 0.976]
    for radius in radii {
        for wedge in 0 ..< 20 {
            points.append(DartboardGeometry.point(radius: radius, angleDegrees: Double(wedge) * 18))
        }
    }
    return points
}

private func scoringAgreement(detected: BoardCalibration, camera: SyntheticCamera) -> Double {
    let probes = scoringProbePoints()
    var matches = 0
    for probe in probes {
        let image = camera.project(x: probe.x, y: probe.y)
        if detected.dartInput(atImageX: image.x, imageY: image.y) == DartboardGeometry.dartInput(at: probe) {
            matches += 1
        }
    }
    return Double(matches) / Double(probes.count)
}

private func detectedCalibration(_ detection: BoardDetection, camera: SyntheticCamera) -> BoardCalibration? {
    BoardCalibration(
        controlPoints: detection.controlPoints,
        imageAspectRatio: camera.aspectRatio,
        quality: CalibrationQuality(fitConfidence: detection.agreement, brightness: 0.5, sharpness: 0.8)
    )
}

@Test(
    .tags(.unit, .vision, .regression),
    arguments: [
        SyntheticCamera(),
        SyntheticCamera(yawDegrees: 25, distance: 5.5),
        SyntheticCamera(yawDegrees: -35, pitchDegrees: 10, distance: 6),
        SyntheticCamera(pitchDegrees: -30, distance: 5.5, centerX: 0.45),
        SyntheticCamera(yawDegrees: 20, pitchDegrees: 20, rollDegrees: 6, distance: 6.5, centerX: 0.55),
        SyntheticCamera(yawDegrees: 15, pitchDegrees: -25, distance: 5.2, aspectRatio: 16.0 / 9.0, centerY: 0.8),
    ]
)
func boardDetectorRecoversPerspectiveCalibration(camera: SyntheticCamera) throws {
    let width = camera.aspectRatio > 1 ? 360 : 640
    let frame = SyntheticScene.render(camera: camera, width: width)
    let detection = try #require(BoardDetector.detect(in: frame))
    #expect(detection.usedBullCenter)
    #expect(detection.agreement > 0.8)
    // Landmarks land within about 1% of the board radius (under 2 mm) of the truth.
    let radius = camera.project(x: 0, y: 0).distance(to: camera.project(x: 1, y: 0))
    #expect(detection.controlPoints.maxDisplacement(from: camera.controlPoints) < radius * 0.012)
    let calibration = try #require(detectedCalibration(detection, camera: camera))
    #expect(scoringAgreement(detected: calibration, camera: camera) >= 0.99)
}

@Test(.tags(.unit, .vision, .regression))
func boardDetectorWorksInDimLight() throws {
    let camera = SyntheticCamera(yawDegrees: 20, pitchDegrees: -10, distance: 6)
    let frame = SyntheticScene.render(camera: camera, width: 640, brightness: 0.45)
    let detection = try #require(BoardDetector.detect(in: frame))
    let calibration = try #require(detectedCalibration(detection, camera: camera))
    #expect(scoringAgreement(detected: calibration, camera: camera) >= 0.99)
}

@Test(.tags(.unit, .vision, .regression))
func boardDetectorFindsNothingWithoutABoard() throws {
    let rgb = [UInt8](repeating: 110, count: 320 * 180 * 3)
    let frame = try #require(ColorFrame(width: 320, height: 180, rgb: rgb))
    #expect(BoardDetector.detect(in: frame) == nil)
}

@Test(.tags(.unit, .vision, .regression))
func agreementDropsWhenTheCameraMoves() throws {
    let camera = SyntheticCamera(yawDegrees: 20, distance: 5.5)
    let calibration = try #require(camera.calibration())
    let same = SyntheticScene.render(camera: camera, width: 480)
    let moved = SyntheticScene.render(camera: SyntheticCamera(yawDegrees: 20, distance: 5.5, centerX: 0.58), width: 480)
    let before = BoardDetector.agreement(of: calibration, in: same)
    let after = BoardDetector.agreement(of: calibration, in: moved)
    #expect(before > 0.85)
    #expect(after < before * 0.6)
}

@Test(.tags(.unit, .vision, .regression))
func ringColorClassifierSeparatesBedsFromNeutrals() {
    #expect(BoardDetector.ringColor(red: 196, green: 34, blue: 44) == .red)
    #expect(BoardDetector.ringColor(red: 22, green: 128, blue: 70) == .green)
    #expect(BoardDetector.ringColor(red: 90, green: 16, blue: 20) == .red) // dim red
    #expect(BoardDetector.ringColor(red: 222, green: 206, blue: 168) == .none) // sisal
    #expect(BoardDetector.ringColor(red: 30, green: 30, blue: 32) == .none) // black bed
    #expect(BoardDetector.ringColor(red: 40, green: 90, blue: 210) == .none) // blue flight
}
