import Foundation
import Testing
@testable import DartBuddy

private func atcDart(_ multiplier: DartMultiplier, _ segment: Int) -> DartInput {
    DartInput(multiplier: multiplier, segment: .oneToTwenty(segment))
}

private func missDart() -> DartInput {
    DartInput(multiplier: .single, segment: .miss, isMiss: true)
}

// MARK: - Scoring table

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func atc180TrebleScoresThreePoints() throws {
    let player = UUID()
    let state = try AroundTheClock180Engine.makeInitialState(
        config: MatchConfigAroundTheClock180(),
        playerIds: [player]
    )
    #expect(state.currentNumber == 1)

    let outcome = try AroundTheClock180Engine.submitTurn(
        state: state,
        darts: [atcDart(.triple, 1), atcDart(.triple, 1), atcDart(.triple, 1)]
    )

    // Three trebles on number 1 → 3 + 3 + 3 = 9 pts
    #expect(outcome.event.pointsThisVisit == 9)
    #expect(outcome.updatedState.players[0].cumulativePoints == 9)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func atc180SingleScoresOnePoint() throws {
    let player = UUID()
    let state = try AroundTheClock180Engine.makeInitialState(
        config: MatchConfigAroundTheClock180(),
        playerIds: [player]
    )

    let outcome = try AroundTheClock180Engine.submitTurn(
        state: state,
        darts: [atcDart(.single, 1)]
    )

    #expect(outcome.event.pointsThisVisit == 1)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func atc180DoubleScoresOnePoint() throws {
    let player = UUID()
    let state = try AroundTheClock180Engine.makeInitialState(
        config: MatchConfigAroundTheClock180(),
        playerIds: [player]
    )

    let outcome = try AroundTheClock180Engine.submitTurn(
        state: state,
        darts: [atcDart(.double, 1)]
    )

    #expect(outcome.event.pointsThisVisit == 1)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func atc180MissScoresZeroPoints() throws {
    let player = UUID()
    let state = try AroundTheClock180Engine.makeInitialState(
        config: MatchConfigAroundTheClock180(),
        playerIds: [player]
    )

    let outcome = try AroundTheClock180Engine.submitTurn(
        state: state,
        darts: [missDart(), missDart(), missDart()]
    )

    #expect(outcome.event.pointsThisVisit == 0)
    #expect(outcome.updatedState.players[0].cumulativePoints == 0)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func atc180OffTargetDartScoresZero() throws {
    let player = UUID()
    let state = try AroundTheClock180Engine.makeInitialState(
        config: MatchConfigAroundTheClock180(),
        playerIds: [player]
    )
    // Aiming at number 5 while current target is 1 → zero.
    let outcome = try AroundTheClock180Engine.submitTurn(
        state: state,
        darts: [atcDart(.triple, 5)]
    )

    #expect(outcome.event.pointsThisVisit == 0)
}

// MARK: - Perfect score

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func atc180PerfectScoreIs180() throws {
    let player = UUID()
    var state = try AroundTheClock180Engine.makeInitialState(
        config: MatchConfigAroundTheClock180(),
        playerIds: [player]
    )

    for number in 1 ... 20 {
        #expect(state.currentNumber == number)
        state = try AroundTheClock180Engine.submitTurn(
            state: state,
            darts: [atcDart(.triple, number), atcDart(.triple, number), atcDart(.triple, number)]
        ).updatedState
    }

    #expect(state.isComplete)
    #expect(state.players[0].cumulativePoints == AroundTheClock180Engine.perfectScore)
    #expect(state.winnerPlayerId == player)
}

// MARK: - Number progression

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func atc180AdvancesToNextNumberAfterThreeDarts() throws {
    let player = UUID()
    let state = try AroundTheClock180Engine.makeInitialState(
        config: MatchConfigAroundTheClock180(),
        playerIds: [player]
    )

    let next = try AroundTheClock180Engine.submitTurn(
        state: state,
        darts: [missDart(), missDart(), missDart()]
    ).updatedState

    #expect(next.currentNumber == 2)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func atc180AlwaysAdvancesRegardlessOfScore() throws {
    let player = UUID()
    var state = try AroundTheClock180Engine.makeInitialState(
        config: MatchConfigAroundTheClock180(),
        playerIds: [player]
    )

    // Even with max score, always advances.
    state = try AroundTheClock180Engine.submitTurn(
        state: state,
        darts: [atcDart(.triple, 1), atcDart(.triple, 1), atcDart(.triple, 1)]
    ).updatedState

    #expect(state.currentNumber == 2)
    #expect(state.isComplete == false)
}

