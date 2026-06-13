import Foundation
import Testing
@testable import DartBuddy

private func golfDart(_ multiplier: DartMultiplier, _ segment: Int) -> DartInput {
    DartInput(multiplier: multiplier, segment: .oneToTwenty(segment))
}

private func missDart() -> DartInput {
    DartInput(multiplier: .single, segment: .miss, isMiss: true)
}

// MARK: - Last-dart stroke resolution

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func golfDoubleOnTargetScoresOneStroke() throws {
    #expect(GolfEngine.strokesForLastDart(golfDart(.double, 5), holeSegment: 5) == 1)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func golfTripleOnTargetScoresTwoStrokes() throws {
    #expect(GolfEngine.strokesForLastDart(golfDart(.triple, 3), holeSegment: 3) == 2)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func golfSingleOnTargetScoresThreeStrokes() throws {
    #expect(GolfEngine.strokesForLastDart(golfDart(.single, 7), holeSegment: 7) == 3)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func golfMissScoresFiveStrokes() throws {
    #expect(GolfEngine.strokesForLastDart(missDart(), holeSegment: 1) == 5)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func golfOffTargetScoresFiveStrokes() throws {
    #expect(GolfEngine.strokesForLastDart(golfDart(.triple, 4), holeSegment: 2) == 5)
}

// MARK: - Engine submit: last dart counts

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func golfLastDartCountsNotFirst() throws {
    let players = [UUID(), UUID()]
    let state = try GolfEngine.makeInitialState(config: MatchConfigGolf(), playerIds: players)

    // First dart hits double (would be 1 stroke), last dart is miss (5 strokes)
    let input = GolfTurnInput(darts: [golfDart(.double, 1), missDart()])
    let outcome = try GolfEngine.submitTurn(state: state, input: input)

    #expect(outcome.event.strokesRecorded == 5, "Last dart (miss) should record 5 strokes")
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func golfLastDartTripleAfterMissScoresTwoStrokes() throws {
    let players = [UUID(), UUID()]
    let state = try GolfEngine.makeInitialState(config: MatchConfigGolf(), playerIds: players)

    // First dart misses, last dart is triple on segment 1
    let input = GolfTurnInput(darts: [missDart(), golfDart(.triple, 1)])
    let outcome = try GolfEngine.submitTurn(state: state, input: input)

    #expect(outcome.event.strokesRecorded == 2)
}

// MARK: - Early end

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func golfEarlyEndAfterOneDartRecordsCorrectly() throws {
    let players = [UUID(), UUID()]
    let state = try GolfEngine.makeInitialState(config: MatchConfigGolf(), playerIds: players)

    let input = GolfTurnInput(darts: [golfDart(.double, 1)], endedEarly: true)
    let outcome = try GolfEngine.submitTurn(state: state, input: input)

    #expect(outcome.event.strokesRecorded == 1)
    #expect(outcome.event.endedEarly == true)
    #expect(outcome.event.darts.count == 1)
}

// MARK: - Player rotation and hole advancement

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func golfHoleAdvancesAfterAllPlayersComplete() throws {
    let players = [UUID(), UUID()]
    var state = try GolfEngine.makeInitialState(config: MatchConfigGolf(), playerIds: players)
    #expect(state.currentHole == 1)

    state = try GolfEngine.submitTurn(state: state, input: GolfTurnInput(darts: [golfDart(.single, 1)])).updatedState
    #expect(state.currentPlayerIndex == 1)
    #expect(state.currentHole == 1)

    state = try GolfEngine.submitTurn(state: state, input: GolfTurnInput(darts: [golfDart(.single, 1)])).updatedState
    #expect(state.currentPlayerIndex == 0)
    #expect(state.currentHole == 2)
}

// MARK: - Win condition (lowest strokes)

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func golfLowestStrokesWinsNineHoleCourse() throws {
    let p1 = UUID()
    let p2 = UUID()
    var state = try GolfEngine.makeInitialState(config: MatchConfigGolf(courseLength: .nine), playerIds: [p1, p2])

    // Play all 9 holes; p1 always doubles (1 stroke), p2 always misses (5 strokes)
    for hole in 1 ... 9 {
        // p1 throws double on current hole
        let p1Input = GolfTurnInput(darts: [golfDart(.double, hole)])
        state = try GolfEngine.submitTurn(state: state, input: p1Input).updatedState
        // p2 misses
        let p2Input = GolfTurnInput(darts: [missDart()])
        state = try GolfEngine.submitTurn(state: state, input: p2Input).updatedState
    }

    #expect(state.isComplete)
    #expect(state.winnerPlayerId == p1)
    // p1: 9 holes × 1 stroke = 9; p2: 9 × 5 = 45
    #expect(state.players.first(where: { $0.playerId == p1 })?.runningTotal == 9)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func golfLowestStrokesWinsEighteenHoleCourse() throws {
    let p1 = UUID()
    let p2 = UUID()
    var state = try GolfEngine.makeInitialState(config: MatchConfigGolf(courseLength: .eighteen), playerIds: [p1, p2])

    for hole in 1 ... 18 {
        state = try GolfEngine.submitTurn(state: state, input: GolfTurnInput(darts: [golfDart(.double, hole)])).updatedState
        state = try GolfEngine.submitTurn(state: state, input: GolfTurnInput(darts: [missDart()])).updatedState
    }

    #expect(state.isComplete)
    #expect(state.winnerPlayerId == p1)
    #expect(state.players.first(where: { $0.playerId == p1 })?.runningTotal == 18)
}

// MARK: - Tie: no single winner

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func golfTieProducesNoWinnerButCompletes() throws {
    let p1 = UUID()
    let p2 = UUID()
    var state = try GolfEngine.makeInitialState(config: MatchConfigGolf(courseLength: .nine), playerIds: [p1, p2])

    // Both players miss every hole → tied at 45 each
    for _ in 1 ... 9 {
        state = try GolfEngine.submitTurn(state: state, input: GolfTurnInput(darts: [missDart()])).updatedState
        state = try GolfEngine.submitTurn(state: state, input: GolfTurnInput(darts: [missDart()])).updatedState
    }

    #expect(state.isComplete)
    #expect(state.winnerPlayerId == nil)
}

// MARK: - Invalid input guards

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func golfRejectsTooManyDarts() throws {
    let players = [UUID(), UUID()]
    let state = try GolfEngine.makeInitialState(config: MatchConfigGolf(), playerIds: players)
    let input = GolfTurnInput(darts: [golfDart(.single, 1), golfDart(.single, 1), golfDart(.single, 1), golfDart(.single, 1)])

    #expect(throws: AppError.self) {
        try GolfEngine.submitTurn(state: state, input: input)
    }
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func golfRejectsEmptyDarts() throws {
    let players = [UUID(), UUID()]
    let state = try GolfEngine.makeInitialState(config: MatchConfigGolf(), playerIds: players)
    let input = GolfTurnInput(darts: [])

    #expect(throws: AppError.self) {
        try GolfEngine.submitTurn(state: state, input: input)
    }
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func golfRejectsSubmitOnCompletedMatch() throws {
    let p1 = UUID()
    let p2 = UUID()
    var state = try GolfEngine.makeInitialState(config: MatchConfigGolf(courseLength: .nine), playerIds: [p1, p2])

    for hole in 1 ... 9 {
        state = try GolfEngine.submitTurn(state: state, input: GolfTurnInput(darts: [golfDart(.double, hole)])).updatedState
        state = try GolfEngine.submitTurn(state: state, input: GolfTurnInput(darts: [missDart()])).updatedState
    }

    #expect(state.isComplete)
    #expect(throws: AppError.self) {
        try GolfEngine.submitTurn(state: state, input: GolfTurnInput(darts: [golfDart(.single, 1)]))
    }
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func golfRejectsTooFewPlayers() throws {
    #expect(throws: AppError.self) {
        try GolfEngine.makeInitialState(config: MatchConfigGolf(), playerIds: [UUID()])
    }
}

