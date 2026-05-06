import Foundation
import Testing

@MainActor
@Test(.tags(.integration, .setupFlow, .navigation, .smoke, .regression))
func setupValidationRequiresMinimumPlayers() async {
    let vm = MatchSetupViewModel(
        playerRepository: FakePlayerRepository(players: [makePlayer("A")]),
        settingsRepository: FakeSettingsRepository(),
        matchRepository: FakeMatchRepository(),
        activeMatchStore: ActiveMatchStore()
    )
    await vm.onAppear()
    vm.selectedPlayerIds = []
    vm.revalidate()

    #expect(!vm.canStart)
    #expect(vm.validationErrors.contains("setup.validation.minimumPlayers"))
}

@MainActor
@Test(.tags(.integration, .setupFlow, .navigation, .smoke, .regression))
func setupStartRouteUsesSelectedMode() async {
    let players = [makePlayer("A"), makePlayer("B")]
    let vm = MatchSetupViewModel(
        playerRepository: FakePlayerRepository(players: players),
        settingsRepository: FakeSettingsRepository(),
        matchRepository: FakeMatchRepository(),
        activeMatchStore: ActiveMatchStore()
    )
    await vm.onAppear()
    vm.updateMode(.cricket)
    vm.togglePlayer(players[0].id)
    vm.togglePlayer(players[1].id)

    let route = await vm.startMatchRoute()
    if case .cricketMatch = route {
        #expect(true)
    } else {
        Issue.record("Expected cricket route")
    }
}

private func makePlayer(_ name: String) -> PlayerSummary {
    PlayerSummary(id: UUID(), name: name, isArchived: false, createdAt: Date(), updatedAt: Date())
}

private actor FakePlayerRepository: PlayerRepository {
    let players: [PlayerSummary]
    init(players: [PlayerSummary]) { self.players = players }
    func fetchPlayers(includeArchived _: Bool) async throws -> [PlayerSummary] { players }
    func createPlayer(name _: String) async throws -> PlayerSummary { players[0] }
    func updatePlayerName(playerId _: UUID, name _: String) async throws -> PlayerSummary { players[0] }
    func archivePlayer(playerId _: UUID) async throws {}
    func unarchivePlayer(playerId _: UUID) async throws {}
    func deletePlayer(playerId _: UUID) async throws {}
}

private actor FakeSettingsRepository: SettingsRepository {
    func fetchSettings() async throws -> SettingsSummary {
        settings
    }

    func seedDefaultsIfNeeded() async throws -> SettingsSummary {
        settings
    }

    func updateSettings(_ settings: SettingsSummary) async throws -> SettingsSummary {
        settings
    }

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
        defaultLegsToWin: 3,
        defaultSetsEnabled: false,
        updatedAt: Date()
    )
}

private actor FakeMatchRepository: MatchRepository {
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
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented") }
    func appendEvent(matchId _: UUID, eventTypeRaw _: String, eventPayload _: Data) async throws -> MatchEventSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented") }
    func saveSnapshot(matchId: UUID, snapshotVersion: Int, snapshotPayload: Data) async throws -> MatchSnapshotSummary {
        MatchSnapshotSummary(
            id: UUID(),
            matchId: matchId,
            snapshotVersion: snapshotVersion,
            snapshotPayload: snapshotPayload,
            updatedAt: Date()
        )
    }
    func fetchLatestSnapshot(matchId _: UUID) async throws -> MatchSnapshotSummary? { nil }
    func fetchMatch(matchId _: UUID) async throws -> MatchSummary? { nil }
    func fetchParticipants(matchId _: UUID) async throws -> [MatchParticipantSummary] { [] }
}
