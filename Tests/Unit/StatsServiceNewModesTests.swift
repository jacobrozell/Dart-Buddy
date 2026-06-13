import Foundation
import Testing
@testable import DartBuddy

// Stats breakdown coverage for event types introduced with the expanded game catalog.

private func miss() -> DartInput {
    DartInput(multiplier: .single, segment: .miss, isMiss: true)
}

private func segment(_ multiplier: DartMultiplier, _ value: Int) -> DartInput {
    DartInput(multiplier: multiplier, segment: .oneToTwenty(value))
}

private func makeStatsInput(
    type: MatchType,
    player: UUID,
    opponent: UUID,
    submit: (inout MatchLifecycleSession) throws -> Void
) throws -> MatchStatsInput {
    var session = try MatchLifecycleService.createMatch(
        type: type,
        config: MatchConfigDefaults.config(for: type),
        participants: [
            MatchParticipant(playerId: player, displayNameAtMatchStart: "Player", turnOrder: 0),
            MatchParticipant(playerId: opponent, displayNameAtMatchStart: "Other", turnOrder: 1)
        ]
    )
    try submit(&session)
    return MatchStatsInput(
        type: type,
        participantKeys: [player, opponent],
        winnerKey: nil,
        events: session.events
    )
}

@Test(.tags(.unit, .stats, .regression))
func breakdownsCountAmericanCricketMarksAndPoints() throws {
    let player = UUID()
    let opponent = UUID()
    let input = try makeStatsInput(type: .americanCricket, player: player, opponent: opponent) { session in
        session = try MatchLifecycleService.submitAmericanCricketTurn(
            session: session,
            darts: [segment(.triple, 20)]
        )
    }
    let rows = StatsService.breakdowns(from: [input], nameById: [player: "Player", opponent: "Other"])
    let row = try #require(rows.first { $0.playerId == player })
    #expect(row.darts == 1)
    #expect(row.hitsBySector["20"] == 1)
}

@Test(.tags(.unit, .stats, .regression))
func breakdownsCountMickeyMouseMarks() throws {
    let player = UUID()
    let opponent = UUID()
    let input = try makeStatsInput(type: .mickeyMouse, player: player, opponent: opponent) { session in
        session = try MatchLifecycleService.submitMickeyMouseTurn(
            session: session,
            darts: [segment(.double, 20)]
        )
    }
    let rows = StatsService.breakdowns(from: [input], nameById: [player: "Player", opponent: "Other"])
    let row = try #require(rows.first { $0.playerId == player })
    #expect(row.cricketMarks == 2)
    #expect(row.darts == 1)
}

@Test(.tags(.unit, .stats, .regression))
func breakdownsCountGolfStrokesFromLastDart() throws {
    let player = UUID()
    let opponent = UUID()
    let input = try makeStatsInput(type: .golf, player: player, opponent: opponent) { session in
        session = try MatchLifecycleService.submitGolfTurn(
            session: session,
            input: GolfTurnInput(darts: [miss(), segment(.double, 1)])
        )
    }
    let rows = StatsService.breakdowns(from: [input], nameById: [player: "Player", opponent: "Other"])
    let row = try #require(rows.first { $0.playerId == player })
    #expect(row.points == 1)
    #expect(row.darts == 2)
}

@Test(.tags(.unit, .stats, .regression))
func breakdownsCountKnockoutVisitTotals() throws {
    let player = UUID()
    let opponent = UUID()
    let input = try makeStatsInput(type: .knockout, player: player, opponent: opponent) { session in
        session = try MatchLifecycleService.submitKnockoutTurn(
            session: session,
            darts: [segment(.single, 20), segment(.single, 20), segment(.single, 5)]
        )
    }
    let rows = StatsService.breakdowns(from: [input], nameById: [player: "Player", opponent: "Other"])
    let row = try #require(rows.first { $0.playerId == player })
    #expect(row.points == 45)
    #expect(row.darts == 3)
}

@Test(.tags(.unit, .stats, .regression))
func breakdownsCountPracticeModeDarts() throws {
    let player = UUID()
    var session = try MatchLifecycleService.createMatch(
        type: .aroundTheClock,
        config: MatchConfigDefaults.config(for: .aroundTheClock),
        participants: [
            MatchParticipant(playerId: player, displayNameAtMatchStart: "Solo", turnOrder: 0)
        ]
    )
    session = try MatchLifecycleService.submitAroundTheClockTurn(session: session, darts: [miss(), miss()])
    let input = MatchStatsInput(
        type: .aroundTheClock,
        participantKeys: [player],
        winnerKey: nil,
        events: session.events
    )
    let rows = StatsService.breakdowns(from: [input], nameById: [player: "Solo"])
    let row = try #require(rows.first)
    #expect(row.darts == 2)
}

