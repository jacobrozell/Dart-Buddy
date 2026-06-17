import Foundation
import Testing
@testable import DartBuddy

// MARK: - Helpers

private func playable(_ n: Int) -> PrisonerDartHit { .playable(segment: n) }
private func innerSingle(_ n: Int) -> PrisonerDartHit { .innerSingle(segment: n) }
private let bull: PrisonerDartHit = .bull
private let outside: PrisonerDartHit = .outsideDouble

// MARK: - Setup

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func prisonerRequiresTwoToEightPlayers() {
    #expect(throws: AppError.self) {
        _ = try PrisonerEngine.makeInitialState(
            config: MatchConfigPrisoner(),
            playerIds: [UUID()]
        )
    }
    #expect(throws: AppError.self) {
        _ = try PrisonerEngine.makeInitialState(
            config: MatchConfigPrisoner(),
            playerIds: (0 ..< 9).map { _ in UUID() }
        )
    }
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func prisonerInitialStateStartsAtSegmentOneWithFullPool() throws {
    let state = try PrisonerEngine.makeInitialState(
        config: MatchConfigPrisoner(),
        playerIds: [UUID(), UUID()]
    )
    #expect(state.players.allSatisfy { $0.pool == 3 && $0.progressIndex == 0 })
    #expect(state.currentPlayer.currentTarget == 1)
    #expect(state.prisoners.isEmpty)
    #expect(state.dartsAvailableThisVisit == 3)
}

// MARK: - Clockwise sequence

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func prisonerClockwiseSequenceStartsCorrectly() {
    let seq = MatchConfigPrisoner.clockwiseSequence
    #expect(seq.count == 20)
    #expect(seq[0] == 1)
    #expect(seq[1] == 18)
    #expect(seq[2] == 4)
    #expect(seq[3] == 13)
    #expect(seq.last == 20)
    #expect(Set(seq) == Set(1 ... 20))
}

// MARK: - Progression

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func prisonerHitOnTargetSegmentAdvances() throws {
    let state = try PrisonerEngine.makeInitialState(
        config: MatchConfigPrisoner(),
        playerIds: [UUID(), UUID()]
    )
    let outcome = try PrisonerEngine.submitVisit(
        state: state,
        hits: [playable(1), playable(18), playable(4)]
    )
    #expect(outcome.event.progressIndexAfter == 3)
    #expect(outcome.updatedState.players[1].progressIndex == 0)
    // Player 1 now active.
    #expect(outcome.updatedState.currentPlayer.currentTarget == 1)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func prisonerHitOnNonTargetSegmentDoesNotAdvance() throws {
    let state = try PrisonerEngine.makeInitialState(
        config: MatchConfigPrisoner(),
        playerIds: [UUID(), UUID()]
    )
    // Target is 1; throw at 4 and 18 (later in sequence but not current).
    let outcome = try PrisonerEngine.submitVisit(
        state: state,
        hits: [playable(4), playable(18), outside]
    )
    #expect(outcome.event.progressIndexAfter == 0)
    #expect(outcome.event.dartsLost == 1)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func prisonerWinAtSegment20() throws {
    var state = try PrisonerEngine.makeInitialState(
        config: MatchConfigPrisoner(),
        playerIds: [UUID(), UUID()]
    )
    state.players[0].progressIndex = 19  // target = 20
    let outcome = try PrisonerEngine.submitVisit(state: state, hits: [playable(20)])
    #expect(outcome.event.matchCompleted)
    #expect(outcome.updatedState.isComplete)
    #expect(outcome.updatedState.winnerPlayerId == state.players[0].playerId)
}

