import Foundation
import Testing
@testable import DartsScoreboard

@MainActor
@Test(.tags(.unit, .player, .regression))
func playerEditValidationRejectsDuplicateName() {
    let vm = PlayerEditViewModel(existingNames: ["Alice"], editing: nil)
    vm.name = "alice"
    vm.validate()
    #expect(!vm.canSave)
    #expect(vm.validationMessage == "player.validation.duplicateName")
}

@MainActor
@Test(.tags(.integration, .history, .match, .regression))
func historyFiltersByModeDeterministically() async {
    let now = Date()
    let vm = HistoryListViewModel(
        matchRepository: FakeHistoryMatchRepository(
            rows: [
                MatchSummary(
                    id: UUID(),
                    type: .x01,
                    status: .completed,
                    startedAt: now,
                    endedAt: now,
                    winnerPlayerId: nil,
                    currentTurnPlayerId: nil,
                    currentLegIndex: 0,
                    currentSetIndex: 0,
                    eventCount: 10,
                    createdAt: now,
                    updatedAt: now
                ),
                MatchSummary(
                    id: UUID(),
                    type: .cricket,
                    status: .completed,
                    startedAt: now,
                    endedAt: now,
                    winnerPlayerId: nil,
                    currentTurnPlayerId: nil,
                    currentLegIndex: 0,
                    currentSetIndex: 0,
                    eventCount: 12,
                    createdAt: now,
                    updatedAt: now
                )
            ]
        ),
        playerRepository: FakeHistoryPlayerRepository(players: [])
    )
    vm.modeFilter = .x01
    await vm.applyFilters()

    #expect(vm.rows.count == 1)
    #expect(vm.rows.first?.summary.type == .x01)
}

@MainActor
@Test(.tags(.integration, .history, .player, .regression))
func historyFiltersByPlayer() async {
    let alice = UUID()
    let bob = UUID()
    let carol = UUID()
    let now = Date()
    let x01Match = MatchSummary(
        id: UUID(),
        type: .x01,
        status: .completed,
        startedAt: now,
        endedAt: now,
        winnerPlayerId: alice,
        currentTurnPlayerId: nil,
        currentLegIndex: 0,
        currentSetIndex: 0,
        eventCount: 10,
        createdAt: now,
        updatedAt: now
    )
    let cricketMatch = MatchSummary(
        id: UUID(),
        type: .cricket,
        status: .completed,
        startedAt: now,
        endedAt: now,
        winnerPlayerId: carol,
        currentTurnPlayerId: nil,
        currentLegIndex: 0,
        currentSetIndex: 0,
        eventCount: 12,
        createdAt: now,
        updatedAt: now
    )
    let vm = HistoryListViewModel(
        matchRepository: FakeHistoryMatchRepository(
            rows: [x01Match, cricketMatch],
            participantsByMatchId: [
                x01Match.id: [
                    MatchParticipantSummary(id: UUID(), matchId: x01Match.id, playerId: alice, turnOrder: 0, displayNameAtMatchStart: "Alice", avatarStyleAtMatchStart: nil),
                    MatchParticipantSummary(id: UUID(), matchId: x01Match.id, playerId: bob, turnOrder: 1, displayNameAtMatchStart: "Bob", avatarStyleAtMatchStart: nil)
                ],
                cricketMatch.id: [
                    MatchParticipantSummary(id: UUID(), matchId: cricketMatch.id, playerId: carol, turnOrder: 0, displayNameAtMatchStart: "Carol", avatarStyleAtMatchStart: nil),
                    MatchParticipantSummary(id: UUID(), matchId: cricketMatch.id, playerId: bob, turnOrder: 1, displayNameAtMatchStart: "Bob", avatarStyleAtMatchStart: nil)
                ]
            ]
        ),
        playerRepository: FakeHistoryPlayerRepository(players: [
            PlayerSummary(id: alice, name: "Alice", isArchived: false, isBot: false, botDifficultyRaw: nil, avatarStyleRaw: nil, preferredColorToken: nil, notes: nil, createdAt: now, updatedAt: now),
            PlayerSummary(id: bob, name: "Bob", isArchived: false, isBot: false, botDifficultyRaw: nil, avatarStyleRaw: nil, preferredColorToken: nil, notes: nil, createdAt: now, updatedAt: now),
            PlayerSummary(id: carol, name: "Carol", isArchived: false, isBot: false, botDifficultyRaw: nil, avatarStyleRaw: nil, preferredColorToken: nil, notes: nil, createdAt: now, updatedAt: now)
        ])
    )

    await vm.applyFilters()
    #expect(vm.rows.count == 2)

    vm.playerFilter = bob
    await vm.applyFilters()
    #expect(vm.rows.count == 2)

    vm.playerFilter = carol
    await vm.applyFilters()
    #expect(vm.rows.count == 1)
    #expect(vm.rows.first?.summary.type == .cricket)
    #expect(vm.state == .readyFiltered)
}

