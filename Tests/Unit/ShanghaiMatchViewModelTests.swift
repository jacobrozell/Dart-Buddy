import Foundation
import Testing
@testable import DartBuddy

private func shanghaiDart(_ multiplier: DartMultiplier, _ segment: Int) -> DartInput {
    DartInput(multiplier: multiplier, segment: .oneToTwenty(segment))
}

@MainActor
private func makeShanghaiViewModel(
    participantCount: Int = 2,
    roundCount: Int = 20,
    bonusRule: ShanghaiBonusRule = .bonus150,
    preTurns: [[DartInput]] = []
) throws -> (vm: ShanghaiMatchViewModel, store: ActiveMatchStore) {
    let ids = (0 ..< participantCount).map { _ in UUID() }
    let participants = ids.enumerated().map { index, id in
        MatchParticipant(playerId: id, displayNameAtMatchStart: "P\(index + 1)", turnOrder: index)
    }
    var session = try MatchLifecycleService.createMatch(
        type: .shanghai,
        config: .shanghai(MatchConfigShanghai(roundCount: roundCount, bonusRule: bonusRule)),
        participants: participants
    )
    for darts in preTurns {
        session = try MatchLifecycleService.submitShanghaiTurn(session: session, darts: darts)
    }
    let store = ActiveMatchStore()
    store.save(session)
    let vm = ShanghaiMatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: ShanghaiSilentLogSink()),
        matchRepository: ShanghaiFakeMatchRepository(),
        statsRepository: ShanghaiFakeStatsRepository(),
        feedbackPreferences: {
            let prefs = FeedbackPreferences()
            prefs.botStaggerEnabled = false
            return prefs
        }()
    )
    return (vm, store)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func shanghaiViewModelLockedSegmentMatchesCurrentRound() async throws {
    let (vm, _) = try makeShanghaiViewModel()

    #expect(vm.lockedSegment == 1)
    #expect(vm.shanghaiState?.currentRound == 1)
    #expect(vm.scoringHint?.contains("1") == true)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func shanghaiViewModelRequiresThreeDartsBeforeSubmit() async throws {
    let (vm, _) = try makeShanghaiViewModel()
    vm.enteredDarts = [shanghaiDart(.single, 1), shanghaiDart(.double, 1)]

    #expect(vm.canSubmit == false)
}

@MainActor
@Test(.tags(.integration, .match, .critical, .regression))
func shanghaiViewModelHumanSubmitUpdatesPoints() async throws {
    let (vm, _) = try makeShanghaiViewModel()
    vm.enteredDarts = [
        shanghaiDart(.single, 1),
        shanghaiDart(.double, 1),
        shanghaiDart(.triple, 1)
    ]

    await vm.submitTurn()

    #expect(vm.state == .shanghaiFeedback || vm.state == .readyTurn)
    #expect(vm.shanghaiState?.players[0].cumulativePoints == 156)
    #expect(vm.enteredDarts.isEmpty)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func shanghaiViewModelScoreboardShowsRoundPreviewForSmallField() async throws {
    let (vm, _) = try makeShanghaiViewModel(participantCount: 4)
    vm.enteredDarts = [shanghaiDart(.single, 1)]

    #expect(vm.showsRoundPointsColumn == true)
    let activeRow = vm.scoreboardRows.first(where: \.isActive)
    #expect(activeRow?.roundPoints != nil)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func shanghaiViewModelHeaderAccessibilityIncludesTitleAndRound() async throws {
    let (vm, _) = try makeShanghaiViewModel()

    #expect(vm.headerAccessibilityLabel.contains(L10n.string("play.shanghai.title")))
    #expect(vm.headerAccessibilityLabel.contains(vm.headerText))
    #expect(vm.goalReminder == L10n.string("play.shanghai.goalReminder"))
}

@MainActor
@Test(.tags(.integration, .match, .critical, .regression))
func shanghaiViewModelInstantWinCompletesMatch() async throws {
    let (vm, store) = try makeShanghaiViewModel(roundCount: 3, bonusRule: .instantWin)
    vm.enteredDarts = [
        shanghaiDart(.single, 1),
        shanghaiDart(.double, 1),
        shanghaiDart(.triple, 1)
    ]

    await vm.submitTurn()

    #expect(vm.state == .matchCompleted)
    #expect(vm.shanghaiState?.isComplete == true)
    #expect(store.completedSessions().count == 1)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func shanghaiViewModelRehydratesSessionFromSnapshotWhenStoreEmpty() async throws {
    let ids = [UUID(), UUID()]
    var session = try MatchLifecycleService.createMatch(
        type: .shanghai,
        config: .shanghai(MatchConfigShanghai(roundCount: 5)),
        participants: ids.enumerated().map { index, id in
            MatchParticipant(playerId: id, displayNameAtMatchStart: "P\(index + 1)", turnOrder: index)
        }
    )
    session = try MatchLifecycleService.submitShanghaiTurn(session: session, darts: [shanghaiDart(.single, 1)])
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
            eventTypeRaw: "shanghaiTurn",
            eventPayload: try CodablePayloadCoder.encode(envelope),
            createdAt: envelope.timestamp
        )
    }
    let store = ActiveMatchStore()
    let vm = ShanghaiMatchViewModel(
        matchId: matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: ShanghaiSilentLogSink()),
        matchRepository: ShanghaiRehydratingFakeMatchRepository(snapshot: snapshotSummary),
        statsRepository: ShanghaiRehydratingFakeStatsRepository(events: eventSummaries),
        feedbackPreferences: FeedbackPreferences()
    )

    #expect(vm.session == nil)
    await vm.onAppear()

    #expect(vm.session?.events.count == 1)
    #expect(vm.shanghaiState?.players[0].cumulativePoints == 1)
    #expect(store.session(for: matchId) != nil)
}

private struct ShanghaiSilentLogSink: LogSink {
    func write(_: LogEntry) {}
}

private actor ShanghaiFakeMatchRepository: MatchRepository {
    func createMatch(type: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary {
        makeSummary(type: type, status: .inProgress)
    }
    func fetchActiveMatch() async throws -> MatchSummary? { nil }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { [] }
    func fetchHistoryWithParticipants(page _: Int, pageSize _: Int, filter _: MatchHistoryFilter) async throws -> [MatchHistoryRecord] { [] }
    func updateMatch(_: MatchSummary) async throws {}
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary {
        makeSummary(type: .shanghai, status: .completed)
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

}

private actor ShanghaiFakeStatsRepository: StatsRepository {
    func fetchEvents(matchId _: UUID) async throws -> [MatchEventSummary] { [] }
    func fetchEvents(matchIds _: [UUID]) async throws -> [MatchEventSummary] { [] }
}

private actor ShanghaiRehydratingFakeMatchRepository: MatchRepository {
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
        makeSummary(type: .shanghai, status: .completed)
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

}

private actor ShanghaiRehydratingFakeStatsRepository: StatsRepository {
    let events: [MatchEventSummary]
    init(events: [MatchEventSummary]) { self.events = events }
    func fetchEvents(matchId _: UUID) async throws -> [MatchEventSummary] { events }
    func fetchEvents(matchIds _: [UUID]) async throws -> [MatchEventSummary] { events }
}
