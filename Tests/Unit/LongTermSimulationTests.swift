import Foundation
import Testing
@testable import DartBuddy

/// End-to-end integration for the primary user journey: configure a match on setup,
/// play it through the live view model (including cold-start rehydration), then
/// read the finished game from History and Statistics.
@MainActor
@Test(.tags(.integration, .setupFlow, .match, .history, .stats, .x01, .critical, .regression))
func setupPlayCompleteHistoryFlowPersistsEndToEnd() async throws {
    let container = try ModelContainerFactory.makeContainer(mode: .inMemory)
    let matchRepo = SwiftDataMatchRepository(container: container)
    let statsRepo = SwiftDataStatsRepository(container: container)
    let playerRepo = SwiftDataPlayerRepository(container: container, matchRepository: matchRepo, statsRepository: statsRepo)
    let settingsRepo = SwiftDataSettingsRepository(container: container)
    let store = ActiveMatchStore()

    let alice = try await playerRepo.createPlayer(name: "Alice")
    let bob = try await playerRepo.createPlayer(name: "Bob")

    let setupVM = MatchSetupViewModel(
        playerRepository: playerRepo,
        settingsRepository: settingsRepo,
        matchRepository: matchRepo,
        activeMatchStore: store,
        pendingMatchPlayerSelections: PendingMatchPlayerSelections(),
        logger: DefaultAppLogger(minimumLevel: .fault, sink: IntegrationSilentLogSink())
    )
    await setupVM.onAppear()
    setupVM.randomOrder = false
    setupVM.togglePlayer(alice.id)
    setupVM.togglePlayer(bob.id)
    setupVM.x01StartScore = 301
    setupVM.x01CheckoutMode = .singleOut
    setupVM.x01LegsToWin = 1

    guard case let .x01Match(matchId) = await setupVM.startMatchRoute() else {
        Issue.record("Expected setup to return an X01 match route")
        return
    }

    #expect(try await matchRepo.fetchActiveMatch()?.id == matchId)
    #expect(store.session(for: matchId) != nil)

    let liveVM = X01MatchViewModel(
        matchId: matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: IntegrationSilentLogSink()),
        matchRepository: matchRepo,
        statsRepository: statsRepo
    )
    await liveVM.onAppear()
    liveVM.inputMode = .dartEntry
    liveVM.enteredDarts = IntegrationTurns.first301[0]
    await liveVM.submitTurn()
    #expect(liveVM.playerCards[0].score == 121)

    // Simulate app relaunch: in-memory session store is empty but SwiftData still has the match.
    store.remove(matchId: matchId)
    #expect(store.session(for: matchId) == nil)

    let resumedVM = X01MatchViewModel(
        matchId: matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: IntegrationSilentLogSink()),
        matchRepository: matchRepo,
        statsRepository: statsRepo
    )
    await resumedVM.onAppear()
    #expect(resumedVM.playerCards[0].score == 121)
    #expect(resumedVM.session?.events.count == 1)

    resumedVM.inputMode = .dartEntry
    for darts in IntegrationTurns.first301.dropFirst() {
        resumedVM.enteredDarts = darts
        await resumedVM.submitTurn()
    }

    #expect(resumedVM.state == .matchCompleted)
    #expect(try await matchRepo.fetchActiveMatch() == nil)

    let history = try await matchRepo.fetchHistory(page: 0, pageSize: 10)
    #expect(history.count == 1)
    #expect(history.first?.winnerPlayerId == alice.id)

    let historyVM = HistoryListViewModel(matchRepository: matchRepo, playerRepository: playerRepo)
    await historyVM.applyFilters()
    #expect(historyVM.rows.count == 1)
    #expect(historyVM.rows.first?.standings.contains { $0.isWinner && $0.name == "Alice" } == true)

    let detailVM = HistoryDetailViewModel(
        matchId: matchId,
        matchRepository: matchRepo,
        statsRepository: statsRepo
    )
    await detailVM.onAppear()
    #expect(detailVM.isX01)
    #expect(detailVM.breakdowns.count == 2)

    let statsVM = StatisticsViewModel(
        matchRepository: matchRepo,
        statsRepository: statsRepo,
        playerRepository: playerRepo
    )
    statsVM.modeFilter = .x01
    statsVM.period = .all
    await statsVM.load()
    let aliceRow = try #require(statsVM.rows.first { $0.playerId == alice.id })
    #expect(aliceRow.games == 1)
    #expect(aliceRow.wins == 1)
    let bobRow = try #require(statsVM.rows.first { $0.playerId == bob.id })
    #expect(bobRow.games == 1)
    #expect(bobRow.wins == 0)
}

