import Foundation
import Testing
@testable import DartBuddy

// Geometry coverage for the visual dartboard input. Taps are expressed on a board
// centered at (0, 0) with radius 100, so coordinates read as fractions of the radius.

private func resolve(x: Double, y: Double) -> DartInput? {
    BoardHitResolver.dartInput(x: x, y: y, centerX: 0, centerY: 0, radius: 100)
}

@Test(.tags(.unit, .scoringInput, .offline, .regression))
func boardCenterResolvesBulls() {
    #expect(resolve(x: 0, y: 0) == DartInput(multiplier: .single, segment: .innerBull))
    #expect(resolve(x: 0, y: -5) == DartInput(multiplier: .single, segment: .innerBull))
    // Between the bull rings: outer bull.
    #expect(resolve(x: 0, y: -12) == DartInput(multiplier: .single, segment: .outerBull))
    #expect(resolve(x: 12, y: 0) == DartInput(multiplier: .single, segment: .outerBull))
}

@Test(.tags(.unit, .scoringInput, .offline, .regression))
func boardTopWedgeResolvesTwentyAcrossRings() {
    // Straight up from center at increasing radii: single, triple, single, double.
    #expect(resolve(x: 0, y: -30) == DartInput(multiplier: .single, segment: .oneToTwenty(20)))
    #expect(resolve(x: 0, y: -55) == DartInput(multiplier: .triple, segment: .oneToTwenty(20)))
    #expect(resolve(x: 0, y: -75) == DartInput(multiplier: .single, segment: .oneToTwenty(20)))
    #expect(resolve(x: 0, y: -95) == DartInput(multiplier: .double, segment: .oneToTwenty(20)))
}

@Test(.tags(.unit, .scoringInput, .offline, .regression))
func boardCardinalDirectionsMatchStandardClockLayout() {
    // 3 o'clock is the 6 wedge, 6 o'clock the 3 wedge, 9 o'clock the 11 wedge.
    #expect(resolve(x: 95, y: 0) == DartInput(multiplier: .double, segment: .oneToTwenty(6)))
    #expect(resolve(x: 0, y: 95) == DartInput(multiplier: .double, segment: .oneToTwenty(3)))
    #expect(resolve(x: -95, y: 0) == DartInput(multiplier: .double, segment: .oneToTwenty(11)))
}

@Test(.tags(.unit, .scoringInput, .offline, .regression))
func boardWedgeBoundariesSplitTwentyAndNeighbors() {
    let wedgeAngle = 2 * Double.pi / 20
    // Just inside each side of the 20 wedge (centered at the top, spanning ±9°).
    let insideRight = wedgeAngle / 2 - 0.01
    let insideLeft = -wedgeAngle / 2 + 0.01
    #expect(BoardHitResolver.segmentValue(forAngle: insideRight) == 20)
    #expect(BoardHitResolver.segmentValue(forAngle: insideLeft) == 20)
    // Just past the boundary: 1 clockwise, 5 counterclockwise.
    #expect(BoardHitResolver.segmentValue(forAngle: wedgeAngle / 2 + 0.01) == 1)
    #expect(BoardHitResolver.segmentValue(forAngle: -wedgeAngle / 2 - 0.01) == 5)
    // Full-turn wrap maps back onto the same wedge.
    #expect(BoardHitResolver.segmentValue(forAngle: 2 * Double.pi) == 20)
    #expect(BoardHitResolver.segmentValue(forAngle: -2 * Double.pi) == 20)
}

@Test(.tags(.unit, .scoringInput, .offline, .regression))
func boardTapsOutsidePlayableCircleResolveToNothing() {
    #expect(resolve(x: 0, y: -101) == nil)
    #expect(resolve(x: 80, y: 80) == nil)
    #expect(BoardHitResolver.dartInput(x: 0, y: 0, centerX: 0, centerY: 0, radius: 0) == nil)
}

@Test(.tags(.unit, .scoringInput, .offline, .regression))
func boardRingBandsCoverTheFullRadius() {
    #expect(BoardHitResolver.ring(forNormalizedRadius: 0.0) == .innerBull)
    #expect(BoardHitResolver.ring(forNormalizedRadius: 0.1) == .outerBull)
    #expect(BoardHitResolver.ring(forNormalizedRadius: 0.3) == .innerSingle)
    #expect(BoardHitResolver.ring(forNormalizedRadius: 0.5) == .triple)
    #expect(BoardHitResolver.ring(forNormalizedRadius: 0.7) == .outerSingle)
    #expect(BoardHitResolver.ring(forNormalizedRadius: 0.95) == .double)
    #expect(BoardHitResolver.ring(forNormalizedRadius: 1.0) == .double)
    #expect(BoardHitResolver.ring(forNormalizedRadius: 1.01) == .outsideBoard)
}

@Test(.tags(.unit, .scoringInput, .offline, .regression))
func boardSegmentOrderIsTheRegulationClock() {
    #expect(BoardHitResolver.segmentOrder.count == 20)
    #expect(Set(BoardHitResolver.segmentOrder) == Set(1 ... 20))
    #expect(BoardHitResolver.segmentOrder.first == 20)
}

@Test(.tags(.unit, .scoringInput, .settings, .offline, .regression))
func dartEntryPresentationFallsBackToNumberPad() {
    #expect(DartEntryPresentation(rawValueOrDefault: nil) == .numberPad)
    #expect(DartEntryPresentation(rawValueOrDefault: "garbage") == .numberPad)
    #expect(DartEntryPresentation(rawValueOrDefault: "visualBoard") == .visualBoard)
    #expect(DartEntryPresentation.numberPad.toggled == .visualBoard)
    #expect(DartEntryPresentation.visualBoard.toggled == .numberPad)
}
