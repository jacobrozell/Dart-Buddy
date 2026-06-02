import Foundation
import Testing
@testable import DartsScoreboard

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
func setupAllowsTwoBotsWithoutHumans() async {
    let vm = botSetupViewModel(players: [], store: ActiveMatchStore())
    await vm.onAppear()
    await vm.addBot(.easy)
    await vm.addBot(.medium)

    #expect(vm.selectedParticipantCount == 2)
    #expect(vm.canStart)
    #expect(vm.validationErrors.isEmpty)
}

@MainActor
@Test(.tags(.integration, .setupFlow, .match, .regression))
func setupRejectsSingleBot() async {
    let vm = botSetupViewModel(players: [], store: ActiveMatchStore())
    await vm.onAppear()
    await vm.addBot(.easy)
    vm.revalidate()

    #expect(!vm.canStart)
    #expect(vm.validationErrors.contains("setup.validation.minimumPlayers"))
}

@MainActor
@Test(.tags(.integration, .setupFlow, .match, .regression))
func setupRemoveBotUpdatesValidation() async {
    let vm = botSetupViewModel(players: [], store: ActiveMatchStore())
    await vm.onAppear()
    await vm.addBot(.easy)
    await vm.addBot(.medium)
    let botId = vm.availableBots[0].id

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
    let vm = X01MatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: BotSilentLogSink()),
        matchRepository: BotFakeMatchRepository(),
        statsRepository: BotFakeStatsRepository()
    )

    #expect(vm.isCurrentPlayerBot)
    #expect(vm.currentBotDifficulty == .easy)
    #expect(!vm.canHumanInput)
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
    let vm = X01MatchViewModel(
        matchId: session.runtime.matchId,
        store: store,
        logger: DefaultAppLogger(minimumLevel: .fault, sink: BotSilentLogSink()),
        matchRepository: BotFakeMatchRepository(),
        statsRepository: BotFakeStatsRepository()
    )

    await vm.playBotTurnIfNeeded()

    #expect(vm.session?.events.count == 1)
    #expect(vm.isCurrentPlayerBot == false)
    #expect(vm.canHumanInput)
    #expect(vm.enteredDarts.isEmpty)
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
        logger: DefaultAppLogger(minimumLevel: .fault, sink: BotSilentLogSink()),
        matchRepository: BotFakeMatchRepository(),
        statsRepository: BotFakeStatsRepository()
    )

    #expect(vm.isCurrentPlayerBot)
    #expect(vm.currentBotDifficulty == .hard)
    #expect(!vm.canHumanInput)
}

// MARK: - Test helpers

private func makeBotTestPlayer(_ name: String) -> PlayerSummary {
    PlayerSummary(id: UUID(), name: name, isArchived: false, createdAt: Date(), updatedAt: Date())
}

@MainActor
private func botSetupViewModel(players: [PlayerSummary], store: ActiveMatchStore) -> MatchSetupViewModel {
    MatchSetupViewModel(
        playerRepository: BotFakePlayerRepository(players: players),
        settingsRepository: BotFakeSettingsRepository(),
        matchRepository: BotCapturingMatchRepository(store: store),
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

private final class BotSilentLogSink: LogSink, @unchecked Sendable {
    func write(_: LogEntry) {}
}

private actor BotFakePlayerRepository: PlayerRepository {
    private var players: [PlayerSummary]
    init(players: [PlayerSummary]) { self.players = players }
    func fetchPlayers(includeArchived _: Bool) async throws -> [PlayerSummary] { players }
    func createPlayer(name _: String) async throws -> PlayerSummary { players[0] }
    func createBot(difficulty: BotDifficulty) async throws -> PlayerSummary {
        let name = BotNaming.nextDefaultName(difficulty: difficulty, existingNames: players.map(\.name))
        let bot = PlayerSummary(
            id: UUID(),
            name: name,
            isArchived: false,
            isBot: true,
            botDifficultyRaw: difficulty.rawValue,
            createdAt: Date(),
            updatedAt: Date()
        )
        players.append(bot)
        return bot
    }
    func updatePlayerName(playerId _: UUID, name _: String) async throws -> PlayerSummary { players[0] }
    func archivePlayer(playerId _: UUID) async throws {}
    func unarchivePlayer(playerId _: UUID) async throws {}
    func deletePlayer(playerId _: UUID) async throws {}
}

private actor BotFakeSettingsRepository: SettingsRepository {
    func fetchSettings() async throws -> SettingsSummary { settings }
    func seedDefaultsIfNeeded() async throws -> SettingsSummary { settings }
    func updateSettings(_ settings: SettingsSummary) async throws -> SettingsSummary { settings }
    func resetPreferencesToDefaults() async throws {}
    func resetAllLocalData() async throws {}

    private let settings = SettingsSummary(
        id: UUID(),
        appearanceModeRaw: "system",
        hapticsEnabled: true,
        soundEnabled: true,
        defaultMatchTypeRaw: "x01",
        defaultX01StartScore: 501,
        defaultCheckoutModeRaw: "doubleOut",
        defaultCheckInModeRaw: "straightIn",
        defaultLegFormatRaw: "firstTo",
        defaultLegsToWin: 3,
        defaultSetsEnabled: false,
        updatedAt: Date()
    )
}

private actor BotCapturingMatchRepository: MatchRepository {
    let store: ActiveMatchStore

    init(store: ActiveMatchStore) { self.store = store }

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
    func fetchHistoryWithParticipants(page _: Int, pageSize _: Int) async throws -> [MatchHistoryRecord] { [] }
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

private actor BotFakeMatchRepository: MatchRepository {
    func createMatch(type: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary {
        MatchSummary(
            id: UUID(), type: type, status: .inProgress, startedAt: Date(), endedAt: nil,
            winnerPlayerId: nil, currentTurnPlayerId: nil, currentLegIndex: 0, currentSetIndex: 0,
            eventCount: 0, createdAt: Date(), updatedAt: Date()
        )
    }
    func fetchActiveMatch() async throws -> MatchSummary? { nil }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { [] }
    func fetchHistoryWithParticipants(page _: Int, pageSize _: Int) async throws -> [MatchHistoryRecord] { [] }
    func updateMatch(_: MatchSummary) async throws {}
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary {
        MatchSummary(
            id: UUID(), type: .x01, status: .completed, startedAt: Date(), endedAt: Date(),
            winnerPlayerId: nil, currentTurnPlayerId: nil, currentLegIndex: 0, currentSetIndex: 0,
            eventCount: 1, createdAt: Date(), updatedAt: Date()
        )
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

private actor BotFakeStatsRepository: StatsRepository {
    func fetchEvents(matchId _: UUID) async throws -> [MatchEventSummary] { [] }
}