@Test(.tags(.unit, .stats, .regression))
func breakdownsCountEnglishCricketRuns() throws {
    let player = UUID()
    let opponent = UUID()
    let input = try makeStatsInput(type: .englishCricket, player: player, opponent: opponent) { session in
        session = try MatchLifecycleService.submitEnglishCricketTurn(
            session: session,
            darts: [segment(.single, 20), segment(.single, 20), segment(.single, 20)]
        )
    }
    let rows = StatsService.breakdowns(from: [input], nameById: [player: "Player", opponent: "Other"])
    let row = try #require(rows.first { $0.playerId == player })
    #expect(row.darts == 3)
}

@Test(.tags(.unit, .stats, .regression))
func breakdownsCountFootballGoalsAfterKickoff() throws {
    let player = UUID()
    let opponent = UUID()
    var session = try MatchLifecycleService.createMatch(
        type: .football,
        config: .football(MatchConfigFootball(goalsToWin: 10, kickoffMode: .singleBull)),
        participants: [
            MatchParticipant(playerId: player, displayNameAtMatchStart: "Player", turnOrder: 0),
            MatchParticipant(playerId: opponent, displayNameAtMatchStart: "Other", turnOrder: 1)
        ]
    )
    session = try MatchLifecycleService.submitFootballTurn(
        session: session,
        darts: [
            miss(),
            DartInput(multiplier: .single, segment: .outerBull),
            miss()
        ]
    )
    session = try MatchLifecycleService.submitFootballTurn(
        session: session,
        darts: [
            miss(),
            DartInput(multiplier: .single, segment: .outerBull),
            miss()
        ]
    )
    session = try MatchLifecycleService.submitFootballTurn(
        session: session,
        darts: [segment(.double, 20), segment(.double, 18), miss()]
    )
    let input = MatchStatsInput(
        type: .football,
        participantKeys: [player, opponent],
        winnerKey: nil,
        events: session.events
    )
    let rows = StatsService.breakdowns(from: [input], nameById: [player: "Player", opponent: "Other"])
    let scorer = try #require(rows.first { $0.playerId == player })
    #expect(scorer.darts == 6)
    #expect(scorer.points >= 1)
}

@Test(.tags(.unit, .stats, .regression))
func breakdownsCountSuddenDeathAndFiftyOneByFivesVisits() throws {
    let players = [UUID(), UUID(), UUID()]
    var suddenDeath = try MatchLifecycleService.createMatch(
        type: .suddenDeath,
        config: MatchConfigDefaults.config(for: .suddenDeath),
        participants: players.enumerated().map { index, id in
            MatchParticipant(playerId: id, displayNameAtMatchStart: "P\(index + 1)", turnOrder: index)
        }
    )
    suddenDeath = try MatchLifecycleService.submitSuddenDeathTurn(session: suddenDeath, darts: [miss()])
    let suddenRows = StatsService.breakdowns(
        from: [MatchStatsInput(type: .suddenDeath, participantKeys: players, winnerKey: nil, events: suddenDeath.events)],
        nameById: Dictionary(uniqueKeysWithValues: players.enumerated().map { index, id in
            (id, "P\(index + 1)")
        })
    )
    let suddenScorer = try #require(suddenRows.first { $0.playerId == players[0] })
    #expect(suddenScorer.darts == 3)

    let p1 = UUID()
    let p2 = UUID()
    var fiftyOne = try MatchLifecycleService.createMatch(
        type: .fiftyOneByFives,
        config: MatchConfigDefaults.config(for: .fiftyOneByFives),
        participants: [
            MatchParticipant(playerId: p1, displayNameAtMatchStart: "A", turnOrder: 0),
            MatchParticipant(playerId: p2, displayNameAtMatchStart: "B", turnOrder: 1)
        ]
    )
    fiftyOne = try MatchLifecycleService.submitFiftyOneByFivesTurn(
        session: fiftyOne,
        darts: [segment(.triple, 20)]
    )
    let fiftyRows = StatsService.breakdowns(
        from: [MatchStatsInput(type: .fiftyOneByFives, participantKeys: [p1, p2], winnerKey: nil, events: fiftyOne.events)],
        nameById: [p1: "A", p2: "B"]
    )
    let scorer = try #require(fiftyRows.first { $0.playerId == p1 })
    #expect(scorer.darts == 3)
    #expect(scorer.points == 12)
}

