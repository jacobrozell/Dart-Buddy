import Foundation
import Testing
@testable import DartBuddy

@Test(.tags(.unit, .stats, .regression))
func matchStatsLoaderPaginatesHistoryAndBatchFetchesEvents() async throws {
    let matchRepo = PaginatingMatchRepository(pageSize: 2, totalPages: 2)
    let statsRepo = BatchTrackingStatsRepository()

    let result = try await MatchStatsLoader.load(
        matchRepository: matchRepo,
        statsRepository: statsRepo,
        request: MatchStatsLoadRequest(matchType: .x01),
        pageSize: 2
    )

    #expect(await matchRepo.fetchCallCount == 3)
    #expect(await statsRepo.batchFetchCallCount == 2)
    #expect(result.inputs.count == 4)
    #expect(result.namesById.count == 8)
}

@Test(.tags(.unit, .stats, .cricket, .regression))
func matchStatsLoaderFiltersCricketHistoryByParticipant() async throws {
    let carol = UUID()
    let bob = UUID()
    let dave = UUID()
    let matchRepo = SinglePageMatchRepository(records: [
        makeHistoryRecord(participantIds: [carol, bob], type: .cricket),
        makeHistoryRecord(participantIds: [bob, dave], type: .cricket),
        makeHistoryRecord(participantIds: [dave], type: .cricket)
    ])

    let result = try await MatchStatsLoader.load(
        matchRepository: matchRepo,
        statsRepository: BatchTrackingStatsRepository(),
        request: MatchStatsLoadRequest(matchType: .cricket, participantPlayerId: carol)
    )

    #expect(result.inputs.count == 1)
    #expect(result.inputs[0].type == .cricket)
    #expect(result.inputs[0].participantKeys.contains(carol))
}

@Test(.tags(.unit, .stats, .regression))
func matchStatsLoaderRecentMatchesSkipsRecordsWithoutPlayer() async throws {
    let carol = UUID()
    let bob = UUID()
    let dave = UUID()
    let carolMatch = makeHistoryRecord(participantIds: [carol, bob], type: .cricket)
    let otherMatch = makeHistoryRecord(participantIds: [bob, dave], type: .x01)
    let matchRepo = CatalogStyleMatchRepository(records: [otherMatch, carolMatch])

    let recent = try await MatchStatsLoader.recentMatches(
        for: carol,
        matchRepository: matchRepo,
        limit: 5
    )

    #expect(recent.count == 1)
    #expect(recent[0].type == .cricket)
    #expect(recent[0].opponentLabel == "B")
}

@Test(.tags(.unit, .stats, .regression))
func matchStatsLoaderBuildPlayerSummariesCountsWinsPerMode() async throws {
    let carol = UUID()
    let bob = UUID()
    let x01Winner = makeHistoryRecord(participantIds: [carol, bob], type: .x01, playedAt: Date(), winner: carol)
    let cricketWinner = makeHistoryRecord(participantIds: [carol, bob], type: .cricket, playedAt: Date().addingTimeInterval(-3600), winner: bob)
    let matchRepo = CatalogStyleMatchRepository(records: [x01Winner, cricketWinner])

    let summaries = try await MatchStatsLoader.buildPlayerSummaries(matchRepository: matchRepo)

    #expect(summaries[carol]?.games == 2)
    #expect(summaries[carol]?.wins == 1)
    #expect(summaries[bob]?.games == 2)
    #expect(summaries[bob]?.wins == 1)
}

@Test(.tags(.unit, .stats, .regression))
func matchStatsLoaderFiltersByParticipant() async throws {
    let target = UUID()
    let other = UUID()
    let matchRepo = SinglePageMatchRepository(records: [
        makeHistoryRecord(participantIds: [target, other], type: .x01),
        makeHistoryRecord(participantIds: [other], type: .x01),
    ])
    let statsRepo = BatchTrackingStatsRepository()

    let result = try await MatchStatsLoader.load(
        matchRepository: matchRepo,
        statsRepository: statsRepo,
        request: MatchStatsLoadRequest(matchType: .x01, participantPlayerId: target)
    )

    #expect(result.inputs.count == 1)
    #expect(result.inputs[0].participantKeys.contains(target))
}

