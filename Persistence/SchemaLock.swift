import SwiftData

/// Persistence contract boundaries per App Store release tag.
///
/// Never edit a schema file after its release tag ships — add `SchemaV{n+1}` + stage + test instead.
/// See `specs/SwiftData.md` §15 and `.cursor/rules/swiftdata-schema-releases.mdc`.
public enum SchemaLock {
    public static let release_1_0_0 = Schema.Version(1, 0, 0)
    public static let release_1_0_0Schema: any VersionedSchema.Type = SchemaV1.self

    public static let release_1_1_0 = Schema.Version(2, 0, 0)
    public static let release_1_1_0Schema: any VersionedSchema.Type = SchemaV2.self

    /// Active schema for new containers and reset inventory alignment.
    public static var currentReleaseSchema: any VersionedSchema.Type {
        release_1_1_0Schema
    }
}
