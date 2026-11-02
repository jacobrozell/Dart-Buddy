import Testing
@testable import DartBuddy

private let gridSize = 16

private func uniformGrid(_ value: Double = 0.5) -> LumaGrid {
    LumaGrid(width: gridSize, height: gridSize, values: Array(repeating: value, count: gridSize * gridSize))!
}

/// Uniform grid with a 2x2 bright blob whose top-left cell is at (x, y).
private func gridWithBlob(atX x: Int, y: Int, delta: Double = 0.4) -> LumaGrid {
    var values = Array(repeating: 0.5, count: gridSize * gridSize)
    for dy in 0 ..< 2 {
        for dx in 0 ..< 2 {
            values[(y + dy) * gridSize + (x + dx)] += delta
        }
    }
    return LumaGrid(width: gridSize, height: gridSize, values: values)!
}

/// Feeds enough identical frames to capture a stable baseline.
private func stabilize(_ detector: inout ImpactDetector, frames: Int = 8) {
    for _ in 0 ..< frames {
        #expect(detector.process(uniformGrid()) == nil)
    }
}

@Test(.tags(.unit, .vision, .regression))
func lumaGridValidatesDimensions() {
    #expect(LumaGrid(width: 2, height: 2, values: [0.1, 0.2, 0.3]) == nil)
    #expect(LumaGrid(width: 0, height: 2, values: []) == nil)
    #expect(LumaGrid(width: 2, height: 2, values: [0.1, 0.2, 0.3, 0.4]) != nil)
}

@Test(.tags(.unit, .vision, .regression))
func persistentStationaryBlobIsDetectedOnce() {
    var detector = ImpactDetector()
    stabilize(&detector)

    let blob = gridWithBlob(atX: 4, y: 4)
    #expect(detector.process(blob) == nil)
    #expect(detector.process(blob) == nil)
    let candidate = detector.process(blob)
    #expect(candidate != nil)
    if let candidate {
        // Centroid of the 2x2 block spanning cells 4...5.
        #expect(abs(candidate.imageX - 5.0 / Double(gridSize)) < 0.001)
        #expect(abs(candidate.imageY - 5.0 / Double(gridSize)) < 0.001)
        #expect(candidate.confidence >= 0.3)
        #expect(candidate.confidence <= 0.9)
    }
}

@Test(.tags(.unit, .vision, .regression))
func detectedBlobIsAbsorbedIntoBaseline() {
    var detector = ImpactDetector()
    stabilize(&detector)
    let blob = gridWithBlob(atX: 4, y: 4)
    for _ in 0 ..< 3 { _ = detector.process(blob) }

    // The same scene must not re-trigger, even after the cooldown expires.
    for _ in 0 ..< 20 {
        #expect(detector.process(blob) == nil)
    }

    // A second dart elsewhere is detected against the updated baseline.
    var values = blob.values
    for dy in 0 ..< 2 {
        for dx in 0 ..< 2 {
            values[(10 + dy) * gridSize + (10 + dx)] += 0.4
        }
    }
    let secondBlob = LumaGrid(width: gridSize, height: gridSize, values: values)!
    var candidate: ImpactDetector.Candidate?
    for _ in 0 ..< 3 {
        candidate = detector.process(secondBlob)
    }
    #expect(candidate != nil)
    if let candidate {
        #expect(abs(candidate.imageX - 11.0 / Double(gridSize)) < 0.001)
    }
}

@Test(.tags(.unit, .vision, .regression))
func largeSceneMotionResetsBaselineInsteadOfDetecting() {
    var detector = ImpactDetector()
    stabilize(&detector)

    // Half the frame changes: a player walking up to the board.
    var values = Array(repeating: 0.5, count: gridSize * gridSize)
    for index in 0 ..< values.count / 2 { values[index] = 0.9 }
    let motion = LumaGrid(width: gridSize, height: gridSize, values: values)!
    for _ in 0 ..< 5 {
        #expect(detector.process(motion) == nil)
    }

    // Until the scene re-stabilizes, small changes are not trusted as darts.
    #expect(detector.process(gridWithBlob(atX: 4, y: 4)) == nil)
}

@Test(.tags(.unit, .vision, .regression))
func movingBlobIsNotReportedAsImpact() {
    var detector = ImpactDetector()
    stabilize(&detector)

    for offset in 0 ..< 6 {
        #expect(detector.process(gridWithBlob(atX: 2 + offset * 2, y: 4)) == nil)
    }
}

@Test(.tags(.unit, .vision, .regression))
func slowLightingDriftIsNotReportedAsImpact() {
    var detector = ImpactDetector()
    stabilize(&detector)

    for step in 1 ... 60 {
        #expect(detector.process(gridWithBlob(atX: 4, y: 4, delta: Double(step) * 0.005)) == nil)
    }
}

