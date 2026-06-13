import Foundation
import Testing
@testable import DartBuddy

// MARK: - Helpers

private func miss() -> DartInput {
    DartInput(multiplier: .single, segment: .miss, isMiss: true)
}

private func d(_ multiplier: DartMultiplier, _ segment: Int) -> DartInput {
    DartInput(multiplier: multiplier, segment: .oneToTwenty(segment))
}

/// Submit a full 3-dart visit worth `points` for the current player using
/// convenient single-dart inputs.
private func submitVisit(_ points: Int, state: SuddenDeathState) throws -> SuddenDeathState {
    let darts = SuddenDeathEngine.dartsFromEvent(
        SuddenDeathTurnEvent(
            playerId: UUID(),
            turnIndex: 0,
            round: 1,
            visitIndexInRound: 0,
            pointsThisVisit: points,
            cumulativeTotalAfterTurn: points,
            roundCompleted: false,
            eliminatedPlayerIds: [],
            timestamp: Date()
        )
    )
    return try SuddenDeathEngine.submitTurn(state: state, darts: darts).updatedState
}

private func makeState(
    playerCount: Int = 3,
    config: MatchConfigSuddenDeath = MatchConfigSuddenDeath()
) throws -> SuddenDeathState {
    let ids = (0 ..< playerCount).map { _ in UUID() }
    return try SuddenDeathEngine.makeInitialState(config: config, playerIds: ids)
}

// MARK: - Initial state

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func suddenDeathInitialStateHasThreePlayers() throws {
    let state = try makeState(playerCount: 3)
    #expect(state.players.count == 3)
    #expect(state.currentRound == 1)
    #expect(state.currentPlayerIndex == 0)
    #expect(state.isComplete == false)
    #expect(state.activePlayerIds.count == 3)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func suddenDeathMinimumPlayerCountEnforced() throws {
    let ids = [UUID(), UUID()]
    #expect(throws: AppError.self) {
        try SuddenDeathEngine.makeInitialState(config: MatchConfigSuddenDeath(), playerIds: ids)
    }
}

// MARK: - Turn advancement within a round

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func suddenDeathTurnAdvancesToNextPlayerWithinRound() throws {
    var state = try makeState(playerCount: 3)
    let p0 = state.players[0].playerId

    state = try SuddenDeathEngine.submitTurn(state: state, darts: [d(.single, 20), miss(), miss()]).updatedState
    #expect(state.currentPlayerIndex == 1)
    #expect(state.currentRound == 1)
    #expect(state.players[0].roundTotal == 20)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func suddenDeathRoundDoesNotCompleteUntilAllPlayersHaveThrown() throws {
    var state = try makeState(playerCount: 3)

    // Submit for player 0 and 1 — round not yet complete.
    state = try SuddenDeathEngine.submitTurn(state: state, darts: [d(.single, 5), miss(), miss()]).updatedState
    state = try SuddenDeathEngine.submitTurn(state: state, darts: [d(.single, 10), miss(), miss()]).updatedState
    #expect(state.currentRound == 1)
    #expect(state.isComplete == false)
    #expect(state.activePlayerIds.count == 3)
}

// MARK: - Elimination

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func suddenDeathEliminatesLowestScorer() throws {
    var state = try makeState(playerCount: 3)
    let p0 = state.players[0].playerId
    let p1 = state.players[1].playerId
    let p2 = state.players[2].playerId

    // P0 scores 5, P1 scores 20, P2 scores 15.
    state = try SuddenDeathEngine.submitTurn(state: state, darts: [d(.single, 5), miss(), miss()]).updatedState
    state = try SuddenDeathEngine.submitTurn(state: state, darts: [d(.single, 20), miss(), miss()]).updatedState
    let outcome = try SuddenDeathEngine.submitTurn(state: state, darts: [d(.single, 15), miss(), miss()])

    #expect(outcome.event.roundCompleted == true)
    #expect(outcome.event.eliminatedPlayerIds == [p0])
    #expect(outcome.updatedState.players.first(where: { $0.playerId == p0 })?.isEliminated == true)
    #expect(outcome.updatedState.players.filter(\.isEliminated).count == 1)
    #expect(outcome.updatedState.currentRound == 2)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func suddenDeathEliminatesAllTiedLowest() throws {
    var state = try makeState(playerCount: 4)
    let p0 = state.players[0].playerId
    let p1 = state.players[1].playerId

    // P0 and P1 score 5, P2 scores 20, P3 scores 15.
    state = try SuddenDeathEngine.submitTurn(state: state, darts: [d(.single, 5), miss(), miss()]).updatedState
    state = try SuddenDeathEngine.submitTurn(state: state, darts: [d(.single, 5), miss(), miss()]).updatedState
    state = try SuddenDeathEngine.submitTurn(state: state, darts: [d(.single, 20), miss(), miss()]).updatedState
    let outcome = try SuddenDeathEngine.submitTurn(state: state, darts: [d(.single, 15), miss(), miss()])

    #expect(outcome.event.roundCompleted == true)
    let eliminatedIds = Set(outcome.event.eliminatedPlayerIds)
    #expect(eliminatedIds.contains(p0))
    #expect(eliminatedIds.contains(p1))
    #expect(outcome.updatedState.players.filter(\.isEliminated).count == 2)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func suddenDeathAllTieSafetyRuleNobodyEliminated() throws {
    // Edge case: all players score the same total — nobody is eliminated.
    var state = try makeState(playerCount: 3)

    state = try SuddenDeathEngine.submitTurn(state: state, darts: [d(.single, 10), miss(), miss()]).updatedState
    state = try SuddenDeathEngine.submitTurn(state: state, darts: [d(.single, 10), miss(), miss()]).updatedState
    let outcome = try SuddenDeathEngine.submitTurn(state: state, darts: [d(.single, 10), miss(), miss()])

    #expect(outcome.event.roundCompleted == true)
    #expect(outcome.event.eliminatedPlayerIds.isEmpty)
    #expect(outcome.updatedState.players.filter(\.isEliminated).isEmpty)
    // All still active — round advances but player count unchanged.
    #expect(outcome.updatedState.activePlayerIds.count == 3)
}

