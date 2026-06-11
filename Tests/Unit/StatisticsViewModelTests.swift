import Foundation
import Testing
@testable import DartBuddy

// MARK: - StatisticsViewModel

@MainActor
@Test(.tags(.integration, .stats, .regression))
func statisticsViewModelIsEmptyWhenNoCompletedOrActiveMatches() async {
    let vm = StatisticsViewModel(
        matchRepository: StatsVMFakeMatchRepository(),
        statsRepository: StatsVMFakeStatsRepository(events: []),
        playerRepository: StatsVMFakePlayerRepository()
    )
    await vm.load()

    #expect(vm.rows.isEmpty)
    #expect(!vm.includesPartialActiveMatch)
}

@MainActor
@Test(.tags(.integration, .stats, .x01, .regression))
func statisticsViewModelFiltersByMode() async throws {
    let fixture = try makeStatsVMCompletedFixture()
    let vm = StatisticsViewModel(
        matchRepository: StatsVMFakeMatchRepository(completed: fixture),
        statsRepository: StatsVMFakeStatsRepository(events: fixture.events),
        playerRepository: StatsVMFakePlayerRepository()
    )

    vm.modeFilter = .cricket
    await vm.load()
    #expect(vm.rows.isEmpty)

    vm.modeFilter = .x01
    await vm.load()
    #expect(vm.rows.count == 2)
}

@MainActor
@Test(.tags(.integration, .stats, .regression))
func statisticsViewModelFiltersByPeriod() async throws {
    let fixture = try makeStatsVMCompletedFixture(playedAt: Date().addingTimeInterval(-864_000))
    let vm = StatisticsViewModel(
        matchRepository: StatsVMFakeMatchRepository(completed: fixture),
        statsRepository: StatsVMFakeStatsRepository(events: fixture.events),
        playerRepository: StatsVMFakePlayerRepository()
    )

    vm.period = .d7
    await vm.load()
    #expect(vm.rows.isEmpty)

    vm.period = .all
    await vm.load()
    #expect(vm.rows.count == 2)
}

@MainActor
@Test(.tags(.integration, .stats, .x01, .regression))
func statisticsViewModelIncludesPartialActiveMatch() async throws {
    let partial = try makeStatsVMPartialFixture()
    let vm = StatisticsViewModel(
        matchRepository: StatsVMFakeMatchRepository(active: partial),
        statsRepository: StatsVMFakeStatsRepository(events: partial.events),
        playerRepository: StatsVMFakePlayerRepository()
    )
    vm.modeFilter = .x01
    vm.period = .all
    await vm.load()

    #expect(vm.includesPartialActiveMatch)
    #expect(vm.rows.count == 2)
    let jacob = try #require(vm.rows.first { $0.playerId == partial.jacob })
    #expect(jacob.games == 0)
    #expect(jacob.wins == 0)
    #expect(jacob.darts == 3)
    #expect(jacob.points == 60)
}

@MainActor
@Test(.tags(.integration, .stats, .x01, .player, .regression))
func statisticsViewModelShowsTrendChartForFilteredPlayer() async throws {
    let jacob = UUID()
    let sam = UUID()
    let earlier = try makeStatsVMCompletedFixture(playedAt: Date().addingTimeInterval(-86_400), jacob: jacob, sam: sam)
    let later = try makeStatsVMCompletedFixture(playedAt: Date(), jacob: jacob, sam: sam)
    let repo = MultiStatsVMFakeMatchRepository(fixtures: [earlier, later])
    let events = earlier.events + later.events
    let vm = StatisticsViewModel(
        matchRepository: repo,
        statsRepository: StatsVMFakeStatsRepository(events: events),
        playerRepository: StatsVMFakePlayerRepository()
    )
    vm.modeFilter = .x01
    vm.playerFilter = jacob
    await vm.load()

    #expect(vm.showsTrendChart)
    #expect(vm.trendPoints.count == 2)
    #expect(vm.trendPoints[0].date < vm.trendPoints[1].date)
}