private enum IntegrationTurns {
    static func d(_ multiplier: DartMultiplier, _ value: Int) -> DartInput {
        DartInput(multiplier: multiplier, segment: .oneToTwenty(value))
    }

    /// 301 single-out, first seat checks out on its second visit.
    static let first301: [[DartInput]] = [
        [d(.triple, 20), d(.triple, 20), d(.triple, 20)],
        [d(.triple, 20), d(.single, 20), d(.single, 20)],
        [d(.triple, 20), d(.triple, 20), d(.single, 1)]
    ]
}

private final class IntegrationSilentLogSink: LogSink, @unchecked Sendable {
    func write(_: LogEntry) {}
}

/// inspects every read surface (Statistics, Player detail, History). The whole
/// flow runs through the real SwiftData repositories + lifecycle service, so it
/// exercises the same persistence and recompute-on-read path the app uses.
@MainActor
@Test(.tags(.integration, .stats, .history, .regression))
func longTermFiftyGameSimulationKeepsDataConsistent() async throws {
    let container = try ModelContainerFactory.makeContainer(mode: .inMemory)
    let matchRepo = SwiftDataMatchRepository(container: container)
    let statsRepo = SwiftDataStatsRepository(container: container)
    let playerRepo = SwiftDataPlayerRepository(container: container, matchRepository: matchRepo, statsRepository: statsRepo)

    var roster: [PlayerSummary] = []
    for name in ["Alice", "Bob", "Carol", "Dave"] {
        roster.append(try await playerRepo.createPlayer(name: name))
    }

    // Expected per-mode games/wins, accumulated as we play so we can assert the
    // recomputed Statistics rows match reality exactly.
    var expectedGames: [MatchType: [UUID: Int]] = [.x01: [:], .cricket: [:]]
    var expectedWins: [MatchType: [UUID: Int]] = [.x01: [:], .cricket: [:]]

    func tally(type: MatchType, participants: [PlayerSummary], winner: PlayerSummary) {
        for player in participants { expectedGames[type]?[player.id, default: 0] += 1 }
        expectedWins[type]?[winner.id, default: 0] += 1
    }

    let pairs: [(PlayerSummary, PlayerSummary)] = [
        (roster[0], roster[1]), (roster[2], roster[3]), (roster[0], roster[2]),
        (roster[1], roster[3]), (roster[0], roster[3]), (roster[1], roster[2])
    ]

    var played = 0

    // 30 X01 301 single-out games, alternating which seat checks out so winner
    // detection is exercised for both the first and second player.
    for index in 0 ..< 30 {
        let (a, b) = pairs[index % pairs.count]
        let firstWins = index.isMultiple(of: 2)
        let winner = try await playX01PerDart(
            matchRepo: matchRepo,
            config: MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut),
            ordered: [a, b],
            turns: firstWins ? Turns.first301 : Turns.second301
        )
        #expect(winner == (firstWins ? a.id : b.id))
        tally(type: .x01, participants: [a, b], winner: firstWins ? a : b)
        played += 1
    }

    // 12 X01 501 double-out games (first seat wins); rotate the seat to spread wins.
    for index in 0 ..< 12 {
        let (a, b) = pairs[index % pairs.count]
        let ordered = index.isMultiple(of: 2) ? [a, b] : [b, a]
        let winner = try await playX01PerDart(
            matchRepo: matchRepo,
            config: MatchConfigX01(startScore: 501, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .doubleOut),
            ordered: ordered,
            turns: Turns.first501DoubleOut
        )
        #expect(winner == ordered[0].id)
        tally(type: .x01, participants: ordered, winner: ordered[0])
        played += 1
    }

    // 5 Cricket games (first seat closes everything, then opponent closes for completion).
    for index in 0 ..< 5 {
        let (a, b) = pairs[index % pairs.count]
        let ordered = index.isMultiple(of: 2) ? [a, b] : [b, a]
        let winner = try await playCricket(matchRepo: matchRepo, ordered: ordered)
        #expect(winner == ordered[0].id)
        tally(type: .cricket, participants: ordered, winner: ordered[0])
        played += 1
    }

    // 3 multi-leg (first to 2 legs) X01 games entered as totals; the first seat
    // sweeps both legs. Exercises leg progression + total-entry persistence.
    for index in 0 ..< 3 {
        let (a, b) = pairs[index % pairs.count]
        let winner = try await playX01Totals(
            matchRepo: matchRepo,
            config: MatchConfigX01(startScore: 301, legsToWin: 2, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut),
            ordered: [a, b],
            totals: Turns.twoLegSweep301
        )
        #expect(winner == a.id)
        tally(type: .x01, participants: [a, b], winner: a)
        played += 1
    }

    #expect(played == 50)

    // Every game is completed and visible in history, with no lingering active match.
    let history = try await matchRepo.fetchHistory(page: 0, pageSize: 1000)
    #expect(history.count == 50)
    #expect(history.allSatisfy { $0.status == .completed })
    #expect(history.allSatisfy { $0.winnerPlayerId != nil })
    let activeMatch = try await matchRepo.fetchActiveMatch()
    #expect(activeMatch == nil)

    // --- Statistics: X01 leaderboard recomputed from raw events ---
    let x01Stats = StatisticsViewModel(matchRepository: matchRepo, statsRepository: statsRepo, playerRepository: playerRepo)
    x01Stats.modeFilter = .x01
    x01Stats.period = .all
    await x01Stats.load()

    let totalX01Games = 30 + 12 + 3
    #expect(x01Stats.rows.reduce(0) { $0 + $1.wins } == totalX01Games)
    for row in x01Stats.rows {
        #expect(row.games == expectedGames[.x01]?[row.playerId])
        #expect(row.wins == expectedWins[.x01]?[row.playerId] ?? 0)
        #expect(row.average3Dart > 0)
        #expect(row.points > 0)
        #expect(row.darts > 0)
        #expect(row.wins <= row.games)
    }
    #expect(!x01Stats.sectorHits.isEmpty)
    // 20s are thrown in nearly every X01 game, so the sector chart must show them.
    #expect(x01Stats.sectorHits.contains { $0.sector == "20" && $0.count > 0 })

    // --- Statistics: Cricket leaderboard ---
    let cricketStats = StatisticsViewModel(matchRepository: matchRepo, statsRepository: statsRepo, playerRepository: playerRepo)
    cricketStats.modeFilter = .cricket
    cricketStats.period = .all
    await cricketStats.load()
    #expect(cricketStats.rows.reduce(0) { $0 + $1.wins } == 5)
    for row in cricketStats.rows {
        #expect(row.games == expectedGames[.cricket]?[row.playerId])
        #expect(row.wins == expectedWins[.cricket]?[row.playerId] ?? 0)
    }

    // --- Time-window filter: "Today" must include matches played just now ---
    let todayStats = StatisticsViewModel(matchRepository: matchRepo, statsRepository: statsRepo, playerRepository: playerRepo)
    todayStats.modeFilter = .x01
    todayStats.period = .today
    await todayStats.load()
    #expect(todayStats.rows.reduce(0) { $0 + $1.games } == x01Stats.rows.reduce(0) { $0 + $1.games })

    // --- Player detail: a single player's lifetime stats line up with the leaderboard ---
    let alice = roster[0]
    let aliceDetail = PlayerDetailViewModel(
        playerId: alice.id,
        playerName: alice.name,
        playerRepository: playerRepo,
        matchRepository: matchRepo,
        statsRepository: statsRepo
    )
    await aliceDetail.load()
    #expect(aliceDetail.hasAnyGames)
    let aliceX01 = try #require(aliceDetail.x01)
    #expect(aliceX01.games == expectedGames[.x01]?[alice.id])
    #expect(aliceX01.wins == expectedWins[.x01]?[alice.id] ?? 0)

    // --- History list: mode filters partition the 50 games correctly ---
    let historyVM = HistoryListViewModel(matchRepository: matchRepo, playerRepository: playerRepo)
    await historyVM.applyFilters()
    while historyVM.hasMorePages { await historyVM.loadMore() }
    #expect(historyVM.rows.count == 50)

    historyVM.modeFilter = .x01
    await historyVM.applyFilters()
    while historyVM.hasMorePages { await historyVM.loadMore() }
    #expect(historyVM.rows.count == totalX01Games)
    #expect(historyVM.rows.allSatisfy { $0.standings.contains { $0.isWinner } })

    historyVM.modeFilter = .cricket
    await historyVM.applyFilters()
    while historyVM.hasMorePages { await historyVM.loadMore() }
    #expect(historyVM.rows.count == 5)
}

