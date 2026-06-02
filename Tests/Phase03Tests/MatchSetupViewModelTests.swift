import Foundation
import Testing
@testable import DartsScoreboard

@MainActor
@Test(.tags(.integration, .setupFlow, .navigation, .smoke, .regression))
func setupValidationRequiresMinimumPlayers() async {
    let vm = MatchSetupViewModel(
        playerRepository: FakePlayerRepository(players: [makePlayer("A")]),
        settingsRepository: FakeSettingsRepository(),
        matchRepository: FakeMatchRepository(),
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections()
    )
    await vm.onAppear()
    vm.selectedPlayerIds = []
    vm.revalidate()

    #expect(!vm.canStart)
    #expect(vm.validationErrors.contains("setup.validation.minimumPlayers"))
}

@MainActor
@Test(.tags(.integration, .setupFlow, .navigation, .smoke, .regression))
func setupOnAppearSelectsPendingPlayersWhenPresent() async {
    let players = [makePlayer("A"), makePlayer("B")]
    let pending = PendingMatchPlayerSelections()
    pending.enqueueForNextMatchSetup(players[1].id)
    let vm = MatchSetupViewModel(
        playerRepository: FakePlayerRepository(players: players),
        settingsRepository: FakeSettingsRepository(),
        matchRepository: FakeMatchRepository(),
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: pending
    )
    await vm.onAppear()
    #expect(vm.selectedPlayerIds.contains(players[1].id))
    #expect(!vm.selectedPlayerIds.contains(players[0].id))
}

@MainActor
@Test(.tags(.integration, .setupFlow, .navigation, .smoke, .regression))
func setupAddPlayerToSelectionIsIdempotent() async {
    let players = [makePlayer("A"), makePlayer("B")]
    let vm = MatchSetupViewModel(
        playerRepository: FakePlayerRepository(players: players),
        settingsRepository: FakeSettingsRepository(),
        matchRepository: FakeMatchRepository(),
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections()
    )
    await vm.onAppear()
    vm.addPlayerToSelection(players[0].id)
    vm.addPlayerToSelection(players[0].id)
    #expect(vm.selectedPlayerIds == Set([players[0].id]))
}

@MainActor
@Test(.tags(.integration, .setupFlow, .navigation, .smoke, .regression))
func setupStartRouteUsesSelectedMode() async {
    let players = [makePlayer("A"), makePlayer("B")]
    let vm = MatchSetupViewModel(
        playerRepository: FakePlayerRepository(players: players),
        settingsRepository: FakeSettingsRepository(),
        matchRepository: FakeMatchRepository(),
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections()
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

@MainActor
@Test(.tags(.integration, .setupFlow, .navigation, .regression))
func setupStartPromptsWhenAnotherMatchIsActive() async {
    let players = [makePlayer("A"), makePlayer("B")]
    let repo = ActiveConflictMatchRepository(hasActive: true)
    let vm = MatchSetupViewModel(
        playerRepository: FakePlayerRepository(players: players),
        settingsRepository: FakeSettingsRepository(),
        matchRepository: repo,
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections()
    )
    await vm.onAppear()
    vm.togglePlayer(players[0].id)
    vm.togglePlayer(players[1].id)

    let route = await vm.startMatchRoute()
    #expect(route == nil)
    #expect(vm.showActiveMatchConflict)
    #expect(await repo.deletedCount == 0)
    #expect(vm.validationErrors.isEmpty)
}

@MainActor
@Test(.tags(.integration, .setupFlow, .navigation, .regression))
func setupConfirmReplaceAbandonsActiveMatchThenStarts() async {
    let players = [makePlayer("A"), makePlayer("B")]
    let repo = ActiveConflictMatchRepository(hasActive: true)
    let vm = MatchSetupViewModel(
        playerRepository: FakePlayerRepository(players: players),
        settingsRepository: FakeSettingsRepository(),
        matchRepository: repo,
        activeMatchStore: ActiveMatchStore(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections()
    )
    await vm.onAppear()
    vm.togglePlayer(players[0].id)
    vm.togglePlayer(players[1].id)

    let route = await vm.confirmReplaceActiveMatch()
    #expect(route != nil)
    #expect(!vm.showActiveMatchConflict)
    #expect(await repo.abandonedCount == 1)
    #expect(await repo.deletedCount == 0)
}

private func makePlayer(_ name: String) -> PlayerSummary {
    PlayerSummary(id: UUID(), name: name, isArchived: false, createdAt: Date(), updatedAt: Date())
}

private actor FakePlayerRepository: PlayerRepository {
    let players: [PlayerSummary]
    init(players: [PlayerSummary]) { self.players = players }
    func fetchPlayers(includeArchived _: Bool) async throws -> [PlayerSummary] { players }
    func createPlayer(name _: String) async throws -> PlayerSummary { players[0] }
    func createBot(difficulty: BotDifficulty) async throws -> PlayerSummary {
        PlayerSummary(
            id: UUID(),
            name: BotNaming.nextDefaultName(difficulty: difficulty, existingNames: players.map(\.name)),
            isArchived: false,
            isBot: true,
            botDifficultyRaw: difficulty.rawValue,
            createdAt: Date(),
            updatedAt: Date()
        )
    }
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
        defaultCheckInModeRaw: "straightIn",
        defaultLegFormatRaw: "firstTo",
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
    func deleteMatch(matchId _: UUID) async throws {}
}

/// Reports an in-progress match so the setup flow must prompt before starting,
/// and records abandon vs delete operations from the "Game in Progress" confirmation.
private actor ActiveConflictMatchRepository: MatchRepository {
    private var hasActive: Bool
    private(set) var deletedCount = 0
    private(set) var abandonedCount = 0

    init(hasActive: Bool) { self.hasActive = hasActive }

    private func activeSummary() -> MatchSummary {
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

    func createMatch(type: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary {
        MatchSummary(id: UUID(), type: type, status: .inProgress, startedAt: Date(), endedAt: nil, winnerPlayerId: nil, currentTurnPlayerId: nil, currentLegIndex: 0, currentSetIndex: 0, eventCount: 0, createdAt: Date(), updatedAt: Date())
    }

    func fetchActiveMatch() async throws -> MatchSummary? { hasActive ? activeSummary() : nil }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { [] }
    func fetchHistoryWithParticipants(page _: Int, pageSize _: Int) async throws -> [MatchHistoryRecord] { [] }
    func updateMatch(_ match: MatchSummary) async throws {
        if match.status == .abandoned {
            abandonedCount += 1
            hasActive = false
        }
    }
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented") }
    func appendEvent(matchId _: UUID, eventTypeRaw _: String, eventPayload _: Data) async throws -> MatchEventSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented") }
    func saveSnapshot(matchId: UUID, snapshotVersion: Int, snapshotPayload: Data) async throws -> MatchSnapshotSummary {
        MatchSnapshotSummary(id: UUID(), matchId: matchId, snapshotVersion: snapshotVersion, snapshotPayload: snapshotPayload, updatedAt: Date())
    }
    func fetchLatestSnapshot(matchId _: UUID) async throws -> MatchSnapshotSummary? { nil }
    func fetchMatch(matchId _: UUID) async throws -> MatchSummary? { nil }
    func fetchParticipants(matchId _: UUID) async throws -> [MatchParticipantSummary] { [] }
    func deleteMatch(matchId _: UUID) async throws {
        deletedCount += 1
        hasActive = false
    }
}
