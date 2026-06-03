import Foundation
import Testing
@testable import DartsScoreboard

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

    vm.mode = .cricket
    await vm.load()
    #expect(vm.rows.isEmpty)

    vm.mode = .x01
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
    vm.mode = .x01
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
@Test(.tags(.integration, .stats, .x01, .regression))
func statisticsViewModelOmitsPartialWhenModeDiffers() async throws {
    let partial = try makeStatsVMPartialFixture()
    let vm = StatisticsViewModel(
        matchRepository: StatsVMFakeMatchRepository(active: partial),
        statsRepository: StatsVMFakeStatsRepository(events: partial.events),
        playerRepository: StatsVMFakePlayerRepository()
    )
    vm.mode = .cricket
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
    let summary: MatchSummary
    let participants: [MatchParticipantSummary]
    let events: [MatchEventSummary]
    let snapshot: MatchSnapshotSummary
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

private func makeStatsVMCompletedFixture(playedAt: Date = Date()) throws -> StatsVMCompletedFixture {
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

private actor StatsVMFakeMatchRepository: MatchRepository {
    private let completed: StatsVMCompletedFixture?
    private let active: StatsVMPartialFixture?

    init(completed: StatsVMCompletedFixture? = nil, active: StatsVMPartialFixture? = nil) {
        self.completed = completed
        self.active = active
    }

    func createMatch(type _: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary {
        throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error")
    }

    func fetchActiveMatch() async throws -> MatchSummary? { active?.summary }

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
        if active?.matchId == matchId { return active?.snapshot }
        if completed?.matchId == matchId { return completed?.snapshot }
        return nil
    }

    func fetchMatch(matchId: UUID) async throws -> MatchSummary? {
        if active?.matchId == matchId { return active?.summary }
        if completed?.matchId == matchId { return completed?.summary }
        return nil
    }

    func fetchParticipants(matchId: UUID) async throws -> [MatchParticipantSummary] {
        if active?.matchId == matchId { return active?.participants ?? [] }
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

private actor StatsVMFakePlayerRepository: PlayerRepository {
    func fetchPlayers(includeArchived _: Bool) async throws -> [PlayerSummary] { [] }
    func createPlayer(name _: String) async throws -> PlayerSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error") }
    func createBot(difficulty _: BotDifficulty) async throws -> PlayerSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error") }
    func updatePlayerName(playerId _: UUID, name _: String) async throws -> PlayerSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error") }
    func updatePlayerProfile(playerId _: UUID, name _: String, avatarStyle _: PlayerAvatarStyle, colorToken _: PlayerColorToken, notes _: String) async throws -> PlayerSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error") }
    func archivePlayer(playerId _: UUID) async throws {}
    func unarchivePlayer(playerId _: UUID) async throws {}
    func deletePlayer(playerId _: UUID) async throws {}
}