// MARK: - Replay round-trip

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func golfReplayRestoresState() throws {
    let p1 = UUID()
    let p2 = UUID()
    let config = MatchConfigGolf(courseLength: .nine)
    var state = try GolfEngine.makeInitialState(config: config, playerIds: [p1, p2])

    let first = try GolfEngine.submitTurn(state: state, input: GolfTurnInput(darts: [golfDart(.double, 1)]))
    state = first.updatedState
    let second = try GolfEngine.submitTurn(state: state, input: GolfTurnInput(darts: [golfDart(.triple, 1)]))

    let replayed = try GolfEngine.replay(
        config: config,
        playerIds: [p1, p2],
        events: [first.event, second.event]
    )

    #expect(replayed.players[0].strokesByHole[1] == 1)
    #expect(replayed.players[1].strokesByHole[1] == 2)
    #expect(replayed.currentHole == 2)
}

// MARK: - Running total accumulates

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func golfRunningTotalAccumulatesAcrossHoles() throws {
    let players = [UUID(), UUID()]
    var state = try GolfEngine.makeInitialState(config: MatchConfigGolf(courseLength: .nine), playerIds: players)

    // Hole 1: single (3 strokes)
    state = try GolfEngine.submitTurn(state: state, input: GolfTurnInput(darts: [golfDart(.single, 1)])).updatedState
    // p2 hole 1
    state = try GolfEngine.submitTurn(state: state, input: GolfTurnInput(darts: [missDart()])).updatedState
    // Hole 2: double (1 stroke)
    state = try GolfEngine.submitTurn(state: state, input: GolfTurnInput(darts: [golfDart(.double, 2)])).updatedState

    #expect(state.players[0].runningTotal == 4)
}
