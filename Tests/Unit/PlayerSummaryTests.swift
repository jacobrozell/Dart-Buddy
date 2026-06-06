import Foundation
import Testing
@testable import DartBuddy

@Suite("Player summary", .tags(.unit, .player, .regression))
struct PlayerSummaryTests {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    @Test
    func presetBotIsDetectedFromDifficulty() {
        let bot = makeSummary(
            isBot: true,
            botKindRaw: nil,
            botDifficultyRaw: BotDifficulty.medium.rawValue
        )
        #expect(bot.isPresetBot)
        #expect(!bot.isCustomBot)
        #expect(!bot.isTrainingBot)
    }

    @Test
    func customBotIsDetectedFromKindAndEncodedMetrics() {
        let metrics = CustomBotMetrics(x01Average: 40, cricketMPR: 1.5)
        let bot = makeSummary(
            isBot: true,
            botKindRaw: BotKind.custom.rawValue,
            botDifficultyRaw: metrics.encode()
        )
        #expect(bot.isCustomBot)
        #expect(bot.customBotMetrics == metrics)
        #expect(!bot.isPresetBot)
    }

    @Test
    func trainingBotIsDetectedFromKind() {
        let linked = UUID()
        let bot = makeSummary(
            isBot: true,
            botKindRaw: BotKind.training.rawValue,
            botDifficultyRaw: BotDifficulty.medium.rawValue,
            linkedPlayerId: linked
        )
        #expect(bot.isTrainingBot)
        #expect(bot.linkedPlayerId == linked)
        #expect(!bot.isPresetBot)
    }

    @Test
    func humanPlayerIsNotClassifiedAsBotVariant() {
        let human = makeSummary(isBot: false, botKindRaw: nil, botDifficultyRaw: nil)
        #expect(!human.isPresetBot)
        #expect(!human.isCustomBot)
        #expect(!human.isTrainingBot)
    }

    private func makeSummary(
        isBot: Bool,
        botKindRaw: String?,
        botDifficultyRaw: String?,
        linkedPlayerId: UUID? = nil
    ) -> PlayerSummary {
        PlayerSummary(
            id: UUID(),
            name: "Player",
            isArchived: false,
            isBot: isBot,
            botDifficultyRaw: botDifficultyRaw,
            botKindRaw: botKindRaw,
            linkedPlayerId: linkedPlayerId,
            createdAt: now,
            updatedAt: now
        )
    }
}