// MARK: - Reusable scripted turns

private enum Turns {
    static func d(_ multiplier: DartMultiplier, _ value: Int) -> DartInput {
        DartInput(multiplier: multiplier, segment: .oneToTwenty(value))
    }

    static let miss = DartInput(multiplier: .single, segment: .miss, isMiss: true)
    static let innerBull = DartInput(multiplier: .single, segment: .innerBull)

    /// 301 single-out, first seat checks out on its second visit.
    static let first301: [[DartInput]] = [
        [d(.triple, 20), d(.triple, 20), d(.triple, 20)], // 180 -> 121
        [d(.triple, 20), d(.single, 20), d(.single, 20)], // 100 -> 201
        [d(.triple, 20), d(.triple, 20), d(.single, 1)]   // 121 checkout -> win
    ]

    /// 301 single-out, second seat checks out.
    static let second301: [[DartInput]] = [
        [d(.triple, 20), d(.single, 20), d(.single, 20)], // P0 100 -> 201
        [d(.triple, 20), d(.triple, 20), d(.triple, 20)], // P1 180 -> 121
        [d(.triple, 20), d(.single, 20), d(.single, 20)], // P0 100 -> 101
        [d(.triple, 20), d(.triple, 20), d(.single, 1)]   // P1 121 checkout -> win
    ]

