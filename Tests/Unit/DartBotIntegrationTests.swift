import Foundation
import Testing
@testable import DartBuddy

// MARK: - Setup roster

@MainActor
@Test(.tags(.integration, .setupFlow, .match, .regression))
func setupAllowsHumanPlusBot() async {
    let players = [makeBotTestPlayer("Alice")]
    let store = ActiveMatchStore()
    let vm = botSetupViewModel(players: players, store: store)
    await vm.onAppear()
    vm.togglePlayer(players[0].id)
    await vm.addBot(.hard)

    #expect(vm.selectedParticipantCount == 2)
    #expect(vm.canStart)

    let route = await vm.startMatchRoute()
    guard case let .x01Match(matchId) = route else {
        Issue.record("Expected x01 route")
        return
    }

    let session = store.session(for: matchId)
    #expect(session?.runtime.participants.count == 2)
    #expect(session?.runtime.participants.filter(\.isBot).count == 1)
    #expect(session?.runtime.participants.first(where: \.isBot)?.botDifficulty == .hard)
}

@MainActor
@Test(.tags(.integration, .setupFlow, .match, .regression))
func setupRejectsTwoBotsWithoutHumans() async {
    let vm = botSetupViewModel(players: [], store: ActiveMatchStore())
    await vm.onAppear()
    await vm.addBot(.easy)
    await vm.addBot(.medium)

    #expect(vm.selectedParticipantCount == 2)
    #expect(vm.canStart == false)
    #expect(vm.validationErrors.contains("setup.validation.requiresHuman"))
}

@MainActor
@Test(.tags(.integration, .setupFlow, .match, .regression))
func setupRejectsSingleBot() async {
    let vm = botSetupViewModel(players: [], store: ActiveMatchStore())
    await vm.onAppear()
    await vm.addBot(.easy)
    vm.revalidate()

    // Solo X01 is allowed, but a lone bot still can't start without a human.
    #expect(!vm.canStart)
    #expect(vm.validationErrors.contains("setup.validation.requiresHuman"))
}

@MainActor
@Test(.tags(.integration, .setupFlow, .match, .regression))
func setupRemoveBotUpdatesValidation() async {
    let vm = botSetupViewModel(players: [], store: ActiveMatchStore())
    await vm.onAppear()
    await vm.addBot(.easy)
    await vm.addBot(.medium)
    let botId = vm.selectedPlayers[0].id

    vm.togglePlayer(botId)
    vm.revalidate()

    #expect(vm.selectedParticipantCount == 1)
    #expect(!vm.canStart)
}

// MARK: - Lifecycle

