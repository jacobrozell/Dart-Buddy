import Foundation
import Testing
@testable import DartBuddy

// MARK: - Helpers

private func bull(_ segment: DartSegment) -> DartInput {
    DartInput(multiplier: .single, segment: segment)
}

private func dbl(_ value: Int) -> DartInput {
    DartInput(multiplier: .double, segment: .oneToTwenty(value))
}

private func sng(_ value: Int) -> DartInput {
    DartInput(multiplier: .single, segment: .oneToTwenty(value))
}

private func trp(_ value: Int) -> DartInput {
    DartInput(multiplier: .triple, segment: .oneToTwenty(value))
}

private func miss() -> DartInput {
    DartInput(multiplier: .single, segment: .miss, isMiss: true)
}

// MARK: - Kickoff gate

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func footballKickoffGateBlocksGoalsUntilBullHit() throws {
    let p1 = UUID()
    let p2 = UUID()
    let config = MatchConfigFootball(goalsToWin: 10, kickoffMode: .singleBull)
    var state = try FootballEngine.makeInitialState(config: config, playerIds: [p1, p2])

    // Player 1 throws doubles but has not kicked off yet — no goals
    let outcome = try FootballEngine.submitTurn(state: state, darts: [dbl(20), dbl(18), dbl(16)])
    #expect(outcome.event.goalsAdded == 0)
    #expect(outcome.updatedState.players[0].goals == 0)
    #expect(outcome.updatedState.players[0].kickoffComplete == false)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func footballSingleBullCompletesKickoff() throws {
    let p1 = UUID()
    let p2 = UUID()
    let config = MatchConfigFootball(goalsToWin: 10, kickoffMode: .singleBull)
    var state = try FootballEngine.makeInitialState(config: config, playerIds: [p1, p2])

    // Player 1 hits outer bull — kickoff complete
    let outcome = try FootballEngine.submitTurn(state: state, darts: [miss(), bull(.outerBull), miss()])
    #expect(outcome.event.kickoffAchieved == true)
    #expect(outcome.updatedState.players[0].kickoffComplete == true)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func footballInnerBullCompletesKickoffSingleBullMode() throws {
    let p1 = UUID()
    let p2 = UUID()
    let config = MatchConfigFootball(goalsToWin: 10, kickoffMode: .singleBull)
    var state = try FootballEngine.makeInitialState(config: config, playerIds: [p1, p2])

    let outcome = try FootballEngine.submitTurn(state: state, darts: [bull(.innerBull), miss(), miss()])
    #expect(outcome.event.kickoffAchieved == true)
    #expect(outcome.updatedState.players[0].kickoffComplete == true)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func footballTwoOuterBullsModeRequiresTwoHits() throws {
    let p1 = UUID()
    let p2 = UUID()
    let config = MatchConfigFootball(goalsToWin: 10, kickoffMode: .twoOuterBulls)
    var state = try FootballEngine.makeInitialState(config: config, playerIds: [p1, p2])

    // First outer bull — not yet kicked off
    state = try FootballEngine.submitTurn(state: state, darts: [bull(.outerBull), miss(), miss()]).updatedState
    // Advance to p2's turn; take p2's turn then come back to p1
    state = try FootballEngine.submitTurn(state: state, darts: [miss(), miss(), miss()]).updatedState

    #expect(state.players[0].kickoffComplete == false)
    #expect(state.players[0].kickoffProgress == 1)

    // Second outer bull — kickoff complete
    let outcome = try FootballEngine.submitTurn(state: state, darts: [bull(.outerBull), miss(), miss()])
    #expect(outcome.event.kickoffAchieved == true)
    #expect(outcome.updatedState.players[0].kickoffComplete == true)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func footballTwoOuterBullsModeInnerBullCountsAsImmediate() throws {
    let p1 = UUID()
    let p2 = UUID()
    let config = MatchConfigFootball(goalsToWin: 10, kickoffMode: .twoOuterBulls)
    var state = try FootballEngine.makeInitialState(config: config, playerIds: [p1, p2])

    // One inner bull should complete kickoff even in twoOuterBulls mode
    let outcome = try FootballEngine.submitTurn(state: state, darts: [bull(.innerBull), miss(), miss()])
    #expect(outcome.event.kickoffAchieved == true)
    #expect(outcome.updatedState.players[0].kickoffComplete == true)
}