// MARK: - Win condition

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func suddenDeathLastPlayerStandingWins() throws {
    var state = try makeState(playerCount: 3)
    let p0 = state.players[0].playerId
    let p1 = state.players[1].playerId
    let p2 = state.players[2].playerId

    // Round 1: eliminate P0 (lowest).
    state = try SuddenDeathEngine.submitTurn(state: state, darts: [d(.single, 1), miss(), miss()]).updatedState
    state = try SuddenDeathEngine.submitTurn(state: state, darts: [d(.single, 20), miss(), miss()]).updatedState
    state = try SuddenDeathEngine.submitTurn(state: state, darts: [d(.single, 20), miss(), miss()]).updatedState
    #expect(state.players.first(where: { $0.playerId == p0 })?.isEliminated == true)

    // Round 2: P1 vs P2 — eliminate P1.
    state = try SuddenDeathEngine.submitTurn(state: state, darts: [d(.single, 2), miss(), miss()]).updatedState
    state = try SuddenDeathEngine.submitTurn(state: state, darts: [d(.single, 20), miss(), miss()]).updatedState

    #expect(state.isComplete == true)
    #expect(state.winnerPlayerId == p2)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func suddenDeathMatchCompleteThrowsOnFurtherSubmission() throws {
    var state = try makeState(playerCount: 3)

    // Force completion in 2 rounds.
    state = try SuddenDeathEngine.submitTurn(state: state, darts: [d(.single, 1), miss(), miss()]).updatedState
    state = try SuddenDeathEngine.submitTurn(state: state, darts: [d(.single, 20), miss(), miss()]).updatedState
    state = try SuddenDeathEngine.submitTurn(state: state, darts: [d(.single, 20), miss(), miss()]).updatedState
    state = try SuddenDeathEngine.submitTurn(state: state, darts: [d(.single, 1), miss(), miss()]).updatedState
    state = try SuddenDeathEngine.submitTurn(state: state, darts: [d(.single, 20), miss(), miss()]).updatedState

    #expect(state.isComplete == true)
    #expect(throws: AppError.self) {
        try SuddenDeathEngine.submitTurn(state: state, darts: [miss(), miss(), miss()])
    }
}

// MARK: - visitsPerRound = 2

@Test(.tags(.unit, .match, .offline, .regression))
func suddenDeathTwoVisitsPerRoundDelaysElimination() throws {
    let config = MatchConfigSuddenDeath(visitsPerRound: 2)
    var state = try makeState(playerCount: 3, config: config)

    // Each player needs 2 visits before elimination resolves.
    // Visit 1, all players:
    state = try SuddenDeathEngine.submitTurn(state: state, darts: [d(.single, 5), miss(), miss()]).updatedState  // P0 v1
    #expect(state.currentRound == 1)
    state = try SuddenDeathEngine.submitTurn(state: state, darts: [d(.single, 10), miss(), miss()]).updatedState // P1 v1
    state = try SuddenDeathEngine.submitTurn(state: state, darts: [d(.single, 15), miss(), miss()]).updatedState // P2 v1
    #expect(state.activePlayerIds.count == 3) // no elimination yet
    #expect(state.currentRound == 1)

    // Visit 2, all players:
    state = try SuddenDeathEngine.submitTurn(state: state, darts: [d(.single, 1), miss(), miss()]).updatedState  // P0 v2
    state = try SuddenDeathEngine.submitTurn(state: state, darts: [d(.single, 10), miss(), miss()]).updatedState // P1 v2
    let outcome = try SuddenDeathEngine.submitTurn(state: state, darts: [d(.single, 15), miss(), miss()])        // P2 v2

    #expect(outcome.event.roundCompleted == true)
    // P0 total = 6, P1 = 20, P2 = 30 → P0 eliminated.
    let p0 = outcome.updatedState.players[0].playerId
    #expect(outcome.event.eliminatedPlayerIds.contains(p0))
}

