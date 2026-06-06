import Foundation
import Testing
@testable import DartBuddy

private func d(_ multiplier: DartMultiplier, _ segment: Int) -> DartInput {
    DartInput(multiplier: multiplier, segment: .oneToTwenty(segment))
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func shanghaiRoundOneScoresFaceValue() throws {
    let players = [UUID(), UUID()]
    var state = try ShanghaiEngine.makeInitialState(config: MatchConfigShanghai(roundCount: 20), playerIds: players)
    #expect(state.currentRound == 1)

    let outcome = try ShanghaiEngine.submitTurn(
        state: state,
        darts: [d(.single, 1), d(.double, 1), d(.triple, 1)]
    )

    #expect(outcome.event.pointsThisVisit == 156)
    #expect(outcome.event.achievedShanghai)
    #expect(outcome.updatedState.players[0].cumulativePoints == 156)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func shanghaiInstantWinEndsMatch() throws {
    let winner = UUID()
    let players = [winner, UUID()]
    var state = try ShanghaiEngine.makeInitialState(
        config: MatchConfigShanghai(roundCount: 3, bonusRule: .instantWin),
        playerIds: players
    )

    state = try ShanghaiEngine.submitTurn(
        state: state,
        darts: [d(.single, 1), d(.double, 1), d(.triple, 1)]
    ).updatedState

    #expect(state.isComplete)
    #expect(state.winnerPlayerId == winner)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func shanghaiOffTargetScoresZero() throws {
    let players = [UUID(), UUID()]
    let state = try ShanghaiEngine.makeInitialState(config: MatchConfigShanghai(), playerIds: players)

    let outcome = try ShanghaiEngine.submitTurn(
        state: state,
        darts: [d(.triple, 4), d(.triple, 5)]
    )

    #expect(outcome.event.pointsThisVisit == 0)
    #expect(outcome.updatedState.players[0].cumulativePoints == 0)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func shanghaiRoundRotationAfterAllPlayers() throws {
    let players = [UUID(), UUID(), UUID()]
    var state = try ShanghaiEngine.makeInitialState(config: MatchConfigShanghai(roundCount: 20), playerIds: players)

    state = try ShanghaiEngine.submitTurn(state: state, darts: [d(.single, 1)]).updatedState
    #expect(state.currentPlayerIndex == 1)
    #expect(state.currentRound == 1)

    state = try ShanghaiEngine.submitTurn(state: state, darts: [d(.single, 1)]).updatedState
    #expect(state.currentPlayerIndex == 2)

    state = try ShanghaiEngine.submitTurn(state: state, darts: [d(.single, 1)]).updatedState
    #expect(state.currentPlayerIndex == 0)
    #expect(state.currentRound == 2)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func shanghaiExtraRoundsBreakTie() throws {
    let p1 = UUID()
    let p2 = UUID()
    var state = try ShanghaiEngine.makeInitialState(
        config: MatchConfigShanghai(roundCount: 1),
        playerIds: [p1, p2]
    )

    state = try ShanghaiEngine.submitTurn(state: state, darts: [d(.single, 1)]).updatedState
    state = try ShanghaiEngine.submitTurn(state: state, darts: [d(.single, 1)]).updatedState
    #expect(state.isExtraRound)
    #expect(state.currentRound == 2)
    #expect(state.isComplete == false)

    state = try ShanghaiEngine.submitTurn(state: state, darts: [d(.triple, 2)]).updatedState
    state = try ShanghaiEngine.submitTurn(state: state, darts: [DartInput(multiplier: .single, segment: .miss, isMiss: true)]).updatedState
    #expect(state.isComplete)
    #expect(state.winnerPlayerId == p1)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func shanghaiReplayRestoresState() throws {
    let players = [UUID(), UUID()]
    var session = try ShanghaiEngine.makeInitialState(config: MatchConfigShanghai(roundCount: 2), playerIds: players)
    let first = try ShanghaiEngine.submitTurn(state: session, darts: [d(.double, 1)])
    session = first.updatedState
    let second = try ShanghaiEngine.submitTurn(state: session, darts: [d(.single, 1)])

    let replayed = try ShanghaiEngine.replay(
        config: MatchConfigShanghai(roundCount: 2),
        playerIds: players,
        events: [first.event, second.event]
    )

    #expect(replayed.players[0].cumulativePoints == 2)
    #expect(replayed.players[1].cumulativePoints == 1)
}
