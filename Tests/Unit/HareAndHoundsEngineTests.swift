import Foundation
import Testing
@testable import DartBuddy

// MARK: - Helpers

private let course = MatchConfigHareAndHounds.clockwiseCourse

private func hit(_ segment: Int) -> DartInput {
    DartInput(multiplier: .single, segment: .oneToTwenty(segment))
}

private func miss() -> DartInput {
    DartInput(multiplier: .single, segment: .miss, isMiss: true)
}

private func wrongSegment(_ segment: Int) -> DartInput {
    // A dart that is not a miss but hits a different segment
    let other = segment == 20 ? 1 : 20
    return DartInput(multiplier: .single, segment: .oneToTwenty(other))
}

// MARK: - Initial State

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func hareAndHoundsInitialStateHareStartsAt20() throws {
    let hare = UUID()
    let hound = UUID()
    let state = try HareAndHoundsEngine.makeInitialState(
        config: MatchConfigHareAndHounds(houndStart: .segment5),
        playerIds: [hare, hound]
    )
    let harePlayer = state.players.first { $0.role == .hare }
    #expect(harePlayer?.positionIndex == 0)
    #expect(harePlayer?.currentSegment == 20)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func hareAndHoundsInitialStateHoundStartsAtSegment5() throws {
    let state = try HareAndHoundsEngine.makeInitialState(
        config: MatchConfigHareAndHounds(houndStart: .segment5),
        playerIds: [UUID(), UUID()]
    )
    let houndPlayer = state.players.first { $0.role == .hound }
    #expect(houndPlayer?.currentSegment == 5)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func hareAndHoundsInitialStateHoundStartsAtSegment12() throws {
    let state = try HareAndHoundsEngine.makeInitialState(
        config: MatchConfigHareAndHounds(houndStart: .segment12),
        playerIds: [UUID(), UUID()]
    )
    let houndPlayer = state.players.first { $0.role == .hound }
    #expect(houndPlayer?.currentSegment == 12)
}

@Test(.tags(.unit, .match, .offline, .regression))
func hareAndHoundsRequiresExactlyTwoPlayers() throws {
    #expect(throws: AppError.self) {
        try HareAndHoundsEngine.makeInitialState(
            config: MatchConfigHareAndHounds(),
            playerIds: [UUID()]
        )
    }
    #expect(throws: AppError.self) {
        try HareAndHoundsEngine.makeInitialState(
            config: MatchConfigHareAndHounds(),
            playerIds: [UUID(), UUID(), UUID()]
        )
    }
}

// MARK: - Turn Progression

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func hareAndHoundsHitAdvancesHareOnePosition() throws {
    let hare = UUID()
    let hound = UUID()
    let state = try HareAndHoundsEngine.makeInitialState(
        config: MatchConfigHareAndHounds(houndStart: .segment5),
        playerIds: [hare, hound]
    )
    // Hare is at 20 (index 0), next segment clockwise is 1 (index 1).
    let outcome = try HareAndHoundsEngine.submitTurn(
        state: state,
        darts: [hit(20), miss(), miss()]
    )
    let harePlayer = outcome.updatedState.players.first { $0.role == .hare }
    #expect(harePlayer?.positionIndex == 1)
    #expect(harePlayer?.currentSegment == 1)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func hareAndHoundsMissDoesNotAdvancePosition() throws {
    let state = try HareAndHoundsEngine.makeInitialState(
        config: MatchConfigHareAndHounds(),
        playerIds: [UUID(), UUID()]
    )
    let outcome = try HareAndHoundsEngine.submitTurn(
        state: state,
        darts: [miss(), miss(), miss()]
    )
    let harePlayer = outcome.updatedState.players.first { $0.role == .hare }
    #expect(harePlayer?.positionIndex == 0)
}

@Test(.tags(.unit, .match, .offline, .regression))
func hareAndHoundsWrongSegmentDoesNotAdvance() throws {
    let state = try HareAndHoundsEngine.makeInitialState(
        config: MatchConfigHareAndHounds(),
        playerIds: [UUID(), UUID()]
    )
    let outcome = try HareAndHoundsEngine.submitTurn(
        state: state,
        darts: [hit(1), hit(5), hit(18)] // Hare target is 20
    )
    let harePlayer = outcome.updatedState.players.first { $0.role == .hare }
    #expect(harePlayer?.positionIndex == 0)
}