// MARK: - Multiplayer rotation

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func atc180PlayerRotationGoesRoundRobin() throws {
    let players = [UUID(), UUID(), UUID()]
    var state = try AroundTheClock180Engine.makeInitialState(
        config: MatchConfigAroundTheClock180(),
        playerIds: players
    )

    state = try AroundTheClock180Engine.submitTurn(state: state, darts: [missDart()]).updatedState
    #expect(state.currentPlayerIndex == 1)
    #expect(state.currentNumber == 1) // Not yet advanced — only p0 has thrown.

    state = try AroundTheClock180Engine.submitTurn(state: state, darts: [missDart()]).updatedState
    #expect(state.currentPlayerIndex == 2)

    state = try AroundTheClock180Engine.submitTurn(state: state, darts: [missDart()]).updatedState
    // All players done on number 1 → advance to 2.
    #expect(state.currentPlayerIndex == 0)
    #expect(state.currentNumber == 2)
}

// MARK: - Multiplayer win condition

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func atc180HighestTotalWinsMultiplayer() throws {
    let p1 = UUID()
    let p2 = UUID()
    var state = try AroundTheClock180Engine.makeInitialState(
        config: MatchConfigAroundTheClock180(),
        playerIds: [p1, p2]
    )

    // Play all 20 numbers: p1 scores 3 pts per number, p2 scores 0.
    for number in 1 ... 20 {
        // p1 throws treble.
        state = try AroundTheClock180Engine.submitTurn(
            state: state,
            darts: [atcDart(.triple, number)]
        ).updatedState
        // p2 misses.
        state = try AroundTheClock180Engine.submitTurn(
            state: state,
            darts: [missDart()]
        ).updatedState
    }

    #expect(state.isComplete)
    #expect(state.winnerPlayerId == p1)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func atc180TieResultsInNoWinner() throws {
    let p1 = UUID()
    let p2 = UUID()
    var state = try AroundTheClock180Engine.makeInitialState(
        config: MatchConfigAroundTheClock180(),
        playerIds: [p1, p2]
    )

    // Both players miss everything.
    for _ in 1 ... 20 {
        state = try AroundTheClock180Engine.submitTurn(state: state, darts: [missDart()]).updatedState
        state = try AroundTheClock180Engine.submitTurn(state: state, darts: [missDart()]).updatedState
    }

    #expect(state.isComplete)
    #expect(state.winnerPlayerId == nil)
}

// MARK: - Invalid input

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func atc180SubmitOnCompletedMatchThrows() throws {
    let player = UUID()
    var state = try AroundTheClock180Engine.makeInitialState(
        config: MatchConfigAroundTheClock180(),
        playerIds: [player]
    )

    for number in 1 ... 20 {
        state = try AroundTheClock180Engine.submitTurn(
            state: state,
            darts: [missDart()]
        ).updatedState
        _ = number
    }
    #expect(state.isComplete)

    #expect(throws: AppError.self) {
        try AroundTheClock180Engine.submitTurn(state: state, darts: [missDart()])
    }
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func atc180TooManyDartsThrows() throws {
    let player = UUID()
    let state = try AroundTheClock180Engine.makeInitialState(
        config: MatchConfigAroundTheClock180(),
        playerIds: [player]
    )
    let fourDarts = [missDart(), missDart(), missDart(), missDart()]

    #expect(throws: AppError.self) {
        try AroundTheClock180Engine.submitTurn(state: state, darts: fourDarts)
    }
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func atc180EmptyPlayerIdsThrows() {
    #expect(throws: AppError.self) {
        try AroundTheClock180Engine.makeInitialState(
            config: MatchConfigAroundTheClock180(),
            playerIds: []
        )
    }
}

// MARK: - Replay

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func atc180ReplayRestoresState() throws {
    let players = [UUID(), UUID()]
    let config = MatchConfigAroundTheClock180()
    var state = try AroundTheClock180Engine.makeInitialState(config: config, playerIds: players)

    let first = try AroundTheClock180Engine.submitTurn(
        state: state,
        darts: [atcDart(.triple, 1), atcDart(.triple, 1), atcDart(.triple, 1)]
    )
    state = first.updatedState
    let second = try AroundTheClock180Engine.submitTurn(
        state: state,
        darts: [atcDart(.single, 1), missDart(), missDart()]
    )

    let replayed = try AroundTheClock180Engine.replay(
        config: config,
        playerIds: players,
        events: [first.event, second.event]
    )

    #expect(replayed.players[0].cumulativePoints == 9)
    #expect(replayed.players[1].cumulativePoints == 1)
    #expect(replayed.currentNumber == 2)
}

// MARK: - Par score config

@Test(.tags(.unit, .match, .offline, .regression))
func atc180ConfigClampsParScore() {
    let tooHigh = MatchConfigAroundTheClock180(parScore: 999)
    #expect(tooHigh.parScore == 180)
    let negative = MatchConfigAroundTheClock180(parScore: -5)
    #expect(negative.parScore == 0)
    let valid = MatchConfigAroundTheClock180(parScore: 80)
    #expect(valid.parScore == 80)
    let nopar = MatchConfigAroundTheClock180()
    #expect(nopar.parScore == nil)
}
