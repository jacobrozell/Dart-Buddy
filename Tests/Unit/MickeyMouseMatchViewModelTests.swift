import Foundation
import Testing
@testable import DartBuddy

private func d(_ multiplier: DartMultiplier, _ segment: Int) -> DartInput {
    DartInput(multiplier: multiplier, segment: .oneToTwenty(segment))
}

private func miss() -> DartInput {
    DartInput(multiplier: .single, segment: .miss, isMiss: true)
}

@MainActor
private func makeMickeyMouseViewModel(
    participantCount: Int = 2,
    preTurns: [[DartInput]] = []
) throws -> (vm: MickeyMouseMatchViewModel, store: ActiveMatchStore) {
    let ids = (0 ..< participantCount).map { _ in UUID() }
    let participants = ids.enumerated().map { index, id in
        MatchParticipant(playerId: id, displayNameAtMatchStart: "P\(index + 1)", turnOrder: index)
    }
    var session = try MatchLifecycleService.createMatch(
        type: .mickeyMouse,
        config: .mickeyMouse(MatchConfigMickeyMouse()),
        participants: participants
    )
    for darts in preTurns {
        session = try MatchLifecycleService.submitMickeyMouseTurn(session: session, darts: darts)
    }
    let store = ActiveMatchStore()
    store.save(session)
    let vm = MickeyMouseMatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: MickeyMouseSilentLogSink()),
        matchRepository: MickeyMouseFakeMatchRepository(),
        statsRepository: MickeyMouseFakeStatsRepository(),
        feedbackPreferences: {
            let prefs = FeedbackPreferences()
            prefs.botStaggerEnabled = false
            return prefs
        }()
    )
    return (vm, store)
}

// MARK: - Entry validation

@MainActor
@Test(.tags(.integration, .match, .regression))
func mickeyMouseViewModelLockedSegmentMatchesCurrentTarget() async throws {
    let (vm, _) = try makeMickeyMouseViewModel()

    // First target is 20 (index 0).
    #expect(vm.lockedSegment == 20)
    #expect(vm.mickeyMouseState?.currentTargetIndex == 0)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func mickeyMouseViewModelHeaderTextContainsActiveTargetLabel() async throws {
    let (vm, _) = try makeMickeyMouseViewModel()

    #expect(vm.headerText.contains("20"))
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func mickeyMouseViewModelRequiresThreeDartsBeforeSubmit() async throws {
    let (vm, _) = try makeMickeyMouseViewModel()
    vm.enteredDarts = [d(.single, 20), d(.double, 20)]

    #expect(vm.canSubmit == false)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func mickeyMouseViewModelCanSubmitWithThreeDarts() async throws {
    let (vm, _) = try makeMickeyMouseViewModel()
    vm.enteredDarts = [miss(), miss(), miss()]

    #expect(vm.canSubmit == true)
}

// MARK: - Submission

@MainActor
@Test(.tags(.integration, .match, .critical, .regression))
func mickeyMouseViewModelHumanSubmitUpdatesMarks() async throws {
    let (vm, _) = try makeMickeyMouseViewModel()
    vm.enteredDarts = [d(.single, 20), d(.single, 20), miss()]

    await vm.submitTurn()

    #expect(vm.state == .readyTurn || vm.state == .targetAdvanced)
    #expect(vm.mickeyMouseState?.players[0].marksByTarget[0] == 2)
    #expect(vm.enteredDarts.isEmpty)
}

@MainActor
@Test(.tags(.integration, .match, .critical, .regression))
func mickeyMouseViewModelTripleClosesTargetAndAdvances() async throws {
    let (vm, _) = try makeMickeyMouseViewModel()
    vm.enteredDarts = [d(.triple, 20), miss(), miss()]

    await vm.submitTurn()

    // Target should have advanced; state settled to readyTurn.
    let finalState = vm.state
    #expect(finalState == .readyTurn || finalState == .targetAdvanced)
    #expect(vm.mickeyMouseState?.currentTargetIndex == 1)
    #expect(vm.enteredDarts.isEmpty)
}

// MARK: - Undo

@MainActor
@Test(.tags(.integration, .match, .regression))
func mickeyMouseViewModelUndoLastDartRemovesLastEntry() async throws {
    let (vm, _) = try makeMickeyMouseViewModel()
    vm.enteredDarts = [d(.single, 20), d(.single, 20)]

    await vm.undoLastDart()

    #expect(vm.enteredDarts.count == 1)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func mickeyMouseViewModelUndoWhenEmptyRevertsLastTurn() async throws {
    let (vm, store) = try makeMickeyMouseViewModel(
        preTurns: [[d(.single, 20), miss(), miss()]]
    )
    // State: P0 has 1 mark on target 0; it's P1's turn.
    #expect(vm.mickeyMouseState?.players[0].marksByTarget[0] == 1)
    #expect(vm.mickeyMouseState?.currentPlayerIndex == 1)

    await vm.undoLastDart()

    // After undo, P0 should have 0 marks and it should be P0's turn again.
    #expect(vm.mickeyMouseState?.players[0].marksByTarget[0] == 0)
    #expect(vm.mickeyMouseState?.currentPlayerIndex == 0)
}

// MARK: - Bot gating

@MainActor
@Test(.tags(.integration, .match, .regression))
func mickeyMouseViewModelCannotHumanInputWhenBotTurn() async throws {
    let ids = [UUID(), UUID()]
    let participants = [
        MatchParticipant(playerId: ids[0], displayNameAtMatchStart: "Human", turnOrder: 0),
        MatchParticipant(
            playerId: ids[1],
            displayNameAtMatchStart: "Bot",
            turnOrder: 1,
            botDifficultyRaw: BotDifficulty.medium.rawValue,
            botKindRaw: BotKind.preset.rawValue
        )
    ]
    let session = try MatchLifecycleService.createMatch(
        type: .mickeyMouse,
        config: .mickeyMouse(MatchConfigMickeyMouse()),
        participants: participants
    )
    let store = ActiveMatchStore()
    store.save(session)
    let vm = MickeyMouseMatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: MickeyMouseSilentLogSink()),
        matchRepository: MickeyMouseFakeMatchRepository(),
        statsRepository: MickeyMouseFakeStatsRepository()
    )

    // Advance to P1 (the bot) by submitting P0's turn.
    vm.enteredDarts = [miss(), miss(), miss()]
    await vm.submitTurn()

    // It is now the bot's turn — human input should be locked.
    #expect(vm.isCurrentPlayerBot == true)
    #expect(vm.canHumanInput == false)
}

