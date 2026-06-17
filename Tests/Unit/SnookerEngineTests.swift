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

private func miss() -> DartInput {
    DartInput(multiplier: .single, segment: .miss, isMiss: true)
}

// MARK: - Setup

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func snookerRequiresExactlyTwoPlayers() {
    #expect(throws: AppError.self) {
        _ = try SnookerEngine.makeInitialState(
            config: MatchConfigSnooker(),
            playerIds: [UUID()]
        )
    }
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func snookerInitialStateHasFifteenReds() throws {
    let state = try SnookerEngine.makeInitialState(
        config: MatchConfigSnooker(),
        playerIds: [UUID(), UUID()]
    )
    #expect(state.availableReds.count == 15)
    #expect(state.phase == .awaitingRed)
    #expect(state.players.allSatisfy { $0.frameScore == 0 && $0.highestBreak == 0 })
}

// MARK: - Colour values

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func snookerColourValues() {
    #expect(SnookerColour.yellow.points == 2)
    #expect(SnookerColour.green.points == 3)
    #expect(SnookerColour.brown.points == 4)
    #expect(SnookerColour.blue.points == 5)
    #expect(SnookerColour.pink.points == 6)
    #expect(SnookerColour.black.points == 7)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func snookerColourHitDetection() {
    #expect(SnookerColour.yellow.isHit(by: single(16)))
    #expect(SnookerColour.yellow.isHit(by: triple(16)))
    #expect(!SnookerColour.yellow.isHit(by: single(17)))
    #expect(SnookerColour.black.isHit(by: innerBull()))
    #expect(!SnookerColour.black.isHit(by: triple(20)))
}

// MARK: - Red potting

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func snookerRedHitRemovesRedAndAwaitsNomination() throws {
    let state = try SnookerEngine.makeInitialState(
        config: MatchConfigSnooker(),
        playerIds: [UUID(), UUID()]
    )
    let outcome = try SnookerEngine.submitDart(state: state, dart: single(7))
    #expect(outcome.event.ballType == .red)
    #expect(outcome.event.segmentPocketed == 7)
    #expect(outcome.event.points == 1)
    #expect(outcome.updatedState.availableReds.contains(7) == false)
    #expect(outcome.updatedState.availableReds.count == 14)
    if case .awaitingNomination = outcome.updatedState.phase {
        // OK
    } else {
        Issue.record("expected awaitingNomination phase")
    }
    #expect(outcome.updatedState.players[0].frameScore == 1)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func snookerRedMissEndsBreakAndSwapsPlayer() throws {
    let a = UUID(); let b = UUID()
    var state = try SnookerEngine.makeInitialState(
        config: MatchConfigSnooker(),
        playerIds: [a, b]
    )
    let outcome = try SnookerEngine.submitDart(state: state, dart: miss())
    state = outcome.updatedState
    #expect(outcome.event.breakEnded)
    #expect(state.currentBreakerId == b)
    #expect(state.phase == .awaitingRed)
    #expect(state.players[0].frameScore == 0)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func snookerThrowAtSegmentAboveFifteenIsNotARed() throws {
    let state = try SnookerEngine.makeInitialState(
        config: MatchConfigSnooker(),
        playerIds: [UUID(), UUID()]
    )
    let outcome = try SnookerEngine.submitDart(state: state, dart: single(16))
    #expect(outcome.event.segmentPocketed == nil)
    #expect(outcome.event.breakEnded)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func snookerCannotRepottAlreadyPottedRed() throws {
    var state = try SnookerEngine.makeInitialState(
        config: MatchConfigSnooker(),
        playerIds: [UUID(), UUID()]
    )
    state.availableReds.remove(7)
    let outcome = try SnookerEngine.submitDart(state: state, dart: single(7))
    #expect(outcome.event.segmentPocketed == nil)
    #expect(outcome.event.breakEnded)
}

