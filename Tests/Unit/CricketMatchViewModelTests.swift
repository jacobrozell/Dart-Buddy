import Foundation
import Testing
@testable import DartBuddy

// State-machine coverage for the live Cricket match view model using in-memory fakes.

@MainActor
private func makeCricketViewModel(
    participantCount: Int = 2,
    preTurns: [[DartInput]] = [],
    failAppend: Bool = false
) throws -> (vm: CricketMatchViewModel, store: ActiveMatchStore) {
    let participants = cricketParticipants(count: participantCount)
    var session = try MatchLifecycleService.createMatch(
        type: .cricket,
        config: .cricket(MatchConfigCricket()),
        participants: participants
    )
    for darts in preTurns {
        session = try MatchLifecycleService.submitCricketTurn(session: session, darts: darts)
    }
    let store = ActiveMatchStore()
    store.save(session)
    let vm = CricketMatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: CricketSilentLogSink()),
        matchRepository: CricketFakeMatchRepository(failAppend: failAppend),
        statsRepository: CricketFakeStatsRepository()
    )
    return (vm, store)
}

@MainActor
@Test(.tags(.integration, .cricket, .match, .critical, .regression))
func cricketViewModelRehydratesSessionFromSnapshotWhenStoreEmpty() async throws {
    let p0 = UUID()
    let p1 = UUID()
    var session = try MatchLifecycleService.createMatch(
        type: .cricket,
        config: .cricket(MatchConfigCricket()),
        participants: [
            MatchParticipant(playerId: p0, displayNameAtMatchStart: "A", turnOrder: 0),
            MatchParticipant(playerId: p1, displayNameAtMatchStart: "B", turnOrder: 1)
        ]
    )
    session = try MatchLifecycleService.submitCricketTurn(session: session, darts: [CricketTestDarts.triple(20)])
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
            eventTypeRaw: "cricketTurn",
            eventPayload: try CodablePayloadCoder.encode(envelope),
            createdAt: envelope.timestamp
        )
    }
    let store = ActiveMatchStore()
    let vm = CricketMatchViewModel(
        matchId: matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: CricketSilentLogSink()),
        matchRepository: CricketRehydratingFakeMatchRepository(snapshot: snapshotSummary),
        statsRepository: CricketRehydratingFakeStatsRepository(events: eventSummaries)
    )

    #expect(vm.session == nil)
    await vm.onAppear()

    #expect(vm.session?.events.count == 1)
    let firstColumn = try #require(vm.boardColumns.first)
    #expect(firstColumn.marks["20"] == 3)
    #expect(store.session(for: matchId) != nil)
}

@MainActor
@Test(.tags(.integration, .cricket, .match, .regression))
func cricketViewModelSkipsClosureTransitionWhenTargetNotClosed() async throws {
    let (vm, _) = try makeCricketViewModel()
    vm.enteredDarts = [CricketTestDarts.single(20)]

    let submitTask = Task { await vm.submitTurn() }

    var sawClosure = false
    for _ in 0 ..< 60 {
        if vm.state == .closureTransition {
            sawClosure = true
            break
        }
        try await Task.sleep(nanoseconds: 20_000_000)
    }

    await submitTask.value

    #expect(sawClosure == false)
    #expect(vm.state == .readyTurn)
    #expect(vm.enteredDarts.isEmpty)
}

@MainActor
@Test(.tags(.integration, .cricket, .match, .critical, .regression))
func cricketViewModelDoesNotCompleteWhenOnlyFirstPlayerClosesAllTargets() async throws {
    let (vm, store) = try makeCricketViewModel(preTurns: [
        [CricketTestDarts.triple(20), CricketTestDarts.triple(19), CricketTestDarts.triple(18)],
        [CricketTestDarts.miss(), CricketTestDarts.miss(), CricketTestDarts.miss()],
        [CricketTestDarts.triple(17), CricketTestDarts.triple(16), CricketTestDarts.triple(15)],
        [CricketTestDarts.miss(), CricketTestDarts.miss(), CricketTestDarts.miss()]
    ])
    vm.enteredDarts = [CricketTestDarts.innerBull, CricketTestDarts.outerBull]

    await vm.submitTurn()

    #expect(vm.state == .readyTurn)
    #expect(store.completedSessions().isEmpty)
}