@Test(.tags(.unit, .match, .offline, .regression))
func hareAndHoundsOnlyFirstHitCountsPerVisit() throws {
    let hare = UUID()
    let state = try HareAndHoundsEngine.makeInitialState(
        config: MatchConfigHareAndHounds(),
        playerIds: [hare, UUID()]
    )
    // Three hits on the target — should only advance once.
    let outcome = try HareAndHoundsEngine.submitTurn(
        state: state,
        darts: [hit(20), hit(20), hit(20)]
    )
    let harePlayer = outcome.updatedState.players.first { $0.role == .hare }
    #expect(harePlayer?.positionIndex == 1)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func hareAndHoundsTurnAlternatesBetweenPlayers() throws {
    let hare = UUID()
    let hound = UUID()
    var state = try HareAndHoundsEngine.makeInitialState(
        config: MatchConfigHareAndHounds(houndStart: .segment5),
        playerIds: [hare, hound]
    )
    #expect(state.currentPlayerIndex == 0)
    #expect(state.players[state.currentPlayerIndex].role == .hare)

    state = try HareAndHoundsEngine.submitTurn(state: state, darts: [miss()]).updatedState
    #expect(state.currentPlayerIndex == 1)
    #expect(state.players[state.currentPlayerIndex].role == .hound)

    state = try HareAndHoundsEngine.submitTurn(state: state, darts: [miss()]).updatedState
    #expect(state.currentPlayerIndex == 0)
}

// MARK: - Win Conditions

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func hareAndHoundsHoundOvertakeWin() throws {
    let hare = UUID()
    let hound = UUID()

    // Place Hare at index 2 (segment 18), Hound at index 1 (segment 1).
    // Hound hits its target → advances to index 2 → equals Hare → Hound wins.
    var config = MatchConfigHareAndHounds(houndStart: .segment5)
    var state = try HareAndHoundsEngine.makeInitialState(config: config, playerIds: [hare, hound])

    // Manually set positions via replay trick: advance Hare to index 2 via two turns.
    // Hare turn 1 — hit 20 → advance to index 1
    state = try HareAndHoundsEngine.submitTurn(state: state, darts: [hit(20)]).updatedState
    // Hound turn 1 — miss (Hound stays at segment5 index)
    state = try HareAndHoundsEngine.submitTurn(state: state, darts: [miss()]).updatedState
    // Hare turn 2 — hit 1 → advance to index 2
    state = try HareAndHoundsEngine.submitTurn(state: state, darts: [hit(1)]).updatedState

    // Hound is now at segment5 (index 19). For a quicker overtake test, build a state
    // with Hound just behind Hare. Use replay to construct the scenario.
    let segment5Index = course.firstIndex(of: 5)!
    // The hound at index 19, hare at index 2 — not adjacent enough to test cleanly via
    // normal turns. Instead advance the hound by hitting its targets repeatedly until
    // it's one step behind the hare (index 1).
    // Skip this indirect test in favour of a direct event-replay based state construction:
    let directEvents: [HareAndHoundsTurnEvent] = [
        HareAndHoundsTurnEvent(id: UUID(), playerId: hare, turnIndex: 0, role: .hare,
                               positionBefore: 0, positionAfter: 2, winReason: nil, timestamp: Date()),
        HareAndHoundsTurnEvent(id: UUID(), playerId: hound, turnIndex: 1, role: .hound,
                               positionBefore: segment5Index, positionAfter: 1,
                               winReason: nil, timestamp: Date()),
    ]
    var replayState = try HareAndHoundsEngine.replay(
        config: MatchConfigHareAndHounds(houndStart: .segment5),
        playerIds: [hare, hound],
        events: directEvents
    )
    // Hare is at index 2, Hound is at index 1. Hound's turn; Hound target is course[1]=1.
    // Hit the segment to advance Hound to index 2, equalling Hare → Hound wins.
    replayState.currentPlayerIndex = 1 // Hound's turn
    let houndTarget = course[1] // segment 1
    let outcome = try HareAndHoundsEngine.submitTurn(state: replayState, darts: [hit(houndTarget)])
    #expect(outcome.updatedState.isComplete)
    #expect(outcome.updatedState.winnerPlayerId == hound)
    #expect(outcome.updatedState.winReason == .houndOvertook)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func hareAndHoundsHareLapCompleteWin() throws {
    let hare = UUID()
    let hound = UUID()

    // Build a state with Hare at the last position (index 19, segment 5).
    // When Hare hits 5, positionIndex becomes 20 (= courseLength) → Hare wins.
    let finalEvents: [HareAndHoundsTurnEvent] = [
        HareAndHoundsTurnEvent(id: UUID(), playerId: hare, turnIndex: 0, role: .hare,
                               positionBefore: 0, positionAfter: 19, winReason: nil, timestamp: Date()),
        HareAndHoundsTurnEvent(id: UUID(), playerId: hound, turnIndex: 1, role: .hound,
                               positionBefore: 19, positionAfter: 0, winReason: nil, timestamp: Date()),
    ]
    var state = try HareAndHoundsEngine.replay(
        config: MatchConfigHareAndHounds(houndStart: .segment5),
        playerIds: [hare, hound],
        events: finalEvents
    )
    // Hare is at index 19 (segment 5). Hound is at index 0 (segment 20). Hare's turn.
    state.currentPlayerIndex = 0
    let outcome = try HareAndHoundsEngine.submitTurn(state: state, darts: [hit(5)])
    #expect(outcome.updatedState.isComplete)
    #expect(outcome.updatedState.winnerPlayerId == hare)
    #expect(outcome.updatedState.winReason == .hareLapComplete)
}

