import Foundation
import Testing
@testable import DartBuddy

// Extended coverage for X01 multi-leg / multi-set progression, valid checkouts,
// replay determinism, and input validation. Complements X01EngineTests.

private func twoPlayers() -> [UUID] { [UUID(), UUID()] }

private func single(_ value: Int) -> DartInput {
    DartInput(multiplier: .single, segment: .oneToTwenty(value))
}

private func miss() -> DartInput {
    DartInput(multiplier: .single, segment: .miss, isMiss: true)
}

/// Alternating visits until player 0 reaches `remaining` (opponent throws zero).
private func stateWithPlayer0Remaining(
    _ remaining: Int,
    config: MatchConfigX01,
    startScore: Int = 301
) throws -> X01State {
    let players = twoPlayers()
    var state = try X01Engine.makeInitialState(config: config, playerIds: players)
    let scored = startScore - remaining
    state = try X01Engine.submitTurn(state: state, enteredTotal: scored, darts: nil).updatedState
    state = try X01Engine.submitTurn(state: state, enteredTotal: 0, darts: nil).updatedState
    #expect(state.players[0].remainingScore == remaining)
    return state
}

private func advance(_ state: X01State, totals: [Int]) throws -> X01State {
    var current = state
    for total in totals {
        current = try X01Engine.submitTurn(state: current, enteredTotal: total, darts: nil).updatedState
    }
    return current
}

@Test(.tags(.unit, .x01, .critical, .offline, .regression))
func x01DoubleOutFinishingDartCompletesMatch() throws {
    let players = twoPlayers()
    let config = MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .doubleOut)
    var state = try X01Engine.makeInitialState(config: config, playerIds: players)

    // Bring player 0 to exactly 40 remaining.
    state = try advance(state, totals: [180, 0, 81, 0])
    #expect(state.players[0].remainingScore == 40)

    let outcome = try X01Engine.submitTurn(
        state: state,
        enteredTotal: nil,
        darts: [DartInput(multiplier: .double, segment: .oneToTwenty(20))]
    )

    #expect(outcome.event.didCheckout)
    #expect(outcome.event.checkoutDartCount == 1)
    #expect(outcome.updatedState.isComplete)
    #expect(outcome.updatedState.winnerPlayerId == players[0])
}

@Test(.tags(.unit, .x01, .critical, .offline, .regression))
func x01DoubleOutTotalEntryCheckoutCompletesMatch() throws {
    // Total entry carries no per-dart detail, so an exact finish in double-out
    // must be trusted as a checkout rather than treated as a bust.
    let players = twoPlayers()
    let config = MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .doubleOut)
    var state = try X01Engine.makeInitialState(config: config, playerIds: players)
    state = try advance(state, totals: [180, 0, 81, 0]) // player 0 on 40

    let outcome = try X01Engine.submitTurn(state: state, enteredTotal: 40, darts: nil)

    #expect(outcome.event.didCheckout)
    #expect(outcome.updatedState.isComplete)
    #expect(outcome.updatedState.winnerPlayerId == players[0])
}

@Test(.tags(.unit, .x01, .offline, .regression))
func x01TurnRecordsDartsThrownForTotalAndDartEntry() throws {
    let players = twoPlayers()
    let config = MatchConfigX01(startScore: 501, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .doubleOut)
    let state = try X01Engine.makeInitialState(config: config, playerIds: players)

    // Total entry assumes a full 3-dart visit.
    let totalEntry = try X01Engine.submitTurn(state: state, enteredTotal: 60, darts: nil)
    #expect(totalEntry.event.effectiveDartsThrown == 3)

    // Per-dart entry uses the exact count.
    let dartEntry = try X01Engine.submitTurn(
        state: state,
        enteredTotal: nil,
        darts: [DartInput(multiplier: .triple, segment: .oneToTwenty(20)), DartInput(multiplier: .single, segment: .oneToTwenty(5))]
    )
    #expect(dartEntry.event.effectiveDartsThrown == 2)
}

@Test(.tags(.unit, .x01, .stats, .offline, .regression))
func x01TotalEntryGameProducesNonZeroAverage() throws {
    let players = twoPlayers()
    let config = MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)
    var session = try MatchLifecycleService.createMatch(type: .x01, config: .x01(config), participants: [
        MatchParticipant(playerId: players[0], displayNameAtMatchStart: "A", turnOrder: 0),
        MatchParticipant(playerId: players[1], displayNameAtMatchStart: "B", turnOrder: 1)
    ])
    // All total entry (no per-dart detail).
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 100, darts: nil)
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 0, darts: nil)
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 100, darts: nil)

    let input = MatchStatsInput(type: .x01, participantKeys: players, winnerKey: nil, events: session.events)
    let rows = StatsService.breakdowns(from: [input], nameById: [players[0]: "A", players[1]: "B"])
    let a = try #require(rows.first { $0.playerId == players[0] })

    #expect(a.darts == 6) // two visits * 3 darts
    #expect(a.average3Dart > 0)
}

