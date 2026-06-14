import Foundation
import Testing
@testable import DartBuddy

@Suite("App intents coverage", .tags(.unit, .navigation, .regression))
struct AppIntentsCoverageTests {
    @Test
    func intentNamesMatchSpecIdentifiers() {
        #expect(OpenPlayIntent.intentName == "open_play")
        #expect(ResumeActiveMatchIntent.intentName == "resume_active_match")
    }

    @Test
    func shortcutsProviderRespectsAppIntentsFeatureFlag() {
        if LocalFeatureFlagsProvider().isEnabled(.enableAppIntents) {
            #expect(DartBuddyShortcutsProvider.appShortcuts.count == 2)
        } else {
            #expect(DartBuddyShortcutsProvider.appShortcuts.isEmpty)
        }
    }

    @Test
    @MainActor
    func openPlayIntentRoutesToPlayTabWhenEnabled() async throws {
        defer { resetIntentBridge() }
        let state = IntentPerformTestState(selectedTab: .settings)
        try configureIntentBridge(state: state)
        _ = try await OpenPlayIntent().perform()
        #expect(state.selectedTab == .play)
        #expect(state.resetCount == 1)
    }

    @Test
    @MainActor
    func openPlayIntentThrowsWhenFeatureDisabled() async throws {
        defer { resetIntentBridge() }
        IntentRoutingBridge.featureFlagOverrides = [.enableAppIntents: false]
        await #expect(throws: IntentRoutingError.disabled) {
            try await OpenPlayIntent().perform()
        }
    }

    @Test
    @MainActor
    func resumeActiveMatchIntentRoutesResumeWhenMatchExists() async throws {
        defer { resetIntentBridge() }
        let activeMatch = makeIntentActiveMatch()
        let state = IntentPerformTestState(selectedTab: .settings)
        try configureIntentBridge(state: state, activeMatch: activeMatch)
        _ = try await ResumeActiveMatchIntent().perform()
        #expect(state.pendingResume?.match.id == activeMatch.id)
        #expect(state.pendingResume?.startSource == .intent)
    }

    @Test
    @MainActor
    func resumeActiveMatchIntentFallsBackToHomeWhenNoActiveMatch() async throws {
        defer { resetIntentBridge() }
        let state = IntentPerformTestState(selectedTab: .settings)
        try configureIntentBridge(state: state, activeMatch: nil)
        _ = try await ResumeActiveMatchIntent().perform()
        #expect(state.selectedTab == .play)
        #expect(state.pendingResume == nil)
    }

    @Test
    @MainActor
    func resumeActiveMatchIntentEnqueuesWhenShellNotReady() async throws {
        defer { resetIntentBridge() }
        enableAppIntents()
        let pending = PendingAppDestination()
        IntentRoutingBridge.setPendingDeepLink(pending)
        _ = try await ResumeActiveMatchIntent().perform()
        #expect(pending.hasPending)
    }
}

@MainActor
private final class IntentPerformTestState {
    var selectedTab: MainTabView.RootTab
    var resetCount = 0
    var pendingResume: PendingMatchResume?

    init(selectedTab: MainTabView.RootTab) {
        self.selectedTab = selectedTab
    }

    func makeActions() -> AppRouteRouter.Actions {
        AppRouteRouter.Actions(
            setSelectedTab: { [weak self] in self?.selectedTab = $0 },
            setPendingPlayResume: { [weak self] in self?.pendingResume = $0 },
            resetPlayNavigation: { [weak self] in self?.resetCount += 1 }
        )
    }
}

@MainActor
private func configureIntentBridge(
    state: IntentPerformTestState,
    activeMatch: MatchSummary? = nil
) throws {
    enableAppIntents()
    IntentRoutingBridge.configure(
        dependencies: try makeIntentPerformDependencies(activeMatch: activeMatch),
        actions: state.makeActions()
    )
}

@MainActor
private func enableAppIntents() {
    IntentRoutingBridge.featureFlagOverrides = [.enableAppIntents: true]
}

@MainActor
private func resetIntentBridge() {
    IntentRoutingBridge.featureFlagOverrides = [:]
    IntentRoutingBridge.clearRouteActions()
}

@MainActor
private func makeIntentPerformDependencies(activeMatch: MatchSummary?) throws -> AppDependencies {
    AppDependencies(
        modelContainer: try ModelContainerFactory.makeContainer(mode: .inMemory),
        logger: DefaultAppLogger(minimumLevel: .fault, sink: IntentPerformSilentLogSink()),
        playerRepository: IntentPerformFakePlayerRepository(),
        matchRepository: IntentPerformFakeMatchRepository(activeMatch: activeMatch),
        statsRepository: IntentPerformFakeStatsRepository(),
        settingsRepository: IntentPerformFakeSettingsRepository(),
        hapticsService: NoopHapticsService(),
        audioFeedbackService: NoopAudioFeedbackService(),
        turnTotalCallerService: NoopTurnTotalCallerService(),
        userPreferencesStore: UserPreferencesStore(),
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections()
    )
}

private func makeIntentActiveMatch() -> MatchSummary {
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
        eventCount: 1,
        createdAt: Date(),
        updatedAt: Date()
    )
}

private struct IntentPerformSilentLogSink: LogSink {
    func write(_: LogEntry) {}
}

private actor IntentPerformFakePlayerRepository: PlayerRepository {
    func fetchPlayers(includeArchived _: Bool) async throws -> [PlayerSummary] { [] }
    func createPlayer(name _: String) async throws -> PlayerSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error") }
    func createBot(difficulty _: BotDifficulty) async throws -> PlayerSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error") }
    func updatePlayerName(playerId _: UUID, name _: String) async throws -> PlayerSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error") }
    func updatePlayerProfile(playerId _: UUID, name _: String, avatarStyle _: PlayerAvatarStyle, colorToken _: PlayerColorToken, notes _: String) async throws -> PlayerSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error") }
    func archivePlayer(playerId _: UUID) async throws {}
    func unarchivePlayer(playerId _: UUID) async throws {}
    func deletePlayer(playerId _: UUID) async throws {}
}

private actor IntentPerformFakeMatchRepository: MatchRepository {
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

private actor IntentPerformFakeStatsRepository: StatsRepository {
    func fetchEvents(matchId _: UUID) async throws -> [MatchEventSummary] { [] }
    func fetchEvents(matchIds _: [UUID]) async throws -> [MatchEventSummary] { [] }
}

private actor IntentPerformFakeSettingsRepository: SettingsRepository {
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
            defaultDartEntryPresentationRaw: "numberPad",
            updatedAt: Date()
        )
    }
    func seedDefaultsIfNeeded() async throws -> SettingsSummary { try await fetchSettings() }
    func updateSettings(_ settings: SettingsSummary) async throws -> SettingsSummary { settings }
    func resetPreferencesToDefaults() async throws {}
    func resetAllLocalData() async throws {}
}