@MainActor
@Test(.tags(.integration, .stats, .cricket, .regression))
func statisticsViewModelIncludesPartialCricketActiveMatch() async throws {
    let partial = try makeStatsVMPartialCricketFixture()
    let vm = StatisticsViewModel(
        matchRepository: StatsVMFakeMatchRepository(active: partial),
        statsRepository: StatsVMFakeStatsRepository(events: partial.events),
        playerRepository: StatsVMFakePlayerRepository()
    )
    vm.modeFilter = .cricket
    await vm.load()

    #expect(vm.includesPartialActiveMatch)
    #expect(vm.rows.count == 2)
    let thrower = try #require(vm.rows.first { $0.playerId == partial.winner })
    #expect(thrower.games == 0)
    #expect(thrower.cricketMarks > 0)
}

@MainActor
@Test(.tags(.integration, .stats, .player, .regression))
func statisticsViewModelClearsStalePlayerFilter() async throws {
    let fixture = try makeStatsVMCompletedFixture()
    let missingPlayer = UUID()
    let vm = StatisticsViewModel(
        matchRepository: StatsVMFakeMatchRepository(completed: fixture),
        statsRepository: StatsVMFakeStatsRepository(events: fixture.events),
        playerRepository: StatsVMFakePlayerRepository(players: [
            PlayerSummary(id: fixture.jacob, name: "Jacob", isArchived: false, createdAt: Date(), updatedAt: Date())
        ])
    )
    vm.playerFilter = missingPlayer
    await vm.load()

    #expect(vm.playerFilter == nil)
}

@MainActor
@Test(.tags(.integration, .stats, .cricket, .regression))
func statisticsViewModelFiltersCricketCompletedMatches() async throws {
    let fixture = try makeStatsVMCricketCompletedFixture()
    let vm = StatisticsViewModel(
        matchRepository: StatsVMFakeMatchRepository(completed: fixture),
        statsRepository: StatsVMFakeStatsRepository(events: fixture.events),
        playerRepository: StatsVMFakePlayerRepository()
    )

    vm.modeFilter = .x01
    await vm.load()
    #expect(vm.rows.isEmpty)

    vm.modeFilter = .cricket
    await vm.load()
    #expect(vm.rows.count == 2)
    let winner = try #require(vm.rows.first { $0.playerId == fixture.winner })
    #expect(winner.wins == 1)
    #expect(winner.games == 1)
}

@MainActor
@Test(.tags(.integration, .stats, .x01, .regression))
func statisticsViewModelOmitsPartialWhenModeDiffers() async throws {
    let partial = try makeStatsVMPartialFixture()
    let vm = StatisticsViewModel(
        matchRepository: StatsVMFakeMatchRepository(active: partial),
        statsRepository: StatsVMFakeStatsRepository(events: partial.events),
        playerRepository: StatsVMFakePlayerRepository()
    )
    vm.modeFilter = .cricket
    await vm.load()

    #expect(!vm.includesPartialActiveMatch)
    #expect(vm.rows.isEmpty)
}

// MARK: - MatchSummaryViewModel

@MainActor
@Test(.tags(.integration, .match, .regression))
func matchSummaryViewModelHasNoResultWhenSnapshotMissing() async {
    let vm = MatchSummaryViewModel(
        matchId: UUID(),
        store: ActiveMatchStore(),
        matchRepository: StatsVMFakeMatchRepository(),
        statsRepository: StatsVMFakeStatsRepository(events: [])
    )

    await vm.loadIfNeeded()

    #expect(!vm.hasResult)
    #expect(vm.playerRows.isEmpty)
}

// MARK: - Fixtures

private struct StatsVMCompletedFixture {
    let matchId: UUID
    let jacob: UUID
    let sam: UUID
    let winner: UUID
    let summary: MatchSummary
    let participants: [MatchParticipantSummary]
    let events: [MatchEventSummary]
    let snapshot: MatchSnapshotSummary

    init(
        matchId: UUID,
        jacob: UUID,
        sam: UUID,
        winner: UUID,
        summary: MatchSummary,
        participants: [MatchParticipantSummary],
        events: [MatchEventSummary],
        snapshot: MatchSnapshotSummary
    ) {
        self.matchId = matchId
        self.jacob = jacob
        self.sam = sam
        self.winner = winner
        self.summary = summary
        self.participants = participants
        self.events = events
        self.snapshot = snapshot
    }
}

private struct StatsVMPartialFixture {
    let matchId: UUID
    let jacob: UUID
    let sam: UUID
    let summary: MatchSummary
    let participants: [MatchParticipantSummary]
    let events: [MatchEventSummary]
    let snapshot: MatchSnapshotSummary
}