// MARK: - Nomination + colour

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func snookerMustNominateBeforeColourDart() throws {
    var state = try SnookerEngine.makeInitialState(
        config: MatchConfigSnooker(),
        playerIds: [UUID(), UUID()]
    )
    state = try SnookerEngine.submitDart(state: state, dart: single(1)).updatedState
    #expect(throws: AppError.self) {
        _ = try SnookerEngine.submitDart(state: state, dart: single(16))
    }
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func snookerColourHitScoresAndReturnsToRed() throws {
    var state = try SnookerEngine.makeInitialState(
        config: MatchConfigSnooker(),
        playerIds: [UUID(), UUID()]
    )
    state = try SnookerEngine.submitDart(state: state, dart: single(1)).updatedState
    state = try SnookerEngine.nominateColour(state: state, colour: .black)
    let outcome = try SnookerEngine.submitDart(state: state, dart: innerBull())
    #expect(outcome.event.points == 7)
    #expect(outcome.updatedState.players[0].frameScore == 8)  // 1 red + 7 black
    #expect(outcome.updatedState.phase == .awaitingRed)
    #expect(outcome.updatedState.availableReds.count == 14)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func snookerColourMissEndsBreak() throws {
    let a = UUID(); let b = UUID()
    var state = try SnookerEngine.makeInitialState(
        config: MatchConfigSnooker(),
        playerIds: [a, b]
    )
    state = try SnookerEngine.submitDart(state: state, dart: single(1)).updatedState
    state = try SnookerEngine.nominateColour(state: state, colour: .pink)
    let outcome = try SnookerEngine.submitDart(state: state, dart: miss())
    #expect(outcome.event.breakEnded)
    #expect(outcome.updatedState.currentBreakerId == b)
    #expect(outcome.updatedState.players[0].frameScore == 1)
    #expect(outcome.updatedState.players[0].highestBreak == 1)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func snookerLongBreakRecordsHighestBreak() throws {
    var state = try SnookerEngine.makeInitialState(
        config: MatchConfigSnooker(),
        playerIds: [UUID(), UUID()]
    )
    // Three reds + three blacks then miss.
    for n in 1 ... 3 {
        state = try SnookerEngine.submitDart(state: state, dart: single(n)).updatedState
        state = try SnookerEngine.nominateColour(state: state, colour: .black)
        state = try SnookerEngine.submitDart(state: state, dart: innerBull()).updatedState
    }
    // Miss the next red.
    state = try SnookerEngine.submitDart(state: state, dart: miss()).updatedState
    // 3 reds (3) + 3 blacks (21) = 24 break.
    #expect(state.players[0].frameScore == 24)
    #expect(state.players[0].highestBreak == 24)
}

// MARK: - Frame completion

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func snookerFrameEndsWhenLastRedAndColourPotted() throws {
    var state = try SnookerEngine.makeInitialState(
        config: MatchConfigSnooker(),
        playerIds: [UUID(), UUID()]
    )
    // Pre-set 14 reds already gone.
    state.availableReds = [7]
    state.players[0].frameScore = 50
    // Player A pots the last red and the black.
    state = try SnookerEngine.submitDart(state: state, dart: single(7)).updatedState
    state = try SnookerEngine.nominateColour(state: state, colour: .black)
    let outcome = try SnookerEngine.submitDart(state: state, dart: innerBull())
    #expect(outcome.event.frameCompleted)
    #expect(outcome.updatedState.isComplete)
    #expect(outcome.updatedState.winnerPlayerId == state.players[0].playerId)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func snookerFrameEndsWhenMissAfterAllRedsGone() throws {
    let a = UUID(); let b = UUID()
    var state = try SnookerEngine.makeInitialState(
        config: MatchConfigSnooker(),
        playerIds: [a, b]
    )
    // Player A leads 30 - 10 with no reds left.
    state.availableReds = []
    state.players[0].frameScore = 30
    state.players[1].frameScore = 10
    // It is A's turn and no reds remain — they miss.
    let outcome = try SnookerEngine.submitDart(state: state, dart: miss())
    #expect(outcome.updatedState.isComplete)
    #expect(outcome.updatedState.winnerPlayerId == a)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func snookerTieFrameLeavesWinnerNil() throws {
    var state = try SnookerEngine.makeInitialState(
        config: MatchConfigSnooker(),
        playerIds: [UUID(), UUID()]
    )
    state.availableReds = []
    state.players[0].frameScore = 25
    state.players[1].frameScore = 25
    let outcome = try SnookerEngine.submitDart(state: state, dart: miss())
    #expect(outcome.updatedState.isComplete)
    #expect(outcome.updatedState.winnerPlayerId == nil)
}

// MARK: - Phase guards

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func snookerNominateOutOfPhaseThrows() throws {
    let state = try SnookerEngine.makeInitialState(
        config: MatchConfigSnooker(),
        playerIds: [UUID(), UUID()]
    )
    #expect(throws: AppError.self) {
        _ = try SnookerEngine.nominateColour(state: state, colour: .yellow)
    }
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func snookerSubmitAfterCompletionThrows() throws {
    var state = try SnookerEngine.makeInitialState(
        config: MatchConfigSnooker(),
        playerIds: [UUID(), UUID()]
    )
    state.isComplete = true
    #expect(throws: AppError.self) {
        _ = try SnookerEngine.submitDart(state: state, dart: miss())
    }
}