@MainActor
@Test(.tags(.integration, .history, .regression))
func historyListViewModelPaginatesResults() async {
    let now = Date()
    let rows = (0 ..< 30).map { index in
        MatchSummary(
            id: UUID(),
            type: .x01,
            status: .completed,
            startedAt: now.addingTimeInterval(TimeInterval(-index)),
            endedAt: now.addingTimeInterval(TimeInterval(-index)),
            winnerPlayerId: nil,
            currentTurnPlayerId: nil,
            currentLegIndex: 0,
            currentSetIndex: 0,
            eventCount: 1,
            createdAt: now,
            updatedAt: now
        )
    }
    let vm = HistoryListViewModel(
        matchRepository: FakeHistoryMatchRepository(rows: rows),
        playerRepository: FakeHistoryPlayerRepository(players: [])
    )

    await vm.applyFilters()
    #expect(vm.rows.count == 25)
    #expect(vm.hasMorePages == true)

    await vm.loadMore()
    #expect(vm.rows.count == 30)
    #expect(vm.hasMorePages == false)
}

// MARK: - Stats / detail fixtures

private struct StatsFixture {
    let matchId: UUID
    let jacob: UUID
    let sam: UUID
    let summary: MatchSummary
    let participants: [MatchParticipantSummary]
    let events: [MatchEventSummary]
    let snapshot: MatchSnapshotSummary
}

private func makeCompletedX01Fixture() throws -> StatsFixture {
    let matchId = UUID()
    let jacob = UUID()
    let sam = UUID()
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

    let now = Date()
    let summary = MatchSummary(
        id: matchId,
        type: .x01,
        status: .completed,
        startedAt: now,
        endedAt: now,
        winnerPlayerId: jacob,
        currentTurnPlayerId: nil,
        currentLegIndex: 0,
        currentSetIndex: 0,
        eventCount: session.events.count,
        createdAt: now,
        updatedAt: now
    )
    let participants = [
        MatchParticipantSummary(id: UUID(), matchId: matchId, playerId: jacob, turnOrder: 0, displayNameAtMatchStart: "Jacob", avatarStyleAtMatchStart: nil),
        MatchParticipantSummary(id: UUID(), matchId: matchId, playerId: sam, turnOrder: 1, displayNameAtMatchStart: "Sam", avatarStyleAtMatchStart: nil)
    ]
    let events = try session.events.map { envelope in
        MatchEventSummary(
            id: UUID(),
            matchId: matchId,
            eventIndex: envelope.eventIndex,
            eventTypeRaw: "x01Turn",
            eventPayload: try CodablePayloadCoder.encode(envelope),
            createdAt: now
        )
    }
    let snapshot = MatchSnapshotSummary(
        id: UUID(),
        matchId: matchId,
        snapshotVersion: session.latestSnapshot.payloadVersion,
        snapshotPayload: session.latestSnapshot.payload,
        updatedAt: now
    )
    return StatsFixture(matchId: matchId, jacob: jacob, sam: sam, summary: summary, participants: participants, events: events, snapshot: snapshot)
}

