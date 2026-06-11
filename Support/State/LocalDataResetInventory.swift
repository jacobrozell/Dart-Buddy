import Foundation
import SwiftData

/// Canonical inventory of local state cleared by **Reset All Local Data**.
///
/// Spec: `specs/DeleteAllDataSpec.md` (inventory tables, scaling checklist, tests).
///
/// Keep this file updated when adding persistence:
/// - SwiftData `@Model`: add to `SchemaVx.models` **and** `swiftDataDeleters` (counts must match; tests enforce).
/// - Match-setup `UserDefaults`: conform to `PersistedSetupPreferences` and register in `setupPreferenceStores`.
/// - Other `UserDefaults`: add a clear call in `clearAuxiliaryUserDefaults`.
/// - In-memory only: wire through `SettingsViewModel.confirmReset()` (see `inMemorySurfaces`).
enum LocalDataResetInventory {
    /// UserDefaults-backed last-used setup values for each implemented game mode.
    static let setupPreferenceStores: [PersistedSetupPreferences.Type] = [
        CricketSetupPreferences.self,
        BaseballSetupPreferences.self,
        ShanghaiSetupPreferences.self,
        KillerSetupPreferences.self
    ]

    /// Non-setup auxiliary keys cleared on reset (onboarding, marketing dismissals, etc.).
    static func clearAuxiliaryUserDefaults(userDefaults: UserDefaults = .standard) {
        OnboardingStore(userDefaults: userDefaults).clearPersistedState()
        AppStoreUpdateChecker.clearPersistedState(userDefaults: userDefaults)
    }

    /// Deletes every row for each model on the active release schema, then saves.
    static func deleteAllSwiftDataRecords(in container: ModelContainer) throws {
        let context = ModelContext(container)
        for delete in swiftDataDeleters {
            try delete(context)
        }
        try context.save()
    }

    /// Row counts per SwiftData model type (for reset verification tests).
    static func swiftDataRecordCounts(in container: ModelContainer) throws -> [String: Int] {
        let context = ModelContext(container)
        return try swiftDataCounters.reduce(into: [:]) { counts, count in
            let (name, value) = try count(context)
            counts[name] = value
        }
    }

    /// In-memory stores cleared in `SettingsViewModel.confirmReset()` (not persisted).
    static let inMemorySurfaces = [
        "ActiveMatchStore",
        "PendingMatchPlayerSelections"
    ]

    /// Must stay aligned with `SchemaLock.release_1_0_0Schema.models`.
    static let swiftDataDeleters: [(ModelContext) throws -> Void] = [
        { try SwiftDataStoreReset.deleteAll(SchemaV2.PlayerRecord.self, in: $0) },
        { try SwiftDataStoreReset.deleteAll(SchemaV2.MatchRecord.self, in: $0) },
        { try SwiftDataStoreReset.deleteAll(SchemaV2.MatchParticipantRecord.self, in: $0) },
        { try SwiftDataStoreReset.deleteAll(SchemaV2.MatchSnapshotRecord.self, in: $0) },
        { try SwiftDataStoreReset.deleteAll(SchemaV2.MatchEventRecord.self, in: $0) },
        { try SwiftDataStoreReset.deleteAll(SchemaV2.SettingsRecord.self, in: $0) }
    ]

    private static let swiftDataCounters: [(ModelContext) throws -> (String, Int)] = [
        { ctx in (String(describing: SchemaV2.PlayerRecord.self), try SwiftDataStoreReset.count(SchemaV2.PlayerRecord.self, in: ctx)) },
        { ctx in (String(describing: SchemaV2.MatchRecord.self), try SwiftDataStoreReset.count(SchemaV2.MatchRecord.self, in: ctx)) },
        { ctx in (String(describing: SchemaV2.MatchParticipantRecord.self), try SwiftDataStoreReset.count(SchemaV2.MatchParticipantRecord.self, in: ctx)) },
        { ctx in (String(describing: SchemaV2.MatchSnapshotRecord.self), try SwiftDataStoreReset.count(SchemaV2.MatchSnapshotRecord.self, in: ctx)) },
        { ctx in (String(describing: SchemaV2.MatchEventRecord.self), try SwiftDataStoreReset.count(SchemaV2.MatchEventRecord.self, in: ctx)) },
        { ctx in (String(describing: SchemaV2.SettingsRecord.self), try SwiftDataStoreReset.count(SchemaV2.SettingsRecord.self, in: ctx)) }
    ]

    static func assertSwiftDataInventoryMatchesReleaseSchema() {
        let schemaCount = SchemaLock.release_1_0_0Schema.models.count
        precondition(
            swiftDataDeleters.count == schemaCount,
            "LocalDataResetInventory.swiftDataDeleters (\(swiftDataDeleters.count)) must match SchemaLock.release_1_0_0Schema.models (\(schemaCount)). Update the inventory when adding SwiftData models."
        )
        precondition(
            swiftDataCounters.count == schemaCount,
            "LocalDataResetInventory.swiftDataCounters must match SchemaLock.release_1_0_0Schema.models (\(schemaCount))."
        )
    }
}
