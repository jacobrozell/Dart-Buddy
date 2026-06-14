import Foundation
import Testing
@testable import DartBuddy

@Suite("Bot analytics", .tags(.unit, .logging, .regression))
struct BotAnalyticsTests {
    @Test
    func metadataReportsNoBotsForHumanOnlyMatch() {
        let metadata = BotAnalytics.metadata(for: [
            MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "A", turnOrder: 0),
            MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "B", turnOrder: 1)
        ])

        #expect(metadata["hasBot"] == "false")
        #expect(metadata["botCount"] == "0")
        #expect(metadata["humanCount"] == "2")
        #expect(metadata["isBot"] == "false")
        #expect(metadata["botDifficulty"] == nil)
    }

    @Test
    func metadataReportsSinglePresetBotDifficulty() {
        let metadata = BotAnalytics.metadata(for: [
            MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "Jacob", turnOrder: 0),
            MatchParticipant(
                playerId: UUID(),
                displayNameAtMatchStart: "Bot",
                turnOrder: 1,
                botDifficultyRaw: BotDifficulty.hard.rawValue,
                botKindRaw: BotKind.preset.rawValue,
                botEffectiveTierRaw: BotDifficulty.hard.rawValue
            )
        ])

        #expect(metadata["hasBot"] == "true")
        #expect(metadata["botCount"] == "1")
        #expect(metadata["humanCount"] == "1")
        #expect(metadata["botDifficulty"] == "hard")
        #expect(metadata["botDifficulties"] == "hard")
        #expect(metadata["botKind"] == "preset")
        #expect(metadata["botKinds"] == "preset")
        #expect(metadata["botEffectiveTier"] == "hard")
    }

    @Test
    func metadataReportsMultipleBotDifficultiesSorted() {
        let metadata = BotAnalytics.metadata(for: [
            MatchParticipant(
                playerId: UUID(),
                displayNameAtMatchStart: "Bot A",
                turnOrder: 0,
                botDifficultyRaw: BotDifficulty.pro.rawValue,
                botKindRaw: BotKind.preset.rawValue,
                botEffectiveTierRaw: BotDifficulty.pro.rawValue
            ),
            MatchParticipant(
                playerId: UUID(),
                displayNameAtMatchStart: "Bot B",
                turnOrder: 1,
                botDifficultyRaw: BotDifficulty.easy.rawValue,
                botKindRaw: BotKind.preset.rawValue,
                botEffectiveTierRaw: BotDifficulty.easy.rawValue
            )
        ])

        #expect(metadata["botCount"] == "2")
        #expect(metadata["humanCount"] == "0")
        #expect(metadata["botDifficulties"] == "easy,pro")
        #expect(metadata["botEffectiveTiers"] == "easy,pro")
        #expect(metadata["botDifficulty"] == nil)
    }

    @Test
    func metadataReportsTrainingBotKindWithoutPresetDifficulty() {
        let metadata = BotAnalytics.metadata(for: [
            MatchParticipant(playerId: UUID(), displayNameAtMatchStart: "Jacob", turnOrder: 0),
            MatchParticipant(
                playerId: UUID(),
                displayNameAtMatchStart: "Training Bot",
                turnOrder: 1,
                botKindRaw: BotKind.training.rawValue,
                botSkillProfilePayload: Data([0x01])
            )
        ])

        #expect(metadata["botKind"] == "training")
        #expect(metadata["botKinds"] == "training")
        #expect(metadata["botDifficulty"] == nil)
        #expect(metadata["botDifficulties"] == nil)
    }
}
