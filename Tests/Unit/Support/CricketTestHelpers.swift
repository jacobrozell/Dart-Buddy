import Foundation
@testable import DartBuddy

func cricketPlayerIds(count: Int) -> [UUID] {
    (0 ..< count).map { _ in UUID() }
}

func cricketConfig(
    pointsEnabled: Bool = true,
    scoringMode: CricketScoringMode = .standard,
    legsToWin: Int = 1,
    setsEnabled: Bool = false,
    setsToWin: Int? = nil,
    legFormat: X01LegFormat = .firstTo
) -> MatchConfigCricket {
    MatchConfigCricket(
        pointsEnabled: pointsEnabled,
        scoringMode: scoringMode,
        legsToWin: legsToWin,
        setsEnabled: setsEnabled,
        setsToWin: setsToWin,
        legFormat: legFormat
    )
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

    /// Each player closes `target` once so it is knocked out board-wide.
    static func knockOutTarget(_ state: CricketState, target: CricketTarget, playerCount: Int) throws -> CricketState {
        let closeTurn: [DartInput]
        switch target {
        case .bull:
            closeTurn = [innerBull, outerBull]
        case .t20, .t19, .t18, .t17, .t16, .t15:
            closeTurn = [triple(Int(target.rawValue)!)]
        }
        var state = state
        for _ in 0 ..< playerCount {
            state = try submit(state, closeTurn)
        }
        return state
    }

    /// Closes all targets for whoever is up, skipping `(playerCount - 1)` opponents between each close visit.
    static func closeAllTargetsForCurrentPlayer(_ state: CricketState, playerCount: Int) throws -> CricketState {
        let skipTurns = max(0, playerCount - 1)
        var state = state
        state = try submit(state, [triple(20), triple(19), triple(18)])
        for _ in 0 ..< skipTurns {
            state = try submit(state, [miss(), miss(), miss()])
        }
        state = try submit(state, [triple(17), triple(16), triple(15)])
        for _ in 0 ..< skipTurns {
            state = try submit(state, [miss(), miss(), miss()])
        }
        state = try submit(state, [innerBull, outerBull])
        return state
    }

    /// Each player runs the same close sweep in turn order (no overflow scoring when kept in sync).
    static func runSynchronizedCloseSweep(_ state: CricketState, playerCount: Int) throws -> CricketState {
        let sweeps: [[DartInput]] = [
            [triple(20), triple(19), triple(18)],
            [triple(17), triple(16), triple(15)],
            [innerBull, outerBull]
        ]
        var state = state
        var sweepsDone = Array(repeating: 0, count: playerCount)
        for _ in 0 ..< (playerCount * sweeps.count) {
            let idx = state.currentPlayerIndex
            state = try submit(state, sweeps[sweepsDone[idx]])
            sweepsDone[idx] += 1
        }
        return state
    }
}
