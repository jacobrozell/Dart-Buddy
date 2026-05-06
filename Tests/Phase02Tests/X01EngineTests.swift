import Foundation
import Testing
@testable import DartsScoreboard

@Test(.tags(.unit, .x01, .critical, .offline, .regression))
func x01SingleOutCheckoutCompletesMatch() throws {
    let players = [UUID(), UUID()]
    let config = MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)
    var state = try X01Engine.makeInitialState(config: config, playerIds: players)

    state = try X01Engine.submitTurn(state: state, enteredTotal: 180, darts: nil).updatedState
    state = try X01Engine.submitTurn(state: state, enteredTotal: 0, darts: nil).updatedState
    state = try X01Engine.submitTurn(state: state, enteredTotal: 121, darts: nil).updatedState

    #expect(state.isComplete)
    #expect(state.winnerPlayerId == players[0])
}

@Test(.tags(.unit, .x01, .critical, .offline, .regression))
func x01DoubleOutInvalidFinishBecomesBust() throws {
    let players = [UUID(), UUID()]
    let config = MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .doubleOut)
    var state = try X01Engine.makeInitialState(config: config, playerIds: players)

    // Bring player 1 down to 40 remaining, preserving turn order.
    state = try X01Engine.submitTurn(state: state, enteredTotal: 180, darts: nil).updatedState
    state = try X01Engine.submitTurn(state: state, enteredTotal: 0, darts: nil).updatedState
    state = try X01Engine.submitTurn(state: state, enteredTotal: 81, darts: nil).updatedState
    state = try X01Engine.submitTurn(state: state, enteredTotal: 0, darts: nil).updatedState

    let outcome = try X01Engine.submitTurn(
        state: state,
        enteredTotal: nil,
        darts: [
            DartInput(multiplier: .single, segment: .oneToTwenty(20)),
            DartInput(multiplier: .single, segment: .oneToTwenty(20))
        ]
    )

    #expect(outcome.event.isBust)
    #expect(outcome.updatedState.players[0].remainingScore == 40)
    #expect(!outcome.updatedState.isComplete)
}

@Test(.tags(.unit, .x01, .critical, .offline, .regression))
func x01OverflowBustResetsAppliedScore() throws {
    let players = [UUID(), UUID()]
    let config = MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)
    var state = try X01Engine.makeInitialState(config: config, playerIds: players)

    // Bring player 1 to a low score, then overflow with a legal turn total.
    state = try X01Engine.submitTurn(state: state, enteredTotal: 180, darts: nil).updatedState
    state = try X01Engine.submitTurn(state: state, enteredTotal: 0, darts: nil).updatedState
    state = try X01Engine.submitTurn(state: state, enteredTotal: 61, darts: nil).updatedState
    state = try X01Engine.submitTurn(state: state, enteredTotal: 0, darts: nil).updatedState

    let outcome = try X01Engine.submitTurn(state: state, enteredTotal: 100, darts: nil)

    #expect(outcome.event.isBust)
    #expect(outcome.event.appliedTotal == 0)
    #expect(outcome.updatedState.players[0].remainingScore == 60)
}