@MainActor
@Test(.tags(.integration, .cricket, .match, .critical, .regression))
func cricketViewModelCompletesWhenAllPlayersCloseAllTargets() async throws {
    let (vm, store) = try makeCricketViewModel(preTurns: [
        [CricketTestDarts.triple(20), CricketTestDarts.triple(19), CricketTestDarts.triple(18)],
        [CricketTestDarts.miss(), CricketTestDarts.miss(), CricketTestDarts.miss()],
        [CricketTestDarts.triple(17), CricketTestDarts.triple(16), CricketTestDarts.triple(15)],
        [CricketTestDarts.miss(), CricketTestDarts.miss(), CricketTestDarts.miss()],
        [CricketTestDarts.innerBull, CricketTestDarts.outerBull],
        [CricketTestDarts.triple(20), CricketTestDarts.triple(19), CricketTestDarts.triple(18)],
        [CricketTestDarts.miss(), CricketTestDarts.miss(), CricketTestDarts.miss()],
        [CricketTestDarts.triple(17), CricketTestDarts.triple(16), CricketTestDarts.triple(15)],
        [CricketTestDarts.miss(), CricketTestDarts.miss(), CricketTestDarts.miss()]
    ])
    vm.enteredDarts = [CricketTestDarts.innerBull, CricketTestDarts.outerBull]

    await vm.submitTurn()

    #expect(vm.state == .matchCompleted)
    #expect(store.completedSessions().count == 1)
}

@MainActor
@Test(.tags(.integration, .cricket, .match, .regression))
func cricketViewModelBoardColumnsCarryParticipantColor() async throws {
    let p0 = UUID()
    let p1 = UUID()
    let session = try MatchLifecycleService.createMatch(
        type: .cricket,
        config: .cricket(MatchConfigCricket()),
        participants: [
            MatchParticipant(
                playerId: p0,
                displayNameAtMatchStart: "A",
                turnOrder: 0,
                preferredColorTokenAtMatchStart: PlayerColorToken.blue.rawValue
            ),
            MatchParticipant(
                playerId: p1,
                displayNameAtMatchStart: "B",
                turnOrder: 1,
                preferredColorTokenAtMatchStart: PlayerColorToken.coral.rawValue
            )
        ]
    )
    let store = ActiveMatchStore()
    store.save(session)
    let vm = CricketMatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: CricketSilentLogSink()),
        matchRepository: CricketFakeMatchRepository(),
        statsRepository: CricketFakeStatsRepository()
    )
    await vm.onAppear()

    #expect(vm.boardColumns[0].colorToken == .blue)
    #expect(vm.boardColumns[1].colorToken == .coral)
}

@MainActor
@Test(.tags(.integration, .cricket, .match, .regression))
func cricketViewModelBoardColumnsFallbackColorForLegacyParticipants() async throws {
    let p0 = UUID()
    let p1 = UUID()
    let session = try MatchLifecycleService.createMatch(
        type: .cricket,
        config: .cricket(MatchConfigCricket()),
        participants: [
            MatchParticipant(
                playerId: p0,
                displayNameAtMatchStart: "A",
                turnOrder: 0,
                preferredColorTokenAtMatchStart: nil
            ),
            MatchParticipant(
                playerId: p1,
                displayNameAtMatchStart: "B",
                turnOrder: 1,
                preferredColorTokenAtMatchStart: PlayerColorToken.coral.rawValue
            )
        ]
    )
    let store = ActiveMatchStore()
    store.save(session)
    let vm = CricketMatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: CricketSilentLogSink()),
        matchRepository: CricketFakeMatchRepository(),
        statsRepository: CricketFakeStatsRepository()
    )
    await vm.onAppear()

    #expect(vm.boardColumns[0].colorToken == PlayerColorToken.defaultForPlayer(id: p0))
}