private func makeStatsVMCompletedFixture(
    playedAt: Date = Date(),
    jacob: UUID = UUID(),
    sam: UUID = UUID()
) throws -> StatsVMCompletedFixture {
    let matchId = UUID()
    func d(_ multiplier: DartMultiplier, _ value: Int) -> DartInput {
        DartInput(multiplier: multiplier, segment: .oneToTwenty(value))
    }
    var session = try MatchLifecycleService.createMatch(
        matchId: matchId,
        type: .x01,
        config: .x01(MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
        participants: [
            MatchParticipant(playerId: jacob, displayNameAtMatchStart: "Jacob", turnOrder: 0),
            MatchParticipant(playerId: sam, displayNameAtMatchStart: "Sam", turnOrder: 1)
        ]
    )
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: nil, darts: [d(.triple, 20), d(.triple, 20), d(.triple, 20)])
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: nil, darts: [d(.triple, 20), d(.single, 20), d(.single, 20)])
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: nil, darts: [d(.triple, 20), d(.triple, 20), d(.single, 1)])

    let summary = MatchSummary(
        id: matchId,
        type: .x01,
        status: .completed,
        startedAt: playedAt,
        endedAt: playedAt,
        winnerPlayerId: jacob,
        currentTurnPlayerId: nil,
        currentLegIndex: 0,
        currentSetIndex: 0,
        eventCount: session.events.count,
        createdAt: playedAt,
        updatedAt: playedAt
    )
    let participants = [
        MatchParticipantSummary(id: UUID(), matchId: matchId, playerId: jacob, turnOrder: 0, displayNameAtMatchStart: "Jacob", avatarStyleAtMatchStart: nil),
        MatchParticipantSummary(id: UUID(), matchId: matchId, playerId: sam, turnOrder: 1, displayNameAtMatchStart: "Sam", avatarStyleAtMatchStart: nil)
    ]
    let latest = session.latestSnapshot
    let events = try session.events.map { envelope in
        MatchEventSummary(
            id: UUID(),
            matchId: matchId,
            eventIndex: envelope.eventIndex,
            eventTypeRaw: "x01Turn",
            eventPayload: try CodablePayloadCoder.encode(envelope),
            createdAt: playedAt
        )
    }
    let snapshot = MatchSnapshotSummary(
        id: UUID(),
        matchId: matchId,
        snapshotVersion: latest.payloadVersion,
        snapshotPayload: latest.payload,
        updatedAt: playedAt
    )
    return StatsVMCompletedFixture(
        matchId: matchId,
        jacob: jacob,
        sam: sam,
        winner: jacob,
        summary: summary,
        participants: participants,
        events: events,
        snapshot: snapshot
    )
}

private func makeStatsVMCricketCompletedFixture(playedAt: Date = Date()) throws -> StatsVMCompletedFixture {
    let matchId = UUID()
    let winner = UUID()
    let loser = UUID()
    var session = try MatchLifecycleService.createMatch(
        matchId: matchId,
        type: .cricket,
        config: .cricket(MatchConfigCricket(legsToWin: 1)),
        participants: [
            MatchParticipant(playerId: winner, displayNameAtMatchStart: "Winner", turnOrder: 0),
            MatchParticipant(playerId: loser, displayNameAtMatchStart: "Loser", turnOrder: 1)
        ]
    )
    let closeNumbers = [
        DartInput(multiplier: .triple, segment: .oneToTwenty(20)),
        DartInput(multiplier: .triple, segment: .oneToTwenty(19)),
        DartInput(multiplier: .triple, segment: .oneToTwenty(18))
    ]
    let closeLow = [
        DartInput(multiplier: .triple, segment: .oneToTwenty(17)),
        DartInput(multiplier: .triple, segment: .oneToTwenty(16)),
        DartInput(multiplier: .triple, segment: .oneToTwenty(15))
    ]
    let closeBull = [
        DartInput(multiplier: .single, segment: .innerBull),
        DartInput(multiplier: .single, segment: .innerBull)
    ]
    for _ in 0 ..< 2 {
        session = try MatchLifecycleService.submitCricketTurn(session: session, darts: closeNumbers)
        session = try MatchLifecycleService.submitCricketTurn(session: session, darts: closeLow)
        session = try MatchLifecycleService.submitCricketTurn(session: session, darts: closeBull)
    }
    #expect(session.runtime.status == .completed)

    let summary = MatchSummary(
        id: matchId,
        type: .cricket,
        status: .completed,
        startedAt: playedAt,
        endedAt: playedAt,
        winnerPlayerId: winner,
        currentTurnPlayerId: nil,
        currentLegIndex: 0,
        currentSetIndex: 0,
        eventCount: session.events.count,
        createdAt: playedAt,
        updatedAt: playedAt
    )
    let participants = [
        MatchParticipantSummary(id: UUID(), matchId: matchId, playerId: winner, turnOrder: 0, displayNameAtMatchStart: "Winner", avatarStyleAtMatchStart: nil),
        MatchParticipantSummary(id: UUID(), matchId: matchId, playerId: loser, turnOrder: 1, displayNameAtMatchStart: "Loser", avatarStyleAtMatchStart: nil)
    ]
    let latest = session.latestSnapshot
    let events = try session.events.map { envelope in
        MatchEventSummary(
            id: UUID(),
            matchId: matchId,
            eventIndex: envelope.eventIndex,
            eventTypeRaw: "cricketTurn",
            eventPayload: try CodablePayloadCoder.encode(envelope),
            createdAt: playedAt
        )
    }
    let snapshot = MatchSnapshotSummary(
        id: UUID(),
        matchId: matchId,
        snapshotVersion: latest.payloadVersion,
        snapshotPayload: latest.payload,
        updatedAt: playedAt
    )
    return StatsVMCompletedFixture(
        matchId: matchId,
        jacob: winner,
        sam: loser,
        winner: winner,
        summary: summary,
        participants: participants,
        events: events,
        snapshot: snapshot
    )
}

