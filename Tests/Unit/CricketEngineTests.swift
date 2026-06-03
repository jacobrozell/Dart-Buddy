import Foundation
import Testing
@testable import DartsScoreboard

@Test(.tags(.unit, .cricket, .critical, .offline, .regression))
func cricketClosureAndOverflowScoring() throws {
    let players = [UUID(), UUID()]
    let config = MatchConfigCricket()
    var state = try CricketEngine.makeInitialState(config: config, playerIds: players)

    // Player 1 closes 20.
    state = try CricketEngine.submitTurn(
        state: state,
        darts: [
            DartInput(multiplier: .triple, segment: .oneToTwenty(20))
        ]
    ).updatedState

    // Player 2 misses.
    state = try CricketEngine.submitTurn(state: state, darts: []).updatedState

    // Player 1 throws triple 20 on closed target; opponent still open, so score 60.
    let outcome = try CricketEngine.submitTurn(
        state: state,
        darts: [DartInput(multiplier: .triple, segment: .oneToTwenty(20))]
    )

    #expect(outcome.updatedState.players[0].score == 60)
}

@Test(.tags(.unit, .cricket, .critical, .offline, .regression))
func cricketBullMarksMapOuterAndInnerCorrectly() throws {
    let players = [UUID(), UUID()]
    let config = MatchConfigCricket()
    let state = try CricketEngine.makeInitialState(config: config, playerIds: players)

    let outcome = try CricketEngine.submitTurn(
        state: state,
        darts: [
            DartInput(multiplier: .single, segment: .outerBull),
            DartInput(multiplier: .double, segment: .innerBull)
        ]
    )

    let marks = outcome.updatedState.players[0].marks["bull"] ?? 0
    #expect(marks == 3)
}