@MainActor
@Test(.tags(.integration, .cricket, .match, .regression))
func cricketViewModelBoardColumnsHideLegsForSingleLegMatch() async throws {
    let session = try MatchLifecycleService.createMatch(
        type: .cricket,
        config: .cricket(MatchConfigCricket(legsToWin: 1, setsEnabled: false)),
        participants: cricketParticipants(count: 2)
    )
    let store = ActiveMatchStore()
    store.save(session)
    let vm = CricketMatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: CricketSilentLogSink()),
        matchRepository: CricketFakeMatchRepository(),
        statsRepository: CricketFakeStatsRepository()
    )
    await vm.onAppear()

    #expect(vm.boardColumns.allSatisfy { !$0.setsEnabled })
}

@MainActor
@Test(.tags(.integration, .cricket, .match, .regression))
func cricketViewModelBoardColumnsOmitLegsLabelForMultiLegMatch() async throws {
    let session = try MatchLifecycleService.createMatch(
        type: .cricket,
        config: .cricket(MatchConfigCricket(legsToWin: 3, setsEnabled: false)),
        participants: cricketParticipants(count: 2)
    )
    let store = ActiveMatchStore()
    store.save(session)
    let vm = CricketMatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: CricketSilentLogSink()),
        matchRepository: CricketFakeMatchRepository(),
        statsRepository: CricketFakeStatsRepository()
    )
    await vm.onAppear()

    #expect(vm.boardColumns.allSatisfy { !$0.setsEnabled })
}

@MainActor
@Test(.tags(.integration, .cricket, .match, .regression))
func cricketViewModelBoardColumnsMatchThreeParticipants() async throws {
    let (vm, _) = try makeCricketViewModel(participantCount: 3)
    await vm.onAppear()

    #expect(vm.boardColumns.count == 3)
    let activeCount = vm.boardColumns.filter(\.isActive).count
    #expect(activeCount == 1)
    #expect(vm.boardColumns[vm.cricketState!.currentPlayerIndex].isActive)
}

@MainActor
@Test(.tags(.integration, .cricket, .match, .critical, .regression))
func cricketViewModelDoesNotCompleteWhenOnlyOneOfThreePlayersCloses() async throws {
    let (vm, store) = try makeCricketViewModel(participantCount: 3, preTurns: [
        [CricketTestDarts.triple(20), CricketTestDarts.triple(19), CricketTestDarts.triple(18)],
        [CricketTestDarts.miss(), CricketTestDarts.miss(), CricketTestDarts.miss()],
        [CricketTestDarts.miss(), CricketTestDarts.miss(), CricketTestDarts.miss()],
        [CricketTestDarts.triple(17), CricketTestDarts.triple(16), CricketTestDarts.triple(15)],
        [CricketTestDarts.miss(), CricketTestDarts.miss(), CricketTestDarts.miss()],
        [CricketTestDarts.miss(), CricketTestDarts.miss(), CricketTestDarts.miss()]
    ])
    vm.enteredDarts = [CricketTestDarts.innerBull, CricketTestDarts.outerBull]

    await vm.submitTurn()

    #expect(vm.state == .readyTurn)
    #expect(store.completedSessions().isEmpty)
}

