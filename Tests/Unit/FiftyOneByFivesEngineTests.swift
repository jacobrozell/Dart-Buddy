import Foundation
import Testing
@testable import DartBuddy

// MARK: - Helpers

private func dart(_ multiplier: DartMultiplier, _ segment: Int) -> DartInput {
    DartInput(multiplier: multiplier, segment: .oneToTwenty(segment))
}

private func miss() -> DartInput {
    DartInput(multiplier: .single, segment: .miss, isMiss: true)
}

private func bull(_ multiplier: DartMultiplier = .single) -> DartInput {
    // outerBull = 25 pts (single context)
    DartInput(multiplier: multiplier, segment: .outerBull)
}

// MARK: - Divisibility gate

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func fiftyOneByFivesDivisibleVisitScoresQuotient() throws {
    // 60 total (triple-20) → 60 % 5 == 0 → award 60/5 = 12 points
    let players = [UUID(), UUID()]
    let state = try FiftyOneByFivesEngine.makeInitialState(
        config: MatchConfigFiftyOneByFives(targetPoints: 51),
        playerIds: players
    )
    let outcome = try FiftyOneByFivesEngine.submitTurn(
        state: state,
        darts: [dart(.triple, 20)]
    )
    #expect(outcome.event.rawTotal == 60)
    #expect(outcome.event.pointsAwarded == 12)
    #expect(outcome.updatedState.players[0].cumulativePoints == 12)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func fiftyOneByFivesNonDivisibleVisitScoresZero() throws {
    // 58 total → 58 % 5 != 0 → award 0
    let players = [UUID(), UUID()]
    let state = try FiftyOneByFivesEngine.makeInitialState(
        config: MatchConfigFiftyOneByFives(targetPoints: 51),
        playerIds: players
    )
    let outcome = try FiftyOneByFivesEngine.submitTurn(
        state: state,
        darts: [dart(.single, 18), dart(.double, 20)]  // 18 + 40 = 58
    )
    #expect(outcome.event.rawTotal == 58)
    #expect(outcome.event.pointsAwarded == 0)
    #expect(outcome.updatedState.players[0].cumulativePoints == 0)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func fiftyOneByFivesAllMissVisitScoresZero() throws {
    // 0 total (all miss) → 0 % 5 == 0 but 0 / 5 == 0 → still 0 points
    let players = [UUID(), UUID()]
    let state = try FiftyOneByFivesEngine.makeInitialState(
        config: MatchConfigFiftyOneByFives(targetPoints: 51),
        playerIds: players
    )
    let outcome = try FiftyOneByFivesEngine.submitTurn(
        state: state,
        darts: [miss(), miss(), miss()]
    )
    #expect(outcome.event.rawTotal == 0)
    #expect(outcome.event.pointsAwarded == 0)
    #expect(outcome.updatedState.players[0].cumulativePoints == 0)
}

// MARK: - Maximum visit (180 → 36 points)

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func fiftyOneByFives180VisitAwards36Points() throws {
    // 3 × triple-20 = 180 → 180 / 5 = 36 points
    let players = [UUID(), UUID()]
    let state = try FiftyOneByFivesEngine.makeInitialState(
        config: MatchConfigFiftyOneByFives(targetPoints: 51),
        playerIds: players
    )
    let outcome = try FiftyOneByFivesEngine.submitTurn(
        state: state,
        darts: [dart(.triple, 20), dart(.triple, 20), dart(.triple, 20)]
    )
    #expect(outcome.event.rawTotal == 180)
    #expect(outcome.event.pointsAwarded == 36)
    #expect(outcome.updatedState.players[0].cumulativePoints == 36)
}

// MARK: - Win condition

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func fiftyOneByFivesWinAtOrAboveTarget() throws {
    // Reach exactly 51 across two visits (20+20+20=60→12, then 15+15+15=45→9 …).
    // Use a simpler path: visit of 45 → 9 pts each, need 51.
    // Build up to ≥51 via repeated 60-total visits (12 pts each, 5 visits = 60 ≥51).
    let winner = UUID()
    let other = UUID()
    var state = try FiftyOneByFivesEngine.makeInitialState(
        config: MatchConfigFiftyOneByFives(targetPoints: 51),
        playerIds: [winner, other]
    )

    // 5 visits of 60 total each = 5 × 12 = 60 ≥ 51 → winner on 5th turn
    var lastOutcome: FiftyOneByFivesTurnOutcome?
    for _ in 0 ..< 4 {
        state = try FiftyOneByFivesEngine.submitTurn(
            state: state,
            darts: [dart(.triple, 20)]
        ).updatedState
        // advance through both players
        state = try FiftyOneByFivesEngine.submitTurn(
            state: state,
            darts: [miss()]
        ).updatedState
    }
    // 5th winner visit: cumulative was 48 after 4 × 12 = 48, now +12 = 60 ≥ 51
    lastOutcome = try FiftyOneByFivesEngine.submitTurn(
        state: state,
        darts: [dart(.triple, 20)]
    )

    #expect(lastOutcome?.updatedState.isComplete == true)
    #expect(lastOutcome?.updatedState.winnerPlayerId == winner)
}

