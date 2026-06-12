import Foundation
import Testing
@testable import DartBuddy

// MARK: - Helpers

private func bull() -> DartInput {
    DartInput(multiplier: .single, segment: .outerBull)
}

private func innerBull() -> DartInput {
    DartInput(multiplier: .single, segment: .innerBull)
}

private func miss() -> DartInput {
    DartInput(multiplier: .single, segment: .miss, isMiss: true)
}

private func d(_ multiplier: DartMultiplier, _ segment: Int, isMiss: Bool = false) -> DartInput {
    DartInput(multiplier: multiplier, segment: .oneToTwenty(segment), isMiss: isMiss)
}

// MARK: - Config & Initialisation

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func englishCricketMakeInitialStateRequiresExactlyTwoPlayers() throws {
    #expect(throws: AppError.self) {
        try EnglishCricketEngine.makeInitialState(
            config: MatchConfigEnglishCricket(),
            playerIds: [UUID()]
        )
    }
    #expect(throws: AppError.self) {
        try EnglishCricketEngine.makeInitialState(
            config: MatchConfigEnglishCricket(),
            playerIds: [UUID(), UUID(), UUID()]
        )
    }
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func englishCricketMakeInitialStateRejectsZeroWickets() throws {
    #expect(throws: AppError.self) {
        try EnglishCricketEngine.makeInitialState(
            config: MatchConfigEnglishCricket(wicketsPerInnings: 0),
            playerIds: [UUID(), UUID()]
        )
    }
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func englishCricketInitialStateIsInnings0BattingPhase() throws {
    let state = try EnglishCricketEngine.makeInitialState(
        config: MatchConfigEnglishCricket(),
        playerIds: [UUID(), UUID()]
    )
    #expect(state.inningsIndex == 0)
    #expect(state.phase == .batting)
    #expect(state.wicketsFallen == 0)
    #expect(state.isComplete == false)
}

