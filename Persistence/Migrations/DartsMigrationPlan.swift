import SwiftData

public enum DartsMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [
            SchemaV1.self,
            SchemaV2_0_0.self,
            SchemaV2.self
        ]
    }

    public static var stages: [MigrationStage] {
        [
            migrateV1ToV2_0_0,
            migrateV2_0_0ToV2_1_0
        ]
    }

    private static let migrateV1ToV2_0_0 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2_0_0.self,
        willMigrate: nil,
        didMigrate: { context in
            let presetRaw = BotKind.preset.rawValue
            let players = try context.fetch(FetchDescriptor<SchemaV2_0_0.PlayerRecord>())
            for player in players where player.isBot == true && player.botDifficultyRaw != nil && player.botKindRaw == nil {
                player.botKindRaw = presetRaw
            }
            let participants = try context.fetch(FetchDescriptor<SchemaV2_0_0.MatchParticipantRecord>())
            for participant in participants where participant.botDifficultyRaw != nil && participant.botKindRaw == nil {
                participant.botKindRaw = presetRaw
            }
            try context.save()
        }
    )

    private static let migrateV2_0_0ToV2_1_0 = MigrationStage.lightweight(
        fromVersion: SchemaV2_0_0.self,
        toVersion: SchemaV2.self
    )
}
