import Foundation
import Testing
@testable import DartBuddy

@Test(.tags(.unit, .match, .regression, .offline))
func resolverTwoPlayerReturnsOpponent() throws {
    let player1 = UUID()
    let player2 = UUID()
    var session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
        participants: [
            MatchParticipant(playerId: player1, displayNameAtMatchStart: "P1", turnOrder: 0),
            MatchParticipant(playerId: player2, displayNameAtMatchStart: "P2", turnOrder: 1)
        ]
    )
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 60, darts: nil)
    let resolution = try MatchForfeitWinnerResolver.resolve(session: session, forfeitingPlayerId: player1)
    #expect(resolution == .automatic(winnerPlayerId: player2))
}

@Test(.tags(.unit, .match, .regression, .offline))
func resolverThreePlayerX01PicksLowestRemaining() throws {
    let p1 = UUID()
    let p2 = UUID()
    let p3 = UUID()
    var session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(MatchConfigX01(startScore: 501, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .doubleOut)),
        participants: [
            MatchParticipant(playerId: p1, displayNameAtMatchStart: "A", turnOrder: 0),
            MatchParticipant(playerId: p2, displayNameAtMatchStart: "B", turnOrder: 1),
            MatchParticipant(playerId: p3, displayNameAtMatchStart: "C", turnOrder: 2)
        ]
    )
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 100, darts: nil)
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 60, darts: nil)
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 140, darts: nil)
    let resolution = try MatchForfeitWinnerResolver.resolve(session: session, forfeitingPlayerId: p1)
    #expect(resolution == .automatic(winnerPlayerId: p3))
}

@Test(.tags(.unit, .match, .regression, .offline))
func resolverThreePlayerCricketEqualScoreUsesTurnOrderTieBreak() throws {
    let alice = UUID()
    let bob = UUID()
    let carol = UUID()
    let session = try MatchLifecycleService.createMatch(
        type: .cricket,
        config: .cricket(MatchConfigCricket()),
        participants: [
            MatchParticipant(playerId: alice, displayNameAtMatchStart: "Alice", turnOrder: 0),
            MatchParticipant(playerId: bob, displayNameAtMatchStart: "Bob", turnOrder: 1),
            MatchParticipant(playerId: carol, displayNameAtMatchStart: "Carol", turnOrder: 2)
        ]
    )
    let resolution = try MatchForfeitWinnerResolver.resolve(session: session, forfeitingPlayerId: alice)
    #expect(resolution == .automatic(winnerPlayerId: bob))
}

@Test(.tags(.unit, .match, .regression, .offline))
func everyShippedMatchTypeHasForfeitStandingsRegistered() throws {
    for entry in GameModeCatalog.all.filter({ $0.status == GameModeStatus.shipped }) where entry.usesStandardMatchForfeit {
        guard let type = entry.matchType else { continue }
        let session = try MatchForfeitStandingsRegistry.fixtureSession(for: type)
        let playerId = session.runtime.participants[0].playerId ?? session.runtime.participants[0].id
        _ = try MatchForfeitStandingsRegistry.standing(for: playerId, in: session)
    }
}
