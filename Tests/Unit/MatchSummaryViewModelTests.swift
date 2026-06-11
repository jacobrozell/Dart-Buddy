import Foundation
import Testing
@testable import DartBuddy

@MainActor
@Test(.tags(.integration, .match, .regression))
func matchSummaryViewModelLoadsSessionFromRepositoryWhenStoreEmpty() async throws {
    let p0 = UUID()
    let p1 = UUID()
    var session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(MatchConfigX01(startScore: 101, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
        participants: [
            MatchParticipant(playerId: p0, displayNameAtMatchStart: "Alice", turnOrder: 0),
            MatchParticipant(playerId: p1, displayNameAtMatchStart: "Bob", turnOrder: 1)
        ]
    )
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 60, darts: nil)
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 0, darts: nil)
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 41, darts: nil)

    let matchId = session.runtime.matchId
    let snapshot = session.latestSnapshot
    let store = ActiveMatchStore()
    let matchRepo = SummaryFakeMatchRepository(
        snapshot: MatchSnapshotSummary(
            id: UUID(),
            matchId: matchId,
            snapshotVersion: snapshot.payloadVersion,
            snapshotPayload: snapshot.payload,
            updatedAt: Date()
        )
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
    let statsRepo = SummaryFakeStatsRepository(events: eventSummaries)

    let vm = MatchSummaryViewModel(
        matchId: matchId,
        store: store,
        matchRepository: matchRepo,
        statsRepository: statsRepo
    )

    #expect(!vm.hasResult)
    await vm.loadIfNeeded()

    #expect(vm.hasResult)
    #expect(vm.winnerName == "Alice")
    #expect(vm.playerRows.count == 2)
    #expect(store.session(for: matchId) != nil)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func matchSummaryX01StatParityIncludesBestOutForEveryPlayer() async throws {
    let p0 = UUID()
    let p1 = UUID()
    var session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(MatchConfigX01(startScore: 101, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
        participants: [
            MatchParticipant(playerId: p0, displayNameAtMatchStart: "Alice", turnOrder: 0),
            MatchParticipant(playerId: p1, displayNameAtMatchStart: "Bob", turnOrder: 1)
        ]
    )
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 60, darts: nil)
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 0, darts: nil)
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 41, darts: nil)

    let store = ActiveMatchStore()
    store.save(session)
    let vm = MatchSummaryViewModel(
        matchId: session.runtime.matchId,
        store: store,
        matchRepository: SummaryFakeMatchRepository(snapshot: MatchSnapshotSummary(
            id: UUID(),
            matchId: session.runtime.matchId,
            snapshotVersion: session.latestSnapshot.payloadVersion,
            snapshotPayload: session.latestSnapshot.payload,
            updatedAt: Date()
        )),
        statsRepository: SummaryFakeStatsRepository(events: [])
    )
    vm.refresh()

    let rows = vm.playerRows
    #expect(rows.count == 2)

    let labelSets = rows.map { $0.stats.map(\.label) }
    #expect(labelSets[0] == labelSets[1])

    let bestOutLabel = L10n.string("play.summary.stat.bestOut")
    #expect(labelSets[0].contains(bestOutLabel))

    let winner = rows.first(where: \.isWinner)
    let loser = rows.first(where: { !$0.isWinner })
    #expect(winner?.stats.first(where: { $0.label == bestOutLabel })?.value == "41")
    #expect(loser?.stats.first(where: { $0.label == bestOutLabel })?.value == "—")
}

@MainActor
@Test(.tags(.unit, .match, .regression))
func matchSummaryX01StatsBuilderIncludesSetsWhenEnabled() throws {
    let p0 = UUID()
    let session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(MatchConfigX01(startScore: 501, legsToWin: 2, setsEnabled: true, setsToWin: 2, checkoutMode: .doubleOut)),
        participants: [
            MatchParticipant(playerId: p0, displayNameAtMatchStart: "A", turnOrder: 0),
            MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "B", turnOrder: 1)
        ]
    )
    let breakdown = PlayerStatBreakdown(playerId: p0, name: "A", darts: 3, points: 60)
    let stats = MatchSummaryViewModel.stats(for: breakdown, runtime: session.runtime)
    let labels = stats.map(\.label)
    #expect(labels.contains(L10n.string("play.summary.stat.sets")))
    #expect(labels.contains(L10n.string("play.summary.stat.legs")))
}