@Test(.tags(.unit, .stats, .match, .regression))
func matchStatsLoaderRehydrateSessionRebuildsFromSnapshotAndEvents() async throws {
    var session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
        participants: [
            MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "A", turnOrder: 0),
            MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "B", turnOrder: 1)
        ]
    )
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 60, darts: nil)
    let matchId = session.runtime.matchId
    let snapshotSummary = MatchSnapshotSummary(
        id: UUID(),
        matchId: matchId,
        snapshotVersion: session.latestSnapshot.payloadVersion,
        snapshotPayload: session.latestSnapshot.payload,
        updatedAt: Date()
    )
    let eventSummaries = try session.events.map { envelope in
        MatchEventSummary(
            id: UUID(),
            matchId: matchId,
            eventIndex: envelope.eventIndex,
            eventTypeRaw: "x01Turn",
            eventPayload: try CodablePayloadCoder.encode(envelope),
            createdAt: envelope.timestamp
        )
    }
    let matchRepo = RehydrateMatchRepository(snapshot: snapshotSummary)
    let statsRepo = RehydrateStatsRepository(events: eventSummaries)

    let rehydrated = try await MatchStatsLoader.rehydrateSession(
        matchId: matchId,
        matchRepository: matchRepo,
        statsRepository: statsRepo
    )

    #expect(rehydrated?.events.count == 1)
    #expect(rehydrated?.runtime.x01State?.players[0].remainingScore == 241)
}

@Test(.tags(.unit, .stats, .match, .regression))
func matchStatsLoaderLoadPartialActiveMatchInputMarksInProgressStats() async throws {
    var session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
        participants: [
            MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "A", turnOrder: 0),
            MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "B", turnOrder: 1)
        ]
    )
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 60, darts: nil)
    let matchId = session.runtime.matchId
    let activeMatch = MatchSummary(
        id: matchId,
        type: .x01,
        status: .inProgress,
        startedAt: session.runtime.startedAt,
        endedAt: nil,
        winnerPlayerId: nil,
        currentTurnPlayerId: nil,
        currentLegIndex: 0,
        currentSetIndex: 0,
        eventCount: session.runtime.eventCount,
        createdAt: session.runtime.startedAt,
        updatedAt: Date()
    )
    let snapshotSummary = MatchSnapshotSummary(
        id: UUID(),
        matchId: matchId,
        snapshotVersion: session.latestSnapshot.payloadVersion,
        snapshotPayload: session.latestSnapshot.payload,
        updatedAt: Date()
    )
    let eventSummaries = try session.events.map { envelope in
        MatchEventSummary(
            id: UUID(),
            matchId: matchId,
            eventIndex: envelope.eventIndex,
            eventTypeRaw: "x01Turn",
            eventPayload: try CodablePayloadCoder.encode(envelope),
            createdAt: envelope.timestamp
        )
    }
    let matchRepo = RehydrateMatchRepository(snapshot: snapshotSummary)
    let statsRepo = RehydrateStatsRepository(events: eventSummaries)

    let result = try await MatchStatsLoader.loadPartialActiveMatchInput(
        matchRepository: matchRepo,
        statsRepository: statsRepo,
        activeMatch: activeMatch
    )

    #expect(result?.inputs.count == 1)
    #expect(result?.inputs[0].isPartial == true)
    #expect(result?.inputs[0].events.count == 1)
    #expect(result?.namesById.values.contains("A") == true)
}

@Test(.tags(.unit, .stats, .regression))
func matchStatsLoaderLoadPartialActiveMatchInputReturnsNilForCompletedMatch() async throws {
    let completed = MatchSummary(
        id: UUID(),
        type: .x01,
        status: .completed,
        startedAt: Date(),
        endedAt: Date(),
        winnerPlayerId: UUID(),
        currentTurnPlayerId: nil,
        currentLegIndex: 0,
        currentSetIndex: 0,
        eventCount: 1,
        createdAt: Date(),
        updatedAt: Date()
    )

    let result = try await MatchStatsLoader.loadPartialActiveMatchInput(
        matchRepository: RehydrateMatchRepository(snapshot: nil),
        statsRepository: RehydrateStatsRepository(events: []),
        activeMatch: completed
    )

    #expect(result == nil)
}

