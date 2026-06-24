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

private func innerBull() -> DartInput {
    DartInput(multiplier: .double, segment: .innerBull)
}

private func outerBull() -> DartInput {
    DartInput(multiplier: .single, segment: .outerBull)
}

private func miss() -> DartInput {
    DartInput(multiplier: .single, segment: .miss, isMiss: true)
}

// MARK: - Setup

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func creaseRequiresExactlyTwoPlayers() {
    #expect(throws: AppError.self) {
        _ = try CreaseEngine.makeInitialState(
            config: MatchConfigCrease(),
            playerIds: [UUID()]
        )
    }
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func creaseRejectsUnsupportedRoundCount() {
    #expect(throws: AppError.self) {
        _ = try CreaseEngine.makeInitialState(
            config: MatchConfigCrease(roundsPerSide: 4),
            playerIds: [UUID(), UUID()]
        )
    }
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func creaseInitialStateStartsAtRoundZeroAwaitingBlock() throws {
    let state = try CreaseEngine.makeInitialState(
        config: MatchConfigCrease(),
        playerIds: [UUID(), UUID()]
    )
    #expect(state.phase == .awaitingBlock)
    #expect(state.roundIndex == 0)
    #expect(state.shooterId == state.players[0].playerId)
    #expect(state.keeperId == state.players[1].playerId)
}

// MARK: - Shot resolution

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func creaseDoubleOnBlockedSegmentIsSave() {
    #expect(CreaseEngine.resolveShot(dart: double(20), blockedSegment: 20) == .save)
    #expect(CreaseEngine.resolveShot(dart: triple(20), blockedSegment: 20) == .save)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func creaseDoubleOnOtherSegmentIsGoal() {
    #expect(CreaseEngine.resolveShot(dart: double(19), blockedSegment: 20) == .goal)
    #expect(CreaseEngine.resolveShot(dart: triple(5), blockedSegment: 20) == .goal)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func creaseSingleNeverScores() {
    #expect(CreaseEngine.resolveShot(dart: single(19), blockedSegment: 20) == .miss)
    #expect(CreaseEngine.resolveShot(dart: single(20), blockedSegment: 20) == .miss)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func creaseInnerBullCountsAsBlocked25() {
    #expect(CreaseEngine.resolveShot(dart: innerBull(), blockedSegment: 25) == .save)
    #expect(CreaseEngine.resolveShot(dart: innerBull(), blockedSegment: 20) == .goal)
    #expect(CreaseEngine.resolveShot(dart: outerBull(), blockedSegment: 20) == .miss)
    #expect(CreaseEngine.resolveShot(dart: miss(), blockedSegment: 20) == .miss)
}

// MARK: - Block guarding

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func creaseRejectsRepeatBlockBeforeVarietyThreshold() throws {
    var state = try CreaseEngine.makeInitialState(
        config: MatchConfigCrease(),
        playerIds: [UUID(), UUID()]
    )
    state = try CreaseEngine.selectBlock(state: state, segment: 20)
    state = try CreaseEngine.submitShot(state: state, dart: miss()).updatedState
    // Round 1: roles swapped. Keeper is players[0]. Now players[1] is keeper next? Let me think:
    // Round 0: shooter=players[0], keeper=players[1].
    // Round 1: shooter=players[1], keeper=players[0]. So players[1]'s block history is {20}.
    // Round 2: shooter=players[0], keeper=players[1] again.
    state = try CreaseEngine.selectBlock(state: state, segment: 5)
    state = try CreaseEngine.submitShot(state: state, dart: miss()).updatedState
    // Round 2: keeper=players[1] (history={20}).
    #expect(throws: AppError.self) {
        _ = try CreaseEngine.selectBlock(state: state, segment: 20)
    }
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func creaseRejectsBlockOutsidePool() throws {
    let state = try CreaseEngine.makeInitialState(
        config: MatchConfigCrease(),
        playerIds: [UUID(), UUID()]
    )
    #expect(throws: AppError.self) {
        _ = try CreaseEngine.selectBlock(state: state, segment: 21)
    }
    #expect(throws: AppError.self) {
        _ = try CreaseEngine.selectBlock(state: state, segment: 0)
    }
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func creaseShotBeforeBlockThrows() throws {
    let state = try CreaseEngine.makeInitialState(
        config: MatchConfigCrease(),
        playerIds: [UUID(), UUID()]
    )
    #expect(throws: AppError.self) {
        _ = try CreaseEngine.submitShot(state: state, dart: double(20))
    }
}

// MARK: - Match flow

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func creaseGoalIncrementsShooterScore() throws {
    var state = try CreaseEngine.makeInitialState(
        config: MatchConfigCrease(),
        playerIds: [UUID(), UUID()]
    )
    state = try CreaseEngine.selectBlock(state: state, segment: 20)
    let outcome = try CreaseEngine.submitShot(state: state, dart: double(19))
    #expect(outcome.event.result == .goal)
    #expect(outcome.updatedState.players[0].goals == 1)
    #expect(outcome.updatedState.players[1].goals == 0)
    #expect(outcome.updatedState.phase == .awaitingBlock)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func creaseRegulationWinnerEndsMatch() throws {
    let a = UUID(); let b = UUID()
    var state = try CreaseEngine.makeInitialState(
        config: MatchConfigCrease(roundsPerSide: 3, blockVarietyRule: false),
        playerIds: [a, b]
    )
    // 6 rounds total. a (shooter on even rounds) scores every time; b always misses.
    for round in 0 ..< 6 {
        state = try CreaseEngine.selectBlock(state: state, segment: 20)
        let dart: DartInput = round % 2 == 0 ? double(19) : miss()
        state = try CreaseEngine.submitShot(state: state, dart: dart).updatedState
    }
    #expect(state.isComplete)
    #expect(state.winnerPlayerId == a)
    #expect(state.players.first(where: { $0.playerId == a })?.goals == 3)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func creaseTiedAfterRegulationEntersSuddenDeath() throws {
    let a = UUID(); let b = UUID()
    var state = try CreaseEngine.makeInitialState(
        config: MatchConfigCrease(roundsPerSide: 3, blockVarietyRule: false),
        playerIds: [a, b]
    )
    // Tie 0-0 after regulation.
    for _ in 0 ..< 6 {
        state = try CreaseEngine.selectBlock(state: state, segment: 20)
        state = try CreaseEngine.submitShot(state: state, dart: miss()).updatedState
    }
    #expect(state.isComplete == false)
    #expect(state.isSuddenDeath)
    // Sudden-death pair: a scores, b misses → a wins.
    state = try CreaseEngine.selectBlock(state: state, segment: 20)
    state = try CreaseEngine.submitShot(state: state, dart: double(19)).updatedState
    // Match not yet complete — b still gets their try.
    #expect(state.isComplete == false)
    state = try CreaseEngine.selectBlock(state: state, segment: 20)
    state = try CreaseEngine.submitShot(state: state, dart: miss()).updatedState
    #expect(state.isComplete)
    #expect(state.winnerPlayerId == a)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func creaseSubmitAfterCompletionThrows() throws {
    var state = try CreaseEngine.makeInitialState(
        config: MatchConfigCrease(),
        playerIds: [UUID(), UUID()]
    )
    state.isComplete = true
    #expect(throws: AppError.self) {
        _ = try CreaseEngine.selectBlock(state: state, segment: 20)
    }
}
