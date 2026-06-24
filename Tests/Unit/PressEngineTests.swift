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
func pressRequiresTwoToFourPlayers() {
    #expect(throws: AppError.self) {
        _ = try PressEngine.makeInitialState(
            config: MatchConfigPress(),
            playerIds: [UUID()]
        )
    }
    #expect(throws: AppError.self) {
        _ = try PressEngine.makeInitialState(
            config: MatchConfigPress(),
            playerIds: Array(repeating: UUID(), count: 5).map { _ in UUID() }
        )
    }
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func pressRejectsUnsupportedWinScores() {
    #expect(throws: AppError.self) {
        _ = try PressEngine.makeInitialState(
            config: MatchConfigPress(pointsToWin: 42),
            playerIds: [UUID(), UUID()]
        )
    }
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func pressInitialStateAwaitsCall() throws {
    let state = try PressEngine.makeInitialState(
        config: MatchConfigPress(),
        playerIds: [UUID(), UUID()]
    )
    #expect(state.phase == .awaitingCall)
    #expect(state.calledSegment == nil)
    #expect(state.ladderStep == 0)
    #expect(state.roundValue == 0)
}

// MARK: - Phase enforcement

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func pressDartBeforeCallThrows() throws {
    let state = try PressEngine.makeInitialState(
        config: MatchConfigPress(),
        playerIds: [UUID(), UUID()]
    )
    #expect(throws: AppError.self) {
        _ = try PressEngine.submitDart(state: state, dart: single(20))
    }
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func pressCallRejectsInvalidSegment() throws {
    let state = try PressEngine.makeInitialState(
        config: MatchConfigPress(),
        playerIds: [UUID(), UUID()]
    )
    #expect(throws: AppError.self) {
        _ = try PressEngine.callSegment(state: state, segment: 25)
    }
    #expect(throws: AppError.self) {
        _ = try PressEngine.callSegment(state: state, segment: 0)
    }
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func pressBankBeforeHitThrows() throws {
    let state = try PressEngine.makeInitialState(
        config: MatchConfigPress(),
        playerIds: [UUID(), UUID()]
    )
    let called = try PressEngine.callSegment(state: state, segment: 20)
    #expect(throws: AppError.self) {
        _ = try PressEngine.bank(state: called)
    }
}

