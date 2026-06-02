import Foundation
import Testing
@testable import DartsScoreboard

@Test(.tags(.unit, .settings, .regression))
func botNamingAssignsIncrementingDefaultNames() {
    #expect(BotNaming.nextDefaultName(difficulty: .easy, existingNames: []) == "Easy Bot 1")
    #expect(BotNaming.nextDefaultName(difficulty: .easy, existingNames: ["Easy Bot 1"]) == "Easy Bot 2")
    #expect(BotNaming.nextDefaultName(difficulty: .easy, existingNames: ["Easy Bot 1", "Easy Bot 3"]) == "Easy Bot 4")
    #expect(BotNaming.nextDefaultName(difficulty: .hard, existingNames: ["Easy Bot 1"]) == "Hard Bot 1")
}

@MainActor
@Test(.tags(.unit, .player, .regression))
func playersListCreateBotAddsPersistedBot() async {
    let repository = RecordingPlayerRepository()
    let vm = PlayersListViewModel(
        repository: repository,
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
    func archivePlayer(playerId _: UUID) async throws {}
    func unarchivePlayer(playerId _: UUID) async throws {}
    func deletePlayer(playerId _: UUID) async throws {}
}