@Test(.tags(.unit, .match, .x01, .regression, .offline))
func lifecycleAcceptsBotGeneratedX01Turn() throws {
    let botId = UUID()
    let humanId = UUID()
    var session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(
            MatchConfigX01(
                startScore: 501,
                legsToWin: 1,
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

    let botPlayer = try #require(session.runtime.x01State?.players[0])
    var rng = BotTestSeededRNG(seed: 11)
    let darts = DartBotEngine.generateX01Turn(
        remaining: botPlayer.remainingScore,
        difficulty: .easy,
        checkoutMode: .doubleOut,
        checkInMode: .straightIn,
        isCheckedIn: botPlayer.isCheckedIn,
        rng: &rng
    )

    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: nil, darts: darts)

    #expect(session.events.count == 1)
    #expect(session.runtime.x01State?.currentPlayerIndex == 1)
    if case let .x01Turn(event) = session.events[0].payload {
        #expect(event.playerId == botId)
        #expect(!event.darts.isEmpty)
    } else {
        Issue.record("Expected x01 turn event")
    }
}

@Test(.tags(.unit, .match, .cricket, .regression, .offline))
func lifecycleAcceptsBotGeneratedCricketTurn() throws {
    let botId = UUID()
    let humanId = UUID()
    var session = try MatchLifecycleService.createMatch(
        type: .cricket,
        config: .cricket(MatchConfigCricket()),
        participants: [
            MatchParticipant(
                playerId: botId,
                displayNameAtMatchStart: BotDifficulty.medium.rosterName,
                turnOrder: 0,
                botDifficultyRaw: BotDifficulty.medium.rawValue
            ),
            MatchParticipant(
                playerId: humanId,
                displayNameAtMatchStart: "Human",
                turnOrder: 1
            )
        ]
    )

    let cricketState = try #require(session.runtime.cricketState)
    var rng = BotTestSeededRNG(seed: 3)
    let darts = DartBotEngine.generateCricketTurn(
        state: cricketState,
        playerIndex: 0,
        difficulty: .medium,
        rng: &rng
    )

    session = try MatchLifecycleService.submitCricketTurn(session: session, darts: darts)

    #expect(session.events.count == 1)
    #expect(session.runtime.cricketState?.currentPlayerIndex == 1)
}

@Test(.tags(.unit, .match, .cricket, .regression, .offline))
func lifecycleAcceptsBotGeneratedCutThroatCricketTurn() throws {
    let botId = UUID()
    let humanId = UUID()
    var session = try MatchLifecycleService.createMatch(
        type: .cricket,
        config: .cricket(cricketConfig(scoringMode: .cutThroat)),
        participants: [
            MatchParticipant(
                playerId: botId,
                displayNameAtMatchStart: BotDifficulty.medium.rosterName,
                turnOrder: 0,
                botDifficultyRaw: BotDifficulty.medium.rawValue
            ),
            MatchParticipant(
                playerId: humanId,
                displayNameAtMatchStart: "Human",
                turnOrder: 1
            )
        ]
    )

    let cricketState = try #require(session.runtime.cricketState)
    var rng = BotTestSeededRNG(seed: 3)
    let darts = DartBotEngine.generateCricketTurn(
        state: cricketState,
        playerIndex: 0,
        difficulty: .medium,
        rng: &rng
    )

    session = try MatchLifecycleService.submitCricketTurn(session: session, darts: darts)

    #expect(session.events.count == 1)
    #expect(session.runtime.cricketState?.currentPlayerIndex == 1)
    #expect(session.runtime.cricketState?.config.scoringMode == .cutThroat)
}

@Test(.tags(.unit, .match, .regression, .offline))
func lifecycleRehydratePreservesBotMetadata() throws {
    let botId = UUID()
    let humanId = UUID()
    let participants = [
        MatchParticipant(
            playerId: botId,
            displayNameAtMatchStart: BotDifficulty.hard.rosterName,
            turnOrder: 0,
            botDifficultyRaw: BotDifficulty.hard.rawValue
        ),
        MatchParticipant(
            playerId: humanId,
            displayNameAtMatchStart: "Human",
            turnOrder: 1
        )
    ]
    var session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(
            MatchConfigX01(
                startScore: 301,
                legsToWin: 1,
                setsEnabled: false,
                setsToWin: nil,
                checkoutMode: .singleOut
            )
        ),
        participants: participants
    )
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 60, darts: nil)
    let snapshot = session.latestSnapshot

    let rehydrated = try MatchLifecycleService.rehydrate(snapshot: snapshot, tailEvents: [])
    let bot = rehydrated.runtime.participants.first(where: \.isBot)

    #expect(bot?.botDifficulty == .hard)
    #expect(DartBotEngine.botDifficulty(playerId: botId, in: rehydrated.runtime.participants) == .hard)
}

// MARK: - View models

