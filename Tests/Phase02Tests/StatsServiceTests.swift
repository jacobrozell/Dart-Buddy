import Foundation
import Testing
@testable import DartsScoreboard

@Test(.tags(.unit, .stats, .offline, .regression))
func statsServiceComputesX01AverageFromEvents() throws {
    let player1 = UUID()
    let player2 = UUID()
    let participants = [
        MatchParticipant(playerId: player1, displayNameAtMatchStart: "P1", turnOrder: 0),
        MatchParticipant(playerId: player2, displayNameAtMatchStart: "P2", turnOrder: 1)
    ]
    var session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
        participants: participants
    )

    session = try MatchLifecycleService.submitX01Turn(
        session: session,
        enteredTotal: nil,
        darts: [
            DartInput(multiplier: .triple, segment: .oneToTwenty(20)),
            DartInput(multiplier: .single, segment: .oneToTwenty(1))
        ]
    )
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 0, darts: nil)
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 180, darts: nil)
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 0, darts: nil)
    session = try MatchLifecycleService.submitX01Turn(
        session: session,
        enteredTotal: nil,
        darts: [
            DartInput(multiplier: .double, segment: .oneToTwenty(20)),
            DartInput(multiplier: .single, segment: .oneToTwenty(20))
        ]
    )

    let aggregates = StatsService.recomputePlayerAggregates(from: [session])
    let average = aggregates[player1]?.x01Average3Dart

    #expect(average != nil)
    #expect(average! > 0)
}

@Test(.tags(.unit, .stats, .offline, .regression))
func statsAverageReturnsZeroWhenNoDarts() {
    #expect(StatsService.x01Average3Dart(totalPointsScored: 100, totalDartsThrown: 0) == 0)
}