// MARK: - mustFinishExact variant

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func fiftyOneByFivesMustFinishExactOvershotScoresZero() throws {
    // Player on 46 pts; visit of 30 total → 6 pts → would reach 52 > 51 → score 0.
    let players = [UUID(), UUID()]
    var state = try FiftyOneByFivesEngine.makeInitialState(
        config: MatchConfigFiftyOneByFives(targetPoints: 51, mustFinishExact: true),
        playerIds: players
    )
    // Manually inflate player[0] to 46 pts by replaying valid visits.
    // 45 total → 9 pts; then 35 total → 7 pts; then 35 total → 7 pts; then 35 total → 7 pts: 9+7+7+7+7=37 too complex
    // Simpler: inject via replay. Use 3 visits of 75 each (triple-5 = 15 × 3? No: triple5=15, three = 45)
    // Actually: visit 45→9, 45→9, 45→9, 45→9, 45→9 = 45 pts; then 5→1 = 46 pts
    for _ in 0 ..< 5 {
        // player[0] visits (45 total → 9 pts each)
        state = try FiftyOneByFivesEngine.submitTurn(
            state: state,
            darts: [dart(.triple, 5), dart(.triple, 5), dart(.triple, 5)]
        ).updatedState
        // player[1] misses
        state = try FiftyOneByFivesEngine.submitTurn(
            state: state,
            darts: [miss()]
        ).updatedState
    }
    // player[0] is now at 45 pts; one more single-5 visit (5 total → 1 pt) = 46
    state = try FiftyOneByFivesEngine.submitTurn(
        state: state,
        darts: [dart(.single, 5)]
    ).updatedState
    state = try FiftyOneByFivesEngine.submitTurn(state: state, darts: [miss()]).updatedState
    // player[0] = 46. Now a visit of 30 total (triple-10) → 6 pts → 52 > 51 → should score 0
    let outcome = try FiftyOneByFivesEngine.submitTurn(
        state: state,
        darts: [dart(.triple, 10)]
    )
    #expect(outcome.event.rawTotal == 30)
    #expect(outcome.event.pointsAwarded == 0)
    #expect(outcome.updatedState.players[0].cumulativePoints == 46)
    #expect(outcome.updatedState.isComplete == false)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func fiftyOneByFivesMustFinishExactExactHitWins() throws {
    // Player on 42 pts, visits 45 total → 9 pts → 42+9=51 == target → wins.
    let winner = UUID()
    let other = UUID()
    var state = try FiftyOneByFivesEngine.makeInitialState(
        config: MatchConfigFiftyOneByFives(targetPoints: 51, mustFinishExact: true),
        playerIds: [winner, other]
    )
    // Build to 42: 4 × 45 → 9 each = 36; + 5→1 = 37; too complex.
    // Use 42 = (3 visits × 45 = 27) + (5→3 visits: 1×30→6 = 33) + (1×45→9 = 42)? Let's just do:
    // 3 × 45 = 27; 1 × 30 = 6; 1 × 45 = 9 → total 42.
    for _ in 0 ..< 3 {
        state = try FiftyOneByFivesEngine.submitTurn(
            state: state,
            darts: [dart(.triple, 5), dart(.triple, 5), dart(.triple, 5)]
        ).updatedState
        state = try FiftyOneByFivesEngine.submitTurn(state: state, darts: [miss()]).updatedState
    }
    state = try FiftyOneByFivesEngine.submitTurn(
        state: state,
        darts: [dart(.triple, 10)]  // 30 total → 6 pts
    ).updatedState
    state = try FiftyOneByFivesEngine.submitTurn(state: state, darts: [miss()]).updatedState
    state = try FiftyOneByFivesEngine.submitTurn(
        state: state,
        darts: [dart(.triple, 5), dart(.triple, 5), dart(.triple, 5)]  // 45 → 9 pts
    ).updatedState
    state = try FiftyOneByFivesEngine.submitTurn(state: state, darts: [miss()]).updatedState
    // player[0] = 42 pts now. Visit 45 → 9 pts → 51 == target → win.
    let outcome = try FiftyOneByFivesEngine.submitTurn(
        state: state,
        darts: [dart(.triple, 5), dart(.triple, 5), dart(.triple, 5)]
    )
    #expect(outcome.event.pointsAwarded == 9)
    #expect(outcome.updatedState.players[0].cumulativePoints == 51)
    #expect(outcome.updatedState.isComplete == true)
    #expect(outcome.updatedState.winnerPlayerId == winner)
}