private actor StatsFakeMatchRepository: MatchRepository {
    private let fixture: StatsFixture
    private(set) var deletedIds: [UUID] = []

    init(fixture: StatsFixture) { self.fixture = fixture }

    func createMatch(type _: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary { fixture.summary }
    func fetchActiveMatch() async throws -> MatchSummary? { nil }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { [fixture.summary] }
    func fetchHistoryWithParticipants(page _: Int, pageSize _: Int, filter: MatchHistoryFilter) async throws -> [MatchHistoryRecord] {
        guard filter.matchType == nil || filter.matchType == fixture.summary.type else { return [] }
        return [MatchHistoryRecord(summary: fixture.summary, participants: fixture.participants)]
    }
    func updateMatch(_: MatchSummary) async throws {}
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary { fixture.summary }
    func appendEvent(matchId _: UUID, eventTypeRaw _: String, eventPayload _: Data) async throws -> MatchEventSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented") }
    func saveSnapshot(matchId _: UUID, snapshotVersion _: Int, snapshotPayload _: Data) async throws -> MatchSnapshotSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented") }
    func fetchLatestSnapshot(matchId: UUID) async throws -> MatchSnapshotSummary? {
        matchId == fixture.matchId ? fixture.snapshot : nil
    }
    func fetchMatch(matchId: UUID) async throws -> MatchSummary? { matchId == fixture.matchId ? fixture.summary : nil }
    func fetchParticipants(matchId _: UUID) async throws -> [MatchParticipantSummary] { fixture.participants }
    func deleteMatch(matchId: UUID) async throws { deletedIds.append(matchId) }

    func wasDeleted(_ id: UUID) -> Bool { deletedIds.contains(id) }
}

private actor StatsFakeStatsRepository: StatsRepository {
    private let events: [MatchEventSummary]
    init(events: [MatchEventSummary]) { self.events = events }
    func fetchEvents(matchId _: UUID) async throws -> [MatchEventSummary] { events }
    func fetchEvents(matchIds _: [UUID]) async throws -> [MatchEventSummary] { events }
}

private actor StatsFakePlayerRepository: PlayerRepository {
    func fetchPlayers(includeArchived _: Bool) async throws -> [PlayerSummary] { [] }
    func createPlayer(name _: String) async throws -> PlayerSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented") }
    func createBot(difficulty _: BotDifficulty) async throws -> PlayerSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented") }
    func updatePlayerName(playerId _: UUID, name _: String) async throws -> PlayerSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented") }
    func updatePlayerProfile(playerId _: UUID, name _: String, avatarStyle _: PlayerAvatarStyle, colorToken _: PlayerColorToken, notes _: String) async throws -> PlayerSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented") }
    func archivePlayer(playerId _: UUID) async throws {}
    func unarchivePlayer(playerId _: UUID) async throws {}
    func deletePlayer(playerId _: UUID) async throws {}
}

@MainActor
@Test(.tags(.integration, .stats, .x01, .regression))
func statisticsViewModelComputesBreakdownRows() async throws {
    let fixture = try makeCompletedX01Fixture()
    let vm = StatisticsViewModel(
        matchRepository: StatsFakeMatchRepository(fixture: fixture),
        statsRepository: StatsFakeStatsRepository(events: fixture.events),
        playerRepository: StatsFakePlayerRepository()
    )
    await vm.load()

    #expect(vm.rows.count == 2)
    let jacob = try #require(vm.rows.first { $0.playerId == fixture.jacob })
    #expect(jacob.wins == 1)
    #expect(jacob.points == 301)
    #expect(jacob.highestScore == 180)
    #expect(!vm.sectorHits.isEmpty)
}

@MainActor
@Test(.tags(.integration, .stats, .player, .regression))
func statisticsViewModelFiltersToSinglePlayer() async throws {
    let fixture = try makeCompletedX01Fixture()
    let vm = StatisticsViewModel(
        matchRepository: StatsFakeMatchRepository(fixture: fixture),
        statsRepository: StatsFakeStatsRepository(events: fixture.events),
        playerRepository: StatsFakePlayerRepository()
    )
    vm.playerFilter = fixture.jacob
    await vm.load()

    #expect(vm.rows.count == 1)
    #expect(vm.rows.first?.playerId == fixture.jacob)
    #expect(vm.rows.first?.wins == 1)
}

@MainActor
@Test(.tags(.integration, .stats, .player, .regression))
func playerDetailViewModelLoadsAllGamesStats() async throws {
    let fixture = try makeCompletedX01Fixture()
    let vm = PlayerDetailViewModel(
        playerId: fixture.jacob,
        playerName: "Jacob",
        matchRepository: StatsFakeMatchRepository(fixture: fixture),
        statsRepository: StatsFakeStatsRepository(events: fixture.events)
    )
    await vm.load()

    #expect(vm.hasAnyGames)
    #expect(vm.cricket == nil)
    let x01 = try #require(vm.x01)
    #expect(x01.games == 1)
    #expect(x01.wins == 1)
    #expect(x01.legs == 1)
    #expect(x01.highestCheckout == 121)
}

@MainActor
@Test(.tags(.integration, .history, .regression))
func historyDetailViewModelDeletesMatch() async throws {
    let fixture = try makeCompletedX01Fixture()
    let repo = StatsFakeMatchRepository(fixture: fixture)
    let vm = HistoryDetailViewModel(
        matchId: fixture.matchId,
        matchRepository: repo,
        statsRepository: StatsFakeStatsRepository(events: fixture.events)
    )
    await vm.onAppear()
    #expect(!vm.breakdowns.isEmpty)
    #expect(vm.isX01)

    let deleted = await vm.deleteMatch()
    #expect(deleted)
    #expect(await repo.wasDeleted(fixture.matchId))
}

@MainActor
@Test(.tags(.integration, .history, .stats, .regression))
func historyDetailViewModelLoadsBreakdownsForCompletedMatch() async throws {
    let fixture = try makeCompletedX01Fixture()
    let vm = HistoryDetailViewModel(
        matchId: fixture.matchId,
        matchRepository: StatsFakeMatchRepository(fixture: fixture),
        statsRepository: StatsFakeStatsRepository(events: fixture.events)
    )
    await vm.onAppear()

    #expect(vm.state == "ready")
    #expect(vm.breakdowns.count == 2)
    #expect(vm.isX01)
    #expect(!vm.configText.isEmpty)
    #expect(vm.standings.count == 2)
}

private actor FakeHistoryMatchRepository: MatchRepository {
    let rows: [MatchSummary]
    let participantsByMatchId: [UUID: [MatchParticipantSummary]]

    init(rows: [MatchSummary], participantsByMatchId: [UUID: [MatchParticipantSummary]] = [:]) {
        self.rows = rows
        self.participantsByMatchId = participantsByMatchId
    }

    private var allRecords: [MatchHistoryRecord] {
        rows.map { MatchHistoryRecord(summary: $0, participants: participantsByMatchId[$0.id] ?? []) }
    }

    private func filteredRecords(filter: MatchHistoryFilter) -> [MatchHistoryRecord] {
        allRecords.filter { record in
            if let type = filter.matchType, record.summary.type != type { return false }
            if let startedAfter = filter.startedAfter, record.summary.startedAt < startedAfter { return false }
            if let playerId = filter.participantPlayerId {
                guard record.participants.contains(where: { ($0.playerId ?? $0.id) == playerId }) else { return false }
            }
            return true
        }
    }

    func createMatch(type _: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary { rows.first! }
    func fetchActiveMatch() async throws -> MatchSummary? { nil }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { rows }
    func fetchHistoryWithParticipants(page: Int, pageSize: Int, filter: MatchHistoryFilter) async throws -> [MatchHistoryRecord] {
        let filtered = filteredRecords(filter: filter)
        let start = max(0, page) * max(1, pageSize)
        guard start < filtered.count else { return [] }
        return Array(filtered.dropFirst(start).prefix(pageSize))
    }
    func updateMatch(_: MatchSummary) async throws {}
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary { rows.first! }
    func appendEvent(matchId _: UUID, eventTypeRaw _: String, eventPayload _: Data) async throws -> MatchEventSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented") }
    func saveSnapshot(matchId _: UUID, snapshotVersion _: Int, snapshotPayload _: Data) async throws -> MatchSnapshotSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented") }
    func fetchLatestSnapshot(matchId _: UUID) async throws -> MatchSnapshotSummary? { nil }
    func fetchMatch(matchId _: UUID) async throws -> MatchSummary? { nil }
    func fetchParticipants(matchId _: UUID) async throws -> [MatchParticipantSummary] { [] }
    func deleteMatch(matchId _: UUID) async throws {}
}

private actor FakeHistoryPlayerRepository: PlayerRepository {
    let players: [PlayerSummary]

    init(players: [PlayerSummary]) {
        self.players = players
    }

    func fetchPlayers(includeArchived _: Bool) async throws -> [PlayerSummary] { players }
    func createPlayer(name _: String) async throws -> PlayerSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented") }
    func createBot(difficulty _: BotDifficulty) async throws -> PlayerSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented") }
    func updatePlayerName(playerId _: UUID, name _: String) async throws -> PlayerSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented") }
    func updatePlayerProfile(playerId _: UUID, name _: String, avatarStyle _: PlayerAvatarStyle, colorToken _: PlayerColorToken, notes _: String) async throws -> PlayerSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented") }
    func archivePlayer(playerId _: UUID) async throws {}
    func unarchivePlayer(playerId _: UUID) async throws {}
    func deletePlayer(playerId _: UUID) async throws {}
}