// MARK: - Batting Formula

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func englishCricketBatterRunsFormulaSubtractsThreshold() throws {
    let players = [UUID(), UUID()]
    let state = try EnglishCricketEngine.makeInitialState(
        config: MatchConfigEnglishCricket(wicketsPerInnings: 10, runsThreshold: 40),
        playerIds: players
    )
    // 60 + 20 + 5 = 85 raw → 85 − 40 = 45 runs
    let outcome = try EnglishCricketEngine.submitTurn(
        state: state,
        darts: [d(.triple, 20), d(.single, 20), d(.single, 5)]
    )
    #expect(outcome.event.runsAdded == 45)
    #expect(outcome.updatedState.players[0].totalRuns == 45)
    #expect(outcome.updatedState.phase == .bowling) // batter done → bowling
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func englishCricketBatterRunsFloorAtZero() throws {
    let players = [UUID(), UUID()]
    let state = try EnglishCricketEngine.makeInitialState(
        config: MatchConfigEnglishCricket(runsThreshold: 40),
        playerIds: players
    )
    // 30 raw < 40 threshold → 0 runs
    let outcome = try EnglishCricketEngine.submitTurn(
        state: state,
        darts: [d(.single, 20), d(.single, 5), d(.single, 5)] // 30 raw
    )
    #expect(outcome.event.runsAdded == 0)
    #expect(outcome.updatedState.players[0].totalRuns == 0)
}

// MARK: - Bowling / Wickets

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func englishCricketBowlerBullCountsAsWicket() throws {
    let players = [UUID(), UUID()]
    var state = try EnglishCricketEngine.makeInitialState(
        config: MatchConfigEnglishCricket(wicketsPerInnings: 10),
        playerIds: players
    )
    // Advance to bowling phase.
    state = try EnglishCricketEngine.submitTurn(
        state: state,
        darts: [miss(), miss(), miss()]
    ).updatedState
    #expect(state.phase == .bowling)

    let outcome = try EnglishCricketEngine.submitTurn(
        state: state,
        darts: [bull(), innerBull(), miss()]
    )
    #expect(outcome.event.wicketsAdded == 2)
    #expect(outcome.updatedState.wicketsFallen == 2)
    #expect(outcome.updatedState.phase == .batting) // back to batter
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func englishCricketWicketsCapEndsInnings() throws {
    let players = [UUID(), UUID()]
    var state = try EnglishCricketEngine.makeInitialState(
        config: MatchConfigEnglishCricket(wicketsPerInnings: 3),
        playerIds: players
    )

    // Run a batter visit with 0 runs, then bowl 3 wickets.
    state = try EnglishCricketEngine.submitTurn(state: state, darts: [miss(), miss(), miss()]).updatedState
    #expect(state.phase == .bowling)

    let outcome = try EnglishCricketEngine.submitTurn(
        state: state,
        darts: [bull(), bull(), bull()]
    )
    #expect(outcome.event.wicketsAdded == 3)
    #expect(outcome.inningsJustCompleted == true)
    #expect(outcome.updatedState.inningsIndex == 1) // innings advanced
    #expect(outcome.updatedState.wicketsFallen == 0) // reset for new innings
    #expect(outcome.updatedState.phase == .batting)  // new innings starts batting
}

// MARK: - Innings Swap

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func englishCricketInnings0SetsRunTarget() throws {
    let p0 = UUID(); let p1 = UUID()
    var state = try EnglishCricketEngine.makeInitialState(
        config: MatchConfigEnglishCricket(wicketsPerInnings: 1, runsThreshold: 0),
        playerIds: [p0, p1]
    )
    // Batter (p0) scores 60 raw = 60 runs (threshold 0).
    state = try EnglishCricketEngine.submitTurn(
        state: state,
        darts: [d(.triple, 20), miss(), miss()]
    ).updatedState

    // Need 1 wicket to end innings 0 — move to bowler.
    #expect(state.phase == .bowling)
    state = try EnglishCricketEngine.submitTurn(
        state: state,
        darts: [bull(), miss(), miss()]
    ).updatedState

    #expect(state.inningsIndex == 1)
    #expect(state.opponentRunTarget == 60)
    #expect(state.batterIndex == 1) // p1 is now batting
}

// MARK: - Early Chase Completion

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func englishCricketSecondBatterPassesTargetEndsInningsEarly() throws {
    let p0 = UUID(); let p1 = UUID()
    // Config: 10 wickets but endWhenTargetPassed = true.
    var state = try EnglishCricketEngine.makeInitialState(
        config: MatchConfigEnglishCricket(wicketsPerInnings: 10, runsThreshold: 0, endWhenTargetPassed: true),
        playerIds: [p0, p1]
    )

    // Innings 0: p0 scores 50 runs (threshold 0), then bowler takes 1 wicket.
    state = try EnglishCricketEngine.submitTurn(
        state: state,
        darts: [d(.triple, 17), miss(), miss()] // 51 raw
    ).updatedState
    state = try EnglishCricketEngine.submitTurn(
        state: state,
        darts: [bull(), miss(), miss()]
    ).updatedState
    #expect(state.inningsIndex == 1)
    let target = state.opponentRunTarget!

    // Innings 1: p1 bats. Score enough to pass target in one visit.
    let bigScore = target + 10
    // Build darts summing to bigScore (using triple + doubles).
    let outcome = try EnglishCricketEngine.submitTurn(
        state: state,
        darts: buildDartsForRaw(bigScore)
    )
    #expect(outcome.inningsJustCompleted == true)
    #expect(outcome.updatedState.isComplete == true)
    #expect(outcome.updatedState.winnerPlayerId == p1)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func englishCricketEndWhenTargetPassedFalseAllowsFullInnings() throws {
    let p0 = UUID(); let p1 = UUID()
    var state = try EnglishCricketEngine.makeInitialState(
        config: MatchConfigEnglishCricket(wicketsPerInnings: 2, runsThreshold: 0, endWhenTargetPassed: false),
        playerIds: [p0, p1]
    )

    // Innings 0: p0 scores 10, bowler takes 2 wickets.
    state = try EnglishCricketEngine.submitTurn(state: state, darts: [d(.single, 10), miss(), miss()]).updatedState
    state = try EnglishCricketEngine.submitTurn(state: state, darts: [bull(), bull(), miss()]).updatedState
    #expect(state.inningsIndex == 1)

    // Innings 1: p1 bats and passes target — innings should NOT end early.
    state = try EnglishCricketEngine.submitTurn(state: state, darts: [d(.single, 20), miss(), miss()]).updatedState
    #expect(state.isComplete == false) // still in progress; needs wickets to end
    #expect(state.phase == .bowling)   // normal progression: batter done → bowling
}

// MARK: - Win Condition

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func englishCricketHigherRunsTotalWins() throws {
    let p0 = UUID(); let p1 = UUID()
    var state = try EnglishCricketEngine.makeInitialState(
        config: MatchConfigEnglishCricket(wicketsPerInnings: 1, runsThreshold: 0),
        playerIds: [p0, p1]
    )
    // Innings 0: p0 scores 60, bowler takes wicket.
    state = try EnglishCricketEngine.submitTurn(state: state, darts: [d(.triple, 20), miss(), miss()]).updatedState
    state = try EnglishCricketEngine.submitTurn(state: state, darts: [bull(), miss(), miss()]).updatedState
    // Innings 1: p1 scores 30 (< 60), bowler takes wicket.
    state = try EnglishCricketEngine.submitTurn(state: state, darts: [d(.single, 10), d(.single, 10), d(.single, 10)]).updatedState
    state = try EnglishCricketEngine.submitTurn(state: state, darts: [bull(), miss(), miss()]).updatedState

    #expect(state.isComplete == true)
    #expect(state.winnerPlayerId == p0)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func englishCricketTiedRunsResultsInNoWinner() throws {
    let p0 = UUID(); let p1 = UUID()
    var state = try EnglishCricketEngine.makeInitialState(
        config: MatchConfigEnglishCricket(wicketsPerInnings: 1, runsThreshold: 0),
        playerIds: [p0, p1]
    )
    // Both score 20.
    state = try EnglishCricketEngine.submitTurn(state: state, darts: [d(.single, 20), miss(), miss()]).updatedState
    state = try EnglishCricketEngine.submitTurn(state: state, darts: [bull(), miss(), miss()]).updatedState
    state = try EnglishCricketEngine.submitTurn(state: state, darts: [d(.single, 20), miss(), miss()]).updatedState
    state = try EnglishCricketEngine.submitTurn(state: state, darts: [bull(), miss(), miss()]).updatedState

    #expect(state.isComplete == true)
    #expect(state.winnerPlayerId == nil)
}

// MARK: - Invalid Input

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func englishCricketSubmitOnCompletedMatchThrows() throws {
    let p0 = UUID(); let p1 = UUID()
    var state = try EnglishCricketEngine.makeInitialState(
        config: MatchConfigEnglishCricket(wicketsPerInnings: 1, runsThreshold: 0),
        playerIds: [p0, p1]
    )
    state = try EnglishCricketEngine.submitTurn(state: state, darts: [d(.triple, 20), miss(), miss()]).updatedState
    state = try EnglishCricketEngine.submitTurn(state: state, darts: [bull(), miss(), miss()]).updatedState
    state = try EnglishCricketEngine.submitTurn(state: state, darts: [miss(), miss(), miss()]).updatedState
    state = try EnglishCricketEngine.submitTurn(state: state, darts: [bull(), miss(), miss()]).updatedState
    #expect(state.isComplete)

    #expect(throws: AppError.self) {
        try EnglishCricketEngine.submitTurn(state: state, darts: [miss(), miss(), miss()])
    }
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func englishCricketSubmitMoreThanThreeDartsThrows() throws {
    let state = try EnglishCricketEngine.makeInitialState(
        config: MatchConfigEnglishCricket(),
        playerIds: [UUID(), UUID()]
    )
    #expect(throws: AppError.self) {
        try EnglishCricketEngine.submitTurn(state: state, darts: [miss(), miss(), miss(), miss()])
    }
}

// MARK: - Replay Round-trip

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func englishCricketReplayRestoresState() throws {
    let p0 = UUID(); let p1 = UUID()
    let config = MatchConfigEnglishCricket(wicketsPerInnings: 3, runsThreshold: 0)
    var state = try EnglishCricketEngine.makeInitialState(config: config, playerIds: [p0, p1])

    var events: [EnglishCricketTurnEvent] = []
    func submit(_ darts: [DartInput]) throws {
        let outcome = try EnglishCricketEngine.submitTurn(state: state, darts: darts)
        state = outcome.updatedState
        events.append(outcome.event)
    }

    try submit([d(.triple, 20), miss(), miss()]) // innings 0 batter: 60 runs
    try submit([bull(), miss(), miss()])          // 1 wicket
    try submit([miss(), miss(), miss()])          // 0 runs
    try submit([bull(), bull(), miss()])          // 2 wickets (total 3 → innings 1 start)

    let replayed = try EnglishCricketEngine.replay(config: config, playerIds: [p0, p1], events: events)

    #expect(replayed.inningsIndex == state.inningsIndex)
    #expect(replayed.players[0].totalRuns == state.players[0].totalRuns)
    #expect(replayed.players[1].totalRuns == state.players[1].totalRuns)
    #expect(replayed.wicketsFallen == state.wicketsFallen)
    #expect(replayed.isComplete == state.isComplete)
}

// MARK: - Undo Semantics (replay of events minus last)

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func englishCricketUndoLastTurnViaReplayRemovesLastEvent() throws {
    let p0 = UUID(); let p1 = UUID()
    let config = MatchConfigEnglishCricket(wicketsPerInnings: 10, runsThreshold: 0)
    var state = try EnglishCricketEngine.makeInitialState(config: config, playerIds: [p0, p1])
    let first = try EnglishCricketEngine.submitTurn(
        state: state,
        darts: [d(.triple, 20), miss(), miss()] // 60 runs
    )
    state = first.updatedState

    // Replay with only the first event (undo of second turn = no second event).
    let undone = try EnglishCricketEngine.replay(
        config: config,
        playerIds: [p0, p1],
        events: [first.event]
    )

    #expect(undone.players[0].totalRuns == 60)
    #expect(undone.phase == .bowling) // after batter turn, back to bowler
}

// MARK: - Private helpers

private func buildDartsForRaw(_ total: Int) -> [DartInput] {
    // Construct 3 darts summing to `total`. Uses T20 (60), S20, S1 etc.
    let dart1 = min(60, total)
    let remaining1 = total - dart1
    let dart2 = min(60, remaining1)
    let remaining2 = remaining1 - dart2
    let dart3 = min(60, remaining2)

    func makeDart(_ points: Int) -> DartInput {
        if points == 0 { return miss() }
        if points % 3 == 0, points / 3 <= 20 {
            return DartInput(multiplier: .triple, segment: .oneToTwenty(points / 3))
        }
        if points % 2 == 0, points / 2 <= 20 {
            return DartInput(multiplier: .double, segment: .oneToTwenty(points / 2))
        }
        if points <= 20 {
            return DartInput(multiplier: .single, segment: .oneToTwenty(points))
        }
        return DartInput(multiplier: .triple, segment: .oneToTwenty(20))
    }

    return [makeDart(dart1), makeDart(dart2), makeDart(dart3)]
}
