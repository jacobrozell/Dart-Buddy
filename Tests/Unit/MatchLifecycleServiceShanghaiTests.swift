import Foundation
import Testing
@testable import DartBuddy

private func d(_ multiplier: DartMultiplier, _ segment: Int) -> DartInput {
    DartInput(multiplier: multiplier, segment: .oneToTwenty(segment))
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func shanghaiLifecycleCreateSubmitSnapshotAndUndo() throws {
    let p1 = UUID()
    let p2 = UUID()
    let participants = [
        MatchParticipant(playerId: p1, displayNameAtMatchStart: "P1", turnOrder: 0),
        MatchParticipant(playerId: p2, displayNameAtMatchStart: "P2", turnOrder: 1)
    ]
    var session = try MatchLifecycleService.createMatch(
        type: .shanghai,
        config: .shanghai(MatchConfigShanghai()),
        participants: participants
    )

    session = try MatchLifecycleService.submitShanghaiTurn(session: session, darts: [d(.single, 1)])
    session = try MatchLifecycleService.submitShanghaiTurn(session: session, darts: [d(.double, 1)])

    #expect(session.runtime.eventCount == 2)
    #expect(session.runtime.shanghaiState?.players[0].cumulativePoints == 1)
    #expect(session.runtime.shanghaiState?.players[1].cumulativePoints == 2)

    let undone = try MatchLifecycleService.undoLastTurn(session: session)
    #expect(undone.runtime.eventCount == 1)
    #expect(undone.runtime.shanghaiState?.players[1].cumulativePoints == 0)
}

@Test(.tags(.unit, .match, .critical, .offline, .regression))
func shanghaiLifecycleReplayMatchesSubmittedTurns() throws {
    let players = [UUID(), UUID()]
    var session = try MatchLifecycleService.createMatch(
        type: .shanghai,
        config: .shanghai(MatchConfigShanghai(roundCount: 1)),
        participants: [
            MatchParticipant(playerId: players[0], displayNameAtMatchStart: "A", turnOrder: 0),
            MatchParticipant(playerId: players[1], displayNameAtMatchStart: "B", turnOrder: 1)
        ]
    )
    session = try MatchLifecycleService.submitShanghaiTurn(session: session, darts: [d(.single, 1)])
    session = try MatchLifecycleService.submitShanghaiTurn(session: session, darts: [d(.double, 1)])

    let events = session.events.compactMap { envelope -> ShanghaiTurnEvent? in
        if case let .shanghaiTurn(turn) = envelope.payload { return turn }
        return nil
    }
    let replayed = try ShanghaiEngine.replay(
        config: MatchConfigShanghai(roundCount: 1),
        playerIds: players,
        events: events
    )

    #expect(replayed.players[0].cumulativePoints == 1)
    #expect(replayed.players[1].cumulativePoints == 2)
    #expect(replayed.isComplete)
}