@MainActor
@Test(.tags(.integration, .x01, .match, .regression))
func x01ViewModelDetectsActiveBotTurn() throws {
    let humanId = UUID()
    let botId = UUID()
    let session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(
            MatchConfigX01(
                startScore: 501,
                legsToWin: 1,
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
    let vm = makeX01BotIntegrationViewModel(
        matchId: session.runtime.matchId,
        store: store
    )

    #expect(vm.isCurrentPlayerBot)
    #expect(vm.currentBotSkillProfile != nil)
    #expect(!vm.canHumanInput)
}

@MainActor
@Test(.tags(.integration, .x01, .match, .critical, .regression))
func x01ViewModelPlaysConsecutiveBotsAfterHumanTurn() async throws {
    let humanId = UUID()
    let bot1Id = UUID()
    let bot2Id = UUID()
    let session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(
            MatchConfigX01(
                startScore: 501,
                legsToWin: 1,
                setsEnabled: false,
                setsToWin: nil,
                checkoutMode: .singleOut
            )
        ),
        participants: [
            MatchParticipant(playerId: humanId, displayNameAtMatchStart: "Human", turnOrder: 0),
            MatchParticipant(
                playerId: bot1Id,
                displayNameAtMatchStart: BotDifficulty.veryEasy.rosterName,
                turnOrder: 1,
                botDifficultyRaw: BotDifficulty.veryEasy.rawValue
            ),
            MatchParticipant(
                playerId: bot2Id,
                displayNameAtMatchStart: BotDifficulty.easy.rosterName,
                turnOrder: 2,
                botDifficultyRaw: BotDifficulty.easy.rawValue
            )
        ]
    )
    let store = ActiveMatchStore()
    store.save(session)
    let prefs = FeedbackPreferences()
    prefs.botStaggerEnabled = false
    let vm = X01MatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink()),
        matchRepository: FakeMatchRepositoryBuilder.botIntegration(),
        statsRepository: FakeStatsRepositoryBuilder.empty(),
        feedbackPreferences: prefs
    )
    vm.inputMode = .totalEntry
    vm.totalEntryText = "60"

    await vm.submitTurn()
    try await waitForX01EventCount(3, on: vm)

    #expect(vm.session?.events.count == 3)
    #expect(vm.isCurrentPlayerBot == false)
    #expect(vm.canHumanInput)
    #expect(!vm.isBotPlaying)
    #expect(vm.x01State?.currentPlayerIndex == 0)
}

@MainActor
@Test(.tags(.integration, .x01, .match, .regression))
func x01ViewModelBotTurnSubmitsVisit() async throws {
    let humanId = UUID()
    let botId = UUID()
    let session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(
            MatchConfigX01(
                startScore: 501,
                legsToWin: 1,
                setsEnabled: false,
                setsToWin: nil,
                checkoutMode: .doubleOut
            )
        ),
        participants: [
            MatchParticipant(
                playerId: botId,
                displayNameAtMatchStart: BotDifficulty.medium.rosterName,
                turnOrder: 0,
                botDifficultyRaw: BotDifficulty.medium.rawValue
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
    let vm = makeX01BotIntegrationViewModel(
        matchId: session.runtime.matchId,
        store: store
    )

    await vm.playBotTurnIfNeeded()

    #expect(vm.session?.events.count == 1)
    #expect(vm.isCurrentPlayerBot == false)
    #expect(vm.canHumanInput)
    #expect(vm.enteredDarts.isEmpty)

    let botCard = try #require(vm.playerCards.first { $0.id == botId })
    let botEvent = try #require(vm.session?.events.first.flatMap { envelope -> X01TurnEvent? in
        guard case let .x01Turn(event) = envelope.payload else { return nil }
        return event
    })
    #expect(botCard.dartsThrown == botEvent.effectiveDartsThrown)
}

