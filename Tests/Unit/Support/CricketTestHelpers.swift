import Foundation
@testable import DartBuddy

func cricketPlayerIds(count: Int) -> [UUID] {
    (0 ..< count).map { _ in UUID() }
}

func cricketParticipants(count: Int, names: [String]? = nil) -> [MatchParticipant] {
    let ids = cricketPlayerIds(count: count)
    let resolvedNames = names ?? (0 ..< count).map { "P\($0)" }
    return zip(ids, resolvedNames).enumerated().map { index, pair in
        MatchParticipant(playerId: pair.0, displayNameAtMatchStart: pair.1, turnOrder: index)
    }
}

enum CricketTestDarts {
    static func triple(_ value: Int) -> DartInput { DartInput(multiplier: .triple, segment: .oneToTwenty(value)) }
    static func single(_ value: Int) -> DartInput { DartInput(multiplier: .single, segment: .oneToTwenty(value)) }
    static func miss() -> DartInput { DartInput(multiplier: .single, segment: .miss, isMiss: true) }
    static let innerBull = DartInput(multiplier: .single, segment: .innerBull)
    static let outerBull = DartInput(multiplier: .single, segment: .outerBull)

    static func submit(_ state: CricketState, _ darts: [DartInput]) throws -> CricketState {
        try CricketEngine.submitTurn(state: state, darts: darts).updatedState
    }

    static func closeAllTargets(_ state: CricketState) throws -> CricketState {
        var state = state
        state = try submit(state, [triple(20), triple(19), triple(18)])
        state = try submit(state, [triple(17), triple(16), triple(15)])
        state = try submit(state, [innerBull, outerBull])
        return state
    }
}
