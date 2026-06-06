import Foundation
import Testing
@testable import DartBuddy

@Test(.tags(.unit, .settings, .regression))
func botNamingAssignsIncrementingDefaultNames() {
    #expect(BotNaming.nextDefaultName(difficulty: .easy, existingNames: []) == "Easy Bot 1")
    #expect(BotNaming.nextDefaultName(difficulty: .easy, existingNames: ["Easy Bot 1"]) == "Easy Bot 2")
    #expect(BotNaming.nextDefaultName(difficulty: .easy, existingNames: ["Easy Bot 1", "Easy Bot 3"]) == "Easy Bot 4")
    #expect(BotNaming.nextDefaultName(difficulty: .hard, existingNames: ["Easy Bot 1"]) == "Hard Bot 1")
}

@Test(.tags(.unit, .settings, .regression))
func botNamingAssignsIncrementingCustomBotNames() {
    let prefix = L10n.string("customBot.namePrefix")
    #expect(BotNaming.nextCustomBotName(existingNames: []) == "\(prefix)1")
    #expect(BotNaming.nextCustomBotName(existingNames: ["\(prefix)1"]) == "\(prefix)2")
    #expect(BotNaming.nextCustomBotName(existingNames: ["\(prefix)1", "\(prefix)4"]) == "\(prefix)5")
    #expect(BotNaming.nextCustomBotName(existingNames: ["Easy Bot 1"]) == "\(prefix)1")
}

@MainActor
@Test(.tags(.unit, .player, .regression))
func playersListCreateBotAddsPersistedBot() async {
    let repository = RecordingPlayerRepository()
    let vm = PlayersListViewModel(
        repository: repository,
        matchRepository: RecordingMatchRepository(),
        pendingMatchPlayerSelections: PendingMatchPlayerSelections()
    )

    await vm.createBot(.easy)
    await vm.createBot(.easy)

    let createdCount = await repository.createdBotCount()
    #expect(createdCount == 2)
    #expect(vm.filteredBots.count == 2)
    #expect(vm.filteredBots[0].name == "Easy Bot 1")
    #expect(vm.filteredBots[1].name == "Easy Bot 2")
    #expect(vm.filteredBots.allSatisfy { $0.isBot })
}

private actor RecordingPlayerRepository: PlayerRepository {
    private(set) var createdBots: [PlayerSummary] = []

    func createdBotCount() -> Int { createdBots.count }

    func fetchPlayers(includeArchived _: Bool) async throws -> [PlayerSummary] { createdBots }
    func createPlayer(name _: String) async throws -> PlayerSummary {
        throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented")
    }
    func createBot(difficulty: BotDifficulty) async throws -> PlayerSummary {
        let bot = PlayerSummary(
            id: UUID(),
            name: BotNaming.nextDefaultName(difficulty: difficulty, existingNames: createdBots.map(\.name)),
            isArchived: false,
            isBot: true,
            botDifficultyRaw: difficulty.rawValue,
            createdAt: Date(),
            updatedAt: Date()
        )
        createdBots.append(bot)
        return bot
    }
    func updatePlayerName(playerId _: UUID, name _: String) async throws -> PlayerSummary { createdBots[0] }
    func updatePlayerProfile(playerId _: UUID, name _: String, avatarStyle _: PlayerAvatarStyle, colorToken _: PlayerColorToken, notes _: String) async throws -> PlayerSummary { createdBots[0] }
    func archivePlayer(playerId _: UUID) async throws {}
    func unarchivePlayer(playerId _: UUID) async throws {}
    func deletePlayer(playerId _: UUID) async throws {}
}

private actor RecordingMatchRepository: MatchRepository {
    func fetchHistoryWithParticipants(page _: Int, pageSize _: Int, filter _: MatchHistoryFilter) async throws -> [MatchHistoryRecord] { [] }
    func createMatch(type _: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary {
        throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented")
    }
    func fetchActiveMatch() async throws -> MatchSummary? { nil }
    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { [] }
    func updateMatch(_: MatchSummary) async throws {}
    func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary {
        throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented")
    }
    func appendEvent(matchId _: UUID, eventTypeRaw _: String, eventPayload _: Data) async throws -> MatchEventSummary {
        throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented")
    }
    func saveSnapshot(matchId _: UUID, snapshotVersion _: Int, snapshotPayload _: Data) async throws -> MatchSnapshotSummary {
        throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented")
    }
    func fetchLatestSnapshot(matchId _: UUID) async throws -> MatchSnapshotSummary? { nil }
    func fetchMatch(matchId _: UUID) async throws -> MatchSummary? { nil }
    func fetchParticipants(matchId _: UUID) async throws -> [MatchParticipantSummary] { [] }
    func deleteMatch(matchId _: UUID) async throws {}
}
