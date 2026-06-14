import SwiftData

/// Persistence baseline for the Dart Buddy 1.0.0 App Store release.
///
/// Pre-release: one schema (`SchemaV1` @ 1.0.0), no migration stages. After 1.0 ships,
/// add `SchemaV2` + stage + tests for each change. See `specs/SwiftData.md` §15.
public enum SchemaLock {
    public static let release_1_0_0 = Schema.Version(1, 0, 0)
    public static let release_1_0_0Schema: any VersionedSchema.Type = SchemaV1.self
}
