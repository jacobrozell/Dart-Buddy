import Foundation
import Testing
@testable import DartBuddy

@Suite("App route router", .tags(.unit, .navigation, .regression))
@MainActor
struct AppRouteRouterTests {
    @Test
    func tabDestinationSelectsTab() async throws {
        let state = RouteTestState(selectedTab: .play)
        let router = AppRouteRouter(dependencies: try makeDependencies())
        let outcome = await router.handle(
            .tab(.settings),
            actions: state.makeActions()
        )

        #expect(outcome == .applied)
        #expect(state.selectedTab == .settings)
    }

    @Test
    func playHomeSelectsPlayAndResetsNavigation() async throws {
        let state = RouteTestState(selectedTab: .settings)
        let router = AppRouteRouter(dependencies: try makeDependencies())
        let outcome = await router.handle(
            .play(.home),
            actions: state.makeActions()
        )

        #expect(outcome == .applied)
        #expect(state.selectedTab == .play)
        #expect(state.resetCount == 1)
    }

    @Test
    func resumeActiveMatchSetsPendingResume() async throws {
        let activeMatch = makeMatchSummary()
        let state = RouteTestState(selectedTab: .settings)
        let router = AppRouteRouter(
            dependencies: try makeDependencies(activeMatch: activeMatch)
        )
        let outcome = await router.handle(
            .play(.resumeActive),
            actions: state.makeActions()
        )

        #expect(outcome == .applied)
        #expect(state.selectedTab == .play)
        #expect(state.pendingResume?.match.id == activeMatch.id)
        #expect(state.pendingResume?.startSource == .deepLink)
    }

