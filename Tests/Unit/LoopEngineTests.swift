import Foundation
import Testing
@testable import DartBuddy

@Suite("Loop engine", .tags(.unit, .match, .regression))
struct LoopEngineTests {
    private func makePlayers(_ count: Int = 2) -> [UUID] {
        (0 ..< count).map { _ in UUID() }
    }

    private func miss() -> LoopSubmittedDart {
        LoopEngine.missSubmittedDart(DartInput(multiplier: .single, segment: .miss, isMiss: true))
    }

    @Test
    func loopRequiresAtLeastTwoPlayers() {
        #expect(throws: (any Error).self) {
            _ = try LoopEngine.makeInitialState(
                config: MatchConfigLoop(),
                playerIds: makePlayers(1)
            )
        }
    }

    @Test
    func loopTargetDiffersFromStandardSingle() throws {
        let lowerLoop = LoopWireTargetArea(segment: 6, kind: .lowerLoop)
        let singleSix = LoopWireTargetArea(segment: 6, kind: .standard, ring: .single)
        #expect(lowerLoop != singleSix)
    }

    @Test
    func openingDartSetsWireTarget() throws {
        let players = makePlayers()
        var state = try LoopEngine.makeInitialState(config: MatchConfigLoop(), playerIds: players)
        let submitted = LoopSubmittedDart(
            dart: DartInput(multiplier: .single, segment: .oneToTwenty(6), isMiss: false),
            wireTarget: LoopWireTargetArea(segment: 6, kind: .lowerLoop)
        )
        let outcome = try LoopEngine.submitVisit(state: state, darts: [submitted])
        state = outcome.updatedState
        #expect(state.target == LoopWireTargetArea(segment: 6, kind: .lowerLoop))
        #expect(!state.needsOpeningTarget)
    }

    @Test
    func mustMatchExactWireTarget() throws {
        let players = makePlayers()
        var state = try LoopEngine.makeInitialState(config: MatchConfigLoop(), playerIds: players)
        state = try LoopEngine.submitVisit(
            state: state,
            darts: [
                LoopSubmittedDart(
                    dart: DartInput(multiplier: .single, segment: .oneToTwenty(6), isMiss: false),
                    wireTarget: LoopWireTargetArea(segment: 6, kind: .lowerLoop)
                )
            ]
        ).updatedState

        let wrongWire = LoopSubmittedDart(
            dart: DartInput(multiplier: .single, segment: .oneToTwenty(6), isMiss: false),
            wireTarget: LoopWireTargetArea(segment: 6, kind: .standard, ring: .single)
        )
        let outcome = try LoopEngine.submitVisit(state: state, darts: [wrongWire, miss(), miss()])
        #expect(outcome.event.lifeLost)
        #expect(outcome.updatedState.players[1].lives == 2)
    }

    @Test
    func splitElevenIsDistinctFromSingleEleven() {
        let split = LoopWireTargetArea(segment: 11, kind: .split)
        let single = LoopWireTargetArea(segment: 11, kind: .standard, ring: .single)
        #expect(split != single)
        let candidates = LoopWireTargetArea.candidates(
            for: DartInput(multiplier: .single, segment: .oneToTwenty(11), isMiss: false)
        )
        #expect(candidates.contains(split))
        #expect(candidates.contains(single))
    }
}
