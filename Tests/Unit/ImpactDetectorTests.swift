import Foundation
import Testing
@testable import DartBuddy

/// A camera off to the side of the board plus helpers to render what the impact
/// detector would see as darts land and get pulled.
private struct ImpactRig {
    let camera: SyntheticCamera
    let calibration: BoardCalibration
    let region: ImageRegion
    var detector = ImpactDetector()
    static let gridSize = 240

    init(camera: SyntheticCamera = SyntheticCamera(yawDegrees: 25, pitchDegrees: -8, distance: 5.5)) throws {
        self.camera = camera
        calibration = try #require(camera.calibration())
        region = ImageRegion.around(calibration)
        detector.configure(calibration: calibration, region: region)
    }

    func frame(darts: [SyntheticDart] = [], brightness: Double = 1) -> ImpactFrame {
        let color = SyntheticScene.render(camera: camera, width: 480, darts: darts, brightness: brightness)
        return SyntheticScene.impactFrame(from: color, region: region, size: Self.gridSize)
    }

    /// Feeds the same frame repeatedly and returns every event raised.
    mutating func hold(_ frame: ImpactFrame, frames: Int = 14) -> [ImpactDetector.Event] {
        var events: [ImpactDetector.Event] = []
        for _ in 0 ..< frames {
            if let event = detector.process(frame) {
                events.append(event)
            }
        }
        return events
    }

    func score(of impact: ImpactDetector.Impact) -> DartInput? {
        calibration.dartInput(atImageX: impact.tip.x, imageY: impact.tip.y)
    }

    func errorMM(of impact: ImpactDetector.Impact, dart: SyntheticDart) -> Double? {
        guard let point = calibration.transform.apply(toImageX: impact.tip.x, imageY: impact.tip.y) else { return nil }
        let dx = point.x - dart.tipX
        let dy = point.y - dart.tipY
        return (dx * dx + dy * dy).squareRoot() * DartboardGeometry.doubleOuterRadiusMM
    }
}

private func singleDart(_ events: [ImpactDetector.Event]) -> ImpactDetector.Impact? {
    guard events.count == 1, case let .dart(impact) = events[0] else { return nil }
    return impact
}

@Test(.tags(.unit, .vision, .regression))
func impactFrameValidatesDimensions() {
    #expect(ImpactFrame(width: 2, height: 2, luma: [0.1, 0.2, 0.3]) == nil)
    #expect(ImpactFrame(width: 0, height: 2, luma: []) == nil)
    #expect(ImpactFrame(width: 2, height: 2, luma: [0.1, 0.2, 0.3, 0.4]) != nil)
}

@Test(.tags(.unit, .vision, .regression))
func emptyBoardRaisesNoEvents() throws {
    var rig = try ImpactRig()
    #expect(rig.hold(rig.frame(), frames: 40).isEmpty)
    #expect(rig.detector.isArmed)
    #expect(rig.detector.dartsOnBoard == 0)
}

@Test(.tags(.unit, .vision, .regression))
func dartTipIsLocatedAndScoredOnce() throws {
    var rig = try ImpactRig()
    _ = rig.hold(rig.frame())
    // Middle of the triple 20 bed.
    let dart = SyntheticDart(tipX: 0, tipY: 0.606)
    let impact = try #require(singleDart(rig.hold(rig.frame(darts: [dart]), frames: 30)))
    #expect(rig.score(of: impact) == DartInput(multiplier: .triple, segment: .oneToTwenty(20)))
    #expect((rig.errorMM(of: impact, dart: dart) ?? .infinity) < 3)
    #expect(impact.confidence >= 0.7)
    #expect(rig.detector.dartsOnBoard == 1)
}

@Test(.tags(.unit, .vision, .regression))
func tipIsFoundAtTheBoardEndNotTheFlight() throws {
    var rig = try ImpactRig()
    _ = rig.hold(rig.frame())
    // The flight of this dart hangs over the neighbouring beds; only the tip is in the bull.
    let dart = SyntheticDart(tipX: 0.01, tipY: 0.0, leanX: -0.1, leanY: 0.15)
    let impact = try #require(singleDart(rig.hold(rig.frame(darts: [dart]))))
    #expect(rig.score(of: impact) == DartInput(multiplier: .single, segment: .innerBull))
    // Tip and tail are well separated: the estimate is an end of the dart, not its middle.
    #expect(impact.tip.distance(to: impact.tail) > rig.calibration.radius * 0.2)
}

