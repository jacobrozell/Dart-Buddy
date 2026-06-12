import Foundation
import Testing
@testable import DartBuddy

// MARK: - Helpers

private func hit(_ segment: Int) -> DartInput {
    DartInput(multiplier: .single, segment: .oneToTwenty(segment))
}

private func miss() -> DartInput {
    DartInput(multiplier: .single, segment: .miss, isMiss: true)
}

private func wrongSegment(_ segment: Int) -> DartInput {
    DartInput(multiplier: .single, segment: .oneToTwenty(segment))
}

// MARK: - Course order

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func grandNationalCourseOrderIs20Segments() {
    #expect(grandNationalCourseOrder.count == 20)
    #expect(grandNationalCourseOrder.first == 20)
    #expect(grandNationalCourseOrder.last == 1)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func grandNationalCourseOrderContainsAllSegmentsOnce() {
    let sorted = grandNationalCourseOrder.sorted()
    #expect(sorted == Array(1 ... 20))
}

// MARK: - Initial state

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func grandNationalInitialStateAtSegmentZero() throws {
    let players = [UUID(), UUID()]
    let state = try GrandNationalEngine.makeInitialState(
        config: MatchConfigGrandNational(),
        playerIds: players
    )
    #expect(state.players.count == 2)
    #expect(state.players[0].segmentIndex == 0)
    #expect(state.players[0].lapsCompleted == 0)
    #expect(state.players[0].isEliminated == false)
    #expect(state.currentPlayerIndex == 0)
    #expect(state.isComplete == false)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func grandNationalInitialHurdleIsSegment20() throws {
    let players = [UUID(), UUID()]
    let state = try GrandNationalEngine.makeInitialState(
        config: MatchConfigGrandNational(),
        playerIds: players
    )
    // The first hurdle is always the first element of the course: 20.
    #expect(state.players[0].currentHurdle == 20)
}

@Test(.tags(.unit, .match, .offline, .regression))
func grandNationalRequiresMinimumTwoPlayers() throws {
    #expect(throws: (any Error).self) {
        try GrandNationalEngine.makeInitialState(
            config: MatchConfigGrandNational(),
            playerIds: [UUID()]
        )
    }
}

