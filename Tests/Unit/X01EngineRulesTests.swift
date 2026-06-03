import Foundation
import Testing
@testable import DartBuddy

private func single(_ v: Int) -> DartInput { DartInput(multiplier: .single, segment: .oneToTwenty(v)) }
private func dbl(_ v: Int) -> DartInput { DartInput(multiplier: .double, segment: .oneToTwenty(v)) }
private func trpl(_ v: Int) -> DartInput { DartInput(multiplier: .triple, segment: .oneToTwenty(v)) }
private func twoPlayers() -> [UUID] { [UUID(), UUID()] }

// MARK: - Master Out

@Test(.tags(.unit, .x01, .regression, .offline))
func x01MasterOutAllowsTripleFinish() throws {
    let players = twoPlayers()
    let config = MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .masterOut)
    var state = try X01Engine.makeInitialState(config: config, playerIds: players)

    state = try X01Engine.submitTurn(state: state, enteredTotal: 180, darts: nil).updatedState // P1 -> 121
    state = try X01Engine.submitTurn(state: state, enteredTotal: 0, darts: nil).updatedState   // P2
    state = try X01Engine.submitTurn(state: state, enteredTotal: 61, darts: nil).updatedState  // P1 -> 60
    state = try X01Engine.submitTurn(state: state, enteredTotal: 0, darts: nil).updatedState   // P2
    state = try X01Engine.submitTurn(state: state, enteredTotal: nil, darts: [trpl(20)]).updatedState

    #expect(state.isComplete)
    #expect(state.winnerPlayerId == players[0])
}

@Test(.tags(.unit, .x01, .regression, .offline))
func x01DoubleOutRejectsTripleFinishAsBust() throws {
    let players = twoPlayers()
    let config = MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .doubleOut)
    var state = try X01Engine.makeInitialState(config: config, playerIds: players)

    state = try X01Engine.submitTurn(state: state, enteredTotal: 180, darts: nil).updatedState
    state = try X01Engine.submitTurn(state: state, enteredTotal: 0, darts: nil).updatedState
    state = try X01Engine.submitTurn(state: state, enteredTotal: 61, darts: nil).updatedState
    state = try X01Engine.submitTurn(state: state, enteredTotal: 0, darts: nil).updatedState
    state = try X01Engine.submitTurn(state: state, enteredTotal: nil, darts: [trpl(20)]).updatedState

    #expect(!state.isComplete)
    #expect(state.players[0].remainingScore == 60) // bust leaves the score untouched
}

// MARK: - Check-In

@Test(.tags(.unit, .x01, .regression, .offline))
func x01DoubleInIgnoresDartsBeforeOpeningDouble() throws {
    let players = twoPlayers()
    let config = MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut, checkInMode: .doubleIn)
    var state = try X01Engine.makeInitialState(config: config, playerIds: players)

    #expect(state.players[0].isCheckedIn == false)

    // Three singles cannot open a double-in leg: nothing should score.
    state = try X01Engine.submitTurn(state: state, enteredTotal: nil, darts: [single(20), single(20), single(20)]).updatedState
    #expect(state.players[0].remainingScore == 301)
    #expect(state.players[0].isCheckedIn == false)

    state = try X01Engine.submitTurn(state: state, enteredTotal: 0, darts: nil).updatedState // P2

    // A double opens the leg; it and the rest of the visit now count.
    state = try X01Engine.submitTurn(state: state, enteredTotal: nil, darts: [dbl(20), single(20), single(20)]).updatedState
    #expect(state.players[0].isCheckedIn == true)
    #expect(state.players[0].remainingScore == 221) // 301 - (40 + 20 + 20)
}

@Test(.tags(.unit, .x01, .regression, .offline))
func x01MasterInOpensOnTripleButDoubleInDoesNot() throws {
    let players = twoPlayers()
    let masterConfig = MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut, checkInMode: .masterIn)
    var masterState = try X01Engine.makeInitialState(config: masterConfig, playerIds: players)
    masterState = try X01Engine.submitTurn(state: masterState, enteredTotal: nil, darts: [trpl(20)]).updatedState
    #expect(masterState.players[0].isCheckedIn == true)
    #expect(masterState.players[0].remainingScore == 241)

    let doubleConfig = MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut, checkInMode: .doubleIn)
    var doubleState = try X01Engine.makeInitialState(config: doubleConfig, playerIds: players)
    doubleState = try X01Engine.submitTurn(state: doubleState, enteredTotal: nil, darts: [trpl(20)]).updatedState
    #expect(doubleState.players[0].isCheckedIn == false)
    #expect(doubleState.players[0].remainingScore == 301)
}

// MARK: - Best of vs First to

@Test(.tags(.unit, .x01, .regression, .offline))
func x01BestOfThreeCompletesAfterTwoLegs() throws {
    let players = twoPlayers()
    let totals = [180, 0, 121, 0, 180, 0, 121] // P1 wins two 301 legs (single out)

    func play(format: X01LegFormat) throws -> X01State {
        let config = MatchConfigX01(startScore: 301, legsToWin: 3, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut, legFormat: format)
        var state = try X01Engine.makeInitialState(config: config, playerIds: players)
        for total in totals {
            state = try X01Engine.submitTurn(state: state, enteredTotal: total, darts: nil).updatedState
        }
        return state
    }

    let bestOf = try play(format: .bestOf)
    #expect(bestOf.isComplete) // best of 3 -> first to 2 legs
    #expect(bestOf.winnerPlayerId == players[0])

    let firstTo = try play(format: .firstTo)
    #expect(!firstTo.isComplete) // first to 3 still needs another leg
    #expect(firstTo.players[0].legsWon == 2)
}
