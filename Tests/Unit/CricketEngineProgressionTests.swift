import Foundation
import Testing
@testable import DartBuddy

// Extended coverage for Cricket win detection, overflow scoring rules,
// round advancement, dart limits, and replay determinism.

private func twoCricketPlayers() -> [UUID] { [UUID(), UUID()] }

private func triple(_ value: Int) -> DartInput { DartInput(multiplier: .triple, segment: .oneToTwenty(value)) }
private func single(_ value: Int) -> DartInput { DartInput(multiplier: .single, segment: .oneToTwenty(value)) }
private func miss() -> DartInput { DartInput(multiplier: .single, segment: .miss, isMiss: true) }
private let innerBull = DartInput(multiplier: .single, segment: .innerBull)
private let outerBull = DartInput(multiplier: .single, segment: .outerBull)

private func submit(_ state: CricketState, _ darts: [DartInput]) throws -> CricketState {
    try CricketEngine.submitTurn(state: state, darts: darts).updatedState
}

@Test(.tags(.unit, .cricket, .critical, .offline, .regression))
func cricketDoesNotCompleteWhenOnlyFirstPlayerClosesAllTargets() throws {
    let players = twoCricketPlayers()
    var state = try CricketEngine.makeInitialState(config: MatchConfigCricket(), playerIds: players)

    state = try submit(state, [triple(20), triple(19), triple(18)])
    state = try submit(state, [miss(), miss(), miss()])
    state = try submit(state, [triple(17), triple(16), triple(15)])
    state = try submit(state, [miss(), miss(), miss()])

    let outcome = try CricketEngine.submitTurn(state: state, darts: [innerBull, outerBull])
    #expect(!outcome.updatedState.isComplete)
    #expect(outcome.updatedState.winnerPlayerId == nil)
    #expect(outcome.updatedState.currentPlayerIndex == 1)
}

@Test(.tags(.unit, .cricket, .critical, .offline, .regression))
func cricketCompletesWhenAllPlayersClosedAllTargetsHighestScoreWins() throws {
    let players = twoCricketPlayers()
    var state = try CricketEngine.makeInitialState(config: MatchConfigCricket(), playerIds: players)

    state = try submit(state, [triple(20), triple(19), triple(18)])
    state = try submit(state, [miss(), miss(), miss()])
    state = try submit(state, [triple(17), triple(16), triple(15)])
    state = try submit(state, [miss(), miss(), miss()])
    state = try submit(state, [innerBull, outerBull])
    #expect(!state.isComplete)

    state = try submit(state, [triple(20), triple(19), triple(18)])
    state = try submit(state, [miss(), miss(), miss()])
    state = try submit(state, [triple(17), triple(16), triple(15)])
    state = try submit(state, [miss(), miss(), miss()])

    let outcome = try CricketEngine.submitTurn(state: state, darts: [innerBull, outerBull])
    #expect(outcome.updatedState.isComplete)
    #expect(outcome.updatedState.winnerPlayerId == players[0])
    #expect(outcome.updatedState.players[0].score == 0)
    #expect(outcome.updatedState.players[1].score == 0)
}

@Test(.tags(.unit, .cricket, .critical, .offline, .regression))
func cricketCompletesOnlyAfterEveryPlayerClosesAllTargetsThreePlayers() throws {
    let players = [UUID(), UUID(), UUID()]
    var state = try CricketEngine.makeInitialState(config: MatchConfigCricket(), playerIds: players)

    let sweeps: [[DartInput]] = [
        [triple(20), triple(19), triple(18)],
        [triple(17), triple(16), triple(15)],
        [innerBull, outerBull]
    ]
    var sweepsDone = Array(repeating: 0, count: players.count)

    for turn in 0 ..< (players.count * sweeps.count) {
        let idx = state.currentPlayerIndex
        state = try submit(state, sweeps[sweepsDone[idx]])
        sweepsDone[idx] += 1
        if turn < (players.count * sweeps.count) - 1 {
            #expect(!state.isComplete)
        }
    }

    #expect(state.isComplete)
    #expect(state.winnerPlayerId == players[0])
}

@Test(.tags(.unit, .cricket, .critical, .offline, .regression))
func cricketUIEquivalentTwoPlayerCloseSequenceCompletesMatch() throws {
    let players = twoCricketPlayers()
    var state = try CricketEngine.makeInitialState(config: MatchConfigCricket(), playerIds: players)

    let closeNumbers: [DartInput] = [triple(20), triple(19), triple(18)]
    let closeLowNumbers: [DartInput] = [triple(17), triple(16), triple(15)]
    let closeBull: [DartInput] = [
        DartInput(multiplier: .single, segment: .innerBull),
        DartInput(multiplier: .single, segment: .innerBull)
    ]

    for _ in players {
        state = try submit(state, closeNumbers)
        state = try submit(state, closeLowNumbers)
        state = try submit(state, closeBull)
    }

    #expect(state.isComplete)
    #expect(state.winnerPlayerId == players[0])
}