@Test(.tags(.unit, .x01, .critical, .offline, .regression))
func x01DoubleOutLeavingOneIsBust() throws {
    let players = twoPlayers()
    let config = MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .doubleOut)
    var state = try X01Engine.makeInitialState(config: config, playerIds: players)
    state = try advance(state, totals: [180, 0, 81, 0]) // player 0 on 40

    let outcome = try X01Engine.submitTurn(state: state, enteredTotal: 39, darts: nil) // would leave 1

    #expect(outcome.event.isBust)
    #expect(outcome.event.appliedTotal == 0)
    #expect(outcome.updatedState.players[0].remainingScore == 40)
    #expect(!outcome.updatedState.isComplete)
}

@Test(.tags(.unit, .x01, .offline, .regression))
func x01SingleOutLeavingOneIsAllowed() throws {
    let players = twoPlayers()
    let config = MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)
    var state = try X01Engine.makeInitialState(config: config, playerIds: players)
    state = try advance(state, totals: [180, 0, 81, 0]) // player 0 on 40

    let outcome = try X01Engine.submitTurn(state: state, enteredTotal: 39, darts: nil) // leaves 1

    #expect(!outcome.event.isBust)
    #expect(outcome.updatedState.players[0].remainingScore == 1)
}

// MARK: - Low remaining (dart-by-dart)

@Test(.tags(.unit, .x01, .critical, .offline, .regression))
func x01DoubleOutThreeLeftSingleTwoThenMissesIsBust() throws {
    // Regression: 3 left, visit 2-0-0 leaves 1 — impossible in double-out, so bust.
    let config = MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .doubleOut)
    let state = try stateWithPlayer0Remaining(3, config: config)

    let outcome = try X01Engine.submitTurn(
        state: state,
        enteredTotal: nil,
        darts: [single(2), miss(), miss()]
    )

    #expect(outcome.event.isBust)
    #expect(outcome.event.appliedTotal == 0)
    #expect(outcome.event.enteredTotal == 2)
    #expect(outcome.updatedState.players[0].remainingScore == 3)
}

@Test(.tags(.unit, .x01, .critical, .offline, .regression))
func x01SingleOutThreeLeftSingleTwoThenMissesLeavesOne() throws {
    // Regression: same visit in single-out must apply the scored points and leave 1.
    let config = MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)
    let state = try stateWithPlayer0Remaining(3, config: config)

    let outcome = try X01Engine.submitTurn(
        state: state,
        enteredTotal: nil,
        darts: [single(2), miss(), miss()]
    )

    #expect(!outcome.event.isBust)
    #expect(outcome.event.appliedTotal == 2)
    #expect(outcome.updatedState.players[0].remainingScore == 1)
}

@Test(.tags(.unit, .x01, .offline, .regression))
func x01DoubleOutThreeLeftTotalEntryTwoIsBust() throws {
    let config = MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .doubleOut)
    let state = try stateWithPlayer0Remaining(3, config: config)

    let outcome = try X01Engine.submitTurn(state: state, enteredTotal: 2, darts: nil)

    #expect(outcome.event.isBust)
    #expect(outcome.updatedState.players[0].remainingScore == 3)
}

@Test(.tags(.unit, .x01, .offline, .regression))
func x01SingleOutThreeLeftTotalEntryTwoLeavesOne() throws {
    let config = MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)
    let state = try stateWithPlayer0Remaining(3, config: config)

    let outcome = try X01Engine.submitTurn(state: state, enteredTotal: 2, darts: nil)

    #expect(!outcome.event.isBust)
    #expect(outcome.updatedState.players[0].remainingScore == 1)
}

@Test(.tags(.unit, .x01, .offline, .regression))
func x01DoubleOutThreeLeftAccidentalDoubleTwoOverflows() throws {
    // Regression: with DOUBLE armed, pad "2" scores 4 and overflows from 3.
    let config = MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .doubleOut)
    let state = try stateWithPlayer0Remaining(3, config: config)

    let outcome = try X01Engine.submitTurn(
        state: state,
        enteredTotal: nil,
        darts: [DartInput(multiplier: .double, segment: .oneToTwenty(2))]
    )

    #expect(outcome.event.isBust)
    #expect(outcome.updatedState.players[0].remainingScore == 3)
}

