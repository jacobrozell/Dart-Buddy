import Foundation
import Testing
@testable import DartBuddy

// MARK: - Setup

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func echoRequiresExactlyTwoPlayers() {
    #expect(throws: AppError.self) {
        _ = try EchoEngine.makeInitialState(
            config: MatchConfigEcho(),
            playerIds: [UUID()]
        )
    }
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func echoRejectsUnsupportedLives() {
    #expect(throws: AppError.self) {
        _ = try EchoEngine.makeInitialState(
            config: MatchConfigEcho(lives: 4),
            playerIds: [UUID(), UUID()]
        )
    }
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func echoInitialStatePopulatesLives() throws {
    let state = try EchoEngine.makeInitialState(
        config: MatchConfigEcho(lives: 5, targetKind: .triples),
        playerIds: [UUID(), UUID()]
    )
    #expect(state.players.allSatisfy { $0.lives == 5 })
    #expect(state.phase == .awaitingDraw)
    #expect(state.currentTarget == nil)
}

// MARK: - Pool

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func echoFullPoolSizes() {
    #expect(EchoEngine.fullPool(for: .singles).count == 20)
    #expect(EchoEngine.fullPool(for: .doubles).count == 20)
    #expect(EchoEngine.fullPool(for: .triples).count == 20)
    #expect(EchoEngine.fullPool(for: .mixed).count == 60)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func echoDrawNoRepeatUntilExhausted() throws {
    var state = try EchoEngine.makeInitialState(
        config: MatchConfigEcho(targetKind: .doubles),
        playerIds: [UUID(), UUID()]
    )
    var rng = SplitMix64(state: 42)
    var seen: Set<EchoTarget> = []
    // Draw 20 doubles → all unique.
    for _ in 0 ..< 20 {
        state = try EchoEngine.drawTarget(state: state, using: &rng)
        let target = state.currentTarget!
        #expect(!seen.contains(target))
        seen.insert(target)
        let outcome = try EchoEngine.submitVerification(state: state, wasHit: true)
        state = outcome.updatedState
        if state.isComplete { break }
    }
    #expect(seen.count == 20)
    #expect(state.remainingPool.isEmpty)
}

// MARK: - Verification flow

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func echoSetTargetThenVerifyHit() throws {
    let a = UUID(); let b = UUID()
    var state = try EchoEngine.makeInitialState(
        config: MatchConfigEcho(),
        playerIds: [a, b]
    )
    state = try EchoEngine.setTarget(state: state, target: EchoTarget(segment: 20, ring: .double))
    #expect(state.phase == .awaitingVerification)
    #expect(state.currentThrowerId == a)
    let outcome = try EchoEngine.submitVerification(state: state, wasHit: true)
    #expect(outcome.event.wasHit)
    #expect(outcome.event.throwerId == a)
    #expect(outcome.event.verifierId == b)
    #expect(outcome.event.livesAfter == 3)
    #expect(outcome.updatedState.currentThrowerId == b)
    #expect(outcome.updatedState.phase == .awaitingDraw)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func echoMissCostsALife() throws {
    var state = try EchoEngine.makeInitialState(
        config: MatchConfigEcho(),
        playerIds: [UUID(), UUID()]
    )
    state = try EchoEngine.setTarget(state: state, target: EchoTarget(segment: 16, ring: .double))
    let outcome = try EchoEngine.submitVerification(state: state, wasHit: false)
    #expect(outcome.event.wasHit == false)
    #expect(outcome.event.livesAfter == 2)
    #expect(outcome.updatedState.players[0].lives == 2)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func echoVerifyBeforeTargetThrows() throws {
    let state = try EchoEngine.makeInitialState(
        config: MatchConfigEcho(),
        playerIds: [UUID(), UUID()]
    )
    #expect(throws: AppError.self) {
        _ = try EchoEngine.submitVerification(state: state, wasHit: true)
    }
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func echoSetTargetRejectsInvalidSegment() throws {
    let state = try EchoEngine.makeInitialState(
        config: MatchConfigEcho(),
        playerIds: [UUID(), UUID()]
    )
    #expect(throws: AppError.self) {
        _ = try EchoEngine.setTarget(state: state, target: EchoTarget(segment: 25, ring: .single))
    }
}

// MARK: - Match completion

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func echoEndsWhenOpponentReachesZeroLives() throws {
    let a = UUID(); let b = UUID()
    var state = try EchoEngine.makeInitialState(
        config: MatchConfigEcho(lives: 3),
        playerIds: [a, b]
    )
    let target = EchoTarget(segment: 20, ring: .double)
    // a misses, b hits, a misses, b hits, a misses → a is eliminated.
    for _ in 0 ..< 3 {
        state = try EchoEngine.setTarget(state: state, target: target)
        state = try EchoEngine.submitVerification(state: state, wasHit: false).updatedState
        if state.isComplete { break }
        state = try EchoEngine.setTarget(state: state, target: target)
        state = try EchoEngine.submitVerification(state: state, wasHit: true).updatedState
    }
    #expect(state.isComplete)
    #expect(state.winnerPlayerId == b)
    #expect(state.players.first(where: { $0.playerId == a })?.lives == 0)
    #expect(state.players.first(where: { $0.playerId == b })?.lives == 3)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func echoSubmitAfterCompleteThrows() throws {
    var state = try EchoEngine.makeInitialState(
        config: MatchConfigEcho(),
        playerIds: [UUID(), UUID()]
    )
    state.isComplete = true
    #expect(throws: AppError.self) {
        _ = try EchoEngine.setTarget(state: state, target: EchoTarget(segment: 1, ring: .double))
    }
}

// MARK: - Replay

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func echoReplayReconstructsLives() throws {
    let a = UUID(); let b = UUID()
    let config = MatchConfigEcho(lives: 3)
    var state = try EchoEngine.makeInitialState(config: config, playerIds: [a, b])
    var events: [EchoRoundEvent] = []
    let plan: [(EchoTarget, Bool)] = [
        (EchoTarget(segment: 20, ring: .double), false),  // a misses → 2
        (EchoTarget(segment: 19, ring: .double), true),   // b hits → 3
        (EchoTarget(segment: 18, ring: .double), false),  // a misses → 1
        (EchoTarget(segment: 16, ring: .double), true),   // b hits → 3
    ]
    for (target, hit) in plan {
        state = try EchoEngine.setTarget(state: state, target: target)
        let outcome = try EchoEngine.submitVerification(state: state, wasHit: hit)
        state = outcome.updatedState
        events.append(outcome.event)
    }
    let replayed = try EchoEngine.replay(config: config, playerIds: [a, b], events: events)
    #expect(replayed.players.first(where: { $0.playerId == a })?.lives == 1)
    #expect(replayed.players.first(where: { $0.playerId == b })?.lives == 3)
    #expect(replayed.roundIndex == 4)
    #expect(replayed.isComplete == false)
}
