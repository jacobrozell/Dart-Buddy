import Foundation
import Testing
@testable import DartBuddy

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

@Test(.tags(.unit, .stats, .offline, .regression))
func statsAverageUsesThreeDartFormula() {
    #expect(StatsService.x01Average3Dart(totalPointsScored: 180, totalDartsThrown: 9) == 60)
    #expect(StatsService.x01Average3Dart(totalPointsScored: 45, totalDartsThrown: 3) == 45)
}

@Test(.tags(.unit, .stats, .offline, .regression))
func statsLiveScorecardAverageUsesPerDartForOpeningVisit() {
    #expect(
        StatsService.x01LiveScorecardAverage(
            committedPoints: 0,
            committedDarts: 0,
            previewPoints: 11,
            previewDarts: 1
        ) == 11
    )
    #expect(
        StatsService.x01LiveScorecardAverage(
            committedPoints: 0,
            committedDarts: 0,
            previewPoints: 40,
            previewDarts: 2
        ) == 20
    )
    #expect(
        StatsService.x01LiveScorecardAverage(
            committedPoints: 0,
            committedDarts: 0,
            previewPoints: 60,
            previewDarts: 3
        ) == 60
    )
    #expect(
        StatsService.x01LiveScorecardAverage(
            committedPoints: 180,
            committedDarts: 3,
            previewPoints: 20,
            previewDarts: 1
        ) == 150
    )
}

private func d(_ multiplier: DartMultiplier, _ value: Int) -> DartInput {
    DartInput(multiplier: multiplier, segment: .oneToTwenty(value))
}

@Test(.tags(.unit, .stats, .x01, .regression))
func breakdownsComputeX01PerPlayerStats() throws {
    let jacob = UUID()
    let sam = UUID()
    var session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
        participants: [
            MatchParticipant(playerId: jacob, displayNameAtMatchStart: "Jacob", turnOrder: 0),
            MatchParticipant(playerId: sam, displayNameAtMatchStart: "Sam", turnOrder: 1)
        ]
    )
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: nil, darts: [d(.triple, 20), d(.triple, 20), d(.triple, 20)]) // Jacob 180 -> 121
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: nil, darts: [d(.triple, 20), d(.single, 20), d(.single, 20)]) // Sam 100 -> 201
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: nil, darts: [d(.triple, 20), d(.triple, 20), d(.single, 1)]) // Jacob 121 -> 0 win

    let input = MatchStatsInput(
        type: .x01,
        participantKeys: [jacob, sam],
        winnerKey: session.runtime.winnerPlayerId,
        events: session.events
    )
    let rows = StatsService.breakdowns(from: [input], nameById: [jacob: "Jacob", sam: "Sam"])

    #expect(rows.first?.playerId == jacob) // winner sorts first

    let j = try #require(rows.first { $0.playerId == jacob })
    #expect(j.games == 1)
    #expect(j.wins == 1)
    #expect(j.legs == 1)
    #expect(j.checkouts == 1)
    #expect(j.highestCheckout == 121)
    #expect(j.darts == 6)
    #expect(j.points == 301)
    #expect(j.highestScore == 180)
    #expect(j.triples == 5)
    #expect(j.doubles == 0)
    #expect(j.hitsBySector["20"] == 5)
    #expect(j.hitsBySector["1"] == 1)
    #expect(abs(j.average3Dart - 150.5) < 0.0001)
    #expect(abs(j.winPercent - 100) < 0.0001)

    let s = try #require(rows.first { $0.playerId == sam })
    #expect(s.games == 1)
    #expect(s.wins == 0)
    #expect(s.legs == 0)
    #expect(s.points == 100)
    #expect(s.highestScore == 100)
}