@MainActor
@Test(.tags(.integration, .x01, .match, .regression))
func x01ViewModelCountsBotVisitDartsWhileBotIsActive() async throws {
    let humanId = UUID()
    let botId = UUID()
    let session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(
            MatchConfigX01(
                startScore: 501,
                legsToWin: 1,
                setsEnabled: false,
                setsToWin: nil,
                checkoutMode: .doubleOut
            )
        ),
        participants: [
            MatchParticipant(
                playerId: botId,
                displayNameAtMatchStart: BotDifficulty.medium.rosterName,
                turnOrder: 0,
                botDifficultyRaw: BotDifficulty.medium.rawValue
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
    let vm = makeX01BotIntegrationViewModel(
        matchId: session.runtime.matchId,
        store: store
    )
    vm.inputMode = .dartEntry
    vm.enteredDarts = [
        DartInput(multiplier: .triple, segment: .oneToTwenty(20)),
        DartInput(multiplier: .single, segment: .oneToTwenty(20))
    ]

    let botCard = try #require(vm.playerCards.first { $0.id == botId })
    #expect(vm.isCurrentPlayerBot)
    #expect(!vm.isBotPlaying)
    #expect(botCard.dartsThrown == 2)
}

@MainActor
@Test(.tags(.integration, .x01, .match, .regression))
func x01ViewModelSignalsTurnTotalCallerForBotVisit() async throws {
    let humanId = UUID()
    let botId = UUID()
    let session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(
            MatchConfigX01(
                startScore: 501,
                legsToWin: 1,
                setsEnabled: false,
                setsToWin: nil,
                checkoutMode: .doubleOut
            )
        ),
        participants: [
            MatchParticipant(
                playerId: botId,
                displayNameAtMatchStart: BotDifficulty.medium.rosterName,
                turnOrder: 0,
                botDifficultyRaw: BotDifficulty.medium.rawValue
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
    let vm = makeX01BotIntegrationViewModel(
        matchId: session.runtime.matchId,
        store: store
    )

    await vm.playBotTurnIfNeeded()

    guard case let .x01Turn(event) = vm.session?.events.last?.payload else {
        Issue.record("Expected x01 turn event")
        return
    }
    #expect(vm.turnTotalCallerSignal?.total == event.appliedTotal)
}

@MainActor
@Test(.tags(.integration, .x01, .match, .regression))
func x01OnAppearRestartsBotAfterInterruptedTurn() async throws {
    let humanId = UUID()
    let botId = UUID()
    let session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(
            MatchConfigX01(
                startScore: 501,
                legsToWin: 1,
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
    let prefs = FeedbackPreferences()
    prefs.botStaggerEnabled = true
    let vm = X01MatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink()),
        matchRepository: FakeMatchRepositoryBuilder.botIntegration(),
        statsRepository: FakeStatsRepositoryBuilder.empty(),
        feedbackPreferences: prefs
    )

    let interrupted = Task { await vm.playBotTurnIfNeeded() }
    try await Task.sleep(nanoseconds: 30_000_000)
    interrupted.cancel()
    _ = await interrupted.result

    #expect(vm.session?.events.count == 0)
    #expect(!vm.isBotPlaying)

    await vm.onAppear()
    try await waitForX01EventCount(1, on: vm)

    #expect(vm.session?.events.count == 1)
    #expect(!vm.isBotPlaying)
    #expect(vm.canHumanInput)
}

@MainActor
@Test(.tags(.integration, .x01, .match, .regression))
func x01DisappearAndReappearRestartsBotAfterInterruptedTurn() async throws {
    let humanId = UUID()
    let botId = UUID()
    let session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(
            MatchConfigX01(
                startScore: 501,
                legsToWin: 1,
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
    let prefs = FeedbackPreferences()
    prefs.botStaggerEnabled = false
    let vm = X01MatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink()),
        matchRepository: FakeMatchRepositoryBuilder.botIntegration(),
        statsRepository: FakeStatsRepositoryBuilder.empty(),
        feedbackPreferences: prefs
    )

    await vm.onAppear()
    vm.onDisappear()
    await vm.onAppear()
    try await waitForX01EventCount(1, on: vm)

    #expect(vm.session?.events.count == 1)
    #expect(!vm.isBotPlaying)
    #expect(vm.canHumanInput)
}

@MainActor
@Test(.tags(.integration, .x01, .match, .regression))
func x01RecoverBotPlaybackRestartsAfterExitAlertDismissedWithStay() async throws {
    let humanId = UUID()
    let botId = UUID()
    let session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(
            MatchConfigX01(
                startScore: 501,
                legsToWin: 1,
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
    let prefs = FeedbackPreferences()
    prefs.botStaggerEnabled = false
    let vm = X01MatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink()),
        matchRepository: FakeMatchRepositoryBuilder.botIntegration(),
        statsRepository: FakeStatsRepositoryBuilder.empty(),
        feedbackPreferences: prefs
    )

    await vm.onAppear()
    vm.onDisappear()
    #expect(vm.isCurrentPlayerBot)
    #expect(!vm.isBotPlaying)

    vm.recoverBotPlaybackIfNeeded()
    try await waitForX01EventCount(1, on: vm)

    #expect(vm.session?.events.count == 1)
    #expect(!vm.isBotPlaying)
    #expect(vm.canHumanInput)
}

@MainActor
private func waitForX01EventCount(
    _ count: Int,
    on vm: X01MatchViewModel,
    expectedState: X01MatchViewModel.State? = nil,
    timeoutNanoseconds: UInt64 = 25_000_000,
    maxAttempts: Int = 400
) async throws {
    for _ in 0 ..< maxAttempts {
        let stateMatches = expectedState.map { vm.state == $0 } ?? true
        if vm.session?.events.count == count, vm.isBotPlaying == false, stateMatches {
            return
        }
        await Task.yield()
        try await Task.sleep(nanoseconds: timeoutNanoseconds)
    }
    Issue.record(
        "Timed out waiting for \(count) X01 events (got \(vm.session?.events.count ?? -1), botPlaying: \(vm.isBotPlaying), state: \(vm.state))."
    )
}

@MainActor
private func waitForX01BotPlaybackToSettle(on vm: X01MatchViewModel) async throws {
    for _ in 0 ..< 140 {
        if vm.isBotPlaying == false, vm.enteredDarts.isEmpty {
            return
        }
        try await Task.sleep(nanoseconds: 25_000_000)
    }
    Issue.record("Timed out waiting for bot playback to settle.")
}

@MainActor
@Test(.tags(.integration, .x01, .match, .regression))
func x01UndoLastDartStepsThroughRestoredBotDartsBeforePreviousTurn() async throws {
    let humanId = UUID()
    let botId = UUID()
    let session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(
            MatchConfigX01(
                startScore: 501,
                legsToWin: 1,
                setsEnabled: false,
                setsToWin: nil,
                checkoutMode: .doubleOut
            )
        ),
        participants: [
            MatchParticipant(playerId: humanId, displayNameAtMatchStart: "Human", turnOrder: 0),
            MatchParticipant(
                playerId: botId,
                displayNameAtMatchStart: BotDifficulty.easy.rosterName,
                turnOrder: 1,
                botDifficultyRaw: BotDifficulty.easy.rawValue
            )
        ]
    )
    let store = ActiveMatchStore()
    store.save(session)
    let prefs = FeedbackPreferences()
    prefs.botStaggerEnabled = false
    let vm = X01MatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink()),
        matchRepository: FakeMatchRepositoryBuilder.botIntegration(),
        statsRepository: FakeStatsRepositoryBuilder.empty(),
        feedbackPreferences: prefs
    )
    vm.inputMode = .dartEntry
    vm.enteredDarts = [
        DartInput(multiplier: .triple, segment: .oneToTwenty(20)),
        DartInput(multiplier: .triple, segment: .oneToTwenty(20)),
        DartInput(multiplier: .triple, segment: .oneToTwenty(20))
    ]
    await vm.submitTurn()
    try await waitForX01EventCount(2, on: vm)
    #expect(vm.session?.events.count == 2)

    await vm.undoLastDart()
    try await waitForX01EventCount(2, on: vm)

    #expect(vm.session?.events.count == 2)
    #expect(!vm.isCurrentPlayerBot)
    #expect(vm.enteredDarts.isEmpty)
}

@MainActor
@Test(.tags(.integration, .x01, .match, .regression))
func x01UndoDuringActiveBotPlaybackCompletesVisit() async throws {
    let humanId = UUID()
    let botId = UUID()
    let session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(
            MatchConfigX01(
                startScore: 501,
                legsToWin: 1,
                setsEnabled: false,
                setsToWin: nil,
                checkoutMode: .doubleOut
            )
        ),
        participants: [
            MatchParticipant(playerId: humanId, displayNameAtMatchStart: "Human", turnOrder: 0),
            MatchParticipant(
                playerId: botId,
                displayNameAtMatchStart: BotDifficulty.easy.rosterName,
                turnOrder: 1,
                botDifficultyRaw: BotDifficulty.easy.rawValue
            )
        ]
    )
    let store = ActiveMatchStore()
    store.save(session)
    let prefs = FeedbackPreferences()
    prefs.botStaggerEnabled = false
    let vm = X01MatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink()),
        matchRepository: FakeMatchRepositoryBuilder.botIntegration(),
        statsRepository: FakeStatsRepositoryBuilder.empty(),
        feedbackPreferences: prefs
    )
    vm.inputMode = .dartEntry
    vm.enteredDarts = [
        DartInput(multiplier: .single, segment: .oneToTwenty(20)),
        DartInput(multiplier: .single, segment: .oneToTwenty(20)),
        DartInput(multiplier: .single, segment: .oneToTwenty(20))
    ]
    let submitTask = Task { await vm.submitTurn() }

    for _ in 0 ..< 40 {
        if vm.isBotPlaying, vm.enteredDarts.count == 2 { break }
        try await Task.sleep(nanoseconds: 25_000_000)
    }
    #expect(vm.isBotPlaying)
    #expect(vm.enteredDarts.count == 2)

    await vm.undoLastDart()
    await submitTask.value
    try await waitForX01BotPlaybackToSettle(on: vm)

    #expect(!vm.isBotPlaying)
    #expect(vm.session?.events.count == 2)
    #expect(!vm.isCurrentPlayerBot)
    #expect(vm.enteredDarts.isEmpty)
}

