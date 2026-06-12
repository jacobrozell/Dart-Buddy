import Testing
@testable import DartBuddy

@Test(.tags(.unit, .vision, .regression))
func innerBullScoresFifty() {
    let dart = DartboardGeometry.dartInput(at: BoardPoint(x: 0.0, y: 0.02))
    #expect(dart.segment == .innerBull)
    #expect(dart.points == 50)
}

@Test(.tags(.unit, .vision, .regression))
func outerBullScoresTwentyFive() {
    let dart = DartboardGeometry.dartInput(at: BoardPoint(x: 0.06, y: 0.0))
    #expect(dart.segment == .outerBull)
    #expect(dart.points == 25)
}

@Test(.tags(.unit, .vision, .regression))
func straightUpSingleTwenty() {
    let dart = DartboardGeometry.dartInput(at: BoardPoint(x: 0.0, y: 0.4))
    #expect(dart == DartInput(multiplier: .single, segment: .oneToTwenty(20)))
}

@Test(.tags(.unit, .vision, .regression))
func tripleRingScoresTripleTwenty() {
    let dart = DartboardGeometry.dartInput(at: BoardPoint(x: 0.0, y: 0.606))
    #expect(dart == DartInput(multiplier: .triple, segment: .oneToTwenty(20)))
    #expect(dart.points == 60)
}

@Test(.tags(.unit, .vision, .regression))
func doubleRingScoresDoubleTwenty() {
    let dart = DartboardGeometry.dartInput(at: BoardPoint(x: 0.0, y: 0.977))
    #expect(dart == DartInput(multiplier: .double, segment: .oneToTwenty(20)))
    #expect(dart.points == 40)
}

@Test(.tags(.unit, .vision, .regression))
func outsideDoubleRingIsMiss() {
    let dart = DartboardGeometry.dartInput(at: BoardPoint(x: 0.0, y: 1.05))
    #expect(dart.isMiss)
    #expect(dart.points == 0)
}

@Test(.tags(.unit, .vision, .regression))
func wedgeCentersMatchSegmentWheel() {
    for (index, expected) in DartboardGeometry.segmentWheel.enumerated() {
        let angle = Double(index) * DartboardGeometry.wedgeAngleDegrees
        #expect(DartboardGeometry.segmentValue(atAngleDegrees: angle) == expected)
    }
}

@Test(.tags(.unit, .vision, .regression))
func wedgeBoundariesResolveToNeighbors() {
    // The 20 wedge spans 351°...9°; 1 sits clockwise of it and 5 counterclockwise.
    #expect(DartboardGeometry.segmentValue(atAngleDegrees: 8.9) == 20)
    #expect(DartboardGeometry.segmentValue(atAngleDegrees: 9.1) == 1)
    #expect(DartboardGeometry.segmentValue(atAngleDegrees: 351.1) == 20)
    #expect(DartboardGeometry.segmentValue(atAngleDegrees: 350.9) == 5)
}

@Test(.tags(.unit, .vision, .regression))
func angleMeasuredClockwiseFromTop() {
    #expect(abs(DartboardGeometry.angleDegrees(of: BoardPoint(x: 0.0, y: 1.0)) - 0) < 0.001)
    #expect(abs(DartboardGeometry.angleDegrees(of: BoardPoint(x: 1.0, y: 0.0)) - 90) < 0.001)
    #expect(abs(DartboardGeometry.angleDegrees(of: BoardPoint(x: 0.0, y: -1.0)) - 180) < 0.001)
    #expect(abs(DartboardGeometry.angleDegrees(of: BoardPoint(x: -1.0, y: 0.0)) - 270) < 0.001)
}

@Test(.tags(.unit, .vision, .regression))
func rightOfCenterHitsSix() {
    // 6 sits at 90° clockwise from the top on a standard board.
    let dart = DartboardGeometry.dartInput(at: BoardPoint(x: 0.4, y: 0.0))
    #expect(dart == DartInput(multiplier: .single, segment: .oneToTwenty(6)))
}