@MainActor
@Test(.tags(.unit, .match, .cricket, .regression))
func matchSummaryCricketStatsBuilderIncludesLegsForMultiLegConfig() throws {
    let p0 = UUID()
    let session = try MatchLifecycleService.createMatch(
        type: .cricket,
        config: .cricket(MatchConfigCricket(legsToWin: 3)),
        participants: [
            MatchParticipant(playerId: p0, displayNameAtMatchStart: "A", turnOrder: 0),
            MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "B", turnOrder: 1)
        ]
    )
    let breakdown = PlayerStatBreakdown(playerId: p0, name: "A", darts: 3, cricketMarks: 3, cricketRounds: 1)
    let stats = MatchSummaryViewModel.stats(for: breakdown, runtime: session.runtime)
    #expect(stats.map(\.label).contains(L10n.string("play.summary.stat.legs")))
}

@MainActor
@Test(.tags(.unit, .match, .regression))
func matchSummaryX01StatsBuilderAlwaysIncludesBestOutPlaceholder() throws {
    let p0 = UUID()
    let session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(MatchConfigX01(startScore: 501, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .doubleOut)),
        participants: [
            MatchParticipant(playerId: p0, displayNameAtMatchStart: "A", turnOrder: 0),
            MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "B", turnOrder: 1)
        ]
    )
    let breakdown = PlayerStatBreakdown(
        playerId: p0,
        name: "A",
        darts: 9,
        points: 501,
        highestCheckout: 0
    )

    let stats = MatchSummaryViewModel.stats(for: breakdown, runtime: session.runtime)
    let labels = stats.map(\.label)
    let values = stats.map(\.value)

    #expect(labels.last == L10n.string("play.summary.stat.bestOut"))
    #expect(values.last == "—")
}

@MainActor
@Test(.tags(.integration, .match, .cricket, .regression))
func matchSummaryViewModelLoadsCricketSession() async throws {
    let p0 = UUID()
    let p1 = UUID()
    var session = try MatchLifecycleService.createMatch(
        type: .cricket,
        config: .cricket(MatchConfigCricket()),
        participants: [
            MatchParticipant(playerId: p0, displayNameAtMatchStart: "Alice", turnOrder: 0),
            MatchParticipant(playerId: p1, displayNameAtMatchStart: "Bob", turnOrder: 1)
        ]
    )
    session = try MatchLifecycleService.submitCricketTurn(session: session, darts: [CricketTestDarts.triple(20)])

    let store = ActiveMatchStore()
    store.save(session)
    let vm = MatchSummaryViewModel(
        matchId: session.runtime.matchId,
        store: store,
        matchRepository: SummaryFakeMatchRepository(snapshot: MatchSnapshotSummary(
            id: UUID(),
            matchId: session.runtime.matchId,
            snapshotVersion: session.latestSnapshot.payloadVersion,
            snapshotPayload: session.latestSnapshot.payload,
            updatedAt: Date()
        )),
        statsRepository: SummaryFakeStatsRepository(events: [])
    )
    vm.refresh()

    #expect(vm.typeLabel == L10n.string("play.cricket.title"))
    #expect(vm.playerRows.count == 2)
    #expect(vm.playerRows[0].stats.contains(where: { $0.label == L10n.string("stats.mpr") }))
}

@MainActor
@Test(.tags(.unit, .match, .cricket, .regression))
func matchSummaryCricketStatsBuilderIncludesScoreAndMPR() throws {
    let p0 = UUID()
    var session = try MatchLifecycleService.createMatch(
        type: .cricket,
        config: .cricket(MatchConfigCricket()),
        participants: [
            MatchParticipant(playerId: p0, displayNameAtMatchStart: "A", turnOrder: 0),
            MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "B", turnOrder: 1)
        ]
    )
    session = try MatchLifecycleService.submitCricketTurn(session: session, darts: [CricketTestDarts.triple(20)])
    let breakdown = PlayerStatBreakdown(
        playerId: p0,
        name: "A",
        darts: 1,
        cricketMarks: 3,
        cricketRounds: 1
    )

    let stats = MatchSummaryViewModel.stats(for: breakdown, runtime: session.runtime)
    let labels = stats.map(\.label)

    #expect(labels.contains(L10n.string("play.summary.stat.score")))
    #expect(labels.contains(L10n.string("stats.mpr")))
    #expect(labels.contains(L10n.string("play.summary.stat.darts")))
}

