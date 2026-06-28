import SwiftData

/// Post–1.0.0: `SchemaV1` frozen at App Store ship; each additive change lands in a new schema + adjacent stage.
public enum DartsMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
    }

    public static var stages: [MigrationStage] {
        [migrateV1ToV2]
    }

    static let migrateV1ToV2 = MigrationStage.lightweight(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self
    )
}