@MainActor
@Test(.tags(.integration, .x01, .match, .regression))
func x01UndoBackToBotTurnRestartsBot() async throws {
    let humanId = UUID()
    let botId = UUID()
    let session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(
            MatchConfigX01(
                startScore: 501,
                legsToWin: 1,
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
    let vm = makeX01BotIntegrationViewModel(
        matchId: session.runtime.matchId,
        store: store
    )

    await vm.playBotTurnIfNeeded()
    #expect(vm.session?.events.count == 1)

    await vm.undoLastTurn()
    try await waitForX01EventCount(1, on: vm)

    #expect(vm.session?.events.count == 1)
    #expect(!vm.isBotPlaying)
    #expect(vm.isCurrentPlayerBot == false)
}

@MainActor
@Test(.tags(.integration, .x01, .match, .critical, .regression))
func x01ViewModelBotContinuesAfterHumanBust() async throws {
    let humanId = UUID()
    let botId = UUID()
    var session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(
            MatchConfigX01(
                startScore: 301,
                legsToWin: 1,
                setsEnabled: false,
                setsToWin: nil,
                checkoutMode: .singleOut
            )
        ),
        participants: [
            MatchParticipant(
                playerId: humanId,
                displayNameAtMatchStart: "Human",
                turnOrder: 0
            ),
            MatchParticipant(
                playerId: botId,
                displayNameAtMatchStart: BotDifficulty.easy.rosterName,
                turnOrder: 1,
                botDifficultyRaw: BotDifficulty.easy.rawValue
            )
        ]
    )
    for total in [180, 0, 81, 0] {
        session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: total, darts: nil)
    }
    let store = ActiveMatchStore()
    store.save(session)
    let vm = makeX01BotIntegrationViewModel(
        matchId: session.runtime.matchId,
        store: store
    )
    vm.inputMode = .totalEntry
    vm.totalEntryText = "50"

    await vm.submitTurn()
    try await waitForX01EventCount(6, on: vm, expectedState: .readyTurn)

    #expect(vm.session?.events.count == 6)
    #expect(vm.isCurrentPlayerBot == false)
    #expect(vm.state == .readyTurn)
}