@MainActor
@Test(.tags(.unit, .match, .regression))
func matchSummaryCanRematchOnlyWhenCompleted() async throws {
    var inProgress = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(MatchConfigX01(startScore: 101, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
        participants: [
            MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "A", turnOrder: 0),
            MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "B", turnOrder: 1)
        ]
    )
    inProgress = try MatchLifecycleService.submitX01Turn(session: inProgress, enteredTotal: 60, darts: nil)
    let store = ActiveMatchStore()
    store.save(inProgress)
    let inProgressVM = MatchSummaryViewModel(
        matchId: inProgress.runtime.matchId,
        store: store,
        matchRepository: SummaryUndoFakeMatchRepository(),
        statsRepository: SummaryFakeStatsRepository(events: [])
    )
    inProgressVM.refresh()
    #expect(!inProgressVM.canRematch)

    var completed = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(MatchConfigX01(startScore: 101, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
        participants: [
            MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "A", turnOrder: 0),
            MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "B", turnOrder: 1)
        ]
    )
    completed.runtime.status = .completed
    store.save(completed)
    let completedVM = MatchSummaryViewModel(
        matchId: completed.runtime.matchId,
        store: store,
        matchRepository: SummaryUndoFakeMatchRepository(),
        statsRepository: SummaryFakeStatsRepository(events: [])
    )
    completedVM.refresh()
    #expect(completedVM.canRematch)
}

@MainActor
@Test(.tags(.unit, .match, .regression))
func matchSummaryCannotUndoInProgressMatch() async throws {
    var session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(MatchConfigX01(startScore: 101, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
        participants: [
            MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "A", turnOrder: 0),
            MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "B", turnOrder: 1)
        ]
    )
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 60, darts: nil)
    let store = ActiveMatchStore()
    store.save(session)
    let vm = MatchSummaryViewModel(
        matchId: session.runtime.matchId,
        store: store,
        matchRepository: SummaryUndoFakeMatchRepository(),
        statsRepository: SummaryFakeStatsRepository(events: [])
    )
    vm.refresh()

    #expect(vm.hasResult)
    #expect(!vm.canUndoLastThrow)
}

@MainActor
@Test(.tags(.unit, .match, .regression))
func matchSummaryLoadIfNeededUsesStoreWithoutRehydrating() async throws {
    let session = try MatchLifecycleService.createMatch(
        type: .cricket,
        config: .cricket(MatchConfigCricket()),
        participants: cricketParticipants(count: 2)
    )
    let store = ActiveMatchStore()
    store.save(session)
    let vm = MatchSummaryViewModel(
        matchId: session.runtime.matchId,
        store: store,
        matchRepository: SummaryFakeMatchRepository(
            snapshot: MatchSnapshotSummary(id: UUID(), matchId: UUID(), snapshotVersion: 1, snapshotPayload: Data(), updatedAt: Date())
        ),
        statsRepository: SummaryFakeStatsRepository(events: [])
    )

    #expect(vm.hasResult)
    await vm.loadIfNeeded()
    #expect(vm.typeLabel == L10n.string("play.cricket.title"))
}

@MainActor
@Test(.tags(.unit, .match, .regression))
func matchSummaryUndoLastThrowSurfacesErrorWhenPersistenceFails() async throws {
    let p0 = UUID()
    let p1 = UUID()
    var session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(MatchConfigX01(startScore: 101, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
        participants: [
            MatchParticipant(playerId: p0, displayNameAtMatchStart: "Alice", turnOrder: 0),
            MatchParticipant(playerId: p1, displayNameAtMatchStart: "Bob", turnOrder: 1)
        ]
    )
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 60, darts: nil)
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 0, darts: nil)
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 41, darts: nil)
    let matchId = session.runtime.matchId
    let store = ActiveMatchStore()
    store.save(session)
    let vm = MatchSummaryViewModel(
        matchId: matchId,
        store: store,
        matchRepository: SummaryFailingUndoMatchRepository(),
        statsRepository: SummaryFakeStatsRepository(events: [])
    )
    vm.refresh()

    let restored = await vm.undoLastThrow()
    #expect(restored == nil)
    #expect(vm.undoErrorKey != nil)
}