// MARK: - Goal counting

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func footballDoubleScoresGoalAfterKickoff() throws {
    let p1 = UUID()
    let p2 = UUID()
    let config = MatchConfigFootball(goalsToWin: 10)
    // Pre-kick p1 off
    var state = try FootballEngine.makeInitialState(config: config, playerIds: [p1, p2])
    state = try FootballEngine.submitTurn(state: state, darts: [bull(.outerBull), miss(), miss()]).updatedState
    // p2 turn
    state = try FootballEngine.submitTurn(state: state, darts: [miss(), miss(), miss()]).updatedState

    // p1 scoring: 2 doubles
    let outcome = try FootballEngine.submitTurn(state: state, darts: [dbl(20), dbl(18), miss()])
    #expect(outcome.event.goalsAdded == 2)
    #expect(outcome.updatedState.players[0].goals == 2)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func footballSingleAndTripleDoNotScore() throws {
    let p1 = UUID()
    let p2 = UUID()
    let config = MatchConfigFootball(goalsToWin: 10)
    var state = try FootballEngine.makeInitialState(config: config, playerIds: [p1, p2])
    state = try FootballEngine.submitTurn(state: state, darts: [bull(.outerBull), miss(), miss()]).updatedState
    state = try FootballEngine.submitTurn(state: state, darts: [miss(), miss(), miss()]).updatedState

    let outcome = try FootballEngine.submitTurn(state: state, darts: [sng(20), trp(20), miss()])
    #expect(outcome.event.goalsAdded == 0)
    #expect(outcome.updatedState.players[0].goals == 0)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func footballBullCountsAsGoalDuringScoring() throws {
    let p1 = UUID()
    let p2 = UUID()
    let config = MatchConfigFootball(goalsToWin: 10)
    var state = try FootballEngine.makeInitialState(config: config, playerIds: [p1, p2])
    // Kickoff p1
    state = try FootballEngine.submitTurn(state: state, darts: [bull(.innerBull), miss(), miss()]).updatedState
    // p2
    state = try FootballEngine.submitTurn(state: state, darts: [miss(), miss(), miss()]).updatedState

    // p1 scoring: two bull hits count as 2 goals
    let outcome = try FootballEngine.submitTurn(
        state: state,
        darts: [bull(.outerBull), bull(.innerBull), miss()]
    )
    #expect(outcome.event.goalsAdded == 2)
    #expect(outcome.updatedState.players[0].goals == 2)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func footballBullScoresRepeatedly() throws {
    // Bull can score multiple times in the same visit and across visits.
    let p1 = UUID()
    let p2 = UUID()
    let config = MatchConfigFootball(goalsToWin: 10)
    var state = try FootballEngine.makeInitialState(config: config, playerIds: [p1, p2])
    state = try FootballEngine.submitTurn(state: state, darts: [bull(.innerBull), miss(), miss()]).updatedState
    state = try FootballEngine.submitTurn(state: state, darts: [miss(), miss(), miss()]).updatedState

    // Visit 1: 3 bulls = 3 goals
    let outcome1 = try FootballEngine.submitTurn(
        state: state,
        darts: [bull(.outerBull), bull(.outerBull), bull(.innerBull)]
    )
    #expect(outcome1.event.goalsAdded == 3)
    state = outcome1.updatedState
    // p2 pass
    state = try FootballEngine.submitTurn(state: state, darts: [miss(), miss(), miss()]).updatedState

    // Visit 2: 3 more bulls = 6 total
    let outcome2 = try FootballEngine.submitTurn(
        state: state,
        darts: [bull(.outerBull), bull(.outerBull), bull(.innerBull)]
    )
    #expect(outcome2.event.goalsAdded == 3)
    #expect(outcome2.updatedState.players[0].goals == 6)
}

