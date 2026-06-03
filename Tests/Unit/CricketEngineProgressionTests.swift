import Foundation
import Testing
@testable import DartBuddy

// Extended coverage for Cricket win detection, overflow scoring rules,
// round advancement, dart limits, and replay determinism.

@Test(.tags(.unit, .cricket, .critical, .offline, .regression))
func cricketDoesNotCompleteWhenOnlyFirstPlayerClosesAllTargets() throws {
    let players = cricketPlayerIds(count: 2)
    var state = try CricketEngine.makeInitialState(config: MatchConfigCricket(), playerIds: players)

    state = try CricketTestDarts.submit(state, [CricketTestDarts.triple(20), CricketTestDarts.triple(19), CricketTestDarts.triple(18)])
    state = try CricketTestDarts.submit(state, [CricketTestDarts.miss(), CricketTestDarts.miss(), CricketTestDarts.miss()])
    state = try CricketTestDarts.submit(state, [CricketTestDarts.triple(17), CricketTestDarts.triple(16), CricketTestDarts.triple(15)])
    state = try CricketTestDarts.submit(state, [CricketTestDarts.miss(), CricketTestDarts.miss(), CricketTestDarts.miss()])

    let outcome = try CricketEngine.submitTurn(state: state, darts: [CricketTestDarts.innerBull, CricketTestDarts.outerBull])
    #expect(!outcome.updatedState.isComplete)
    #expect(outcome.updatedState.winnerPlayerId == nil)
    #expect(outcome.updatedState.currentPlayerIndex == 1)
}

@Test(.tags(.unit, .cricket, .critical, .offline, .regression))
func cricketCompletesWhenAllPlayersClosedAllTargetsHighestScoreWins() throws {
    let players = cricketPlayerIds(count: 2)
    var state = try CricketEngine.makeInitialState(config: MatchConfigCricket(), playerIds: players)

    state = try CricketTestDarts.submit(state, [CricketTestDarts.triple(20), CricketTestDarts.triple(19), CricketTestDarts.triple(18)])
    state = try CricketTestDarts.submit(state, [CricketTestDarts.miss(), CricketTestDarts.miss(), CricketTestDarts.miss()])
    state = try CricketTestDarts.submit(state, [CricketTestDarts.triple(17), CricketTestDarts.triple(16), CricketTestDarts.triple(15)])
    state = try CricketTestDarts.submit(state, [CricketTestDarts.miss(), CricketTestDarts.miss(), CricketTestDarts.miss()])
    state = try CricketTestDarts.submit(state, [CricketTestDarts.innerBull, CricketTestDarts.outerBull])
    #expect(!state.isComplete)

    state = try CricketTestDarts.submit(state, [CricketTestDarts.triple(20), CricketTestDarts.triple(19), CricketTestDarts.triple(18)])
    state = try CricketTestDarts.submit(state, [CricketTestDarts.miss(), CricketTestDarts.miss(), CricketTestDarts.miss()])
    state = try CricketTestDarts.submit(state, [CricketTestDarts.triple(17), CricketTestDarts.triple(16), CricketTestDarts.triple(15)])
    state = try CricketTestDarts.submit(state, [CricketTestDarts.miss(), CricketTestDarts.miss(), CricketTestDarts.miss()])

    let outcome = try CricketEngine.submitTurn(state: state, darts: [CricketTestDarts.innerBull, CricketTestDarts.outerBull])
    #expect(outcome.updatedState.isComplete)
    #expect(outcome.updatedState.winnerPlayerId == players[0])
    #expect(outcome.updatedState.players[0].score == 0)
    #expect(outcome.updatedState.players[1].score == 0)
}

@Test(.tags(.unit, .cricket, .critical, .offline, .regression))
func cricketCompletesWhenAllThreePlayersCloseAllTargets() throws {
    let players = cricketPlayerIds(count: 3)
    var state = try CricketEngine.makeInitialState(config: MatchConfigCricket(), playerIds: players)

    for playerIndex in 0 ..< players.count {
        state = try CricketTestDarts.closeAllTargetsForCurrentPlayer(state, playerCount: players.count)
        if playerIndex < players.count - 1 {
            #expect(!state.isComplete)
            #expect(state.winnerPlayerId == nil)
        }
    }

    #expect(state.isComplete)
    #expect(state.winnerPlayerId == players[0])
}