@MainActor
@Test(.tags(.unit, .match, .regression))
func matchSummaryRefreshReloadsSessionFromStore() async throws {
    let store = ActiveMatchStore()
    var session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(MatchConfigX01(startScore: 101, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
        participants: [
            MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "A", turnOrder: 0),
            MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "B", turnOrder: 1)
        ]
    )
    store.save(session)
    let vm = MatchSummaryViewModel(
        matchId: session.runtime.matchId,
        store: store,
        matchRepository: SummaryFakeMatchRepository(snapshot: MatchSnapshotSummary(
            id: UUID(), matchId: session.runtime.matchId, snapshotVersion: 1, snapshotPayload: Data(), updatedAt: Date()
        )),
        statsRepository: SummaryFakeStatsRepository(events: [])
    )
    #expect(vm.hasResult)

    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 60, darts: nil)
    store.save(session)
    vm.refresh()

    #expect(vm.playerRows.first?.stats.first?.value == "60.0")
}

@MainActor
@Test(.tags(.unit, .match, .regression))
func matchSummaryUndoLastThrowReopensCompletedCricketMatch() async throws {
    let preTurns: [[DartInput]] = [
        [CricketTestDarts.triple(20), CricketTestDarts.triple(19), CricketTestDarts.triple(18)],
        [CricketTestDarts.miss(), CricketTestDarts.miss(), CricketTestDarts.miss()],
        [CricketTestDarts.triple(17), CricketTestDarts.triple(16), CricketTestDarts.triple(15)],
        [CricketTestDarts.miss(), CricketTestDarts.miss(), CricketTestDarts.miss()],
        [CricketTestDarts.innerBull, CricketTestDarts.outerBull],
        [CricketTestDarts.triple(20), CricketTestDarts.triple(19), CricketTestDarts.triple(18)],
        [CricketTestDarts.miss(), CricketTestDarts.miss(), CricketTestDarts.miss()],
        [CricketTestDarts.triple(17), CricketTestDarts.triple(16), CricketTestDarts.triple(15)],
        [CricketTestDarts.miss(), CricketTestDarts.miss(), CricketTestDarts.miss()],
        [CricketTestDarts.innerBull, CricketTestDarts.outerBull]
    ]
    var session = try MatchLifecycleService.createMatch(
        type: .cricket,
        config: .cricket(MatchConfigCricket()),
        participants: cricketParticipants(count: 2)
    )
    for darts in preTurns {
        session = try MatchLifecycleService.submitCricketTurn(session: session, darts: darts)
    }
    let matchId = session.runtime.matchId
    #expect(session.runtime.status == .completed)

    let store = ActiveMatchStore()
    store.save(session)
    let matchRepo = SummaryUndoFakeMatchRepository()
    let vm = MatchSummaryViewModel(
        matchId: matchId,
        store: store,
        matchRepository: matchRepo,
        statsRepository: SummaryFakeStatsRepository(events: [])
    )
    vm.refresh()
    #expect(vm.canUndoLastThrow)

    let restored = await vm.undoLastThrow()
    #expect(restored != nil)
    #expect(store.session(for: matchId)?.runtime.status == .inProgress)
    #expect(await matchRepo.updatedSummaries.last?.status == .inProgress)
}

@MainActor
@Test(.tags(.unit, .match, .regression))
func matchSummaryUndoLastThrowReopensCompletedMatch() async throws {
    let p0 = UUID()
    let p1 = UUID()
    var session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(MatchConfigX01(startScore: 101, legsToWin: 1, setsEnabled: false, setsToWin: nil, checkoutMode: .singleOut)),
        participants: [
            MatchParticipant(playerId: p0, displayNameAtMatchStart: "Alice", turnOrder: 0),
            MatchParticipant(playerId: p1, displayNameAtMatchStart: "Bob", turnOrder: 1)
        ]
    )
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 60, darts: nil)
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 0, darts: nil)
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 41, darts: nil)

    let matchId = session.runtime.matchId
    #expect(session.runtime.status == .completed)

    let store = ActiveMatchStore()
    store.save(session)
    let matchRepo = SummaryUndoFakeMatchRepository()
    let vm = MatchSummaryViewModel(
        matchId: matchId,
        store: store,
        matchRepository: matchRepo,
        statsRepository: SummaryFakeStatsRepository(events: [])
    )
    vm.refresh()

    #expect(vm.canUndoLastThrow)
    let restored = await vm.undoLastThrow()
    #expect(restored != nil)
    #expect(vm.canUndoLastThrow == false)
    #expect(store.session(for: matchId)?.runtime.status == .inProgress)
    #expect(store.session(for: matchId)?.runtime.winnerPlayerId == nil)
    #expect(await matchRepo.updatedSummaries.last?.status == .inProgress)
}

