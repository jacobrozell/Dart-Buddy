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
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink()),
        matchRepository: FakeMatchRepositoryBuilder.matchViewModel(completedType: .x01),
        statsRepository: FakeStatsRepository(),
        feedbackPreferences: feedbackPreferences
    )
    return (vm, store)
}

@MainActor
@Test(.tags(.integration, .x01, .match, .regression))
func x01BotTurnCompletesWithAndWithoutStagger() async throws {
    let fastPrefs = FeedbackPreferences()
    fastPrefs.botStaggerEnabled = false
    let (fastVM, _) = try makeBotFirstX01ViewModel(feedbackPreferences: fastPrefs)
    await fastVM.playBotTurnIfNeeded()
    #expect(fastVM.session?.events.count == 1)

    let staggeredPrefs = FeedbackPreferences()
    staggeredPrefs.botStaggerEnabled = true
    let (staggeredVM, _) = try makeBotFirstX01ViewModel(feedbackPreferences: staggeredPrefs)
    await staggeredVM.playBotTurnIfNeeded()
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
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink()),
        matchRepository: FakeMatchRepositoryBuilder.matchViewModel(completedType: .x01),
        statsRepository: FakeStatsRepository()
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