// MARK: - Scoring / hit & advance

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func grandNationalHitFirstHurdleAdvancesSegmentIndex() throws {
    let players = [UUID(), UUID()]
    var state = try GrandNationalEngine.makeInitialState(
        config: MatchConfigGrandNational(),
        playerIds: players
    )
    // First hurdle is 20.
    let outcome = try GrandNationalEngine.submitTurn(
        state: state,
        darts: [hit(20), miss(), miss()]
    )
    state = outcome.updatedState
    #expect(outcome.event.segmentIndexAfter == 1)
    #expect(outcome.event.eliminated == false)
    #expect(state.players[0].segmentIndex == 1)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func grandNationalMissAllThreeDartsEliminatesPlayer() throws {
    let p1 = UUID()
    let p2 = UUID()
    var state = try GrandNationalEngine.makeInitialState(
        config: MatchConfigGrandNational(),
        playerIds: [p1, p2]
    )
    // Throw three darts none of which hit hurdle 20.
    let outcome = try GrandNationalEngine.submitTurn(
        state: state,
        darts: [hit(5), miss(), miss()]  // 5 is not the hurdle (20)
    )
    state = outcome.updatedState
    #expect(outcome.event.eliminated == true)
    #expect(state.players[0].isEliminated == true)
    #expect(state.isComplete == false) // P2 still alive
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func grandNationalHitOnAnyDartCountsAsSuccess() throws {
    let players = [UUID(), UUID()]
    var state = try GrandNationalEngine.makeInitialState(
        config: MatchConfigGrandNational(),
        playerIds: players
    )
    // Miss first two then hit on the third dart.
    let outcome = try GrandNationalEngine.submitTurn(
        state: state,
        darts: [miss(), miss(), hit(20)]
    )
    #expect(outcome.event.eliminated == false)
    #expect(outcome.updatedState.players[0].segmentIndex == 1)
}

// MARK: - Turn rotation and skipping eliminated players

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func grandNationalTurnRotatesAfterEachPlayer() throws {
    let players = [UUID(), UUID(), UUID()]
    var state = try GrandNationalEngine.makeInitialState(
        config: MatchConfigGrandNational(),
        playerIds: players
    )
    // P0 hits, should move to P1.
    state = try GrandNationalEngine.submitTurn(state: state, darts: [hit(20)]).updatedState
    #expect(state.currentPlayerIndex == 1)

    // P1 hits, should move to P2.
    state = try GrandNationalEngine.submitTurn(state: state, darts: [hit(20)]).updatedState
    #expect(state.currentPlayerIndex == 2)

    // P2 hits, wraps back to P0.
    state = try GrandNationalEngine.submitTurn(state: state, darts: [hit(20)]).updatedState
    #expect(state.currentPlayerIndex == 0)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func grandNationalSkipsEliminatedPlayerInRotation() throws {
    let p0 = UUID()
    let p1 = UUID()
    let p2 = UUID()
    var state = try GrandNationalEngine.makeInitialState(
        config: MatchConfigGrandNational(),
        playerIds: [p0, p1, p2]
    )
    // P0 hits.
    state = try GrandNationalEngine.submitTurn(state: state, darts: [hit(20)]).updatedState
    // P1 misses all — eliminated (first hurdle is 20, throw something else).
    state = try GrandNationalEngine.submitTurn(state: state, darts: [hit(5), miss(), miss()]).updatedState
    #expect(state.players[1].isEliminated == true)
    // Should skip P1 and go to P2.
    #expect(state.currentPlayerIndex == 2)
}

// MARK: - Lap counting

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func grandNationalCompletingCourseIncrementsLapCount() throws {
    let players = [UUID(), UUID()]
    var state = try GrandNationalEngine.makeInitialState(
        config: MatchConfigGrandNational(laps: 2),
        playerIds: players
    )
    // Advance P0 through all 20 segments to complete lap 1.
    // We do this by submitting 20 turns for P0 (one per segment), each time
    // hitting the correct hurdle.  After every P0 turn we also submit a miss for P1
    // so turn rotation works properly.
    for lapSegment in 0 ..< 20 {
        let hurdleForP0 = grandNationalCourseOrder[lapSegment]
        state = try GrandNationalEngine.submitTurn(state: state, darts: [hit(hurdleForP0)]).updatedState
        // P1's turn — hit their current hurdle to keep them alive.
        let hurdleForP1 = grandNationalCourseOrder[state.players[1].segmentIndex]
        state = try GrandNationalEngine.submitTurn(state: state, darts: [hit(hurdleForP1)]).updatedState
    }
    // P0 should have completed 1 lap and be back at segment 0.
    #expect(state.players[0].lapsCompleted == 1)
    #expect(state.players[0].segmentIndex == 0)
}

// MARK: - Win condition

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func grandNationalWinnerDeclaredAfterRequiredLaps() throws {
    let winner = UUID()
    let other = UUID()
    var state = try GrandNationalEngine.makeInitialState(
        config: MatchConfigGrandNational(laps: 1),
        playerIds: [winner, other]
    )
    // Complete 1 lap for the winner: 20 segments.
    for lapSeg in 0 ..< 20 {
        let hurdle = grandNationalCourseOrder[lapSeg]
        state = try GrandNationalEngine.submitTurn(state: state, darts: [hit(hurdle)]).updatedState
        if state.isComplete { break }
        // Other player also hits to stay alive.
        let otherHurdle = grandNationalCourseOrder[state.players[1].segmentIndex]
        state = try GrandNationalEngine.submitTurn(state: state, darts: [hit(otherHurdle)]).updatedState
        if state.isComplete { break }
    }
    #expect(state.isComplete == true)
    #expect(state.winnerPlayerId == winner)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func grandNationalLastSurvivorWinsWhenAllOthersEliminated() throws {
    let survivor = UUID()
    let p2 = UUID()
    var state = try GrandNationalEngine.makeInitialState(
        config: MatchConfigGrandNational(),
        playerIds: [survivor, p2]
    )
    // Survivor hits the first hurdle (20).
    state = try GrandNationalEngine.submitTurn(state: state, darts: [hit(20)]).updatedState
    // P2 misses all three darts — eliminated. Survivor is sole survivor → wins.
    let outcome = try GrandNationalEngine.submitTurn(state: state, darts: [hit(5), miss(), miss()])
    state = outcome.updatedState
    #expect(state.isComplete == true)
    #expect(state.winnerPlayerId == survivor)
}

// MARK: - Replay round-trip

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func grandNationalReplayRestoresState() throws {
    let p1 = UUID()
    let p2 = UUID()
    let config = MatchConfigGrandNational(laps: 2)
    var state = try GrandNationalEngine.makeInitialState(config: config, playerIds: [p1, p2])

    let outcome1 = try GrandNationalEngine.submitTurn(state: state, darts: [hit(20)])
    state = outcome1.updatedState
    let outcome2 = try GrandNationalEngine.submitTurn(state: state, darts: [hit(20)])
    state = outcome2.updatedState

    let replayed = try GrandNationalEngine.replay(
        config: config,
        playerIds: [p1, p2],
        events: [outcome1.event, outcome2.event]
    )

    #expect(replayed.players[0].segmentIndex == state.players[0].segmentIndex)
    #expect(replayed.players[1].segmentIndex == state.players[1].segmentIndex)
    #expect(replayed.currentPlayerIndex == state.currentPlayerIndex)
    #expect(replayed.isComplete == state.isComplete)
}

// MARK: - Invalid input guards

@Test(.tags(.unit, .match, .offline, .regression))
func grandNationalSubmitOnCompletedMatchThrows() throws {
    let p1 = UUID()
    let p2 = UUID()
    var state = try GrandNationalEngine.makeInitialState(
        config: MatchConfigGrandNational(laps: 1),
        playerIds: [p1, p2]
    )
    // Eliminate P2 so P1 wins immediately.
    state = try GrandNationalEngine.submitTurn(state: state, darts: [hit(20)]).updatedState
    state = try GrandNationalEngine.submitTurn(state: state, darts: [hit(5), miss(), miss()]).updatedState
    // P1 is now the last survivor and the match is complete.
    #expect(state.isComplete)
    #expect(throws: (any Error).self) {
        try GrandNationalEngine.submitTurn(state: state, darts: [hit(20)])
    }
}

@Test(.tags(.unit, .match, .offline, .regression))
func grandNationalRejectsTooManyDarts() throws {
    let players = [UUID(), UUID()]
    let state = try GrandNationalEngine.makeInitialState(
        config: MatchConfigGrandNational(),
        playerIds: players
    )
    #expect(throws: (any Error).self) {
        try GrandNationalEngine.submitTurn(state: state, darts: [hit(20), hit(5), miss(), miss()])
    }
}