// MARK: - Turn rotation

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func fiftyOneByFivesPlayerAdvancesAfterVisit() throws {
    let players = [UUID(), UUID(), UUID()]
    var state = try FiftyOneByFivesEngine.makeInitialState(
        config: MatchConfigFiftyOneByFives(targetPoints: 51),
        playerIds: players
    )
    #expect(state.currentPlayerIndex == 0)

    state = try FiftyOneByFivesEngine.submitTurn(state: state, darts: [miss()]).updatedState
    #expect(state.currentPlayerIndex == 1)

    state = try FiftyOneByFivesEngine.submitTurn(state: state, darts: [miss()]).updatedState
    #expect(state.currentPlayerIndex == 2)

    state = try FiftyOneByFivesEngine.submitTurn(state: state, darts: [miss()]).updatedState
    #expect(state.currentPlayerIndex == 0)
}

// MARK: - Invalid input guards

@Test(.tags(.unit, .match, .offline, .regression))
func fiftyOneByFivesRejectsSubmitOnCompletedMatch() throws {
    let players = [UUID(), UUID()]
    var state = try FiftyOneByFivesEngine.makeInitialState(
        config: MatchConfigFiftyOneByFives(targetPoints: 12),
        playerIds: players
    )
    // Single visit of 60 → 12 pts = win immediately
    state = try FiftyOneByFivesEngine.submitTurn(
        state: state,
        darts: [dart(.triple, 20)]
    ).updatedState
    #expect(state.isComplete == true)

    #expect(throws: AppError.self) {
        try FiftyOneByFivesEngine.submitTurn(state: state, darts: [miss()])
    }
}

@Test(.tags(.unit, .match, .offline, .regression))
func fiftyOneByFivesRejectsMoreThanThreeDarts() throws {
    let players = [UUID(), UUID()]
    let state = try FiftyOneByFivesEngine.makeInitialState(
        config: MatchConfigFiftyOneByFives(),
        playerIds: players
    )
    #expect(throws: AppError.self) {
        try FiftyOneByFivesEngine.submitTurn(
            state: state,
            darts: [miss(), miss(), miss(), miss()]
        )
    }
}

@Test(.tags(.unit, .match, .offline, .regression))
func fiftyOneByFivesRejectsFewerThanTwoPlayers() throws {
    #expect(throws: AppError.self) {
        try FiftyOneByFivesEngine.makeInitialState(
            config: MatchConfigFiftyOneByFives(),
            playerIds: [UUID()]
        )
    }
}

// MARK: - Replay round-trip

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func fiftyOneByFivesReplayRestoresState() throws {
    let players = [UUID(), UUID()]
    var state = try FiftyOneByFivesEngine.makeInitialState(
        config: MatchConfigFiftyOneByFives(targetPoints: 51),
        playerIds: players
    )
    let first = try FiftyOneByFivesEngine.submitTurn(
        state: state,
        darts: [dart(.triple, 20)]  // 60 → 12 pts
    )
    state = first.updatedState
    let second = try FiftyOneByFivesEngine.submitTurn(
        state: state,
        darts: [dart(.single, 5), dart(.single, 5), dart(.single, 5)]  // 15 → 3 pts
    )

    let replayed = try FiftyOneByFivesEngine.replay(
        config: MatchConfigFiftyOneByFives(targetPoints: 51),
        playerIds: players,
        events: [first.event, second.event]
    )

    #expect(replayed.players[0].cumulativePoints == 12)
    #expect(replayed.players[1].cumulativePoints == 3)
    #expect(replayed.currentPlayerIndex == 0)
}

// MARK: - Undo semantics (replay minus last event)

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func fiftyOneByFivesUndoRestoresPreviousState() throws {
    let players = [UUID(), UUID()]
    var state = try FiftyOneByFivesEngine.makeInitialState(
        config: MatchConfigFiftyOneByFives(targetPoints: 51),
        playerIds: players
    )
    let first = try FiftyOneByFivesEngine.submitTurn(
        state: state,
        darts: [dart(.triple, 20)]  // player[0] → 12 pts
    )
    state = first.updatedState
    let second = try FiftyOneByFivesEngine.submitTurn(
        state: state,
        darts: [dart(.triple, 20)]  // player[1] → 12 pts
    )

    // Undo: replay only the first event.
    let afterUndo = try FiftyOneByFivesEngine.replay(
        config: MatchConfigFiftyOneByFives(targetPoints: 51),
        playerIds: players,
        events: [first.event]
    )

    #expect(afterUndo.players[0].cumulativePoints == 12)
    #expect(afterUndo.players[1].cumulativePoints == 0)
    #expect(afterUndo.currentPlayerIndex == 1)
    _ = second  // suppress unused-variable warning
}
