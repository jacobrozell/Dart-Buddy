import Foundation
import Testing
@testable import DartBuddy

private func baseballDart(_ multiplier: DartMultiplier, _ segment: Int) -> DartInput {
    DartInput(multiplier: multiplier, segment: .oneToTwenty(segment))
}

@MainActor
private func makeBaseballViewModel(
    participantCount: Int = 2,
    inningCount: Int = 1,
    tieBreaker: BaseballTieBreaker = .extraInnings,
    preTurns: [[DartInput]] = []
) throws -> (vm: BaseballMatchViewModel, store: ActiveMatchStore) {
    let ids = (0 ..< participantCount).map { _ in UUID() }
    let participants = ids.enumerated().map { index, id in
        MatchParticipant(playerId: id, displayNameAtMatchStart: "P\(index + 1)", turnOrder: index)
    }
    var session = try MatchLifecycleService.createMatch(
        type: .baseball,
        config: .baseball(MatchConfigBaseball(inningCount: inningCount, tieBreaker: tieBreaker)),
        participants: participants
    )
    for darts in preTurns {
        session = try MatchLifecycleService.submitBaseballTurn(session: session, darts: darts)
    }
    let store = ActiveMatchStore()
    store.save(session)
    let vm = BaseballMatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: BaseballSilentLogSink()),
        matchRepository: BaseballFakeMatchRepository(),
        statsRepository: BaseballFakeStatsRepository()
    )
    return (vm, store)
}

@MainActor
@Test(.tags(.integration, .baseball, .match, .critical, .regression))
func baseballViewModelRehydratesSessionFromSnapshotWhenStoreEmpty() async throws {
    let p0 = UUID()
    let p1 = UUID()
    var session = try MatchLifecycleService.createMatch(
        type: .baseball,
        config: .baseball(MatchConfigBaseball()),
        participants: [
            MatchParticipant(playerId: p0, displayNameAtMatchStart: "A", turnOrder: 0),
            MatchParticipant(playerId: p1, displayNameAtMatchStart: "B", turnOrder: 1)
        ]
    )
    session = try MatchLifecycleService.submitBaseballTurn(session: session, darts: [baseballDart(.single, 1)])
    let matchId = session.runtime.matchId
    let snapshot = session.latestSnapshot
    let snapshotSummary = MatchSnapshotSummary(
        id: UUID(),
        matchId: matchId,
        snapshotVersion: snapshot.payloadVersion,
        snapshotPayload: snapshot.payload,
        updatedAt: Date()
    )
    let eventSummaries = try session.events.map { envelope in
        MatchEventSummary(
            id: UUID(),
            matchId: matchId,
            eventIndex: envelope.eventIndex,
            eventTypeRaw: "baseballTurn",
            eventPayload: try CodablePayloadCoder.encode(envelope),
            createdAt: envelope.timestamp
        )
    }
    let store = ActiveMatchStore()
    let vm = BaseballMatchViewModel(
        matchId: matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: BaseballSilentLogSink()),
        matchRepository: BaseballRehydratingFakeMatchRepository(snapshot: snapshotSummary),
        statsRepository: BaseballRehydratingFakeStatsRepository(events: eventSummaries)
    )

    #expect(vm.session == nil)
    await vm.onAppear()

    #expect(vm.session?.events.count == 1)
    #expect(vm.baseballState?.players[0].cumulativeRuns == 1)
    #expect(store.session(for: matchId) != nil)
}

@MainActor
@Test(.tags(.integration, .baseball, .match, .critical, .regression))
func baseballViewModelHumanSubmitUpdatesRuns() async throws {
    let (vm, _) = try makeBaseballViewModel()
    vm.enteredDarts = [baseballDart(.single, 1), baseballDart(.double, 1)]

    await vm.submitTurn()

    #expect(vm.state == .readyTurn)
    #expect(vm.baseballState?.players[0].cumulativeRuns == 3)
    #expect(vm.enteredDarts.isEmpty)
}

@MainActor
@Test(.tags(.integration, .baseball, .match, .critical, .regression))
func baseballViewModelCompletesSingleInningMatch() async throws {
    let (vm, store) = try makeBaseballViewModel(
        inningCount: 1,
        preTurns: [[baseballDart(.single, 1)]]
    )
    vm.enteredDarts = [baseballDart(.triple, 1)]

    await vm.submitTurn()

    #expect(vm.state == .matchCompleted)
    #expect(store.completedSessions().count == 1)
    #expect(vm.baseballState?.winnerPlayerId != nil)
}

@MainActor
@Test(.tags(.integration, .baseball, .match, .regression))
func baseballViewModelScoreboardShowsPlayoffRoundRuns() async throws {
    let (vm, _) = try makeBaseballViewModel(
        inningCount: 1,
        tieBreaker: .bullPlayoff,
        preTurns: [
            [baseballDart(.single, 1)],
            [baseballDart(.single, 1)]
        ]
    )

    #expect(vm.baseballState?.phase == .bullPlayoff)
    vm.enteredDarts = [DartInput(multiplier: .single, segment: .outerBull)]

    let row = vm.scoreboardRows.first
    #expect(row?.visitRunsKind == .playoffRound)
    #expect(row?.visitRuns == 1)
    #expect(row?.isLeading == true)
}

@MainActor
@Test(.tags(.integration, .baseball, .match, .regression))
func baseballViewModelHidesInningStripDuringPlayoff() async throws {
    let (vm, _) = try makeBaseballViewModel(
        inningCount: 1,
        tieBreaker: .bullPlayoff,
        preTurns: [
            [baseballDart(.single, 1)],
            [baseballDart(.single, 1)]
        ]
    )

    #expect(vm.showsInningProgressStrip == false)
}