private struct StatsVMPartialCricketFixture {
    let matchId: UUID
    let winner: UUID
    let loser: UUID
    let summary: MatchSummary
    let participants: [MatchParticipantSummary]
    let events: [MatchEventSummary]
    let snapshot: MatchSnapshotSummary
}

private func makeStatsVMPartialCricketFixture() throws -> StatsVMPartialCricketFixture {
    let matchId = UUID()
    let winner = UUID()
    let loser = UUID()
    var session = try MatchLifecycleService.createMatch(
        matchId: matchId,
        type: .cricket,
        config: .cricket(MatchConfigCricket()),
        participants: [
            MatchParticipant(playerId: winner, displayNameAtMatchStart: "Winner", turnOrder: 0),
            MatchParticipant(playerId: loser, displayNameAtMatchStart: "Loser", turnOrder: 1)
        ]
    )
    session = try MatchLifecycleService.submitCricketTurn(
        session: session,
        darts: [DartInput(multiplier: .triple, segment: .oneToTwenty(20))]
    )
    let startedAt = Date()
    let summary = MatchSummary(
        id: matchId,
        type: .cricket,
        status: .inProgress,
        startedAt: startedAt,
        endedAt: nil,
        winnerPlayerId: nil,
        currentTurnPlayerId: loser,
        currentLegIndex: 0,
        currentSetIndex: 0,
        eventCount: session.events.count,
        createdAt: startedAt,
        updatedAt: startedAt
    )
    let participants = [
        MatchParticipantSummary(id: UUID(), matchId: matchId, playerId: winner, turnOrder: 0, displayNameAtMatchStart: "Winner", avatarStyleAtMatchStart: nil),
        MatchParticipantSummary(id: UUID(), matchId: matchId, playerId: loser, turnOrder: 1, displayNameAtMatchStart: "Loser", avatarStyleAtMatchStart: nil)
    ]
    let latest = session.latestSnapshot
    let events = try session.events.map { envelope in
        MatchEventSummary(
            id: UUID(),
            matchId: matchId,
            eventIndex: envelope.eventIndex,
            eventTypeRaw: "cricketTurn",
            eventPayload: try CodablePayloadCoder.encode(envelope),
            createdAt: envelope.timestamp
        )
    }
    let snapshot = MatchSnapshotSummary(
        id: UUID(),
        matchId: matchId,
        snapshotVersion: latest.payloadVersion,
        snapshotPayload: latest.payload,
        updatedAt: startedAt
    )
    return StatsVMPartialCricketFixture(
        matchId: matchId,
        winner: winner,
        loser: loser,
        summary: summary,
        participants: participants,
        events: events,
        snapshot: snapshot
    )
}