@Test(.tags(.unit, .vision, .regression))
func threeDartsThenTakeoutProducesThreeScoresAndACleared() throws {
    var rig = try ImpactRig()
    _ = rig.hold(rig.frame())
    let darts = [
        SyntheticDart(tipX: 0, tipY: 0.606), // T20
        SyntheticDart(tipX: 0.03, tipY: 0.585, leanX: 0.08), // touching the first: S20 just under the treble
        SyntheticDart(tipX: 0.3, tipY: -0.72, leanX: -0.05), // S17 region
    ]
    var scores: [DartInput] = []
    for count in 1 ... 3 {
        let impact = try #require(singleDart(rig.hold(rig.frame(darts: Array(darts.prefix(count))))))
        scores.append(try #require(rig.score(of: impact)))
        #expect((rig.errorMM(of: impact, dart: darts[count - 1]) ?? .infinity) < 3.5)
    }
    #expect(scores == darts.map { DartboardGeometry.dartInput(at: BoardPoint(x: $0.tipX, y: $0.tipY)) })
    #expect(rig.detector.dartsOnBoard == 3)

    // Player pulls the darts: board returns to empty.
    #expect(rig.hold(rig.frame()) == [.boardCleared])
    #expect(rig.detector.dartsOnBoard == 0)

    // Next visit is detected against the fresh reference.
    #expect(singleDart(rig.hold(rig.frame(darts: [darts[2]]))) != nil)
}

@Test(.tags(.unit, .vision, .regression))
func pullingOneDartIsNotScoredAsAThrow() throws {
    var rig = try ImpactRig()
    _ = rig.hold(rig.frame())
    let first = SyntheticDart(tipX: -0.4, tipY: 0.3)
    let second = SyntheticDart(tipX: 0.5, tipY: -0.1)
    #expect(singleDart(rig.hold(rig.frame(darts: [first]))) != nil)
    #expect(singleDart(rig.hold(rig.frame(darts: [first, second]))) != nil)
    // Second dart falls out / is pulled while the first stays.
    #expect(rig.hold(rig.frame(darts: [first])).isEmpty)
    #expect(rig.detector.dartsOnBoard == 1)
    #expect(rig.hold(rig.frame()) == [.boardCleared])
}

@Test(.tags(.unit, .vision, .regression))
func movementIsIgnoredUntilTheSceneSettles() throws {
    var rig = try ImpactRig()
    _ = rig.hold(rig.frame())
    // A dart wobbling between two positions never holds still long enough to evaluate.
    let wobbleA = rig.frame(darts: [SyntheticDart(tipX: 0.2, tipY: 0.2, leanX: 0.05)])
    let wobbleB = rig.frame(darts: [SyntheticDart(tipX: 0.2, tipY: 0.2, leanX: 0.25)])
    for index in 0 ..< 12 {
        #expect(rig.detector.process(index % 2 == 0 ? wobbleA : wobbleB) == nil)
    }
    #expect(singleDart(rig.hold(wobbleA)) != nil)
}

@Test(.tags(.unit, .vision, .regression))
func playerStandingInFrontOfBoardIsNotADart() throws {
    var rig = try ImpactRig()
    let empty = rig.frame()
    _ = rig.hold(empty)
    // Darken the left 45% of the view, as a body stepping in front of the camera would.
    var luma = empty.luma
    for y in 0 ..< empty.height {
        for x in 0 ..< Int(Double(empty.width) * 0.45) {
            luma[y * empty.width + x] = 0.05
        }
    }
    let blocked = try #require(ImpactFrame(width: empty.width, height: empty.height, luma: luma, cb: empty.cb, cr: empty.cr))
    #expect(rig.hold(blocked, frames: 30).isEmpty)
    #expect(rig.hold(empty).isEmpty)
    #expect(rig.detector.dartsOnBoard == 0)
}

@Test(.tags(.unit, .vision, .regression))
func armReachingInFromTheEdgeIsNotADart() throws {
    var rig = try ImpactRig()
    let empty = rig.frame()
    _ = rig.hold(empty)
    // A thick bar from the right border to the middle of the board.
    var luma = empty.luma
    for y in (empty.height / 2 - 9) ..< (empty.height / 2 + 9) {
        for x in (empty.width / 2) ..< empty.width {
            luma[y * empty.width + x] = 0.75
        }
    }
    let arm = try #require(ImpactFrame(width: empty.width, height: empty.height, luma: luma, cb: empty.cb, cr: empty.cr))
    #expect(rig.hold(arm, frames: 30).isEmpty)
}

@Test(.tags(.unit, .vision, .regression))
func gradualExposureChangeDoesNotRaiseEvents() throws {
    var rig = try ImpactRig()
    _ = rig.hold(rig.frame())
    for step in 1 ... 6 {
        #expect(rig.hold(rig.frame(brightness: 1 - 0.03 * Double(step)), frames: 10).isEmpty)
    }
    // Detection still works at the new exposure.
    let dart = SyntheticDart(tipX: -0.5, tipY: -0.4)
    let frame = rig.frame(darts: [dart], brightness: 0.82)
    #expect(singleDart(rig.hold(frame)) != nil)
}

@Test(.tags(.unit, .vision, .regression))
func dartInTheNumberRingScoresAsAMiss() throws {
    var rig = try ImpactRig()
    _ = rig.hold(rig.frame())
    let nearMiss = SyntheticDart(tipX: 0, tipY: 1.12)
    let impact = try #require(singleDart(rig.hold(rig.frame(darts: [nearMiss]))))
    #expect(rig.score(of: impact)?.isMiss == true)
}

@Test(.tags(.unit, .vision, .regression))
func headOnCameraFallsBackToShapeAndLowersConfidence() throws {
    var rig = try ImpactRig(camera: SyntheticCamera())
    _ = rig.hold(rig.frame())
    let dart = SyntheticDart(tipX: -0.7, tipY: 0.1, leanX: 0.1)
    let impact = try #require(singleDart(rig.hold(rig.frame(darts: [dart]))))
    #expect((rig.errorMM(of: impact, dart: dart) ?? .infinity) < 4)
    #expect(impact.confidence < 0.92)
}

@Test(.tags(.unit, .vision, .regression))
func resetForgetsReferences() throws {
    var rig = try ImpactRig()
    _ = rig.hold(rig.frame())
    #expect(rig.detector.isArmed)
    rig.detector.reset()
    #expect(!rig.detector.isArmed)
    // With no reference yet, a board that already holds a dart becomes the baseline.
    #expect(rig.hold(rig.frame(darts: [SyntheticDart(tipX: 0, tipY: 0.3)])).isEmpty)
}

/// Adds deterministic pseudo-random sensor noise to a frame.
private func noisy(_ frame: ImpactFrame, seed: UInt64, amplitude: Float = 0.02) -> ImpactFrame {
    var state = seed &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
    func next() -> Float {
        state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
        return Float(state >> 40) / Float(1 << 24) * 2 - 1
    }
    let luma = frame.luma.map { $0 + next() * amplitude }
    let cb = frame.cb.map { $0 + next() * amplitude / 2 }
    let cr = frame.cr.map { $0 + next() * amplitude / 2 }
    return ImpactFrame(width: frame.width, height: frame.height, luma: luma, cb: cb, cr: cr) ?? frame
}

@Test(.tags(.unit, .vision, .regression))
func sensorNoiseNeitherTriggersNorHidesDetections() throws {
    var rig = try ImpactRig()
    let empty = rig.frame()
    var events: [ImpactDetector.Event] = []
    for index in 0 ..< 60 {
        if let event = rig.detector.process(noisy(empty, seed: UInt64(index))) { events.append(event) }
    }
    #expect(events.isEmpty)
    #expect(rig.detector.isArmed)

    let dart = SyntheticDart(tipX: 0.42, tipY: 0.44)
    let withDart = rig.frame(darts: [dart])
    for index in 60 ..< 100 {
        if let event = rig.detector.process(noisy(withDart, seed: UInt64(index))) { events.append(event) }
    }
    let impact = try #require(singleDart(events))
    #expect((rig.errorMM(of: impact, dart: dart) ?? .infinity) < 4)

    events = []
    for index in 100 ..< 140 {
        if let event = rig.detector.process(noisy(empty, seed: UInt64(index))) { events.append(event) }
    }
    #expect(events == [.boardCleared])
}
