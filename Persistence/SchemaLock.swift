import SwiftData

/// Persistence baseline for the Dart Buddy 1.0.0 App Store release.
///
/// After 1.0 ships, any entity or column change requires a new `SchemaVx` file,
/// an adjacent stage in `DartsMigrationPlan`, and migration tests. See `specs/SwiftData.md` §15.
public enum SchemaLock {
    public static let release_1_0_0 = Schema.Version(2, 2, 0)
    public static let release_1_0_0Schema: any VersionedSchema.Type = SchemaV2.self
}