    /// 501 double-out, first seat finishes on D12.
    static let first501DoubleOut: [[DartInput]] = [
        [d(.triple, 20), d(.triple, 20), d(.triple, 20)], // P0 180 -> 321
        [d(.single, 20), d(.single, 20), d(.single, 20)], // P1 60 -> 441
        [d(.triple, 20), d(.triple, 20), d(.triple, 20)], // P0 180 -> 141
        [d(.single, 20), d(.single, 20), d(.single, 20)], // P1 60 -> 381
        [d(.triple, 20), d(.triple, 19), d(.double, 12)]  // P0 141 checkout (double out) -> win
    ]

    /// Cricket: first seat closes 20-15 + bull while the opponent misses, then opponent closes all.
    static let cricketSweep: [[DartInput]] = [
        [d(.triple, 20), d(.triple, 19), d(.triple, 18)], // P0 closes 20,19,18
        [miss, miss, miss],                               // P1
        [d(.triple, 17), d(.triple, 16), d(.triple, 15)], // P0 closes 17,16,15
        [miss, miss, miss],                               // P1
        [innerBull, innerBull],                           // P0 closes bull
        [d(.triple, 20), d(.triple, 19), d(.triple, 18)], // P1 closes 20,19,18
        [miss, miss, miss],                               // P0
        [d(.triple, 17), d(.triple, 16), d(.triple, 15)], // P1 closes 17,16,15
        [miss, miss, miss],                               // P0
        [innerBull, innerBull]                            // P1 closes bull -> match ends
    ]

    /// 301 single-out, first-to-2-legs, first seat sweeps both legs (total entry).
    /// Turn order flips to the other seat at the start of leg 2.
    static let twoLegSweep301: [Int] = [180, 0, 121, /* leg1 */ 0, 180, 0, 121 /* leg2 */]
}

// MARK: - Persistence helpers (mirror the production setup -> play -> complete flow)

@discardableResult
private func playX01PerDart(
    matchRepo: SwiftDataMatchRepository,
    config: MatchConfigX01,
    ordered: [PlayerSummary],
    turns: [[DartInput]]
) async throws -> UUID? {
    let payload = MatchConfigPayload.x01(config)
    let matchId = try await createPersistedMatch(matchRepo: matchRepo, type: .x01, payload: payload, ordered: ordered)
    var session = try MatchLifecycleService.createMatch(
        matchId: matchId,
        type: .x01,
        config: payload,
        participants: lifecycleParticipants(ordered)
    )
    try await saveSnapshot(matchRepo: matchRepo, matchId: matchId, session: session)
    for darts in turns {
        session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: nil, darts: darts)
        try await appendLastEvent(matchRepo: matchRepo, matchId: matchId, session: session, typeRaw: "x01Turn")
        try await saveSnapshot(matchRepo: matchRepo, matchId: matchId, session: session)
    }
    return try await finish(matchRepo: matchRepo, matchId: matchId, session: session)
}

