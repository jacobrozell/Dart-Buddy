import Foundation
import Testing
@testable import DartBuddy

// MARK: - Bot pacing (X01)

@MainActor
private func makeBotFirstX01ViewModel(
    feedbackPreferences: FeedbackPreferences = FeedbackPreferences()
) throws -> (vm: X01MatchViewModel, store: ActiveMatchStore) {
    let humanId = UUID()
    let botId = UUID()
    let session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(
            MatchConfigX01(
                startScore: 501,
                legsToWin: 3,
                setsEnabled: false,
                setsToWin: nil,
                checkoutMode: .doubleOut
            )
        ),
        participants: [
            MatchParticipant(
                playerId: botId,
                displayNameAtMatchStart: BotDifficulty.easy.rosterName,
                turnOrder: 0,
                botDifficultyRaw: BotDifficulty.easy.rawValue
            ),
            MatchParticipant(
                playerId: humanId,
                displayNameAtMatchStart: "Human",
                turnOrder: 1
            )
        ]
    )
    let store = ActiveMatchStore()
    store.save(session)
    let vm = X01MatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: PolishSilentLogSink()),
        matchRepository: PolishFakeMatchRepository(),
        statsRepository: PolishFakeStatsRepository(),
        feedbackPreferences: feedbackPreferences
    )
    return (vm, store)
}

@MainActor
@Test(.tags(.integration, .x01, .match, .regression))
func x01BotTurnCompletesFasterWhenStaggerDisabled() async throws {
    let fastPrefs = FeedbackPreferences()
    fastPrefs.botStaggerEnabled = false
    let (fastVM, _) = try makeBotFirstX01ViewModel(feedbackPreferences: fastPrefs)

    let fastStart = ContinuousClock.now
    await fastVM.playBotTurnIfNeeded()
    let fastElapsed = fastStart.duration(to: ContinuousClock.now)

    let staggeredPrefs = FeedbackPreferences()
    staggeredPrefs.botStaggerEnabled = true
    let (staggeredVM, _) = try makeBotFirstX01ViewModel(feedbackPreferences: staggeredPrefs)

    let staggeredStart = ContinuousClock.now
    await staggeredVM.playBotTurnIfNeeded()
    let staggeredElapsed = staggeredStart.duration(to: ContinuousClock.now)

    #expect(fastElapsed < staggeredElapsed)
    #expect(fastVM.session?.events.count == 1)
    #expect(staggeredVM.session?.events.count == 1)
}

@MainActor
@Test(.tags(.integration, .x01, .match, .regression))
func x01BotTurnRevealsThreeDartsBeforeSubmit() async throws {
    let prefs = FeedbackPreferences()
    prefs.botStaggerEnabled = false
    let (vm, _) = try makeBotFirstX01ViewModel(feedbackPreferences: prefs)

    let playTask = Task { await vm.playBotTurnIfNeeded() }

    var sawPartialVisit = false
    for _ in 0 ..< 40 {
        if vm.isBotPlaying, (1 ... 2).contains(vm.enteredDarts.count) {
            sawPartialVisit = true
            break
        }
        try await Task.sleep(nanoseconds: 25_000_000)
    }

    await playTask.value
    #expect(sawPartialVisit)
    #expect(vm.enteredDarts.isEmpty)
}

// MARK: - Cricket closure highlight

private func triple(_ value: Int) -> DartInput {
    DartInput(multiplier: .triple, segment: .oneToTwenty(value))
}

@MainActor
private func makeCricketViewModelForPolish(
    preTurns: [[DartInput]] = []
) throws -> (vm: CricketMatchViewModel, store: ActiveMatchStore) {
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
    for darts in preTurns {
        session = try MatchLifecycleService.submitCricketTurn(session: session, darts: darts)
    }
    let store = ActiveMatchStore()
    store.save(session)
    let vm = CricketMatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: PolishSilentLogSink()),
        matchRepository: PolishFakeMatchRepository(),
        statsRepository: PolishFakeStatsRepository()
    )
    return (vm, store)
}

@MainActor
@Test(.tags(.integration, .cricket, .match, .regression))
func cricketBoardHighlightsColumnDuringClosureTransition() async throws {
    let (vm, _) = try makeCricketViewModelForPolish()
    vm.enteredDarts = [triple(20)]

    let submitTask = Task { await vm.submitTurn() }

    var highlightedDuringClosure = false
    for _ in 0 ..< 60 {
        if vm.state == .closureTransition {
            let highlighted = vm.boardColumns.filter(\.isClosureHighlight)
            if highlighted.count == 1 {
                highlightedDuringClosure = true
                break
            }
        }
        try await Task.sleep(nanoseconds: 20_000_000)
    }

    await submitTask.value

    #expect(highlightedDuringClosure)
    #expect(vm.state == .readyTurn)
    #expect(vm.boardColumns.allSatisfy { !$0.isClosureHighlight })
}

@MainActor
@Test(.tags(.integration, .cricket, .match, .regression))
func cricketViewModelObservesClosureTransitionDuringSubmit() async throws {
    let (vm, _) = try makeCricketViewModelForPolish()
    vm.enteredDarts = [triple(20)]

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

    #expect(sawClosure)
    #expect(vm.state == .readyTurn)
}

// MARK: - Fakes

private final class PolishSilentLogSink: LogSink, @unchecked Sendable {
    func write(_: LogEntry) {}
}

private actor PolishFakeStatsRepository: StatsRepository {
    func fetchEvents(matchId _: UUID) async throws -> [MatchEventSummary] { [] }
    func fetchEvents(matchIds _: [UUID]) async throws -> [MatchEventSummary] { [] }
}

private actor PolishFakeMatchRepository: MatchRepository {
    func createMatch(type: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary {
        MatchSummary(
            id: UUID(),
            type: type,
            status: .inProgress,
            startedAt: Date(),
            endedAt: nil,
            winnerPlayerId: nil,
            currentTurnPlayerId: nil,
            currentLegIndex: 0,
            currentSetIndex: 0,
            eventCount: 0,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    func fetchActiveMatch() async throws -> MatchSummary? { nil }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { [] }
    func fetchHistoryWithParticipants(page _: Int, pageSize _: Int, filter _: MatchHistoryFilter) async throws -> [MatchHistoryRecord] { [] }
    func updateMatch(_: MatchSummary) async throws {}
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary {
        throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented")
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