// MARK: - Error Handling

@Test(.tags(.unit, .match, .offline, .regression))
func hareAndHoundsSubmitOnCompletedMatchThrows() throws {
    let hare = UUID()
    let hound = UUID()
    var state = try HareAndHoundsEngine.makeInitialState(
        config: MatchConfigHareAndHounds(houndStart: .segment5),
        playerIds: [hare, hound]
    )
    // Force complete
    let finalEvents: [HareAndHoundsTurnEvent] = [
        HareAndHoundsTurnEvent(id: UUID(), playerId: hare, turnIndex: 0, role: .hare,
                               positionBefore: 0, positionAfter: 19, winReason: nil, timestamp: Date()),
    ]
    state = try HareAndHoundsEngine.replay(
        config: MatchConfigHareAndHounds(houndStart: .segment5),
        playerIds: [hare, hound],
        events: [
            HareAndHoundsTurnEvent(id: UUID(), playerId: hare, turnIndex: 0, role: .hare,
                                   positionBefore: 0, positionAfter: 0, winReason: .hareLapComplete, timestamp: Date()),
        ]
    )
    #expect(state.isComplete)
    #expect(throws: AppError.self) {
        try HareAndHoundsEngine.submitTurn(state: state, darts: [miss()])
    }
}

@Test(.tags(.unit, .match, .offline, .regression))
func hareAndHoundsTooManyDartsThrows() throws {
    let state = try HareAndHoundsEngine.makeInitialState(
        config: MatchConfigHareAndHounds(),
        playerIds: [UUID(), UUID()]
    )
    #expect(throws: AppError.self) {
        try HareAndHoundsEngine.submitTurn(
            state: state,
            darts: [miss(), miss(), miss(), miss()]
        )
    }
}

// MARK: - Replay Round-trip

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func hareAndHoundsReplayRestoresState() throws {
    let hare = UUID()
    let hound = UUID()
    var state = try HareAndHoundsEngine.makeInitialState(
        config: MatchConfigHareAndHounds(houndStart: .segment5),
        playerIds: [hare, hound]
    )

    let outcome1 = try HareAndHoundsEngine.submitTurn(state: state, darts: [hit(20)])
    state = outcome1.updatedState
    let outcome2 = try HareAndHoundsEngine.submitTurn(state: state, darts: [miss()])
    state = outcome2.updatedState

    let replayed = try HareAndHoundsEngine.replay(
        config: MatchConfigHareAndHounds(houndStart: .segment5),
        playerIds: [hare, hound],
        events: [outcome1.event, outcome2.event]
    )

    let hareInOriginal = state.players.first { $0.role == .hare }
    let hareInReplay = replayed.players.first { $0.role == .hare }
    #expect(hareInOriginal?.positionIndex == hareInReplay?.positionIndex)
    #expect(state.currentPlayerIndex == replayed.currentPlayerIndex)
    #expect(state.isComplete == replayed.isComplete)
}

// MARK: - Course Order

@Test(.tags(.unit, .offline, .regression))
func hareAndHoundsCourseContainsAllTwentySegments() {
    let course = MatchConfigHareAndHounds.clockwiseCourse
    #expect(course.count == 20)
    #expect(Set(course) == Set(1 ... 20))
    #expect(course.first == 20)
    #expect(course.last == 5)
}