// MARK: - Mark board rows

@MainActor
@Test(.tags(.integration, .match, .regression))
func mickeyMouseViewModelMarkBoardRowsMatchPlayerCount() async throws {
    let (vm, _) = try makeMickeyMouseViewModel(participantCount: 3)

    #expect(vm.markBoardRows.count == 3)
}

@MainActor
@Test(.tags(.integration, .match, .regression))
func mickeyMouseViewModelMarkBoardActiveRowMatchesCurrentPlayer() async throws {
    let (vm, _) = try makeMickeyMouseViewModel()

    let activeRows = vm.markBoardRows.filter(\.isActive)
    #expect(activeRows.count == 1)
}

// MARK: - Rehydration

@MainActor
@Test(.tags(.integration, .match, .regression))
func mickeyMouseViewModelRehydratesSessionFromSnapshotWhenStoreEmpty() async throws {
    let ids = [UUID(), UUID()]
    var session = try MatchLifecycleService.createMatch(
        type: .mickeyMouse,
        config: .mickeyMouse(MatchConfigMickeyMouse()),
        participants: ids.enumerated().map { index, id in
            MatchParticipant(playerId: id, displayNameAtMatchStart: "P\(index + 1)", turnOrder: index)
        }
    )
    session = try MatchLifecycleService.submitMickeyMouseTurn(
        session: session,
        darts: [d(.single, 20), miss(), miss()]
    )
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
            eventTypeRaw: "mickeyMouseTurn",
            eventPayload: try CodablePayloadCoder.encode(envelope),
            createdAt: envelope.timestamp
        )
    }
    let store = ActiveMatchStore()
    let vm = MickeyMouseMatchViewModel(
        matchId: matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: MickeyMouseSilentLogSink()),
        matchRepository: MickeyMouseRehydratingFakeMatchRepository(snapshot: snapshotSummary),
        statsRepository: MickeyMouseRehydratingFakeStatsRepository(events: eventSummaries)
    )

    #expect(vm.session == nil)
    await vm.onAppear()

    #expect(vm.session?.events.count == 1)
    #expect(vm.mickeyMouseState?.players[0].marksByTarget[0] == 1)
    #expect(store.session(for: matchId) != nil)
}

// MARK: - Test doubles

private struct MickeyMouseSilentLogSink: LogSink {
    func write(_: LogEntry) {}
}

private actor MickeyMouseFakeMatchRepository: MatchRepository {
    func createMatch(type: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary {
        makeSummary(type: type, status: .inProgress)
    }
    func fetchActiveMatch() async throws -> MatchSummary? { nil }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { [] }
    func fetchHistoryWithParticipants(page _: Int, pageSize _: Int, filter _: MatchHistoryFilter) async throws -> [MatchHistoryRecord] { [] }
    func updateMatch(_: MatchSummary) async throws {}
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary {
        makeSummary(type: .mickeyMouse, status: .completed)
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

private actor MickeyMouseFakeStatsRepository: StatsRepository {
    func fetchEvents(matchId _: UUID) async throws -> [MatchEventSummary] { [] }
    func fetchEvents(matchIds _: [UUID]) async throws -> [MatchEventSummary] { [] }
}

private actor MickeyMouseRehydratingFakeMatchRepository: MatchRepository {
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
        makeSummary(type: .mickeyMouse, status: .completed)
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

private actor MickeyMouseRehydratingFakeStatsRepository: StatsRepository {
    let events: [MatchEventSummary]
    init(events: [MatchEventSummary]) { self.events = events }
    func fetchEvents(matchId _: UUID) async throws -> [MatchEventSummary] { events }
    func fetchEvents(matchIds _: [UUID]) async throws -> [MatchEventSummary] { events }
}
