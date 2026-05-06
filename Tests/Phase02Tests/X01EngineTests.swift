import Foundation
import Testing

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
    let config = MatchConfigX01(startScore: 40, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .doubleOut)
    var state = try X01Engine.makeInitialState(config: config, playerIds: players)

    let outcome = try X01Engine.submitTurn(
        state: state,
        enteredTotal: nil,
        darts: [DartInput(multiplier: .single, segment: .oneToTwenty(20))]
    )

    #expect(outcome.event.isBust)
    #expect(outcome.updatedState.players[0].remainingScore == 40)
    #expect(!outcome.updatedState.isComplete)
}

@Test(.tags(.unit, .x01, .critical, .offline, .regression))
func x01OverflowBustResetsAppliedScore() throws {
    let players = [UUID(), UUID()]
    let config = MatchConfigX01(startScore: 32, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)
    let state = try X01Engine.makeInitialState(config: config, playerIds: players)

    let outcome = try X01Engine.submitTurn(state: state, enteredTotal: 60, darts: nil)

    #expect(outcome.event.isBust)
    #expect(outcome.event.appliedTotal == 0)
    #expect(outcome.updatedState.players[0].remainingScore == 32)
}