@Test(.tags(.unit, .cricket, .critical, .offline, .regression))
func cricketUIEquivalentTwoPlayerCloseSequenceCompletesMatch() throws {
    let players = cricketPlayerIds(count: 2)
    var state = try CricketEngine.makeInitialState(config: MatchConfigCricket(), playerIds: players)

    let closeNumbers: [DartInput] = [CricketTestDarts.triple(20), CricketTestDarts.triple(19), CricketTestDarts.triple(18)]
    let closeLowNumbers: [DartInput] = [CricketTestDarts.triple(17), CricketTestDarts.triple(16), CricketTestDarts.triple(15)]
    let closeBull: [DartInput] = [
        DartInput(multiplier: .single, segment: .innerBull),
        DartInput(multiplier: .single, segment: .innerBull)
    ]

    for _ in players {
        state = try CricketTestDarts.submit(state, closeNumbers)
        state = try CricketTestDarts.submit(state, closeLowNumbers)
        state = try CricketTestDarts.submit(state, closeBull)
    }

    #expect(state.isComplete)
    #expect(state.winnerPlayerId == players[0])
}

@Test(.tags(.unit, .cricket, .critical, .offline, .regression))
func cricketHighestScoreWinsWhenBoardFullyClosedNotFirstFinisher() throws {
    let players = cricketPlayerIds(count: 2)
    var state = try CricketEngine.makeInitialState(config: MatchConfigCricket(), playerIds: players)

    state = try CricketTestDarts.submit(state, [CricketTestDarts.triple(20)])
    state = try CricketTestDarts.submit(state, [CricketTestDarts.miss(), CricketTestDarts.miss(), CricketTestDarts.miss()])
    state = try CricketTestDarts.submit(state, [CricketTestDarts.triple(20)])
    #expect(state.players[0].score == 60)

    state = try CricketTestDarts.submit(state, [CricketTestDarts.triple(20), CricketTestDarts.triple(19), CricketTestDarts.triple(18)])
    state = try CricketTestDarts.submit(state, [CricketTestDarts.triple(20), CricketTestDarts.triple(19), CricketTestDarts.triple(18)])
    state = try CricketTestDarts.submit(state, [CricketTestDarts.triple(17), CricketTestDarts.triple(16), CricketTestDarts.triple(15)])
    state = try CricketTestDarts.submit(state, [CricketTestDarts.triple(17), CricketTestDarts.triple(16), CricketTestDarts.triple(15)])
    state = try CricketTestDarts.submit(state, [CricketTestDarts.innerBull, CricketTestDarts.outerBull])
    state = try CricketTestDarts.submit(state, [CricketTestDarts.innerBull, CricketTestDarts.outerBull])

    #expect(state.isComplete)
    #expect(state.winnerPlayerId == players[0])
    #expect(state.players[0].score == 60)
    #expect(state.players[1].score == 0)
}

@Test(.tags(.unit, .cricket, .critical, .offline, .regression))
func cricketOverflowScoresWhenOpponentStillOpen() throws {
    let players = cricketPlayerIds(count: 2)
    var state = try CricketEngine.makeInitialState(config: MatchConfigCricket(), playerIds: players)

    state = try CricketTestDarts.submit(state, [CricketTestDarts.triple(20)]) // p0 closes 20
    state = try CricketTestDarts.submit(state, [CricketTestDarts.miss()])      // p1 still open on 20
    let outcome = try CricketEngine.submitTurn(state: state, darts: [CricketTestDarts.triple(20)]) // 3 overflow marks

    #expect(outcome.updatedState.players[0].score == 60) // 3 * 20
}

@Test(.tags(.unit, .cricket, .critical, .offline, .regression))
func cricketNoOverflowScoringWhenOpponentHasClosed() throws {
    let players = cricketPlayerIds(count: 2)
    var state = try CricketEngine.makeInitialState(config: MatchConfigCricket(), playerIds: players)

    state = try CricketTestDarts.submit(state, [CricketTestDarts.triple(20)]) // p0 closes 20
    state = try CricketTestDarts.submit(state, [CricketTestDarts.triple(20)]) // p1 also closes 20
    let outcome = try CricketEngine.submitTurn(state: state, darts: [CricketTestDarts.triple(20)]) // overflow, but 20 closed for everyone

    #expect(outcome.updatedState.players[0].score == 0)
}

