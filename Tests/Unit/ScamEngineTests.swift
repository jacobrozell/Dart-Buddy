import Foundation
import Testing
@testable import DartBuddy

// MARK: - Helpers

private func single(_ n: Int) -> DartInput {
    DartInput(multiplier: .single, segment: .oneToTwenty(n))
}

private func double(_ n: Int) -> DartInput {
    DartInput(multiplier: .double, segment: .oneToTwenty(n))
}

private func triple(_ n: Int) -> DartInput {
    DartInput(multiplier: .triple, segment: .oneToTwenty(n))
}

private func miss() -> DartInput {
    DartInput(multiplier: .single, segment: .miss, isMiss: true)
}

// MARK: - Setup

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func scamRequiresExactlyTwoPlayers() {
    #expect(throws: AppError.self) {
        _ = try ScamEngine.makeInitialState(
            config: MatchConfigScam(),
            playerIds: [UUID()]
        )
    }
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func scamInitialStateStartsAtHalfZeroStopper() throws {
    let a = UUID(); let b = UUID()
    let state = try ScamEngine.makeInitialState(
        config: MatchConfigScam(),
        playerIds: [a, b]
    )
    #expect(state.halfIndex == 0)
    #expect(state.currentRole == .stopper)
    #expect(state.currentPlayerId == a)
    #expect(state.currentHalf.closedSegments.isEmpty)
    #expect(state.currentHalf.highestOpenSegment == 20)
}

// MARK: - Stopper

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func scamStopperClosesSegmentsHit() throws {
    var state = try ScamEngine.makeInitialState(
        config: MatchConfigScam(),
        playerIds: [UUID(), UUID()]
    )
    let outcome = try ScamEngine.submitVisit(
        state: state,
        darts: [triple(20), single(19), miss()]
    )
    state = outcome.updatedState
    #expect(Set(outcome.event.segmentsClosedThisVisit) == Set([20, 19]))
    #expect(state.currentHalf.closedSegments == Set([19, 20]))
    #expect(state.currentRole == .scorer)
    #expect(state.currentHalf.highestOpenSegment == 18)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func scamStopperHitOnAlreadyClosedSegmentIsNoOp() throws {
    var state = try ScamEngine.makeInitialState(
        config: MatchConfigScam(),
        playerIds: [UUID(), UUID()]
    )
    state.halves[0].closedSegments = [20]
    let outcome = try ScamEngine.submitVisit(
        state: state,
        darts: [single(20), single(19), miss()]
    )
    #expect(outcome.event.segmentsClosedThisVisit == [19])
}

// MARK: - Scorer

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func scamScorerCountsOnlyHighestOpenSegment() throws {
    var state = try ScamEngine.makeInitialState(
        config: MatchConfigScam(),
        playerIds: [UUID(), UUID()]
    )
    // Stopper closes 20.
    state = try ScamEngine.submitVisit(state: state, darts: [single(20)]).updatedState
    #expect(state.currentRole == .scorer)
    #expect(state.currentHalf.highestOpenSegment == 19)
    // Scorer throws T19, S19, S18. Only 19s count this visit (highest open at start).
    let outcome = try ScamEngine.submitVisit(
        state: state,
        darts: [triple(19), single(19), single(18)]
    )
    #expect(outcome.event.pointsAdded == 57 + 19)  // T19=57, S19=19, S18=0
    #expect(outcome.updatedState.players[1].totalScore == 76)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func scamScorerScoresZeroIfNoHitOnHighest() throws {
    var state = try ScamEngine.makeInitialState(
        config: MatchConfigScam(),
        playerIds: [UUID(), UUID()]
    )
    state = try ScamEngine.submitVisit(state: state, darts: [miss()]).updatedState  // stopper closes nothing
    #expect(state.currentHalf.highestOpenSegment == 20)
    let outcome = try ScamEngine.submitVisit(
        state: state,
        darts: [single(15), single(10), single(5)]
    )
    #expect(outcome.event.pointsAdded == 0)
    #expect(outcome.updatedState.players[1].totalScore == 0)
}