@Test(.tags(.unit, .x01, .offline, .regression))
func x01DoubleOutTwoLeftSingleTwoIsBust() throws {
    // Regression: exact remaining on a single (not double) is an illegal finish.
    let config = MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .doubleOut)
    let state = try stateWithPlayer0Remaining(2, config: config)

    let outcome = try X01Engine.submitTurn(
        state: state,
        enteredTotal: nil,
        darts: [single(2)]
    )

    #expect(outcome.event.isBust)
    #expect(outcome.updatedState.players[0].remainingScore == 2)
}

@Test(.tags(.unit, .x01, .offline, .regression))
func x01DoubleOutTwoLeftDoubleOneChecksOut() throws {
    let config = MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .doubleOut)
    let state = try stateWithPlayer0Remaining(2, config: config)

    let outcome = try X01Engine.submitTurn(
        state: state,
        enteredTotal: nil,
        darts: [DartInput(multiplier: .double, segment: .oneToTwenty(1))]
    )

    #expect(outcome.event.didCheckout)
    #expect(outcome.updatedState.isComplete)
}

@Test(.tags(.unit, .x01, .critical, .offline, .regression))
func x01LegWinResetsScoresWithoutCompletingMatch() throws {
    let players = twoPlayers()
    let config = MatchConfigX01(startScore: 301, legsToWin: 2, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)
    var state = try X01Engine.makeInitialState(config: config, playerIds: players)

    // Player 0 checks out the first leg (181 + 0 + 120 path keeps it simple via three turns).
    state = try advance(state, totals: [180, 0, 121])

    #expect(!state.isComplete)
    #expect(state.players[0].legsWon == 1)
    #expect(state.legIndex == 1)
    // Scores reset to the start score for the next leg.
    #expect(state.players.allSatisfy { $0.remainingScore == 301 })
}

@Test(.tags(.unit, .x01, .critical, .offline, .regression))
func x01SetProgressionCompletesAfterRequiredSets() throws {
    let players = twoPlayers()
    let config = MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: true, setsToWin: 2, checkoutMode: .singleOut)
    var state = try X01Engine.makeInitialState(config: config, playerIds: players)

    // Win set 1 (one leg), opponent throws zeros, then win set 2.
    state = try advance(state, totals: [180, 0, 121]) // set 1 for player 0
    #expect(state.players[0].setsWon == 1)
    #expect(state.players[0].legsWon == 0) // legs reset after a set
    #expect(!state.isComplete)

    state = try advance(state, totals: [0, 180, 0, 121]) // set 2 for player 0
    #expect(state.players[0].setsWon == 2)
    #expect(state.isComplete)
    #expect(state.winnerPlayerId == players[0])
}

@Test(.tags(.unit, .x01, .offline, .regression))
func x01ThrowsWhenEnteredTotalDisagreesWithDarts() throws {
    let players = twoPlayers()
    let config = MatchConfigX01(startScore: 501, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .doubleOut)
    let state = try X01Engine.makeInitialState(config: config, playerIds: players)

    #expect(throws: AppError.self) {
        _ = try X01Engine.submitTurn(
            state: state,
            enteredTotal: 50,
            darts: [DartInput(multiplier: .triple, segment: .oneToTwenty(20))] // 60, not 50
        )
    }
}

@Test(.tags(.unit, .x01, .offline, .regression))
func x01RejectsInvalidStartScore() {
    #expect(throws: AppError.self) {
        _ = try X01Engine.makeInitialState(
            config: MatchConfigX01(startScore: 500, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .doubleOut),
            playerIds: twoPlayers()
        )
    }
}

@Test(.tags(.unit, .x01, .offline, .regression))
func x01RejectsTurnAfterCompletion() throws {
    let players = twoPlayers()
    let config = MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)
    var state = try X01Engine.makeInitialState(config: config, playerIds: players)
    state = try advance(state, totals: [180, 0, 121])
    #expect(state.isComplete)

    #expect(throws: AppError.self) {
        _ = try X01Engine.submitTurn(state: state, enteredTotal: 0, darts: nil)
    }
}

@Test(.tags(.unit, .x01, .critical, .offline, .regression))
func x01ReplayReconstructsIdenticalState() throws {
    let players = twoPlayers()
    let config = MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)
    var state = try X01Engine.makeInitialState(config: config, playerIds: players)

    var events: [X01TurnEvent] = []
    for total in [180, 45, 60, 30, 121] {
        let outcome = try X01Engine.submitTurn(state: state, enteredTotal: total, darts: nil)
        state = outcome.updatedState
        events.append(outcome.event)
    }

    let replayed = try X01Engine.replay(config: config, playerIds: players, events: events)
    #expect(replayed == state)
}
