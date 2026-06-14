import SwiftData

/// Pre-release ship baseline: single schema, no migration stages.
/// After 1.0 ships to users, add `SchemaV2` + an adjacent stage for each schema bump.
public enum DartsMigrationPlan: SchemaMigrationPlan {
    public static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self]
    }

    public static var stages: [MigrationStage] {
        []
    }
}
