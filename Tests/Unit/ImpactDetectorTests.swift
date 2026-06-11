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