@Test(.tags(.unit, .stats, .regression))
func matchStatsLoaderDecodeEventsSortsByEventIndex() throws {
    let matchId = UUID()
    var session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(MatchConfigX01(startScore: 301, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
        participants: [
            MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "A", turnOrder: 0),
            MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "B", turnOrder: 1)
        ]
    )
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 60, darts: nil)
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 0, darts: nil)
    let summaries = try session.events.map { envelope in
        MatchEventSummary(
            id: UUID(),
            matchId: matchId,
            eventIndex: envelope.eventIndex,
            eventTypeRaw: "x01Turn",
            eventPayload: try CodablePayloadCoder.encode(envelope),
            createdAt: envelope.timestamp
        )
    }.reversed()

    let decoded = MatchStatsLoader.decodeEvents(Array(summaries))
    #expect(decoded.count == 2)
    #expect(decoded[0].eventIndex < decoded[1].eventIndex)
}

@Test(.tags(.unit, .stats, .regression))
func matchStatsLoaderFiltersHistoryByStartedAfter() async throws {
    let recent = Date()
    let older = Date().addingTimeInterval(-86_400)
    let matchRepo = DateFilteredMatchRepository(records: [
        makeHistoryRecord(participantIds: [UUID(), UUID()], type: .x01, playedAt: recent),
        makeHistoryRecord(participantIds: [UUID(), UUID()], type: .x01, playedAt: older)
    ])

    let result = try await MatchStatsLoader.load(
        matchRepository: matchRepo,
        statsRepository: RehydrateStatsRepository(events: []),
        request: MatchStatsLoadRequest(matchType: .x01, startedAfter: recent.addingTimeInterval(-3600))
    )

    #expect(result.inputs.count == 1)
}

@Test(.tags(.unit, .stats, .match, .regression))
func matchStatsLoaderRehydrateSessionReturnsNilWithoutSnapshot() async throws {
    let rehydrated = try await MatchStatsLoader.rehydrateSession(
        matchId: UUID(),
        matchRepository: RehydrateMatchRepository(snapshot: nil),
        statsRepository: RehydrateStatsRepository(events: [])
    )
    #expect(rehydrated == nil)
}

@Test(.tags(.unit, .stats, .regression))
func matchStatsLoaderRecentMatchesReturnsEmptyWhenLimitIsZero() async throws {
    let recent = try await MatchStatsLoader.recentMatches(
        for: UUID(),
        matchRepository: PaginatingMatchRepository(pageSize: 2, totalPages: 1),
        limit: 0
    )
    #expect(recent.isEmpty)
}

