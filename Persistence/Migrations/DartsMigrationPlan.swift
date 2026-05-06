import SwiftData

public enum DartsMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [
            SchemaV1.self
        ]
    }

    public static var stages: [MigrationStage] {
        [
            // Future adjacent migrations, for example:
            // migrateV1ToV2
        ]
    }
}
