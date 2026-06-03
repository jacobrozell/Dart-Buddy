import Foundation
import Testing
@testable import DartsScoreboard

// Unit coverage for the lowest-level scoring primitive shared by both engines.

@Test(.tags(.unit, .scoringInput, .offline, .regression))
func dartPointsHonorMultipliersAndBulls() {
    #expect(DartInput(multiplier: .single, segment: .oneToTwenty(5)).points == 5)
    #expect(DartInput(multiplier: .double, segment: .oneToTwenty(20)).points == 40)
    #expect(DartInput(multiplier: .triple, segment: .oneToTwenty(20)).points == 60)
    #expect(DartInput(multiplier: .single, segment: .outerBull).points == 25)
    #expect(DartInput(multiplier: .single, segment: .innerBull).points == 50)
}

@Test(.tags(.unit, .scoringInput, .offline, .regression))
func dartMissAlwaysScoresZero() {
    #expect(DartInput(multiplier: .triple, segment: .oneToTwenty(20), isMiss: true).points == 0)
    #expect(DartInput(multiplier: .single, segment: .miss).points == 0)
}

@Test(.tags(.unit, .scoringInput, .cricket, .offline, .regression))
func dartCricketTargetMappingOnlyCoversValidTargets() {
    #expect(DartSegment.oneToTwenty(20).cricketTargetRaw == "20")
    #expect(DartSegment.oneToTwenty(15).cricketTargetRaw == "15")
    #expect(DartSegment.outerBull.cricketTargetRaw == "bull")
    #expect(DartSegment.innerBull.cricketTargetRaw == "bull")
    // Numbers below 15 and misses are not cricket targets.
    #expect(DartSegment.oneToTwenty(14).cricketTargetRaw == nil)
    #expect(DartSegment.miss.cricketTargetRaw == nil)
}

@Test(.tags(.unit, .scoringInput, .offline, .regression))
func dartMultiplierMarkValues() {
    #expect(DartMultiplier.single.markValue == 1)
    #expect(DartMultiplier.double.markValue == 2)
    #expect(DartMultiplier.triple.markValue == 3)
}
