import Foundation
import Testing
@testable import DartBuddy

private func d(_ multiplier: DartMultiplier, _ segment: Int) -> DartInput {
    DartInput(multiplier: multiplier, segment: .oneToTwenty(segment))
}

private func pick(_ segment: Int) -> DartInput {
    d(.single, segment)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func killerPickAssignsUniqueNumbers() throws {
    let players = [UUID(), UUID(), UUID()]
    var state = try KillerEngine.makeInitialState(config: MatchConfigKiller(), playerIds: players)

    state = try KillerEngine.submitPick(state: state, dart: pick(5)).updatedState
    state = try KillerEngine.submitPick(state: state, dart: pick(5)).updatedState
    #expect(state.players.filter { $0.assignedNumber == 5 }.count == 1)

    state = try KillerEngine.submitPick(state: state, dart: pick(12)).updatedState
    state = try KillerEngine.submitPick(state: state, dart: pick(20)).updatedState
    #expect(state.phase == .playing)
    #expect(Set(state.players.compactMap(\.assignedNumber)) == Set([5, 12, 20]))
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func killerBecomeKillerOnOwnDoubleOnly() throws {
    let players = [UUID(), UUID(), UUID()]
    var state = try playingState(players: players, numbers: [5, 12, 20])
    let throwerIndex = state.currentPlayerIndex

    state = try KillerEngine.submitTurn(state: state, darts: [d(.double, 5)]).updatedState
    #expect(state.players[throwerIndex].isKiller)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func killerDamageRequiresKillerStatusAndDouble() throws {
    let players = [UUID(), UUID(), UUID()]
    var state = try playingState(players: players, numbers: [5, 12, 20])
    let miss = DartInput(multiplier: .single, segment: .miss, isMiss: true)

    state = try KillerEngine.submitTurn(state: state, darts: [d(.double, 12)]).updatedState
    #expect(state.players[1].lives == 3)

    state = try KillerEngine.submitTurn(state: state, darts: [miss]).updatedState
    state = try KillerEngine.submitTurn(state: state, darts: [miss]).updatedState

    state = try KillerEngine.submitTurn(state: state, darts: [d(.double, 5)]).updatedState
    #expect(state.players[0].isKiller)

    state = try KillerEngine.submitTurn(state: state, darts: [miss]).updatedState
    state = try KillerEngine.submitTurn(state: state, darts: [miss]).updatedState

    state = try KillerEngine.submitTurn(state: state, darts: [d(.double, 12)]).updatedState
    #expect(state.players[1].lives == 2)

    state = try KillerEngine.submitTurn(state: state, darts: [miss]).updatedState
    state = try KillerEngine.submitTurn(state: state, darts: [miss]).updatedState
    state = try KillerEngine.submitTurn(state: state, darts: [miss]).updatedState

    state = try KillerEngine.submitTurn(state: state, darts: [d(.single, 12)]).updatedState
    #expect(state.players[1].lives == 2)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func killerSelfDoublePenalty() throws {
    let players = [UUID(), UUID(), UUID()]
    var state = try playingState(players: players, numbers: [5, 12, 20])
    state.players[0].isKiller = true

    state = try KillerEngine.submitTurn(state: state, darts: [d(.double, 5)]).updatedState
    #expect(state.players[0].lives == 2)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func killerLifecycleUndoRestoresLives() throws {
    let players = [UUID(), UUID(), UUID()]
    let participants = players.enumerated().map { index, id in
        MatchParticipant(playerId: id, displayNameAtMatchStart: "P\(index + 1)", turnOrder: index)
    }
    var session = try MatchLifecycleService.createMatch(
        type: .killer,
        config: .killer(MatchConfigKiller()),
        participants: participants
    )
    for number in [5, 12, 20] {
        session = try MatchLifecycleService.submitKillerPick(session: session, dart: pick(number))
    }

    session = try MatchLifecycleService.submitKillerTurn(session: session, darts: [d(.double, 5)])
    session = try MatchLifecycleService.submitKillerTurn(session: session, darts: [d(.double, 12)])
    #expect(session.runtime.killerState?.players[1].lives == 2)

    let undone = try MatchLifecycleService.undoLastTurn(session: session)
    #expect(undone.runtime.killerState?.players[1].lives == 3)
}

private func playingState(players: [UUID], numbers: [Int]) throws -> KillerState {
    var state = try KillerEngine.makeInitialState(config: MatchConfigKiller(), playerIds: players)
    for (index, number) in numbers.enumerated() {
        state.players[index].assignedNumber = number
    }
    state.phase = .playing
    state.pickQueue = []
    state.currentPlayerIndex = 0
    return state
}