@Test(.tags(.unit, .cricket, .critical, .offline, .regression))
func cricketHighestScoreWinsWhenBoardFullyClosedNotFirstFinisher() throws {
    let players = twoCricketPlayers()
    var state = try CricketEngine.makeInitialState(config: MatchConfigCricket(), playerIds: players)

    state = try submit(state, [triple(20)])
    state = try submit(state, [miss(), miss(), miss()])
    state = try submit(state, [triple(20)])
    #expect(state.players[0].score == 60)

    state = try submit(state, [triple(20), triple(19), triple(18)])
    state = try submit(state, [triple(20), triple(19), triple(18)])
    state = try submit(state, [triple(17), triple(16), triple(15)])
    state = try submit(state, [triple(17), triple(16), triple(15)])
    state = try submit(state, [innerBull, outerBull])
    state = try submit(state, [innerBull, outerBull])

    #expect(state.isComplete)
    #expect(state.winnerPlayerId == players[0])
    #expect(state.players[0].score == 60)
    #expect(state.players[1].score == 0)
}

@Test(.tags(.unit, .cricket, .critical, .offline, .regression))
func cricketOverflowScoresWhenOpponentStillOpen() throws {
    let players = twoCricketPlayers()
    var state = try CricketEngine.makeInitialState(config: MatchConfigCricket(), playerIds: players)

    state = try submit(state, [triple(20)]) // p0 closes 20
    state = try submit(state, [miss()])      // p1 still open on 20
    let outcome = try CricketEngine.submitTurn(state: state, darts: [triple(20)]) // 3 overflow marks

    #expect(outcome.updatedState.players[0].score == 60) // 3 * 20
}

@Test(.tags(.unit, .cricket, .critical, .offline, .regression))
func cricketNoOverflowScoringWhenOpponentHasClosed() throws {
    let players = twoCricketPlayers()
    var state = try CricketEngine.makeInitialState(config: MatchConfigCricket(), playerIds: players)

    state = try submit(state, [triple(20)]) // p0 closes 20
    state = try submit(state, [triple(20)]) // p1 also closes 20
    let outcome = try CricketEngine.submitTurn(state: state, darts: [triple(20)]) // overflow, but 20 closed for everyone

    #expect(outcome.updatedState.players[0].score == 0)
}

@Test(.tags(.unit, .cricket, .offline, .regression))
func cricketAdvancesRoundIndexAfterFullRound() throws {
    let players = twoCricketPlayers()
    var state = try CricketEngine.makeInitialState(config: MatchConfigCricket(), playerIds: players)

    state = try submit(state, [single(20)]) // p0; round still 0
    #expect(state.roundIndex == 0)
    state = try submit(state, [single(20)]) // p1 closes the round
    #expect(state.roundIndex == 1)
    #expect(state.currentPlayerIndex == 0)
}

@Test(.tags(.unit, .cricket, .offline, .regression))
func cricketRejectsMoreThanThreeDarts() throws {
    let players = twoCricketPlayers()
    let state = try CricketEngine.makeInitialState(config: MatchConfigCricket(), playerIds: players)

    #expect(throws: AppError.self) {
        _ = try CricketEngine.submitTurn(state: state, darts: [single(20), single(20), single(20), single(20)])
    }
}

@Test(.tags(.unit, .cricket, .critical, .offline, .regression))
func cricketReplayReconstructsIdenticalState() throws {
    let players = twoCricketPlayers()
    let config = MatchConfigCricket()
    var state = try CricketEngine.makeInitialState(config: config, playerIds: players)

    var events: [CricketTurnEvent] = []
    let turns: [[DartInput]] = [
        [triple(20), single(20), single(19)],
        [single(20), miss(), triple(18)],
        [innerBull, outerBull, single(17)]
    ]
    for darts in turns {
        let outcome = try CricketEngine.submitTurn(state: state, darts: darts)
        state = outcome.updatedState
        events.append(outcome.event)
    }

    let replayed = try CricketEngine.replay(config: config, playerIds: players, events: events)
    #expect(replayed == state)
}

@Test(.tags(.unit, .cricket, .critical, .offline, .regression))
func cricketReplayPreservesInnerBullMarks() throws {
    // Regression: inner bull = 2 marks must survive persistence/replay rather
    // than collapsing to an outer bull (1 mark) via the lossy target mapping.
    let players = twoCricketPlayers()
    let config = MatchConfigCricket()
    var state = try CricketEngine.makeInitialState(config: config, playerIds: players)

    // Two inner bulls (2 + 2 marks, capped at 3) close the bull in one turn.
    let outcome = try CricketEngine.submitTurn(state: state, darts: [innerBull, innerBull])
    state = outcome.updatedState
    #expect(state.players[0].marks["bull"] == 3)

    let replayed = try CricketEngine.replay(config: config, playerIds: players, events: [outcome.event])
    #expect(replayed.players[0].marks["bull"] == 3)
    #expect(replayed == state)

    // A persisted touch must record the precise segment, not just the target.
    #expect(outcome.event.targetsTouched.first?.segmentRaw == "innerBull")
}