private actor RehydrateMatchRepository: MatchRepository {
    let snapshot: MatchSnapshotSummary?

    init(snapshot: MatchSnapshotSummary?) { self.snapshot = snapshot }

    func fetchLatestSnapshot(matchId: UUID) async throws -> MatchSnapshotSummary? {
        snapshot?.matchId == matchId ? snapshot : nil
    }

    func createMatch(type _: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary { fatalError() }
    func fetchActiveMatch() async throws -> MatchSummary? { nil }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { [] }
    func fetchHistoryWithParticipants(page _: Int, pageSize _: Int, filter _: MatchHistoryFilter) async throws -> [MatchHistoryRecord] { [] }
    func updateMatch(_: MatchSummary) async throws {}
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary { fatalError() }
    func appendEvent(matchId _: UUID, eventTypeRaw _: String, eventPayload _: Data) async throws -> MatchEventSummary { fatalError() }
    func saveSnapshot(matchId _: UUID, snapshotVersion _: Int, snapshotPayload _: Data) async throws -> MatchSnapshotSummary { fatalError() }
    func fetchMatch(matchId _: UUID) async throws -> MatchSummary? { nil }
    func fetchParticipants(matchId _: UUID) async throws -> [MatchParticipantSummary] { [] }
    func deleteMatch(matchId _: UUID) async throws {}
}

private actor RehydrateStatsRepository: StatsRepository {
    let events: [MatchEventSummary]

    init(events: [MatchEventSummary]) { self.events = events }

    func fetchEvents(matchId: UUID) async throws -> [MatchEventSummary] {
        events.filter { $0.matchId == matchId }
    }

    func fetchEvents(matchIds _: [UUID]) async throws -> [MatchEventSummary] { [] }
}

private actor CatalogStyleMatchRepository: MatchRepository {
    let records: [MatchHistoryRecord]

    init(records: [MatchHistoryRecord]) { self.records = records }

    func fetchHistoryWithParticipants(page: Int, pageSize: Int, filter: MatchHistoryFilter) async throws -> [MatchHistoryRecord] {
        guard page == 0 else { return [] }
        return records.filter { record in
            if let type = filter.matchType, record.summary.type != type { return false }
            if let startedAfter = filter.startedAfter, record.summary.startedAt < startedAfter { return false }
            return true
        }.prefix(pageSize).map { $0 }
    }

    func createMatch(type _: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary { fatalError() }
    func fetchActiveMatch() async throws -> MatchSummary? { nil }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { [] }
    func updateMatch(_: MatchSummary) async throws {}
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary { fatalError() }
    func appendEvent(matchId _: UUID, eventTypeRaw _: String, eventPayload _: Data) async throws -> MatchEventSummary { fatalError() }
    func saveSnapshot(matchId _: UUID, snapshotVersion _: Int, snapshotPayload _: Data) async throws -> MatchSnapshotSummary { fatalError() }
    func fetchLatestSnapshot(matchId _: UUID) async throws -> MatchSnapshotSummary? { nil }
    func fetchMatch(matchId _: UUID) async throws -> MatchSummary? { nil }
    func fetchParticipants(matchId _: UUID) async throws -> [MatchParticipantSummary] { [] }
    func deleteMatch(matchId _: UUID) async throws {}
}

private actor DateFilteredMatchRepository: MatchRepository {
    let records: [MatchHistoryRecord]

    init(records: [MatchHistoryRecord]) { self.records = records }

    func fetchHistoryWithParticipants(page: Int, pageSize: Int, filter: MatchHistoryFilter) async throws -> [MatchHistoryRecord] {
        guard page == 0 else { return [] }
        return records.filter { record in
            if let type = filter.matchType, record.summary.type != type { return false }
            if let startedAfter = filter.startedAfter, record.summary.startedAt < startedAfter { return false }
            return true
        }.prefix(pageSize).map { $0 }
    }

    func createMatch(type _: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary { fatalError() }
    func fetchActiveMatch() async throws -> MatchSummary? { nil }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { [] }
    func updateMatch(_: MatchSummary) async throws {}
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary { fatalError() }
    func appendEvent(matchId _: UUID, eventTypeRaw _: String, eventPayload _: Data) async throws -> MatchEventSummary { fatalError() }
    func saveSnapshot(matchId _: UUID, snapshotVersion _: Int, snapshotPayload _: Data) async throws -> MatchSnapshotSummary { fatalError() }
    func fetchLatestSnapshot(matchId _: UUID) async throws -> MatchSnapshotSummary? { nil }
    func fetchMatch(matchId _: UUID) async throws -> MatchSummary? { nil }
    func fetchParticipants(matchId _: UUID) async throws -> [MatchParticipantSummary] { [] }
    func deleteMatch(matchId _: UUID) async throws {}
}

private func makeHistoryRecord(
    participantIds: [UUID],
    type: MatchType,
    playedAt: Date = Date(),
    winner: UUID? = nil
) -> MatchHistoryRecord {
    let matchId = UUID()
    return MatchHistoryRecord(
        summary: MatchSummary(
            id: matchId,
            type: type,
            status: .completed,
            startedAt: playedAt,
            endedAt: playedAt,
            winnerPlayerId: winner ?? participantIds.first,
            currentTurnPlayerId: nil,
            currentLegIndex: 0,
            currentSetIndex: 0,
            eventCount: 0,
            createdAt: playedAt,
            updatedAt: playedAt
        ),
        participants: participantIds.enumerated().map { index, id in
            MatchParticipantSummary(
                id: UUID(),
                matchId: matchId,
                playerId: id,
                turnOrder: index,
                displayNameAtMatchStart: index == 0 ? "A" : "B"
            )
        }
    )
}

private actor PaginatingMatchRepository: MatchRepository {
    let pageSize: Int
    let totalPages: Int
    private(set) var fetchCallCount = 0

    init(pageSize: Int, totalPages: Int) {
        self.pageSize = pageSize
        self.totalPages = totalPages
    }

    func fetchHistoryWithParticipants(page: Int, pageSize: Int, filter _: MatchHistoryFilter) async throws -> [MatchHistoryRecord] {
        fetchCallCount += 1
        guard page < totalPages else { return [] }
        return (0..<pageSize).map { _ in
            makeHistoryRecord(participantIds: [UUID(), UUID()], type: .x01)
        }
    }

    func createMatch(type _: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary { fatalError() }
    func fetchActiveMatch() async throws -> MatchSummary? { nil }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { [] }
    func updateMatch(_: MatchSummary) async throws {}
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary { fatalError() }
    func appendEvent(matchId _: UUID, eventTypeRaw _: String, eventPayload _: Data) async throws -> MatchEventSummary { fatalError() }
    func saveSnapshot(matchId _: UUID, snapshotVersion _: Int, snapshotPayload _: Data) async throws -> MatchSnapshotSummary { fatalError() }
    func fetchLatestSnapshot(matchId _: UUID) async throws -> MatchSnapshotSummary? { nil }
    func fetchMatch(matchId _: UUID) async throws -> MatchSummary? { nil }
    func fetchParticipants(matchId _: UUID) async throws -> [MatchParticipantSummary] { [] }
    func deleteMatch(matchId _: UUID) async throws {}
}

private actor SinglePageMatchRepository: MatchRepository {
    let records: [MatchHistoryRecord]

    init(records: [MatchHistoryRecord]) {
        self.records = records
    }

    func fetchHistoryWithParticipants(page: Int, pageSize: Int, filter: MatchHistoryFilter) async throws -> [MatchHistoryRecord] {
        guard page == 0 else { return [] }
        return records.filter { record in
            if let type = filter.matchType, record.summary.type != type { return false }
            if let startedAfter = filter.startedAfter, record.summary.startedAt < startedAfter { return false }
            return true
        }.prefix(pageSize).map { $0 }
    }

    func createMatch(type _: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary { fatalError() }
    func fetchActiveMatch() async throws -> MatchSummary? { nil }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { [] }
    func updateMatch(_: MatchSummary) async throws {}
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary { fatalError() }
    func appendEvent(matchId _: UUID, eventTypeRaw _: String, eventPayload _: Data) async throws -> MatchEventSummary { fatalError() }
    func saveSnapshot(matchId _: UUID, snapshotVersion _: Int, snapshotPayload _: Data) async throws -> MatchSnapshotSummary { fatalError() }
    func fetchLatestSnapshot(matchId _: UUID) async throws -> MatchSnapshotSummary? { nil }
    func fetchMatch(matchId _: UUID) async throws -> MatchSummary? { nil }
    func fetchParticipants(matchId _: UUID) async throws -> [MatchParticipantSummary] { [] }
    func deleteMatch(matchId _: UUID) async throws {}
}

private actor BatchTrackingStatsRepository: StatsRepository {
    private(set) var batchFetchCallCount = 0

    func fetchEvents(matchId _: UUID) async throws -> [MatchEventSummary] { [] }
    func fetchEvents(matchIds: [UUID]) async throws -> [MatchEventSummary] {
        batchFetchCallCount += 1
        return matchIds.map {
            MatchEventSummary(
                id: UUID(),
                matchId: $0,
                eventIndex: 0,
                eventTypeRaw: "turn",
                eventPayload: Data(),
                createdAt: Date()
            )
        }
    }
}