private func makeStatsVMPartialFixture() throws -> StatsVMPartialFixture {
    let matchId = UUID()
    let jacob = UUID()
    let sam = UUID()
    var session = try MatchLifecycleService.createMatch(
        matchId: matchId,
        type: .x01,
        config: .x01(MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
        participants: [
            MatchParticipant(playerId: jacob, displayNameAtMatchStart: "Jacob", turnOrder: 0),
            MatchParticipant(playerId: sam, displayNameAtMatchStart: "Sam", turnOrder: 1)
        ]
    )
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 60, darts: nil)
    let startedAt = Date()
    let summary = MatchSummary(
        id: matchId,
        type: .x01,
        status: .inProgress,
        startedAt: startedAt,
        endedAt: nil,
        winnerPlayerId: nil,
        currentTurnPlayerId: sam,
        currentLegIndex: 0,
        currentSetIndex: 0,
        eventCount: session.events.count,
        createdAt: startedAt,
        updatedAt: startedAt
    )
    let participants = [
        MatchParticipantSummary(id: UUID(), matchId: matchId, playerId: jacob, turnOrder: 0, displayNameAtMatchStart: "Jacob", avatarStyleAtMatchStart: nil),
        MatchParticipantSummary(id: UUID(), matchId: matchId, playerId: sam, turnOrder: 1, displayNameAtMatchStart: "Sam", avatarStyleAtMatchStart: nil)
    ]
    let latest = session.latestSnapshot
    let events = try session.events.map { envelope in
        MatchEventSummary(
            id: UUID(),
            matchId: matchId,
            eventIndex: envelope.eventIndex,
            eventTypeRaw: "x01Turn",
            eventPayload: try CodablePayloadCoder.encode(envelope),
            createdAt: envelope.timestamp
        )
    }
    let snapshot = MatchSnapshotSummary(
        id: UUID(),
        matchId: matchId,
        snapshotVersion: latest.payloadVersion,
        snapshotPayload: latest.payload,
        updatedAt: startedAt
    )
    return StatsVMPartialFixture(
        matchId: matchId,
        jacob: jacob,
        sam: sam,
        summary: summary,
        participants: participants,
        events: events,
        snapshot: snapshot
    )
}

private actor MultiStatsVMFakeMatchRepository: MatchRepository {
    let fixtures: [StatsVMCompletedFixture]

    init(fixtures: [StatsVMCompletedFixture]) { self.fixtures = fixtures }

    func fetchActiveMatch() async throws -> MatchSummary? { nil }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] {
        fixtures.map(\.summary)
    }
    func fetchHistoryWithParticipants(page: Int, pageSize: Int, filter: MatchHistoryFilter) async throws -> [MatchHistoryRecord] {
        guard page == 0 else { return [] }
        return fixtures.compactMap { fixture in
            if let type = filter.matchType, fixture.summary.type != type { return nil }
            if let startedAfter = filter.startedAfter, fixture.summary.startedAt < startedAfter { return nil }
            return MatchHistoryRecord(summary: fixture.summary, participants: fixture.participants)
        }.prefix(pageSize).map { $0 }
    }
    func fetchLatestSnapshot(matchId: UUID) async throws -> MatchSnapshotSummary? {
        fixtures.first { $0.matchId == matchId }?.snapshot
    }
    func fetchMatch(matchId: UUID) async throws -> MatchSummary? {
        fixtures.first { $0.matchId == matchId }?.summary
    }
    func fetchParticipants(matchId: UUID) async throws -> [MatchParticipantSummary] {
        fixtures.first { $0.matchId == matchId }?.participants ?? []
    }

    func createMatch(type _: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary { fatalError() }
    func updateMatch(_: MatchSummary) async throws {}
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary { fatalError() }
    func appendEvent(matchId _: UUID, eventTypeRaw _: String, eventPayload _: Data) async throws -> MatchEventSummary { fatalError() }
    func saveSnapshot(matchId _: UUID, snapshotVersion _: Int, snapshotPayload _: Data) async throws -> MatchSnapshotSummary { fatalError() }
    func deleteMatch(matchId _: UUID) async throws {}
}