@discardableResult
private func playX01Totals(
    matchRepo: SwiftDataMatchRepository,
    config: MatchConfigX01,
    ordered: [PlayerSummary],
    totals: [Int]
) async throws -> UUID? {
    let payload = MatchConfigPayload.x01(config)
    let matchId = try await createPersistedMatch(matchRepo: matchRepo, type: .x01, payload: payload, ordered: ordered)
    var session = try MatchLifecycleService.createMatch(
        matchId: matchId,
        type: .x01,
        config: payload,
        participants: lifecycleParticipants(ordered)
    )
    try await saveSnapshot(matchRepo: matchRepo, matchId: matchId, session: session)
    for total in totals {
        session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: total, darts: nil)
        try await appendLastEvent(matchRepo: matchRepo, matchId: matchId, session: session, typeRaw: "x01Turn")
        try await saveSnapshot(matchRepo: matchRepo, matchId: matchId, session: session)
    }
    return try await finish(matchRepo: matchRepo, matchId: matchId, session: session)
}

@discardableResult
private func playCricket(
    matchRepo: SwiftDataMatchRepository,
    ordered: [PlayerSummary]
) async throws -> UUID? {
    let payload = MatchConfigPayload.cricket(MatchConfigCricket())
    let matchId = try await createPersistedMatch(matchRepo: matchRepo, type: .cricket, payload: payload, ordered: ordered)
    var session = try MatchLifecycleService.createMatch(
        matchId: matchId,
        type: .cricket,
        config: payload,
        participants: lifecycleParticipants(ordered)
    )
    try await saveSnapshot(matchRepo: matchRepo, matchId: matchId, session: session)
    for darts in Turns.cricketSweep {
        session = try MatchLifecycleService.submitCricketTurn(session: session, darts: darts)
        try await appendLastEvent(matchRepo: matchRepo, matchId: matchId, session: session, typeRaw: "cricketTurn")
        try await saveSnapshot(matchRepo: matchRepo, matchId: matchId, session: session)
    }
    return try await finish(matchRepo: matchRepo, matchId: matchId, session: session)
}

private func createPersistedMatch(
    matchRepo: SwiftDataMatchRepository,
    type: MatchType,
    payload: MatchConfigPayload,
    ordered: [PlayerSummary]
) async throws -> UUID {
    let encoded = try CodablePayloadCoder.encode(payload)
    let participantSummaries = ordered.enumerated().map { index, player in
        MatchParticipantSummary(
            id: UUID(),
            matchId: UUID(),
            playerId: player.id,
            turnOrder: index,
            displayNameAtMatchStart: player.name,
            avatarStyleAtMatchStart: nil
        )
    }
    let persisted = try await matchRepo.createMatch(type: type, configPayload: encoded, participants: participantSummaries)
    return persisted.id
}

private func lifecycleParticipants(_ ordered: [PlayerSummary]) -> [MatchParticipant] {
    ordered.enumerated().map { index, player in
        MatchParticipant(playerId: player.id, displayNameAtMatchStart: player.name, turnOrder: index)
    }
}

private func saveSnapshot(matchRepo: SwiftDataMatchRepository, matchId: UUID, session: MatchLifecycleSession) async throws {
    _ = try await matchRepo.saveSnapshot(
        matchId: matchId,
        snapshotVersion: session.latestSnapshot.payloadVersion,
        snapshotPayload: session.latestSnapshot.payload
    )
}

private func appendLastEvent(matchRepo: SwiftDataMatchRepository, matchId: UUID, session: MatchLifecycleSession, typeRaw: String) async throws {
    guard let event = session.events.last else { return }
    _ = try await matchRepo.appendEvent(
        matchId: matchId,
        eventTypeRaw: typeRaw,
        eventPayload: try CodablePayloadCoder.encode(event)
    )
}

private func finish(matchRepo: SwiftDataMatchRepository, matchId: UUID, session: MatchLifecycleSession) async throws -> UUID? {
    #expect(session.runtime.status == .completed)
    let summary = try await matchRepo.completeMatch(
        matchId: matchId,
        endedAt: Date(),
        winnerPlayerId: session.runtime.winnerPlayerId
    )
    return summary.winnerPlayerId
}
