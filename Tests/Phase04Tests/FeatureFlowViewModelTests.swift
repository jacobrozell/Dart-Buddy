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
        )
    )
    vm.modeFilter = .x01
    await vm.applyFilters()

    #expect(vm.rows.count == 1)
    #expect(vm.rows.first?.summary.type == .x01)
}

// MARK: - Stats / detail fixtures

private struct StatsFixture {
    let matchId: UUID
    let jacob: UUID
    let sam: UUID
    let summary: MatchSummary
    let participants: [MatchParticipantSummary]
    let events: [MatchEventSummary]
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
    return StatsFixture(matchId: matchId, jacob: jacob, sam: sam, summary: summary, participants: participants, events: events)
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
    func fetchLatestSnapshot(matchId _: UUID) async throws -> MatchSnapshotSummary? { nil }
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

@MainActor
@Test(.tags(.integration, .stats, .x01, .regression))
func statisticsViewModelComputesBreakdownRows() async throws {
    let fixture = try makeCompletedX01Fixture()
    let vm = StatisticsViewModel(
        matchRepository: StatsFakeMatchRepository(fixture: fixture),
        statsRepository: StatsFakeStatsRepository(events: fixture.events)
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

private actor FakeHistoryMatchRepository: MatchRepository {
    let rows: [MatchSummary]
    init(rows: [MatchSummary]) {
        self.rows = rows
    }

    func createMatch(type _: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary { rows.first! }
    func fetchActiveMatch() async throws -> MatchSummary? { nil }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { rows }
    func fetchHistoryWithParticipants(page _: Int, pageSize _: Int, filter _: MatchHistoryFilter) async throws -> [MatchHistoryRecord] {
        rows.map { MatchHistoryRecord(summary: $0, participants: []) }
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