@MainActor
@Test(.tags(.integration, .cricket, .match, .critical, .regression))
func cricketViewModelCompletesWhenAllThreePlayersCloseAllTargets() async throws {
    let (vm, store) = try makeCricketViewModel(participantCount: 3, preTurns: [
        [CricketTestDarts.triple(20), CricketTestDarts.triple(19), CricketTestDarts.triple(18)],
        [CricketTestDarts.miss(), CricketTestDarts.miss(), CricketTestDarts.miss()],
        [CricketTestDarts.miss(), CricketTestDarts.miss(), CricketTestDarts.miss()],
        [CricketTestDarts.triple(17), CricketTestDarts.triple(16), CricketTestDarts.triple(15)],
        [CricketTestDarts.miss(), CricketTestDarts.miss(), CricketTestDarts.miss()],
        [CricketTestDarts.miss(), CricketTestDarts.miss(), CricketTestDarts.miss()],
        [CricketTestDarts.innerBull, CricketTestDarts.outerBull],
        [CricketTestDarts.triple(20), CricketTestDarts.triple(19), CricketTestDarts.triple(18)],
        [CricketTestDarts.miss(), CricketTestDarts.miss(), CricketTestDarts.miss()],
        [CricketTestDarts.miss(), CricketTestDarts.miss(), CricketTestDarts.miss()],
        [CricketTestDarts.triple(17), CricketTestDarts.triple(16), CricketTestDarts.triple(15)],
        [CricketTestDarts.miss(), CricketTestDarts.miss(), CricketTestDarts.miss()],
        [CricketTestDarts.miss(), CricketTestDarts.miss(), CricketTestDarts.miss()],
        [CricketTestDarts.innerBull, CricketTestDarts.outerBull],
        [CricketTestDarts.triple(20), CricketTestDarts.triple(19), CricketTestDarts.triple(18)],
        [CricketTestDarts.miss(), CricketTestDarts.miss(), CricketTestDarts.miss()],
        [CricketTestDarts.miss(), CricketTestDarts.miss(), CricketTestDarts.miss()],
        [CricketTestDarts.triple(17), CricketTestDarts.triple(16), CricketTestDarts.triple(15)],
        [CricketTestDarts.miss(), CricketTestDarts.miss(), CricketTestDarts.miss()],
        [CricketTestDarts.miss(), CricketTestDarts.miss(), CricketTestDarts.miss()]
    ])
    vm.enteredDarts = [CricketTestDarts.innerBull, CricketTestDarts.outerBull]

    await vm.submitTurn()

    #expect(vm.state == .matchCompleted)
    #expect(store.completedSessions().count == 1)
}

@MainActor
@Test(.tags(.integration, .cricket, .match, .regression))
func cricketViewModelReflectsMarksOnBoardAfterSubmit() async throws {
    let (vm, _) = try makeCricketViewModel()
    await vm.onAppear()
    vm.enteredDarts = [CricketTestDarts.triple(20)]

    await vm.submitTurn()

    let aliceColumn = try #require(vm.boardColumns.first)
    #expect(aliceColumn.marks["20"] == 3)
}

@MainActor
@Test(.tags(.integration, .cricket, .match, .regression))
func cricketViewModelUndoRevertsLastTurn() async throws {
    let (vm, store) = try makeCricketViewModel()
    await vm.onAppear()
    vm.enteredDarts = [CricketTestDarts.triple(20)]
    await vm.submitTurn()
    #expect(vm.session?.events.count == 1)

    await vm.undoLastTurn()

    #expect(vm.state == .readyTurn)
    #expect(vm.session?.events.isEmpty == true)
    #expect((vm.boardColumns.first?.marks["20"] ?? 0) == 0)
    #expect(store.session(for: vm.session!.runtime.matchId)?.events.isEmpty == true)
}

@MainActor
@Test(.tags(.integration, .cricket, .match, .regression))
func cricketViewModelSurfacesErrorWhenPersistenceFails() async throws {
    let (vm, _) = try makeCricketViewModel(failAppend: true)
    vm.enteredDarts = [CricketTestDarts.triple(20)]

    await vm.submitTurn()

    if case .error = vm.state {
        #expect(Bool(true))
    } else {
        Issue.record("Expected error state, got \(vm.state)")
    }
}