private actor StatsVMFakeMatchRepository: MatchRepository {
    private let completed: StatsVMCompletedFixture?
    private let active: (any StatsVMActiveFixture)?

    init(completed: StatsVMCompletedFixture? = nil, active: StatsVMPartialFixture? = nil) {
        self.completed = completed
        self.active = active
    }

    init(completed: StatsVMCompletedFixture? = nil, active: StatsVMPartialCricketFixture) {
        self.completed = completed
        self.active = active
    }

    func createMatch(type _: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary {
        throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error")
    }

    func fetchActiveMatch() async throws -> MatchSummary? { active?.summaryMatch }

    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] {
        completed.map { [$0.summary] } ?? []
    }

    func fetchHistoryWithParticipants(page _: Int, pageSize _: Int, filter: MatchHistoryFilter) async throws -> [MatchHistoryRecord] {
        guard let completed else { return [] }
        if let type = filter.matchType, completed.summary.type != type { return [] }
        if let startedAfter = filter.startedAfter, completed.summary.startedAt < startedAfter { return [] }
        if let playerId = filter.participantPlayerId,
           !completed.participants.contains(where: { $0.playerId == playerId }) {
            return []
        }
        return [MatchHistoryRecord(summary: completed.summary, participants: completed.participants)]
    }

    func updateMatch(_: MatchSummary) async throws {}
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary {
        throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error")
    }
    func appendEvent(matchId _: UUID, eventTypeRaw _: String, eventPayload _: Data) async throws -> MatchEventSummary {
        throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error")
    }
    func saveSnapshot(matchId _: UUID, snapshotVersion _: Int, snapshotPayload _: Data) async throws -> MatchSnapshotSummary {
        throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error")
    }

    func fetchLatestSnapshot(matchId: UUID) async throws -> MatchSnapshotSummary? {
        if active?.matchId == matchId { return active?.snapshotSummary }
        if completed?.matchId == matchId { return completed?.snapshot }
        return nil
    }

    func fetchMatch(matchId: UUID) async throws -> MatchSummary? {
        if active?.matchId == matchId { return active?.summaryMatch }
        if completed?.matchId == matchId { return completed?.summary }
        return nil
    }

    func fetchParticipants(matchId: UUID) async throws -> [MatchParticipantSummary] {
        if let active, active.matchId == matchId { return active.participantSummaries }
        if completed?.matchId == matchId { return completed?.participants ?? [] }
        return []
    }

    func deleteMatch(matchId _: UUID) async throws {}
}

private actor StatsVMFakeStatsRepository: StatsRepository {
    private let events: [MatchEventSummary]

    init(events: [MatchEventSummary]) { self.events = events }

    func fetchEvents(matchId: UUID) async throws -> [MatchEventSummary] {
        events.filter { $0.matchId == matchId }
    }

    func fetchEvents(matchIds: [UUID]) async throws -> [MatchEventSummary] {
        events.filter { matchIds.contains($0.matchId) }
    }
}

private protocol StatsVMActiveFixture {
    var matchId: UUID { get }
    var summaryMatch: MatchSummary { get }
    var participantSummaries: [MatchParticipantSummary] { get }
    var snapshotSummary: MatchSnapshotSummary { get }
}

extension StatsVMPartialFixture: StatsVMActiveFixture {
    var summaryMatch: MatchSummary { summary }
    var participantSummaries: [MatchParticipantSummary] { participants }
    var snapshotSummary: MatchSnapshotSummary { snapshot }
}

extension StatsVMPartialCricketFixture: StatsVMActiveFixture {
    var summaryMatch: MatchSummary { summary }
    var participantSummaries: [MatchParticipantSummary] { participants }
    var snapshotSummary: MatchSnapshotSummary { snapshot }
}

private actor StatsVMFakePlayerRepository: PlayerRepository {
    let players: [PlayerSummary]

    init(players: [PlayerSummary] = []) { self.players = players }

    func fetchPlayers(includeArchived _: Bool) async throws -> [PlayerSummary] { players }
    func createPlayer(name _: String) async throws -> PlayerSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error") }
    func createBot(difficulty _: BotDifficulty) async throws -> PlayerSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error") }
    func updatePlayerName(playerId _: UUID, name _: String) async throws -> PlayerSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error") }
    func updatePlayerProfile(playerId _: UUID, name _: String, avatarStyle _: PlayerAvatarStyle, colorToken _: PlayerColorToken, notes _: String) async throws -> PlayerSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error") }
    func archivePlayer(playerId _: UUID) async throws {}
    func unarchivePlayer(playerId _: UUID) async throws {}
    func deletePlayer(playerId _: UUID) async throws {}
}