// MARK: - Ladder

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func pressSingleHitOffersDecisionWithBankValueOne() throws {
    var state = try PressEngine.makeInitialState(
        config: MatchConfigPress(),
        playerIds: [UUID(), UUID()]
    )
    state = try PressEngine.callSegment(state: state, segment: 20)
    let outcome = try PressEngine.submitDart(state: state, dart: single(20))
    #expect(outcome.event == nil)
    #expect(outcome.updatedState.phase == .decision)
    #expect(outcome.updatedState.ladderStep == 1)
    #expect(outcome.updatedState.roundValue == 1)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func pressBankAddsRoundValueAndRotates() throws {
    let a = UUID(); let b = UUID()
    var state = try PressEngine.makeInitialState(
        config: MatchConfigPress(),
        playerIds: [a, b]
    )
    state = try PressEngine.callSegment(state: state, segment: 20)
    state = try PressEngine.submitDart(state: state, dart: single(20)).updatedState
    let banked = try PressEngine.bank(state: state)
    #expect(banked.event.pointsBanked == 1)
    #expect(banked.event.resolution == .banked)
    #expect(banked.updatedState.players[0].score == 1)
    #expect(banked.updatedState.currentPlayerIndex == 1)
    #expect(banked.updatedState.phase == .awaitingCall)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func pressMissBustsAndRotatesWithoutScore() throws {
    var state = try PressEngine.makeInitialState(
        config: MatchConfigPress(),
        playerIds: [UUID(), UUID()]
    )
    state = try PressEngine.callSegment(state: state, segment: 20)
    // Hit single, press, miss double → bust losing the 1.
    state = try PressEngine.submitDart(state: state, dart: single(20)).updatedState
    state = try PressEngine.press(state: state)
    let busted = try PressEngine.submitDart(state: state, dart: miss())
    #expect(busted.event?.resolution == .bust)
    #expect(busted.event?.pointsBanked == 0)
    #expect(busted.updatedState.players[0].score == 0)
    #expect(busted.updatedState.currentPlayerIndex == 1)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func pressBankReplacesNotAccumulates() throws {
    // Hitting single (1) then double (3) and banking should give 3, not 4.
    var state = try PressEngine.makeInitialState(
        config: MatchConfigPress(),
        playerIds: [UUID(), UUID()]
    )
    state = try PressEngine.callSegment(state: state, segment: 20)
    state = try PressEngine.submitDart(state: state, dart: single(20)).updatedState
    state = try PressEngine.press(state: state)
    state = try PressEngine.submitDart(state: state, dart: double(20)).updatedState
    let banked = try PressEngine.bank(state: state)
    #expect(banked.event.pointsBanked == 3)
    #expect(banked.updatedState.players[0].score == 3)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func pressTripleHitAutoBanksSeven() throws {
    var state = try PressEngine.makeInitialState(
        config: MatchConfigPress(),
        playerIds: [UUID(), UUID()]
    )
    state = try PressEngine.callSegment(state: state, segment: 19)
    state = try PressEngine.submitDart(state: state, dart: single(19)).updatedState
    state = try PressEngine.press(state: state)
    state = try PressEngine.submitDart(state: state, dart: double(19)).updatedState
    state = try PressEngine.press(state: state)
    let outcome = try PressEngine.submitDart(state: state, dart: triple(19))
    #expect(outcome.event?.resolution == .autoBanked)
    #expect(outcome.event?.pointsBanked == 7)
    #expect(outcome.updatedState.players[0].score == 7)
    #expect(outcome.updatedState.phase == .awaitingCall)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func pressWrongSegmentIsAMiss() throws {
    var state = try PressEngine.makeInitialState(
        config: MatchConfigPress(),
        playerIds: [UUID(), UUID()]
    )
    state = try PressEngine.callSegment(state: state, segment: 20)
    // Throw single 19 (wrong segment) → miss → bust.
    let outcome = try PressEngine.submitDart(state: state, dart: single(19))
    #expect(outcome.event?.resolution == .bust)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func pressWrongMultiplierIsAMiss() throws {
    var state = try PressEngine.makeInitialState(
        config: MatchConfigPress(),
        playerIds: [UUID(), UUID()]
    )
    state = try PressEngine.callSegment(state: state, segment: 20)
    // Step 0 requires single — a double-20 does not count.
    let outcome = try PressEngine.submitDart(state: state, dart: double(20))
    #expect(outcome.event?.resolution == .bust)
}

// MARK: - Match completion

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func pressWinsOnceScoreReachesTarget() throws {
    let a = UUID(); let b = UUID()
    var state = try PressEngine.makeInitialState(
        config: MatchConfigPress(pointsToWin: 30),
        playerIds: [a, b]
    )
    // a banks 7 four times = 28; then 7 more = 35 ≥ 30.
    func aTripleRound() throws {
        state = try PressEngine.callSegment(state: state, segment: 20)
        state = try PressEngine.submitDart(state: state, dart: single(20)).updatedState
        state = try PressEngine.press(state: state)
        state = try PressEngine.submitDart(state: state, dart: double(20)).updatedState
        state = try PressEngine.press(state: state)
        state = try PressEngine.submitDart(state: state, dart: triple(20)).updatedState
    }
    func bBust() throws {
        state = try PressEngine.callSegment(state: state, segment: 5)
        state = try PressEngine.submitDart(state: state, dart: miss()).updatedState
    }
    try aTripleRound()
    try bBust()
    try aTripleRound()
    try bBust()
    try aTripleRound()
    try bBust()
    try aTripleRound()
    try bBust()
    try aTripleRound()
    #expect(state.isComplete)
    #expect(state.winnerPlayerId == a)
    #expect(state.players[0].score >= 30)
}
