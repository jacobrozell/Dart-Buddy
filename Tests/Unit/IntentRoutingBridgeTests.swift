import Foundation
import Testing
@testable import DartBuddy

@Suite("Intent routing bridge", .tags(.unit, .navigation, .regression))
@MainActor
struct IntentRoutingBridgeTests {
    @Test
    func routesDirectlyWhenConfigured() async throws {
        defer { resetBridge() }
        let pending = PendingAppDestination()
        let state = IntentRouteTestState(selectedTab: .settings)
        let dependencies = try makeDependencies()
        enableAppIntents()
        IntentRoutingBridge.setPendingDeepLink(pending)
        IntentRoutingBridge.configure(dependencies: dependencies, actions: state.makeActions())

        let outcome = await IntentRoutingBridge.route(.play(.home), intentName: OpenPlayIntent.intentName)

        #expect(outcome == .applied)
        #expect(state.selectedTab == .play)
        #expect(state.resetCount == 1)
        #expect(!pending.hasPending)
    }

    @Test
    func enqueuesWhenRouteActionsMissing() async throws {
        defer { resetBridge() }
        let pending = PendingAppDestination()
        enableAppIntents()
        IntentRoutingBridge.setPendingDeepLink(pending)
        IntentRoutingBridge.clearRouteActions()

        let outcome = await IntentRoutingBridge.route(
            .play(.resumeActive),
            intentName: ResumeActiveMatchIntent.intentName
        )

        #expect(outcome == .applied)
        #expect(pending.hasPending)
    }

    @Test
    func disabledFlagSkipsRouting() async throws {
        defer { resetBridge() }
        let state = IntentRouteTestState(selectedTab: .play)
        let dependencies = try makeDependencies()
        IntentRoutingBridge.featureFlagOverrides = [.enableAppIntents: false]
        IntentRoutingBridge.configure(dependencies: dependencies, actions: state.makeActions())

        let outcome = await IntentRoutingBridge.route(.play(.home), intentName: OpenPlayIntent.intentName)

        #expect(outcome == .failed(.unknownPath))
        #expect(state.resetCount == 0)
    }

    @Test
    func fetchActiveMatchUsesConfiguredDependencies() async throws {
        defer { resetBridge() }
        let activeMatch = makeMatchSummary()
        let dependencies = try makeDependencies(activeMatch: activeMatch)
        IntentRoutingBridge.configure(
            dependencies: dependencies,
            actions: IntentRouteTestState(selectedTab: .play).makeActions()
        )

        let fetched = await IntentRoutingBridge.fetchActiveMatch()

        #expect(fetched?.id == activeMatch.id)
    }

    private func enableAppIntents() {
        IntentRoutingBridge.featureFlagOverrides = [.enableAppIntents: true]
    }

    private func resetBridge() {
        IntentRoutingBridge.featureFlagOverrides = [:]
        IntentRoutingBridge.clearRouteActions()
    }

    private func makeDependencies(activeMatch: MatchSummary? = nil) throws -> AppDependencies {
        AppDependencies(
            modelContainer: try ModelContainerFactory.makeContainer(mode: .inMemory),
            logger: DefaultAppLogger(minimumLevel: .fault, sink: RecordingIntentSink()),
            playerRepository: FakeIntentPlayerRepository(),
            matchRepository: FakeIntentMatchRepository(activeMatch: activeMatch),
            statsRepository: FakeIntentStatsRepository(),
            settingsRepository: FakeIntentSettingsRepository(),
            hapticsService: NoopHapticsService(),
            audioFeedbackService: NoopAudioFeedbackService(),
            turnTotalCallerService: NoopTurnTotalCallerService(),
            userPreferencesStore: UserPreferencesStore(),
            activeMatchStore: ActiveMatchStore(),
            pendingMatchPlayerSelections: PendingMatchPlayerSelections()
        )
    }

