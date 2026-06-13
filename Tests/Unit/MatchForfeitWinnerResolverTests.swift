import Foundation
import Testing
@testable import DartBuddy

@Suite("Match forfeit winner resolver", .tags(.unit, .match, .regression))
struct MatchForfeitWinnerResolverTests {
    @Test
    func twoPlayerMatchPicksRemainingHuman() throws {
        let p1 = UUID()
        let p2 = UUID()
        let session = try MatchLifecycleService.createMatch(
            type: .x01,
            config: .x01(MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
            participants: [
                MatchParticipant(playerId: p1, displayNameAtMatchStart: "Alice", turnOrder: 0),
                MatchParticipant(playerId: p2, displayNameAtMatchStart: "Bob", turnOrder: 1)
            ]
        )

        let resolution = try MatchForfeitWinnerResolver.resolve(session: session, forfeitingPlayerId: p1)

        #expect(resolution == .automatic(winnerPlayerId: p2))
    }

    @Test
    func soloForfeitHasNoWinner() throws {
        let player = UUID()
        let session = try MatchLifecycleService.createMatch(
            type: .aroundTheClock180,
            config: .aroundTheClock180(MatchConfigAroundTheClock180()),
            participants: [
                MatchParticipant(playerId: player, displayNameAtMatchStart: "Solo", turnOrder: 0)
            ]
        )

        let resolution = try MatchForfeitWinnerResolver.resolve(session: session, forfeitingPlayerId: player)

        #expect(resolution == .automatic(winnerPlayerId: nil))
    }

    @Test
    func knockoutThreePlayerMatchCanRequireTieBreak() throws {
        let ids = (0 ..< 3).map { _ in UUID() }
        var session = try MatchLifecycleService.createMatch(
            type: .knockout,
            config: MatchConfigDefaults.config(for: .knockout),
            participants: ids.enumerated().map { index, id in
                MatchParticipant(playerId: id, displayNameAtMatchStart: "P\(index + 1)", turnOrder: index)
            }
        )
        session = try MatchLifecycleService.submitKnockoutTurn(
            session: session,
            darts: [
                DartInput(multiplier: .single, segment: .oneToTwenty(20)),
                DartInput(multiplier: .single, segment: .oneToTwenty(20)),
                DartInput(multiplier: .single, segment: .oneToTwenty(20))
            ]
        )

        let resolution = try MatchForfeitWinnerResolver.resolve(session: session, forfeitingPlayerId: ids[0])

        switch resolution {
        case let .automatic(winner):
            #expect(winner != ids[0])
        case let .chooseAmongTied(candidates):
            #expect(candidates.count >= 2)
            #expect(candidates.allSatisfy { $0.playerId != ids[0] })
        }
    }
}
