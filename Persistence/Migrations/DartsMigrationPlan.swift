import SwiftData

public enum DartsMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [
            SchemaV1.self,
            SchemaV2.self
        ]
    }

    public static var stages: [MigrationStage] {
        [
            migrateV1ToV2
        ]
    }

    private static let migrateV1ToV2 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self,
        willMigrate: nil,
        didMigrate: { context in
            let presetRaw = BotKind.preset.rawValue
            let players = try context.fetch(FetchDescriptor<SchemaV2.PlayerRecord>())
            for player in players where player.isBot == true && player.botDifficultyRaw != nil && player.botKindRaw == nil {
                player.botKindRaw = presetRaw
            }
            try context.save()
        }
    )
}