// MARK: - Prisoner creation + capture

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func prisonerInnerSingleCreatesPrisonerAndShrinksPool() throws {
    let state = try PrisonerEngine.makeInitialState(
        config: MatchConfigPrisoner(),
        playerIds: [UUID(), UUID()]
    )
    let outcome = try PrisonerEngine.submitVisit(
        state: state,
        hits: [innerSingle(7), innerSingle(7), playable(1)]
    )
    #expect(outcome.event.prisonersCreated == [7, 7])
    #expect(outcome.updatedState.prisoners.count == 2)
    #expect(outcome.updatedState.players[0].pool == 3 - 2)
    // Still hit segment 1 → advanced.
    #expect(outcome.event.progressIndexAfter == 1)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func prisonerPlayableHitCapturesPrisonerOnSameSegment() throws {
    let a = UUID(); let b = UUID()
    var state = try PrisonerEngine.makeInitialState(
        config: MatchConfigPrisoner(),
        playerIds: [a, b]
    )
    state.prisoners = [
        PrisonerOnBoard(segment: 1, ownerPlayerId: b),
        PrisonerOnBoard(segment: 1, ownerPlayerId: b),
    ]
    // a hits playable 1: advances AND captures one prisoner at 1.
    let outcome = try PrisonerEngine.submitVisit(state: state, hits: [playable(1)])
    #expect(outcome.event.prisonersCaptured == [1])
    #expect(outcome.updatedState.prisoners.count == 1)
    #expect(outcome.updatedState.players[0].pool == 4)
    #expect(outcome.updatedState.players[0].progressIndex == 1)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func prisonerPlayableHitOnNonTargetStillCaptures() throws {
    let a = UUID(); let b = UUID()
    var state = try PrisonerEngine.makeInitialState(
        config: MatchConfigPrisoner(),
        playerIds: [a, b]
    )
    state.prisoners = [PrisonerOnBoard(segment: 13, ownerPlayerId: b)]
    // a's target is 1; throwing playable 13 doesn't advance but does capture.
    let outcome = try PrisonerEngine.submitVisit(state: state, hits: [playable(13)])
    #expect(outcome.event.progressIndexAfter == 0)
    #expect(outcome.event.prisonersCaptured == [13])
    #expect(outcome.updatedState.players[0].pool == 4)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func prisonerBullCapturesBullPrisonerWhenAvailable() throws {
    let a = UUID(); let b = UUID()
    var state = try PrisonerEngine.makeInitialState(
        config: MatchConfigPrisoner(),
        playerIds: [a, b]
    )
    state.prisoners = [PrisonerOnBoard(segment: 25, ownerPlayerId: b)]
    let outcome = try PrisonerEngine.submitVisit(state: state, hits: [bull])
    #expect(outcome.event.prisonersCaptured == [25])
    #expect(outcome.event.prisonersCreated.isEmpty)
    #expect(outcome.updatedState.prisoners.isEmpty)
    #expect(outcome.updatedState.players[0].pool == 4)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func prisonerBullCreatesBullPrisonerWhenNoneOnBoard() throws {
    let state = try PrisonerEngine.makeInitialState(
        config: MatchConfigPrisoner(),
        playerIds: [UUID(), UUID()]
    )
    let outcome = try PrisonerEngine.submitVisit(state: state, hits: [bull])
    #expect(outcome.event.prisonersCreated == [25])
    #expect(outcome.updatedState.prisoners.count == 1)
    #expect(outcome.updatedState.players[0].pool == 2)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func prisonerMultiplePrisonersOnSameSegmentCapturedOneAtATime() throws {
    var state = try PrisonerEngine.makeInitialState(
        config: MatchConfigPrisoner(),
        playerIds: [UUID(), UUID()]
    )
    let other = state.players[1].playerId
    state.prisoners = [
        PrisonerOnBoard(segment: 1, ownerPlayerId: other),
        PrisonerOnBoard(segment: 1, ownerPlayerId: other),
        PrisonerOnBoard(segment: 1, ownerPlayerId: other),
    ]
    let outcome = try PrisonerEngine.submitVisit(
        state: state,
        hits: [playable(1), playable(18), playable(4)]
    )
    // Only the first dart hit segment 1 → only one capture.
    #expect(outcome.event.prisonersCaptured == [1])
    #expect(outcome.updatedState.prisoners.count == 2)
}