    private func makeMatchSummary() -> MatchSummary {
        MatchSummary(
            id: UUID(),
            type: .x01,
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
}

@MainActor
private final class IntentRouteTestState {
    var selectedTab: MainTabView.RootTab
    var resetCount = 0

    init(selectedTab: MainTabView.RootTab) {
        self.selectedTab = selectedTab
    }

    func makeActions() -> AppRouteRouter.Actions {
        AppRouteRouter.Actions(
            setSelectedTab: { [weak self] in self?.selectedTab = $0 },
            setPendingPlayResume: { _ in },
            resetPlayNavigation: { [weak self] in self?.resetCount += 1 }
        )
    }
}

private final class RecordingIntentSink: LogSink, @unchecked Sendable {
    func write(_: LogEntry) {}
}

private actor FakeIntentPlayerRepository: PlayerRepository {
    func fetchPlayers(includeArchived _: Bool) async throws -> [PlayerSummary] { [] }
    func createPlayer(name _: String) async throws -> PlayerSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error") }
    func createBot(difficulty _: BotDifficulty) async throws -> PlayerSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error") }
    func updatePlayerName(playerId _: UUID, name _: String) async throws -> PlayerSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error") }
    func updatePlayerProfile(playerId _: UUID, name _: String, avatarStyle _: PlayerAvatarStyle, colorToken _: PlayerColorToken, notes _: String) async throws -> PlayerSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error") }
    func archivePlayer(playerId _: UUID) async throws {}
    func unarchivePlayer(playerId _: UUID) async throws {}
    func deletePlayer(playerId _: UUID) async throws {}
}

private actor FakeIntentMatchRepository: MatchRepository {
    let activeMatch: MatchSummary?
    init(activeMatch: MatchSummary?) { self.activeMatch = activeMatch }
    func createMatch(type _: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error") }
    func fetchActiveMatch() async throws -> MatchSummary? { activeMatch }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { [] }
    func fetchHistoryWithParticipants(page _: Int, pageSize _: Int, filter _: MatchHistoryFilter) async throws -> [MatchHistoryRecord] { [] }
    func updateMatch(_: MatchSummary) async throws {}
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error") }
    func appendEvent(matchId _: UUID, eventTypeRaw _: String, eventPayload _: Data) async throws -> MatchEventSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error") }
    func saveSnapshot(matchId _: UUID, snapshotVersion _: Int, snapshotPayload _: Data) async throws -> MatchSnapshotSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error") }
    func fetchLatestSnapshot(matchId _: UUID) async throws -> MatchSnapshotSummary? { nil }
    func fetchMatch(matchId _: UUID) async throws -> MatchSummary? { nil }
    func fetchParticipants(matchId _: UUID) async throws -> [MatchParticipantSummary] { [] }
    func deleteMatch(matchId _: UUID) async throws {}
}

private actor FakeIntentStatsRepository: StatsRepository {
    func fetchEvents(matchId _: UUID) async throws -> [MatchEventSummary] { [] }
    func fetchEvents(matchIds _: [UUID]) async throws -> [MatchEventSummary] { [] }
}

private actor FakeIntentSettingsRepository: SettingsRepository {
    func fetchSettings() async throws -> SettingsSummary {
        SettingsSummary(
            id: UUID(),
            appearanceModeRaw: "system",
            hapticsEnabled: true,
            soundEnabled: true,
            turnTotalCallerEnabled: false,
            defaultMatchTypeRaw: "x01",
            defaultX01StartScore: 501,
            defaultCheckoutModeRaw: "doubleOut",
            defaultCheckInModeRaw: "straightIn",
            defaultLegFormatRaw: "firstTo",
            defaultLegsToWin: 3,
            defaultSetsEnabled: false,
            botStaggerEnabled: true,
            botDartHapticsEnabled: true,
            instantBotTurnsEnabled: false,
            defaultDartEntryPresentationRaw: "numberPad",
            updatedAt: Date()
        )
    }

    func seedDefaultsIfNeeded() async throws -> SettingsSummary { try await fetchSettings() }
    func updateSettings(_ settings: SettingsSummary) async throws -> SettingsSummary { settings }
    func resetPreferencesToDefaults() async throws {}
    func resetAllLocalData() async throws {}
}