@MainActor
@Test(.tags(.integration, .cricket, .match, .regression))
func cricketViewModelDartsThrownCountsMissesLikePostGameStats() async throws {
    let (vm, _) = try makeCricketViewModel(preTurns: [
        [CricketTestDarts.triple(20), CricketTestDarts.miss(), CricketTestDarts.single(19)]
    ])

    let aliceColumn = try #require(vm.boardColumns.first)
    #expect(aliceColumn.dartsThrown == 3)
}

@MainActor
@Test(.tags(.integration, .cricket, .match, .regression))
func cricketViewModelCountsActiveBotVisitDartsWhileBotIsUp() async throws {
    let botId = UUID()
    let humanId = UUID()
    let session = try MatchLifecycleService.createMatch(
        type: .cricket,
        config: .cricket(MatchConfigCricket()),
        participants: [
            MatchParticipant(
                playerId: botId,
                displayNameAtMatchStart: BotDifficulty.easy.rosterName,
                turnOrder: 0,
                botDifficultyRaw: BotDifficulty.easy.rawValue
            ),
            MatchParticipant(playerId: humanId, displayNameAtMatchStart: "Human", turnOrder: 1)
        ]
    )
    let store = ActiveMatchStore()
    store.save(session)
    let vm = CricketMatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: CricketSilentLogSink()),
        matchRepository: CricketFakeMatchRepository(),
        statsRepository: CricketFakeStatsRepository()
    )
    vm.enteredDarts = [CricketTestDarts.triple(20), CricketTestDarts.miss()]

    let botColumn = try #require(vm.boardColumns.first { $0.id == botId })
    #expect(vm.isCurrentPlayerBot)
    #expect(!vm.isBotPlaying)
    #expect(botColumn.dartsThrown == 2)
}

// MARK: - Fakes

private final class CricketSilentLogSink: LogSink, @unchecked Sendable {
    func write(_: LogEntry) {}
}

private actor CricketRehydratingFakeStatsRepository: StatsRepository {
    let events: [MatchEventSummary]

    init(events: [MatchEventSummary]) { self.events = events }

    func fetchEvents(matchId: UUID) async throws -> [MatchEventSummary] {
        events.filter { $0.matchId == matchId }
    }

    func fetchEvents(matchIds _: [UUID]) async throws -> [MatchEventSummary] { [] }
}

private actor CricketRehydratingFakeMatchRepository: MatchRepository {
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
        makeSummary(type: .cricket, status: .completed)
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

private actor CricketFakeStatsRepository: StatsRepository {
    func fetchEvents(matchId _: UUID) async throws -> [MatchEventSummary] { [] }
    func fetchEvents(matchIds _: [UUID]) async throws -> [MatchEventSummary] { [] }
}

private actor CricketFakeMatchRepository: MatchRepository {
    let failAppend: Bool
    init(failAppend: Bool = false) { self.failAppend = failAppend }

    func createMatch(type: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary {
        makeSummary(type: type, status: .inProgress)
    }
    func fetchActiveMatch() async throws -> MatchSummary? { nil }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { [] }
    func fetchHistoryWithParticipants(page _: Int, pageSize _: Int, filter _: MatchHistoryFilter) async throws -> [MatchHistoryRecord] { [] }
    func updateMatch(_: MatchSummary) async throws {}
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary {
        makeSummary(type: .cricket, status: .completed)
    }
    func appendEvent(matchId: UUID, eventTypeRaw: String, eventPayload: Data) async throws -> MatchEventSummary {
        if failAppend {
            throw AppError(code: .storageUnavailable, layer: .data, severity: .error, isRecoverable: true, userMessageKey: "error.repository.storage")
        }
        return MatchEventSummary(id: UUID(), matchId: matchId, eventIndex: 0, eventTypeRaw: eventTypeRaw, eventPayload: eventPayload, createdAt: Date())
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