@MainActor
@Test(.tags(.integration, .x01, .match, .critical, .regression))
func x01ViewModelHumanCanSubmitAfterBotBust() async throws {
    let humanId = UUID()
    let botId = UUID()
    var session = try MatchLifecycleService.createMatch(
        type: .x01,
        config: .x01(
            MatchConfigX01(
                startScore: 301,
                legsToWin: 1,
                setsEnabled: false,
                setsToWin: nil,
                checkoutMode: .singleOut
            )
        ),
        participants: [
            MatchParticipant(playerId: botId, displayNameAtMatchStart: BotDifficulty.easy.rosterName, turnOrder: 0, botDifficultyRaw: BotDifficulty.easy.rawValue),
            MatchParticipant(playerId: humanId, displayNameAtMatchStart: "Human", turnOrder: 1)
        ]
    )
    for total in [180, 0, 81, 0] {
        session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: total, darts: nil)
    }
    session = try MatchLifecycleService.submitX01Turn(session: session, enteredTotal: 50, darts: nil)
    let store = ActiveMatchStore()
    store.save(session)
    let vm = makeX01BotIntegrationViewModel(
        matchId: session.runtime.matchId,
        store: store
    )
    #expect(vm.isCurrentPlayerBot == false)
    #expect(vm.canHumanInput)
    #expect(vm.session?.events.count == 5)

    vm.inputMode = .totalEntry
    vm.totalEntryText = "60"
    await vm.submitTurn()
    try await waitForX01EventCount(7, on: vm, expectedState: .readyTurn)

    #expect(vm.state == .readyTurn)
    // Human visit plus auto bot reply when the turn passes back to the bot.
    #expect(vm.session?.events.count == 7)
}