// MARK: - Win condition

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func footballFirstToGoalsToWinWins() throws {
    let p1 = UUID()
    let p2 = UUID()
    let config = MatchConfigFootball(goalsToWin: 3)
    var state = try FootballEngine.makeInitialState(config: config, playerIds: [p1, p2])

    // Kickoff p1
    state = try FootballEngine.submitTurn(state: state, darts: [bull(.outerBull), miss(), miss()]).updatedState
    // p2 kickoff
    state = try FootballEngine.submitTurn(state: state, darts: [miss(), miss(), miss()]).updatedState
    // p1 scores 3 doubles
    let outcome = try FootballEngine.submitTurn(state: state, darts: [dbl(20), dbl(18), dbl(16)])

    #expect(outcome.event.goalsAdded == 3)
    #expect(outcome.updatedState.isComplete == true)
    #expect(outcome.updatedState.winnerPlayerId == p1)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func footballSubmitAfterCompleteThrows() throws {
    let p1 = UUID()
    let p2 = UUID()
    let config = MatchConfigFootball(goalsToWin: 1)
    var state = try FootballEngine.makeInitialState(config: config, playerIds: [p1, p2])
    state = try FootballEngine.submitTurn(state: state, darts: [bull(.outerBull), miss(), miss()]).updatedState
    state = try FootballEngine.submitTurn(state: state, darts: [miss(), miss(), miss()]).updatedState
    state = try FootballEngine.submitTurn(state: state, darts: [dbl(20), miss(), miss()]).updatedState
    #expect(state.isComplete)

    #expect(throws: AppError.self) {
        _ = try FootballEngine.submitTurn(state: state, darts: [dbl(20), miss(), miss()])
    }
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func footballTooManyDartsThrows() throws {
    let players = [UUID(), UUID()]
    let config = MatchConfigFootball()
    let state = try FootballEngine.makeInitialState(config: config, playerIds: players)

    #expect(throws: AppError.self) {
        _ = try FootballEngine.submitTurn(
            state: state,
            darts: [dbl(20), dbl(18), dbl(16), dbl(14)]
        )
    }
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func footballInvalidPlayerCountThrows() throws {
    let config = MatchConfigFootball()
    #expect(throws: AppError.self) {
        _ = try FootballEngine.makeInitialState(config: config, playerIds: [UUID()])
    }
    #expect(throws: AppError.self) {
        _ = try FootballEngine.makeInitialState(config: config, playerIds: [UUID(), UUID(), UUID()])
    }
}

// MARK: - Replay round-trip

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func footballReplayRestoresState() throws {
    let p1 = UUID()
    let p2 = UUID()
    let config = MatchConfigFootball(goalsToWin: 10)
    var state = try FootballEngine.makeInitialState(config: config, playerIds: [p1, p2])

    let turn1 = try FootballEngine.submitTurn(state: state, darts: [bull(.outerBull), dbl(20), miss()])
    state = turn1.updatedState
    let turn2 = try FootballEngine.submitTurn(state: state, darts: [miss(), miss(), miss()])
    state = turn2.updatedState
    let turn3 = try FootballEngine.submitTurn(state: state, darts: [dbl(18), dbl(16), miss()])

    let replayed = try FootballEngine.replay(
        config: config,
        playerIds: [p1, p2],
        events: [turn1.event, turn2.event, turn3.event]
    )

    #expect(replayed.players[0].goals == turn3.updatedState.players[0].goals)
    #expect(replayed.players[0].kickoffComplete == turn3.updatedState.players[0].kickoffComplete)
    #expect(replayed.turnIndex == turn3.updatedState.turnIndex)
}

// MARK: - Undo semantics (replay minus last event)

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func footballUndoLastTurnRestoresPreviousState() throws {
    let p1 = UUID()
    let p2 = UUID()
    let config = MatchConfigFootball(goalsToWin: 10)
    var state = try FootballEngine.makeInitialState(config: config, playerIds: [p1, p2])

    let turn1 = try FootballEngine.submitTurn(state: state, darts: [bull(.outerBull), dbl(20), miss()])
    state = turn1.updatedState
    let turn2 = try FootballEngine.submitTurn(state: state, darts: [miss(), miss(), miss()])
    state = turn2.updatedState
    let turn3 = try FootballEngine.submitTurn(state: state, darts: [dbl(18), miss(), miss()])

    // Undo last = replay events [turn1, turn2]
    let afterUndo = try FootballEngine.replay(
        config: config,
        playerIds: [p1, p2],
        events: [turn1.event, turn2.event]
    )

    // p1's goals should have reversed back to post-turn1 goals
    #expect(afterUndo.players[0].goals == turn1.updatedState.players[0].goals)
}

// MARK: - Player turn rotation

@Test(.tags(.unit, .match, .offline, .regression))
func footballTurnsAlternateBetweenPlayers() throws {
    let p1 = UUID()
    let p2 = UUID()
    let config = MatchConfigFootball(goalsToWin: 10)
    var state = try FootballEngine.makeInitialState(config: config, playerIds: [p1, p2])

    #expect(state.currentPlayerIndex == 0)
    state = try FootballEngine.submitTurn(state: state, darts: [miss(), miss(), miss()]).updatedState
    #expect(state.currentPlayerIndex == 1)
    state = try FootballEngine.submitTurn(state: state, darts: [miss(), miss(), miss()]).updatedState
    #expect(state.currentPlayerIndex == 0)
}