private actor SummaryFailingUndoMatchRepository: MatchRepository {
    func createMatch(type _: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary {
        throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error")
    }
    func fetchActiveMatch() async throws -> MatchSummary? { nil }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { [] }
    func fetchHistoryWithParticipants(page _: Int, pageSize _: Int, filter _: MatchHistoryFilter) async throws -> [MatchHistoryRecord] { [] }
    func updateMatch(_: MatchSummary) async throws {
        throw AppError(code: .storageUnavailable, layer: .data, severity: .error, isRecoverable: true, userMessageKey: "play.summary.undoFailed")
    }
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary { fatalError() }
    func appendEvent(matchId _: UUID, eventTypeRaw _: String, eventPayload _: Data) async throws -> MatchEventSummary { fatalError() }
    func saveSnapshot(matchId _: UUID, snapshotVersion _: Int, snapshotPayload _: Data) async throws -> MatchSnapshotSummary { fatalError() }
    func fetchLatestSnapshot(matchId _: UUID) async throws -> MatchSnapshotSummary? { nil }
    func fetchMatch(matchId _: UUID) async throws -> MatchSummary? { nil }
    func fetchParticipants(matchId _: UUID) async throws -> [MatchParticipantSummary] { [] }
    func deleteMatch(matchId _: UUID) async throws {}
}

private actor SummaryUndoFakeMatchRepository: MatchRepository {
    private(set) var updatedSummaries: [MatchSummary] = []

    func createMatch(type _: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary {
        throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error")
    }
    func fetchActiveMatch() async throws -> MatchSummary? { nil }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { [] }
    func fetchHistoryWithParticipants(page _: Int, pageSize _: Int, filter _: MatchHistoryFilter) async throws -> [MatchHistoryRecord] { [] }
    func updateMatch(_ match: MatchSummary) async throws {
        updatedSummaries.append(match)
    }
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary {
        throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error")
    }
    func appendEvent(matchId _: UUID, eventTypeRaw _: String, eventPayload _: Data) async throws -> MatchEventSummary {
        throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error")
    }
    func saveSnapshot(matchId _: UUID, snapshotVersion _: Int, snapshotPayload _: Data) async throws -> MatchSnapshotSummary {
        MatchSnapshotSummary(id: UUID(), matchId: UUID(), snapshotVersion: 1, snapshotPayload: Data(), updatedAt: Date())
    }
    func fetchLatestSnapshot(matchId _: UUID) async throws -> MatchSnapshotSummary? { nil }
    func fetchMatch(matchId _: UUID) async throws -> MatchSummary? { nil }
    func fetchParticipants(matchId _: UUID) async throws -> [MatchParticipantSummary] { [] }
    func deleteMatch(matchId _: UUID) async throws {}
}

private actor SummaryFakeMatchRepository: MatchRepository {
    let snapshot: MatchSnapshotSummary

    init(snapshot: MatchSnapshotSummary) {
        self.snapshot = snapshot
    }

    func createMatch(type _: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary {
        throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error")
    }
    func fetchActiveMatch() async throws -> MatchSummary? { nil }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { [] }
    func fetchHistoryWithParticipants(page _: Int, pageSize _: Int, filter _: MatchHistoryFilter) async throws -> [MatchHistoryRecord] { [] }
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
        snapshot.matchId == matchId ? snapshot : nil
    }
    func fetchMatch(matchId _: UUID) async throws -> MatchSummary? { nil }
    func fetchParticipants(matchId _: UUID) async throws -> [MatchParticipantSummary] { [] }
    func deleteMatch(matchId _: UUID) async throws {}
}

private actor SummaryFakeStatsRepository: StatsRepository {
    let events: [MatchEventSummary]

    init(events: [MatchEventSummary]) {
        self.events = events
    }

    func fetchEvents(matchId: UUID) async throws -> [MatchEventSummary] {
        events.filter { $0.matchId == matchId }
    }

    func fetchEvents(matchIds _: [UUID]) async throws -> [MatchEventSummary] { [] }
}