@Test(.tags(.unit, .stats, .cricket, .regression))
func breakdownsComputeCricketHitsAndPoints() throws {
    let p1 = UUID()
    let p2 = UUID()
    var session = try MatchLifecycleService.createMatch(
        type: .cricket,
        config: .cricket(MatchConfigCricket()),
        participants: [
            MatchParticipant(playerId: p1, displayNameAtMatchStart: "P1", turnOrder: 0),
            MatchParticipant(playerId: p2, displayNameAtMatchStart: "P2", turnOrder: 1)
        ]
    )
    session = try MatchLifecycleService.submitCricketTurn(session: session, darts: [d(.triple, 20)]) // P1 closes 20
    session = try MatchLifecycleService.submitCricketTurn(session: session, darts: [d(.single, 19)]) // P2 opens 19
    session = try MatchLifecycleService.submitCricketTurn(session: session, darts: [d(.triple, 20)]) // P1 overflow -> 60 points

    let input = MatchStatsInput(
        type: .cricket,
        participantKeys: [p1, p2],
        winnerKey: nil,
        events: session.events
    )
    let rows = StatsService.breakdowns(from: [input], nameById: [p1: "P1", p2: "P2"])

    let one = try #require(rows.first { $0.playerId == p1 })
    #expect(one.games == 1)
    #expect(one.darts == 2)
    #expect(one.triples == 2)
    #expect(one.hitsBySector["20"] == 2)
    #expect(one.points == 60)
    #expect(one.legs == 0)
    #expect(one.cricketRounds == 2)
    #expect(one.cricketMarks == 3)
    #expect(abs(one.marksPerRound - 1.5) < 0.0001)

    let two = try #require(rows.first { $0.playerId == p2 })
    #expect(two.darts == 1)
    #expect(two.hitsBySector["19"] == 1)
    #expect(two.points == 0)
    #expect(two.cricketRounds == 1)
    #expect(two.cricketMarks == 1)
    #expect(abs(two.marksPerRound - 1.0) < 0.0001)
}

@Test(.tags(.unit, .stats, .x01, .regression))
func breakdownsCountMissesInSectorZero() throws {
    let player = UUID()
    let other = UUID()
    var session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
        participants: [
            MatchParticipant(playerId: player, displayNameAtMatchStart: "Player", turnOrder: 0),
            MatchParticipant(playerId: other, displayNameAtMatchStart: "Other", turnOrder: 1)
        ]
    )
    session = try MatchLifecycleService.submitX01Turn(
        session: session,
        enteredTotal: nil,
        darts: [
            DartInput(multiplier: .single, segment: .miss, isMiss: true),
            DartInput(multiplier: .triple, segment: .oneToTwenty(20)),
            DartInput(multiplier: .single, segment: .miss, isMiss: true)
        ]
    )

    let input = MatchStatsInput(
        type: .x01,
        participantKeys: [player, other],
        winnerKey: nil,
        events: session.events
    )
    let rows = StatsService.breakdowns(from: [input], nameById: [player: "Player", other: "Other"])
    let p = try #require(rows.first { $0.playerId == player })
    #expect(p.hitsBySector["0"] == 2)
    #expect(p.hitsBySector["20"] == 1)
}

@Test(.tags(.unit, .stats, .cricket, .regression))
func breakdownsCountCricketMissesInSectorZero() throws {
    let player = UUID()
    let other = UUID()
    var session = try MatchLifecycleService.createMatch(
        type: .cricket,
        config: .cricket(MatchConfigCricket()),
        participants: [
            MatchParticipant(playerId: player, displayNameAtMatchStart: "Player", turnOrder: 0),
            MatchParticipant(playerId: other, displayNameAtMatchStart: "Other", turnOrder: 1)
        ]
    )
    session = try MatchLifecycleService.submitCricketTurn(
        session: session,
        darts: [DartInput(multiplier: .triple, segment: .oneToTwenty(14))]
    )

    let input = MatchStatsInput(
        type: .cricket,
        participantKeys: [player, other],
        winnerKey: nil,
        events: session.events
    )
    let rows = StatsService.breakdowns(from: [input], nameById: [player: "Player", other: "Other"])
    let p = try #require(rows.first { $0.playerId == player })
    #expect(p.hitsBySector["0"] == 1)
    #expect(p.darts == 1)
}