// MARK: - Replay round-trip

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func suddenDeathReplayRestoresState() throws {
    let ids = [UUID(), UUID(), UUID()]
    var state = try SuddenDeathEngine.makeInitialState(config: MatchConfigSuddenDeath(), playerIds: ids)

    var events: [SuddenDeathTurnEvent] = []

    let o1 = try SuddenDeathEngine.submitTurn(state: state, darts: [d(.single, 5), miss(), miss()])
    state = o1.updatedState; events.append(o1.event)

    let o2 = try SuddenDeathEngine.submitTurn(state: state, darts: [d(.single, 20), miss(), miss()])
    state = o2.updatedState; events.append(o2.event)

    let o3 = try SuddenDeathEngine.submitTurn(state: state, darts: [d(.single, 15), miss(), miss()])
    state = o3.updatedState; events.append(o3.event)

    let replayed = try SuddenDeathEngine.replay(
        config: MatchConfigSuddenDeath(),
        playerIds: ids,
        events: events
    )

    #expect(replayed.currentRound == state.currentRound)
    #expect(replayed.players.map(\.isEliminated) == state.players.map(\.isEliminated))
    #expect(replayed.players.map(\.cumulativeTotal) == state.players.map(\.cumulativeTotal))
}

// MARK: - Undo semantics (replay of events minus last)

@Test(.tags(.unit, .match, .regression))
func suddenDeathUndoLastTurnResetsToBeforeLastVisit() throws {
    let ids = [UUID(), UUID(), UUID()]
    var state = try SuddenDeathEngine.makeInitialState(config: MatchConfigSuddenDeath(), playerIds: ids)

    var events: [SuddenDeathTurnEvent] = []
    let o1 = try SuddenDeathEngine.submitTurn(state: state, darts: [d(.single, 5), miss(), miss()])
    state = o1.updatedState; events.append(o1.event)
    let o2 = try SuddenDeathEngine.submitTurn(state: state, darts: [d(.single, 20), miss(), miss()])
    state = o2.updatedState; events.append(o2.event)

    // Undo = replay without last event.
    let undoState = try SuddenDeathEngine.replay(
        config: MatchConfigSuddenDeath(),
        playerIds: ids,
        events: Array(events.dropLast())
    )

    #expect(undoState.currentPlayerIndex == 1)
    #expect(undoState.players[0].roundTotal == 5)
    #expect(undoState.players[1].roundTotal == 0)
}

// MARK: - Invalid input

@Test(.tags(.unit, .match, .regression))
func suddenDeathTooManyDartsRejected() throws {
    let state = try makeState(playerCount: 3)
    #expect(throws: AppError.self) {
        try SuddenDeathEngine.submitTurn(state: state, darts: [
            d(.single, 1), d(.single, 2), d(.single, 3), d(.single, 4)
        ])
    }
}

// MARK: - eliminateAllTied = false

@Test(.tags(.unit, .match, .offline, .regression))
func suddenDeathEliminateOneWhenTiedEliminatesFirst() throws {
    let config = MatchConfigSuddenDeath(eliminationRule: .eliminateOne)
    var state = try SuddenDeathEngine.makeInitialState(
        config: config,
        playerIds: [UUID(), UUID(), UUID(), UUID()]
    )
    let p0 = state.players[0].playerId
    let p1 = state.players[1].playerId

    // P0 and P1 both score 5, P2 and P3 score 20.
    state = try SuddenDeathEngine.submitTurn(state: state, darts: [d(.single, 5), miss(), miss()]).updatedState
    state = try SuddenDeathEngine.submitTurn(state: state, darts: [d(.single, 5), miss(), miss()]).updatedState
    state = try SuddenDeathEngine.submitTurn(state: state, darts: [d(.single, 20), miss(), miss()]).updatedState
    let outcome = try SuddenDeathEngine.submitTurn(state: state, darts: [d(.single, 20), miss(), miss()])

    // Only one of the tied-lowest players should be eliminated.
    #expect(outcome.event.eliminatedPlayerIds.count == 1)
    #expect(outcome.updatedState.players.filter(\.isEliminated).count == 1)
}