@MainActor
@Test(.tags(.integration, .cricket, .match, .regression))
func cricketViewModelDetectsActiveBotTurn() throws {
    let humanId = UUID()
    let botId = UUID()
    let session = try MatchLifecycleService.createMatch(
        type: .cricket,
        config: .cricket(MatchConfigCricket()),
        participants: [
            MatchParticipant(
                playerId: botId,
                displayNameAtMatchStart: BotDifficulty.hard.rosterName,
                turnOrder: 0,
                botDifficultyRaw: BotDifficulty.hard.rawValue
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
    let vm = CricketMatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink()),
        matchRepository: FakeMatchRepositoryBuilder.botIntegration(),
        statsRepository: FakeStatsRepositoryBuilder.empty()
    )

    #expect(vm.isCurrentPlayerBot)
    #expect(vm.currentBotSkillProfile != nil)
    #expect(!vm.canHumanInput)
}

@MainActor
@Test(.tags(.integration, .cricket, .match, .regression))
func cricketViewModelSignalsTurnTotalCallerForBotVisit() async throws {
    let humanId = UUID()
    let botId = UUID()
    let session = try MatchLifecycleService.createMatch(
        type: .cricket,
        config: .cricket(MatchConfigCricket()),
        participants: [
            MatchParticipant(
                playerId: botId,
                displayNameAtMatchStart: BotDifficulty.hard.rosterName,
                turnOrder: 0,
                botDifficultyRaw: BotDifficulty.hard.rawValue
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
    let vm = CricketMatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink()),
        matchRepository: FakeMatchRepositoryBuilder.botIntegration(),
        statsRepository: FakeStatsRepositoryBuilder.empty()
    )

    await vm.playBotTurnIfNeeded()

    guard case let .cricketTurn(event) = vm.session?.events.last?.payload else {
        Issue.record("Expected cricket turn event")
        return
    }
    #expect(vm.turnTotalCallerSignal?.total == event.totalPointsAdded)
}

// MARK: - Test helpers

@MainActor
private func instantBotFeedbackPreferences() -> FeedbackPreferences {
    let prefs = FeedbackPreferences()
    prefs.botStaggerEnabled = false
    prefs.hapticsEnabled = false
    prefs.soundEnabled = false
    prefs.botDartHapticsEnabled = false
    return prefs
}

@MainActor
private func makeX01BotIntegrationViewModel(
    matchId: UUID,
    store: ActiveMatchStore,
    feedbackPreferences: FeedbackPreferences? = nil
) -> X01MatchViewModel {
    X01MatchViewModel(
        matchId: matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: TestNoopLogSink()),
        matchRepository: FakeMatchRepositoryBuilder.botIntegration(),
        statsRepository: FakeStatsRepositoryBuilder.empty(),
        feedbackPreferences: feedbackPreferences ?? instantBotFeedbackPreferences()
    )
}

private func makeBotTestPlayer(_ name: String) -> PlayerSummary {
    PlayerSummary(id: UUID(), name: name, isArchived: false, createdAt: Date(), updatedAt: Date())
}

@MainActor
private func botSetupViewModel(players: [PlayerSummary], store: ActiveMatchStore) -> MatchSetupViewModel {
    MatchSetupViewModel(
        playerRepository: FakePlayerRepositoryBuilder.botIntegration(players: players),
        settingsRepository: FakeSettingsRepository(),
        matchRepository: FakeMatchRepositoryBuilder.botSetupCapturing(),
        activeMatchStore: store,
        pendingMatchPlayerSelections: PendingMatchPlayerSelections()
    )
}

private struct BotTestSeededRNG: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0xDEADBEEF : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}