// MARK: - Stuck darts / pool

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func prisonerOutsideDoubleReducesNextVisitDarts() throws {
    var state = try PrisonerEngine.makeInitialState(
        config: MatchConfigPrisoner(),
        playerIds: [UUID(), UUID()]
    )
    let outcome = try PrisonerEngine.submitVisit(
        state: state,
        hits: [playable(1), outside, outside]
    )
    state = outcome.updatedState
    // Player 0 has 2 lost darts. Next time player 0 is active, available = 3 - 2 = 1.
    // First we let player 1 take a visit.
    state = try PrisonerEngine.submitVisit(state: state, hits: [outside]).updatedState
    // Back to player 0.
    #expect(state.currentPlayerIndex == 0)
    #expect(state.players[0].stuckOnBoard == 2)
    #expect(state.dartsAvailableThisVisit == 1)
    let nextOutcome = try PrisonerEngine.submitVisit(state: state, hits: [playable(18)])
    // After visit: previous stuck recovered; new stuck = 0 (no outside-double this time).
    #expect(nextOutcome.updatedState.players[0].stuckOnBoard == 0)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func prisonerRejectsMoreDartsThanAvailable() throws {
    var state = try PrisonerEngine.makeInitialState(
        config: MatchConfigPrisoner(),
        playerIds: [UUID(), UUID()]
    )
    state.players[0].stuckOnBoard = 2  // only 1 available
    #expect(throws: AppError.self) {
        _ = try PrisonerEngine.submitVisit(
            state: state,
            hits: [playable(1), playable(18)]
        )
    }
}

// MARK: - Adapter

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func prisonerDartInputAdapterMapsToHitTypes() {
    let single = DartInput(multiplier: .single, segment: .oneToTwenty(7))
    let double = DartInput(multiplier: .double, segment: .oneToTwenty(20))
    let inner = DartInput(multiplier: .double, segment: .innerBull)
    let outer = DartInput(multiplier: .single, segment: .outerBull)
    let miss = DartInput(multiplier: .single, segment: .miss, isMiss: true)
    #expect(PrisonerDartHit.from(single) == .playable(segment: 7))
    #expect(PrisonerDartHit.from(double) == .playable(segment: 20))
    #expect(PrisonerDartHit.from(inner) == .bull)
    #expect(PrisonerDartHit.from(outer) == .bull)
    #expect(PrisonerDartHit.from(miss) == .outsideDouble)
}

// MARK: - Replay

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func prisonerReplayReconstructsBoardAndProgress() throws {
    let a = UUID(); let b = UUID()
    var state = try PrisonerEngine.makeInitialState(
        config: MatchConfigPrisoner(),
        playerIds: [a, b]
    )
    var events: [PrisonerVisitEvent] = []
    let visits: [(player: UUID, hits: [PrisonerDartHit])] = [
        (a, [playable(1), innerSingle(7), outside]),  // a: advance to 18, create prisoner at 7, lose 1
        (b, [playable(1), playable(18)]),             // b: advance to 4
        (a, [playable(18)]),                           // a has 2 darts available (stuck=1) — actually pool=2, stuck=1, available=1
    ]
    for (_, hits) in visits {
        let outcome = try PrisonerEngine.submitVisit(state: state, hits: hits)
        state = outcome.updatedState
        events.append(outcome.event)
    }
    let replayed = try PrisonerEngine.replay(
        config: MatchConfigPrisoner(),
        playerIds: [a, b],
        events: events
    )
    #expect(replayed.players.first(where: { $0.playerId == a })?.progressIndex
            == state.players.first(where: { $0.playerId == a })?.progressIndex)
    #expect(replayed.players.first(where: { $0.playerId == a })?.pool
            == state.players.first(where: { $0.playerId == a })?.pool)
    #expect(replayed.players.first(where: { $0.playerId == b })?.progressIndex
            == state.players.first(where: { $0.playerId == b })?.progressIndex)
    #expect(replayed.prisoners.map(\.segment).sorted() == state.prisoners.map(\.segment).sorted())
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func prisonerSubmitAfterCompletionThrows() throws {
    var state = try PrisonerEngine.makeInitialState(
        config: MatchConfigPrisoner(),
        playerIds: [UUID(), UUID()]
    )
    state.isComplete = true
    #expect(throws: AppError.self) {
        _ = try PrisonerEngine.submitVisit(state: state, hits: [playable(1)])
    }
}