@Test(.tags(.unit, .stats, .baseball, .regression))
func breakdownsBucketBaseballHitsByInningTarget() throws {
    let player = UUID()
    let other = UUID()
    var session = try MatchLifecycleService.createMatch(
        type: .baseball,
        config: .baseball(MatchConfigBaseball(inningCount: 9)),
        participants: [
            MatchParticipant(playerId: player, displayNameAtMatchStart: "Player", turnOrder: 0),
            MatchParticipant(playerId: other, displayNameAtMatchStart: "Other", turnOrder: 1)
        ]
    )
    session = try MatchLifecycleService.submitBaseballTurn(
        session: session,
        darts: [d(.single, 1), d(.double, 1), d(.triple, 4)]
    )

    let input = MatchStatsInput(
        type: .baseball,
        participantKeys: [player, other],
        winnerKey: nil,
        events: session.events
    )
    let rows = StatsService.breakdowns(from: [input], nameById: [player: "Player", other: "Other"])
    let p = try #require(rows.first { $0.playerId == player })
    #expect(p.hitsBySector["1"] == 2)
    #expect(p.hitsBySector["0"] == 1)
    #expect(p.points == 3)
}

@Test(.tags(.unit, .stats, .regression))
func breakdownsAggregateGamesAcrossMatches() throws {
    let player = UUID()
    let other = UUID()
    func makeGame(winner: UUID) throws -> MatchStatsInput {
        var session = try MatchLifecycleService.createMatch(
            type: .x01,
            config: .x01(MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
            participants: [
                MatchParticipant(playerId: player, displayNameAtMatchStart: "Player", turnOrder: 0),
                MatchParticipant(playerId: other, displayNameAtMatchStart: "Other", turnOrder: 1)
            ]
        )
        // games count comes from participants; winner is supplied independently of the scored turns.
        session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 100, darts: nil)
        session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 100, darts: nil)
        return MatchStatsInput(type: .x01, participantKeys: [player, other], winnerKey: winner, events: session.events)
    }

    let rows = StatsService.breakdowns(
        from: [try makeGame(winner: player), try makeGame(winner: other)],
        nameById: [player: "Player", other: "Other"]
    )
    let p = try #require(rows.first { $0.playerId == player })
    #expect(p.games == 2)
    #expect(p.wins == 1)
    #expect(abs(p.winPercent - 50) < 0.0001)
}

@Test(.tags(.unit, .stats, .regression))
func breakdownsPartialMatchCountsThrowsButNotGames() throws {
    let jacob = UUID()
    let sam = UUID()
    var session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
        participants: [
            MatchParticipant(playerId: jacob, displayNameAtMatchStart: "Jacob", turnOrder: 0),
            MatchParticipant(playerId: sam, displayNameAtMatchStart: "Sam", turnOrder: 1)
        ]
    )
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 60, darts: nil)

    let input = MatchStatsInput(
        type: .x01,
        participantKeys: [jacob, sam],
        winnerKey: nil,
        events: session.events,
        isPartial: true
    )
    let rows = StatsService.breakdowns(from: [input], nameById: [jacob: "Jacob", sam: "Sam"])
    let j = try #require(rows.first { $0.playerId == jacob })
    #expect(j.games == 0)
    #expect(j.wins == 0)
    #expect(j.darts == 3)
    #expect(j.points == 60)
}

@Test(.tags(.unit, .stats, .regression))
func x01TrendPointsOrdersMatchesChronologically() throws {
    let player = UUID()
    let other = UUID()
    let early = Date(timeIntervalSince1970: 1_000_000)
    let late = Date(timeIntervalSince1970: 2_000_000)

    func makeSession() throws -> [MatchEventEnvelope] {
        var session = try MatchLifecycleService.createMatch(
            type: .x01,
            config: .x01(MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
            participants: [
                MatchParticipant(playerId: player, displayNameAtMatchStart: "Player", turnOrder: 0),
                MatchParticipant(playerId: other, displayNameAtMatchStart: "Other", turnOrder: 1)
            ]
        )
        session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 60, darts: nil)
        return session.events
    }

    let matches = [
        MatchStatsInput(matchId: UUID(), playedAt: late, type: .x01, participantKeys: [player, other], winnerKey: player, events: try makeSession()),
        MatchStatsInput(matchId: UUID(), playedAt: early, type: .x01, participantKeys: [player, other], winnerKey: player, events: try makeSession())
    ]
    let trend = StatsService.x01TrendPoints(from: matches, playerId: player)
    #expect(trend.count == 2)
    #expect(trend[0].date == early)
    #expect(trend[1].date == late)
    #expect(trend[0].average3Dart > 0)
}