// MARK: - Half + match completion

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func scamHalfEndsWhenAllSegmentsClosed() throws {
    var state = try ScamEngine.makeInitialState(
        config: MatchConfigScam(),
        playerIds: [UUID(), UUID()]
    )
    // Force half 0 to be one segment away from closed: 20→2 closed, 1 open.
    state.halves[0].closedSegments = Set(2 ... 20)
    state.currentRole = .stopper
    // Stopper closes 1.
    state = try ScamEngine.submitVisit(state: state, darts: [single(1)]).updatedState
    #expect(state.currentRole == .scorer)
    #expect(state.currentHalf.closedSegments.count == 20)
    #expect(state.currentHalf.highestOpenSegment == nil)
    // Scorer's visit ends the half: no points possible.
    let outcome = try ScamEngine.submitVisit(state: state, darts: [single(20)])
    state = outcome.updatedState
    #expect(outcome.event.halfCompleted)
    #expect(state.halfIndex == 1)
    #expect(state.currentRole == .stopper)
    #expect(state.currentPlayerId == state.halves[1].stopperPlayerId)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func scamMatchEndsAfterSecondHalfWithHigherTotal() throws {
    let a = UUID(); let b = UUID()
    var state = try ScamEngine.makeInitialState(
        config: MatchConfigScam(),
        playerIds: [a, b]
    )
    // Pre-finish to the very last scorer visit of half 1.
    state.halfIndex = 1
    state.halves[0].closedSegments = Set(1 ... 20)
    state.halves[1].closedSegments = Set(1 ... 20)  // we'll re-open one
    state.halves[1].closedSegments.remove(1)
    state.currentRole = .stopper
    state.players[0].totalScore = 100  // a (scorer in half 2)
    state.players[1].totalScore = 80   // b
    // Stopper (b in half 2) closes 1 → all segments closed.
    state = try ScamEngine.submitVisit(state: state, darts: [single(1)]).updatedState
    // Scorer (a) takes their final visit. Highest open at start = nil — pointsAdded=0.
    let outcome = try ScamEngine.submitVisit(state: state, darts: [single(20)])
    state = outcome.updatedState
    #expect(state.isComplete)
    #expect(state.winnerPlayerId == a)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func scamSubmitAfterCompletionThrows() throws {
    var state = try ScamEngine.makeInitialState(
        config: MatchConfigScam(),
        playerIds: [UUID(), UUID()]
    )
    state.isComplete = true
    #expect(throws: AppError.self) {
        _ = try ScamEngine.submitVisit(state: state, darts: [miss()])
    }
}

// MARK: - Replay

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func scamReplayReconstructsState() throws {
    let a = UUID(); let b = UUID()
    var state = try ScamEngine.makeInitialState(
        config: MatchConfigScam(),
        playerIds: [a, b]
    )
    var events: [ScamVisitEvent] = []
    // Round 1: stopper a closes 20, 18; scorer b hits T19 → 57.
    var outcome = try ScamEngine.submitVisit(state: state, darts: [single(20), single(18), miss()])
    state = outcome.updatedState; events.append(outcome.event)
    outcome = try ScamEngine.submitVisit(state: state, darts: [triple(19), miss(), miss()])
    state = outcome.updatedState; events.append(outcome.event)
    // Round 2: stopper closes 19 — now scorer aims at 17.
    outcome = try ScamEngine.submitVisit(state: state, darts: [single(19)])
    state = outcome.updatedState; events.append(outcome.event)
    outcome = try ScamEngine.submitVisit(state: state, darts: [single(17)])
    state = outcome.updatedState; events.append(outcome.event)

    let replayed = try ScamEngine.replay(
        config: MatchConfigScam(),
        playerIds: [a, b],
        events: events
    )
    #expect(replayed.halves[0].closedSegments == state.halves[0].closedSegments)
    #expect(replayed.players.first { $0.playerId == b }?.totalScore == state.players.first { $0.playerId == b }?.totalScore)
    #expect(replayed.currentRole == state.currentRole)
}