@Test(.tags(.unit, .stats, .regression))
func breakdownsCountSequenceAndEliminationModes() throws {
    let player = UUID()
    let opponent = UUID()
    let participants = [
        MatchParticipant(playerId: player, displayNameAtMatchStart: "Player", turnOrder: 0),
        MatchParticipant(playerId: opponent, displayNameAtMatchStart: "Other", turnOrder: 1)
    ]

    var grandNational = try MatchLifecycleService.createMatch(
        type: .grandNational,
        config: MatchConfigDefaults.config(for: .grandNational),
        participants: participants
    )
    grandNational = try MatchLifecycleService.submitGrandNationalTurn(session: grandNational, darts: [miss()])
    let grandRows = StatsService.breakdowns(
        from: [MatchStatsInput(type: .grandNational, participantKeys: [player, opponent], winnerKey: nil, events: grandNational.events)],
        nameById: [player: "Player", opponent: "Other"]
    )
    let grandScorer = try #require(grandRows.first { $0.playerId == player })
    #expect(grandScorer.darts == 3)

    var nineLives = try MatchLifecycleService.createMatch(
        type: .nineLives,
        config: MatchConfigDefaults.config(for: .nineLives),
        participants: participants
    )
    nineLives = try MatchLifecycleService.submitNineLivesTurn(session: nineLives, darts: [miss()])
    let livesRows = StatsService.breakdowns(
        from: [MatchStatsInput(type: .nineLives, participantKeys: [player, opponent], winnerKey: nil, events: nineLives.events)],
        nameById: [player: "Player", opponent: "Other"]
    )
    let livesScorer = try #require(livesRows.first { $0.playerId == player })
    #expect(livesScorer.darts == 3)
}

@Test(.tags(.unit, .stats, .match, .regression))
func rehydratePreservesAmericanCricketSnapshotPlusTail() throws {
    let players = [UUID(), UUID()]
    var session = try MatchLifecycleService.createMatch(
        type: .americanCricket,
        config: MatchConfigDefaults.config(for: .americanCricket),
        participants: [
            MatchParticipant(playerId: players[0], displayNameAtMatchStart: "A", turnOrder: 0),
            MatchParticipant(playerId: players[1], displayNameAtMatchStart: "B", turnOrder: 1)
        ]
    )
    session = try MatchLifecycleService.submitAmericanCricketTurn(
        session: session,
        darts: [segment(.single, 20)],
        timestamp: Date(timeIntervalSince1970: 10)
    )
    session = try MatchLifecycleService.submitAmericanCricketTurn(
        session: session,
        darts: [segment(.single, 20)],
        timestamp: Date(timeIntervalSince1970: 20)
    )
    let snapshot = session.latestSnapshot

    session = try MatchLifecycleService.submitAmericanCricketTurn(
        session: session,
        darts: [segment(.double, 20)],
        timestamp: Date(timeIntervalSince1970: 30)
    )
    let expectedState = session.runtime.americanCricketState
    let tailEvents = session.events.filter { $0.eventIndex >= snapshot.eventCount }

    let resumed = try MatchLifecycleService.rehydrate(snapshot: snapshot, tailEvents: tailEvents)

    #expect(resumed.runtime.americanCricketState == expectedState)
    #expect(resumed.runtime.eventCount == session.runtime.eventCount)
}

@Test(.tags(.unit, .stats, .match, .regression))
func rehydratePreservesGolfSnapshotPlusTail() throws {
    let players = [UUID(), UUID()]
    var session = try MatchLifecycleService.createMatch(
        type: .golf,
        config: MatchConfigDefaults.config(for: .golf),
        participants: [
            MatchParticipant(playerId: players[0], displayNameAtMatchStart: "A", turnOrder: 0),
            MatchParticipant(playerId: players[1], displayNameAtMatchStart: "B", turnOrder: 1)
        ]
    )
    session = try MatchLifecycleService.submitGolfTurn(
        session: session,
        input: GolfTurnInput(darts: [segment(.double, 1)]),
        timestamp: Date(timeIntervalSince1970: 10)
    )
    let snapshot = session.latestSnapshot

    session = try MatchLifecycleService.submitGolfTurn(
        session: session,
        input: GolfTurnInput(darts: [miss(), segment(.triple, 2)]),
        timestamp: Date(timeIntervalSince1970: 20)
    )
    let expectedState = session.runtime.golfState
    let tailEvents = session.events.filter { $0.eventIndex >= snapshot.eventCount }

    let resumed = try MatchLifecycleService.rehydrate(snapshot: snapshot, tailEvents: tailEvents)

    #expect(resumed.runtime.golfState == expectedState)
    #expect(resumed.runtime.eventCount == session.runtime.eventCount)
}
