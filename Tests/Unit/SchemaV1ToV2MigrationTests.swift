import Foundation
import SwiftData
import Testing
@testable import DartBuddy

/// Disk-backed V1 stores must migrate cleanly to the 1.0 baseline (`SchemaV2`).
/// Serialized to avoid SwiftData schema-registry pollution with in-memory integration tests.
@Suite(.serialized)
struct SchemaV1ToV2MigrationTests {
    @Test(.tags(.migration, .swiftdata, .critical, .regression))
    func migratesLegacyBotRecordsToPresetKind() throws {
        let url = FileManager.default.temporaryDirectory
            .appending(path: "dartbuddy-migration-\(UUID().uuidString).sqlite")
        defer { try? FileManager.default.removeItem(at: url) }

        let v1Schema = Schema(versionedSchema: SchemaV1.self)
        let v1Configuration = ModelConfiguration(schema: v1Schema, url: url)
        let v1Container = try ModelContainer(for: v1Schema, configurations: [v1Configuration])
        let v1Context = ModelContext(v1Container)

        let botId = UUID()
        let matchId = UUID()
        v1Context.insert(
            SchemaV1.PlayerRecord(
                id: botId,
                name: "Legacy Bot",
                isBot: true,
                botDifficultyRaw: BotDifficulty.easy.rawValue
            )
        )
        v1Context.insert(
            SchemaV1.MatchRecord(
                id: matchId,
                typeRaw: MatchType.x01.rawValue,
                statusRaw: MatchLifecycleStatus.inProgress.rawValue,
                configPayload: Data("{}".utf8)
            )
        )
        v1Context.insert(
            SchemaV1.MatchParticipantRecord(
                matchId: matchId,
                playerId: botId,
                turnOrder: 0,
                displayNameAtMatchStart: "Legacy Bot",
                botDifficultyRaw: BotDifficulty.easy.rawValue
            )
        )
        try v1Context.save()

        let migratedContainer = try ModelContainerFactory.makeContainer(mode: .customURL(url))
        let context = ModelContext(migratedContainer)

        let players = try context.fetch(FetchDescriptor<SchemaV2.PlayerRecord>())
        let bot = try #require(players.first { $0.id == botId })
        #expect(bot.botKindRaw == BotKind.preset.rawValue)

        let participants = try context.fetch(FetchDescriptor<SchemaV2.MatchParticipantRecord>())
        let participant = try #require(participants.first { $0.matchId == matchId })
        #expect(participant.botKindRaw == BotKind.preset.rawValue)
        #expect(participant.botSkillProfilePayload == nil)
    }

    @Test(.tags(.migration, .swiftdata, .regression))
    func migratesV2_1_0ToV2_2_0WithNullableScaleColumns() throws {
        let url = FileManager.default.temporaryDirectory
            .appending(path: "dartbuddy-migration-v220-\(UUID().uuidString).sqlite")
        defer { try? FileManager.default.removeItem(at: url) }

        let v210Schema = Schema(versionedSchema: SchemaV2_1_0.self)
        let configuration = ModelConfiguration(schema: v210Schema, url: url)
        let container = try ModelContainer(for: v210Schema, configurations: [configuration])
        let context = ModelContext(container)

        let matchId = UUID()
        context.insert(
            SchemaV2_1_0.MatchRecord(
                id: matchId,
                typeRaw: MatchType.x01.rawValue,
                statusRaw: MatchStatus.completed.rawValue,
                configPayload: Data("{}".utf8)
            )
        )
        try context.save()

        let migratedContainer = try ModelContainerFactory.makeContainer(mode: .customURL(url))
        let migratedContext = ModelContext(migratedContainer)
        let match = try #require(
            try migratedContext.fetch(FetchDescriptor<SchemaV2.MatchRecord>()).first { $0.id == matchId }
        )
        #expect(match.historyCardPayload == nil)
        #expect(match.isCampaignMatch == nil)
        #expect(match.campaignStageId == nil)
    }
}