    @Test
    func resumeUnreachablePartyMatchFails() async throws {
        guard !ProductSurface.showsPartyModes else { return }

        let activeMatch = MatchSummary(
            id: UUID(),
            type: .baseball,
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
        let state = RouteTestState(selectedTab: .settings)
        let router = AppRouteRouter(
            dependencies: try makeDependencies(activeMatch: activeMatch)
        )
        let outcome = await router.handle(
            .play(.resumeActive),
            actions: state.makeActions()
        )

        #expect(outcome == .failed(.unknownPath))
        #expect(state.selectedTab == .play)
        #expect(state.pendingResume == nil)
    }

    @Test
    func resumeUnreachableGolfMatchFailsWhenPartyVisible() async throws {
        guard ProductSurface.showsPartyModes, !ProductSurface.isFullProductSurfaceEnabled else { return }

        let activeMatch = MatchSummary(
            id: UUID(),
            type: .golf,
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
        let state = RouteTestState(selectedTab: .settings)
        let router = AppRouteRouter(
            dependencies: try makeDependencies(activeMatch: activeMatch)
        )
        let outcome = await router.handle(
            .play(.resumeActive),
            actions: state.makeActions()
        )

        #expect(outcome == .failed(.unknownPath))
        #expect(state.selectedTab == .play)
        #expect(state.pendingResume == nil)
    }

    @Test
    func resumeReachableBaseballMatchSucceeds() async throws {
        guard ProductSurface.showsPartyModes, !ProductSurface.isFullProductSurfaceEnabled else { return }

        let activeMatch = MatchSummary(
            id: UUID(),
            type: .baseball,
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
        let state = RouteTestState(selectedTab: .settings)
        let router = AppRouteRouter(
            dependencies: try makeDependencies(activeMatch: activeMatch)
        )
        let outcome = await router.handle(
            .play(.resumeActive),
            actions: state.makeActions()
        )

        #expect(outcome == .applied)
        #expect(state.pendingResume?.match.id == activeMatch.id)
    }

    @Test
    func resumeWithoutActiveMatchFails() async throws {
        let state = RouteTestState(selectedTab: .settings)
        let router = AppRouteRouter(dependencies: try makeDependencies(activeMatch: nil))
        let outcome = await router.handle(
            .play(.resumeActive),
            actions: state.makeActions()
        )

        #expect(outcome == .failed(.unknownPath))
        #expect(state.selectedTab == .play)
    }

    @Test
    func resumeWhenRepositoryThrowsFails() async throws {
        let state = RouteTestState(selectedTab: .settings)
        let router = AppRouteRouter(
            dependencies: try makeDependencies(matchRepository: ThrowingMatchRepository())
        )
        let outcome = await router.handle(
            .play(.resumeActive),
            actions: state.makeActions()
        )

        #expect(outcome == .failed(.unknownPath))
        #expect(state.selectedTab == .play)
        #expect(state.pendingResume == nil)
    }

    @Test
    func unimplementedPlayRoutesFail() async throws {
        let state = RouteTestState(selectedTab: .play)
        let router = AppRouteRouter(dependencies: try makeDependencies())
        let matchId = UUID()

        let outcomes = await [
            router.handle(.play(.setup(.init())), actions: state.makeActions()),
            router.handle(.play(.activeMatch(matchId: matchId)), actions: state.makeActions()),
            router.handle(.play(.matchSummary(matchId: matchId)), actions: state.makeActions()),
        ]

        #expect(outcomes == [.failed(.unknownPath), .failed(.unknownPath), .failed(.unknownPath)])
    }

    @Test
    func unimplementedTopLevelDestinationsFail() async throws {
        let state = RouteTestState(selectedTab: .play)
        let router = AppRouteRouter(dependencies: try makeDependencies())
        let matchId = UUID()
        let playerId = UUID()

        let outcomes = await [
            router.handle(.activity(.root(segment: .history)), actions: state.makeActions()),
            router.handle(.activity(.historyDetail(matchId: matchId)), actions: state.makeActions()),
            router.handle(.players(.detail(playerId: playerId)), actions: state.makeActions()),
            router.handle(.settings(.root), actions: state.makeActions()),
        ]

        #expect(outcomes == Array(repeating: .failed(.unknownPath), count: 4))
    }

    @Test
    func allTabDestinationsMapToRootTabs() async throws {
        let router = AppRouteRouter(dependencies: try makeDependencies())
        let mappings: [(TabDestination, MainTabView.RootTab)] = [
            (.play, .play),
            (.modes, .modes),
            (.players, .players),
            (.activity, .activity),
            (.settings, .settings),
        ]

        for (tab, expectedRootTab) in mappings {
            let state = RouteTestState(selectedTab: .play)
            let outcome = await router.handle(.tab(tab), actions: state.makeActions())
            #expect(outcome == .applied)
            if tab == .modes, !ProductSurface.showsModesTab {
                #expect(state.selectedTab == .play)
            } else {
                #expect(state.selectedTab == expectedRootTab)
            }
        }
    }

    private func makeDependencies(activeMatch: MatchSummary? = nil) throws -> AppDependencies {
        try makeDependencies(matchRepository: FakeMatchRepository(activeMatch: activeMatch))
    }

    private func makeDependencies(matchRepository: any MatchRepository) throws -> AppDependencies {
        AppDependencies(
            modelContainer: try ModelContainerFactory.makeContainer(mode: .inMemory),
            logger: DefaultAppLogger(minimumLevel: .fault, sink: RecordingSink()),
            playerRepository: FakePlayerRepository(),
            matchRepository: matchRepository,
            statsRepository: FakeStatsRepository(),
            settingsRepository: FakeSettingsRepository(),
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
private final class RouteTestState {
    var selectedTab: MainTabView.RootTab
    var pendingResume: PendingMatchResume?
    var resetCount = 0

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

private actor FakePlayerRepository: PlayerRepository {
    func fetchPlayers(includeArchived _: Bool) async throws -> [PlayerSummary] { [] }
    func createPlayer(name _: String) async throws -> PlayerSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error") }
    func createBot(difficulty _: BotDifficulty) async throws -> PlayerSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error") }
    func updatePlayerName(playerId _: UUID, name _: String) async throws -> PlayerSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error") }
    func updatePlayerProfile(playerId _: UUID, name _: String, avatarStyle _: PlayerAvatarStyle, colorToken _: PlayerColorToken, notes _: String) async throws -> PlayerSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error") }
    func archivePlayer(playerId _: UUID) async throws {}
    func unarchivePlayer(playerId _: UUID) async throws {}
    func deletePlayer(playerId _: UUID) async throws {}
}

private actor ThrowingMatchRepository: MatchRepository {
    func createMatch(type _: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error") }
    func fetchActiveMatch() async throws -> MatchSummary? { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error") }
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

private actor FakeMatchRepository: MatchRepository {
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

private actor FakeStatsRepository: StatsRepository {
    func fetchEvents(matchId _: UUID) async throws -> [MatchEventSummary] { [] }
    func fetchEvents(matchIds _: [UUID]) async throws -> [MatchEventSummary] { [] }
}

private actor FakeSettingsRepository: SettingsRepository {
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

private final class RecordingSink: LogSink, @unchecked Sendable {
    func write(_: LogEntry) {}
}