@Test(.tags(.unit, .vision, .regression))
func scatteredChangeIsNotReportedAsImpact() {
    var detector = ImpactDetector()
    stabilize(&detector)

    // An exposure step brightens a few far-apart cells at once.
    var values = Array(repeating: 0.5, count: gridSize * gridSize)
    for (x, y) in [(1, 1), (14, 1), (1, 14), (14, 14)] {
        values[y * gridSize + x] += 0.4
    }
    let scattered = LumaGrid(width: gridSize, height: gridSize, values: values)!
    for _ in 0 ..< 6 {
        #expect(detector.process(scattered) == nil)
    }
}

@Test(.tags(.unit, .vision, .regression))
func changesOutsideRegionAreIgnored() {
    var detector = ImpactDetector()
    detector.setRegion((0 ..< gridSize * gridSize).map { $0 % gridSize < gridSize / 2 })
    stabilize(&detector)

    let outside = gridWithBlob(atX: 12, y: 4)
    for _ in 0 ..< 6 {
        #expect(detector.process(outside) == nil)
    }

    var values = outside.values
    for dy in 0 ..< 2 {
        for dx in 0 ..< 2 {
            values[(4 + dy) * gridSize + (2 + dx)] += 0.4
        }
    }
    let inside = LumaGrid(width: gridSize, height: gridSize, values: values)!
    var candidate: ImpactDetector.Candidate?
    for _ in 0 ..< 3 {
        candidate = detector.process(inside)
    }
    #expect(candidate != nil)
}

@Test(.tags(.unit, .vision, .regression))
func flightOnlyClusterStepsOneDartLengthToTheTip() throws {
    var detector = ImpactDetector()
    detector.setRegion(nil, tipOffset: SIMD2(-0.25, 0.125))
    stabilize(&detector)

    let flight = gridWithBlob(atX: 8, y: 4)
    var candidate: ImpactDetector.Candidate?
    for _ in 0 ..< 3 { candidate = detector.process(flight) }
    let tip = try #require(candidate)
    #expect(abs(tip.imageX - (9.0 / 16 - 0.25)) < 0.001)
    #expect(abs(tip.imageY - (5.0 / 16 + 0.125)) < 0.001)
}

@Test(.tags(.unit, .vision, .regression))
func wholeDartClusterReportsItsTipEnd() throws {
    var detector = ImpactDetector()
    detector.setRegion(nil, tipOffset: SIMD2(-3.0 / 16, 0))
    stabilize(&detector)

    // Flight (2x2 at x 8...9) plus a barrel running left to x = 6.
    var values = gridWithBlob(atX: 8, y: 4).values
    for x in 6 ... 7 { values[4 * gridSize + x] += 0.4 }
    let dart = LumaGrid(width: gridSize, height: gridSize, values: values)!
    var candidate: ImpactDetector.Candidate?
    for _ in 0 ..< 3 { candidate = detector.process(dart) }
    let tip = try #require(candidate)
    #expect(abs(tip.imageX - 6.5 / 16) < 0.001)
    #expect(abs(tip.imageY - 4.5 / 16) < 0.001)
}

@Test(.tags(.unit, .vision, .regression))
func sawLargeMotionTracksFrameToFrameChange() {
    var detector = ImpactDetector()
    stabilize(&detector)
    _ = detector.process(gridWithBlob(atX: 4, y: 4))
    #expect(!detector.sawLargeMotion)

    let motion = LumaGrid(
        width: gridSize,
        height: gridSize,
        values: Array(repeating: 0.9, count: gridSize * gridSize)
    )!
    _ = detector.process(motion)
    #expect(detector.sawLargeMotion)
    _ = detector.process(motion)
    #expect(!detector.sawLargeMotion)
}

@Test(.tags(.unit, .vision, .regression))
func takeoutNeedsSustainedMotion() {
    var takeout = TakeoutDetector()
    // A brief flicker never adds up to a takeout.
    for frame in 0 ..< 60 {
        let fired = takeout.observe(sceneMotion: frame % 10 == 0)
        #expect(!fired)
    }
    takeout.reset()
    var fired = false
    for _ in 0 ..< 10 {
        fired = takeout.observe(sceneMotion: true)
    }
    #expect(fired)
}

@Test(.tags(.unit, .vision, .regression))
func resetForgetsBaseline() {
    var detector = ImpactDetector()
    stabilize(&detector)
    detector.reset()

    // Without a fresh baseline, a blob cannot be confirmed.
    let blob = gridWithBlob(atX: 4, y: 4)
    for _ in 0 ..< 3 {
        #expect(detector.process(blob) == nil)
    }
}