@Test(.tags(.unit, .cricket, .offline, .regression))
func cricketAdvancesRoundIndexAfterFullRound() throws {
    let players = cricketPlayerIds(count: 2)
    var state = try CricketEngine.makeInitialState(config: MatchConfigCricket(), playerIds: players)

    state = try CricketTestDarts.submit(state, [CricketTestDarts.single(20)]) // p0; round still 0
    #expect(state.roundIndex == 0)
    state = try CricketTestDarts.submit(state, [CricketTestDarts.single(20)]) // p1 closes the round
    #expect(state.roundIndex == 1)
    #expect(state.currentPlayerIndex == 0)
}

@Test(.tags(.unit, .cricket, .offline, .regression))
func cricketRejectsMoreThanThreeDarts() throws {
    let players = cricketPlayerIds(count: 2)
    let state = try CricketEngine.makeInitialState(config: MatchConfigCricket(), playerIds: players)

    #expect(throws: AppError.self) {
        _ = try CricketEngine.submitTurn(state: state, darts: [CricketTestDarts.single(20), CricketTestDarts.single(20), CricketTestDarts.single(20), CricketTestDarts.single(20)])
    }
}

@Test(.tags(.unit, .cricket, .critical, .offline, .regression))
func cricketReplayReconstructsIdenticalState() throws {
    let players = cricketPlayerIds(count: 2)
    let config = MatchConfigCricket()
    var state = try CricketEngine.makeInitialState(config: config, playerIds: players)

    var events: [CricketTurnEvent] = []
    let turns: [[DartInput]] = [
        [CricketTestDarts.triple(20), CricketTestDarts.single(20), CricketTestDarts.single(19)],
        [CricketTestDarts.single(20), CricketTestDarts.miss(), CricketTestDarts.triple(18)],
        [CricketTestDarts.innerBull, CricketTestDarts.outerBull, CricketTestDarts.single(17)]
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
    let players = cricketPlayerIds(count: 2)
    let config = MatchConfigCricket()
    var state = try CricketEngine.makeInitialState(config: config, playerIds: players)

    // Two inner bulls (2 + 2 marks, capped at 3) close the bull in one turn.
    let outcome = try CricketEngine.submitTurn(state: state, darts: [CricketTestDarts.innerBull, CricketTestDarts.innerBull])
    state = outcome.updatedState
    #expect(state.players[0].marks["bull"] == 3)

    let replayed = try CricketEngine.replay(config: config, playerIds: players, events: [outcome.event])
    #expect(replayed.players[0].marks["bull"] == 3)
    #expect(replayed == state)

    // A persisted touch must record the precise segment, not just the target.
    #expect(outcome.event.targetsTouched.first?.segmentRaw == "CricketTestDarts.innerBull")
}

// MARK: - 3+ player coverage

@Test(.tags(.unit, .cricket, .offline, .regression))
func cricketRotatesTurnOrderThroughThreePlayers() throws {
    let players = cricketPlayerIds(count: 3)
    var state = try CricketEngine.makeInitialState(config: MatchConfigCricket(), playerIds: players)

    #expect(state.currentPlayerIndex == 0)
    #expect(state.roundIndex == 0)

    state = try CricketTestDarts.submit(state, [CricketTestDarts.miss(), CricketTestDarts.miss(), CricketTestDarts.miss()])
    #expect(state.currentPlayerIndex == 1)
    #expect(state.roundIndex == 0)

    state = try CricketTestDarts.submit(state, [CricketTestDarts.miss(), CricketTestDarts.miss(), CricketTestDarts.miss()])
    #expect(state.currentPlayerIndex == 2)
    #expect(state.roundIndex == 0)

    state = try CricketTestDarts.submit(state, [CricketTestDarts.miss(), CricketTestDarts.miss(), CricketTestDarts.miss()])
    #expect(state.currentPlayerIndex == 0)
    #expect(state.roundIndex == 1)
}

@Test(.tags(.unit, .cricket, .offline, .regression))
func cricketAdvancesRoundIndexAfterFourPlayerRound() throws {
    let players = cricketPlayerIds(count: 4)
    var state = try CricketEngine.makeInitialState(config: MatchConfigCricket(), playerIds: players)

    #expect(state.roundIndex == 0)
    for expectedIndex in 1 ..< 4 {
        state = try CricketTestDarts.submit(state, [CricketTestDarts.miss(), CricketTestDarts.miss(), CricketTestDarts.miss()])
        #expect(state.currentPlayerIndex == expectedIndex)
        #expect(state.roundIndex == 0)
    }

    state = try CricketTestDarts.submit(state, [CricketTestDarts.miss(), CricketTestDarts.miss(), CricketTestDarts.miss()])
    #expect(state.currentPlayerIndex == 0)
    #expect(state.roundIndex == 1)
}

@Test(.tags(.unit, .cricket, .critical, .offline, .regression))
func cricketDoesNotCompleteWhenOnlyOneOfThreePlayersClosesAllTargets() throws {
    let players = cricketPlayerIds(count: 3)
    var state = try CricketEngine.makeInitialState(config: MatchConfigCricket(), playerIds: players)

    state = try CricketTestDarts.closeAllTargetsForCurrentPlayer(state, playerCount: players.count)

    #expect(!state.isComplete)
    #expect(state.winnerPlayerId == nil)
    #expect(state.currentPlayerIndex == 1)
}

@Test(.tags(.unit, .cricket, .critical, .offline, .regression))
func cricketThreeWayTieBreakUsesEarliestSeat() throws {
    let players = cricketPlayerIds(count: 3)
    var state = try CricketEngine.makeInitialState(config: MatchConfigCricket(), playerIds: players)

    state = try CricketTestDarts.runSynchronizedCloseSweep(state, playerCount: players.count)

    #expect(state.isComplete)
    #expect(state.players.allSatisfy { $0.score == 0 })
    #expect(state.winnerPlayerId == players[0])
}

@Test(.tags(.unit, .cricket, .critical, .offline, .regression))
func cricketOverflowScoresWhenAnyOfThreeOpponentsStillOpen() throws {
    let players = cricketPlayerIds(count: 3)
    var state = try CricketEngine.makeInitialState(config: MatchConfigCricket(), playerIds: players)

    state = try CricketTestDarts.submit(state, [CricketTestDarts.triple(20)]) // p0 closes 20
    state = try CricketTestDarts.submit(state, [CricketTestDarts.miss()])      // p1 still open
    state = try CricketTestDarts.submit(state, [CricketTestDarts.miss()])      // p2 still open
    let overflowOutcome = try CricketEngine.submitTurn(state: state, darts: [CricketTestDarts.triple(20)])
    #expect(overflowOutcome.updatedState.players[0].score == 60)

    state = overflowOutcome.updatedState
    state = try CricketTestDarts.submit(state, [CricketTestDarts.triple(20)]) // p1 closes 20
    state = try CricketTestDarts.submit(state, [CricketTestDarts.triple(20)]) // p2 closes 20
    let noScoreOutcome = try CricketEngine.submitTurn(state: state, darts: [CricketTestDarts.triple(20)])
    #expect(noScoreOutcome.updatedState.players[0].score == 60)
}

@Test(.tags(.unit, .cricket, .critical, .offline, .regression))
func cricketReplayReconstructsThreePlayerState() throws {
    let players = cricketPlayerIds(count: 3)
    let config = MatchConfigCricket()
    var state = try CricketEngine.makeInitialState(config: config, playerIds: players)

    var events: [CricketTurnEvent] = []
    let turns: [[DartInput]] = [
        [CricketTestDarts.triple(20), CricketTestDarts.single(19), CricketTestDarts.miss()],
        [CricketTestDarts.single(20), CricketTestDarts.miss(), CricketTestDarts.triple(18)],
        [CricketTestDarts.innerBull, CricketTestDarts.outerBull, CricketTestDarts.single(17)],
        [CricketTestDarts.triple(16), CricketTestDarts.miss(), CricketTestDarts.miss()]
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
func cricketUIEquivalentThreePlayerSynchronizedSweepCompletesMatch() throws {
    let players = cricketPlayerIds(count: 3)
    var state = try CricketEngine.makeInitialState(config: MatchConfigCricket(), playerIds: players)
    let uiBullClose: [DartInput] = [
        DartInput(multiplier: .single, segment: .innerBull),
        DartInput(multiplier: .single, segment: .outerBull)
    ]
    let sweeps: [[DartInput]] = [
        [CricketTestDarts.triple(20), CricketTestDarts.triple(19), CricketTestDarts.triple(18)],
        [CricketTestDarts.triple(17), CricketTestDarts.triple(16), CricketTestDarts.triple(15)],
        uiBullClose
    ]
    var sweepsDone = Array(repeating: 0, count: players.count)
    for _ in 0 ..< (players.count * sweeps.count) {
        let idx = state.currentPlayerIndex
        state = try CricketTestDarts.submit(state, sweeps[sweepsDone[idx]])
        sweepsDone[idx] += 1
    }

    #expect(state.isComplete)
    #expect(state.winnerPlayerId == players[0])
}