@MainActor
@Test(.tags(.integration, .baseball, .match, .regression))
func baseballViewModelHeaderAccessibilityIncludesTitleAndPhase() async throws {
    let (vm, _) = try makeBaseballViewModel(
        inningCount: 1,
        tieBreaker: .bullPlayoff,
        preTurns: [
            [baseballDart(.single, 1)],
            [baseballDart(.single, 1)]
        ]
    )

    #expect(vm.headerAccessibilityLabel.contains(L10n.string("play.baseball.title")))
    #expect(vm.headerAccessibilityLabel.contains(L10n.string("play.baseball.header.bullPlayoff")))
}

private struct BaseballSilentLogSink: LogSink {
    func write(_: LogEntry) {}
}

private actor BaseballFakeMatchRepository: MatchRepository {
    func createMatch(type: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary {
        makeSummary(type: type, status: .inProgress)
    }
    func fetchActiveMatch() async throws -> MatchSummary? { nil }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { [] }
    func fetchHistoryWithParticipants(page _: Int, pageSize _: Int, filter _: MatchHistoryFilter) async throws -> [MatchHistoryRecord] { [] }
    func updateMatch(_: MatchSummary) async throws {}
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary {
        makeSummary(type: .baseball, status: .completed)
    }
    func appendEvent(matchId: UUID, eventTypeRaw: String, eventPayload: Data) async throws -> MatchEventSummary {
        MatchEventSummary(id: UUID(), matchId: matchId, eventIndex: 0, eventTypeRaw: eventTypeRaw, eventPayload: eventPayload, createdAt: Date())
    }
    func saveSnapshot(matchId: UUID, snapshotVersion: Int, snapshotPayload: Data) async throws -> MatchSnapshotSummary {
        MatchSnapshotSummary(id: UUID(), matchId: matchId, snapshotVersion: snapshotVersion, snapshotPayload: snapshotPayload, updatedAt: Date())
    }
    func fetchLatestSnapshot(matchId _: UUID) async throws -> MatchSnapshotSummary? { nil }
    func fetchMatch(matchId _: UUID) async throws -> MatchSummary? { nil }
    func fetchParticipants(matchId _: UUID) async throws -> [MatchParticipantSummary] { [] }
    func deleteMatch(matchId _: UUID) async throws {}

    private func makeSummary(type: MatchType, status: MatchStatus) -> MatchSummary {
        MatchSummary(
            id: UUID(), type: type, status: status, startedAt: Date(), endedAt: nil,
            winnerPlayerId: nil, currentTurnPlayerId: nil, currentLegIndex: 0, currentSetIndex: 0,
            eventCount: 0, createdAt: Date(), updatedAt: Date()
        )
    }
}

private actor BaseballFakeStatsRepository: StatsRepository {
    func fetchEvents(matchId _: UUID) async throws -> [MatchEventSummary] { [] }
    func fetchEvents(matchIds _: [UUID]) async throws -> [MatchEventSummary] { [] }
}

private actor BaseballRehydratingFakeMatchRepository: MatchRepository {
    let snapshot: MatchSnapshotSummary
    init(snapshot: MatchSnapshotSummary) { self.snapshot = snapshot }

    func createMatch(type: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary {
        makeSummary(type: type, status: .inProgress)
    }
    func fetchActiveMatch() async throws -> MatchSummary? { nil }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { [] }
    func fetchHistoryWithParticipants(page _: Int, pageSize _: Int, filter _: MatchHistoryFilter) async throws -> [MatchHistoryRecord] { [] }
    func updateMatch(_: MatchSummary) async throws {}
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary {
        makeSummary(type: .baseball, status: .completed)
    }
    func appendEvent(matchId: UUID, eventTypeRaw: String, eventPayload: Data) async throws -> MatchEventSummary {
        MatchEventSummary(id: UUID(), matchId: matchId, eventIndex: 0, eventTypeRaw: eventTypeRaw, eventPayload: eventPayload, createdAt: Date())
    }
    func saveSnapshot(matchId: UUID, snapshotVersion: Int, snapshotPayload: Data) async throws -> MatchSnapshotSummary {
        MatchSnapshotSummary(id: UUID(), matchId: matchId, snapshotVersion: snapshotVersion, snapshotPayload: snapshotPayload, updatedAt: Date())
    }
    func fetchLatestSnapshot(matchId: UUID) async throws -> MatchSnapshotSummary? {
        snapshot.matchId == matchId ? snapshot : nil
    }
    func fetchMatch(matchId _: UUID) async throws -> MatchSummary? { nil }
    func fetchParticipants(matchId _: UUID) async throws -> [MatchParticipantSummary] { [] }
    func deleteMatch(matchId _: UUID) async throws {}

    private func makeSummary(type: MatchType, status: MatchStatus) -> MatchSummary {
        MatchSummary(
            id: UUID(), type: type, status: status, startedAt: Date(), endedAt: nil,
            winnerPlayerId: nil, currentTurnPlayerId: nil, currentLegIndex: 0, currentSetIndex: 0,
            eventCount: 0, createdAt: Date(), updatedAt: Date()
        )
    }
}

private actor BaseballRehydratingFakeStatsRepository: StatsRepository {
    let events: [MatchEventSummary]
    init(events: [MatchEventSummary]) { self.events = events }
    func fetchEvents(matchId _: UUID) async throws -> [MatchEventSummary] { events }
    func fetchEvents(matchIds _: [UUID]) async throws -> [MatchEventSummary] { events }
}
