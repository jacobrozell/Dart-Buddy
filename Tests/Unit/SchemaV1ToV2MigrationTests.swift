import Foundation
import SwiftData
import Testing
@testable import DartBuddy

@Suite("Schema V1 to V2 migration", .tags(.migration, .swiftdata, .critical, .regression))
struct SchemaV1ToV2MigrationTests {
    @Test
    func diskBackedV1StoreMigratesToV2AndPreservesSettings() async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("dartbuddy-v1-to-v2-\(UUID().uuidString).sqlite")
        defer { try? FileManager.default.removeItem(at: url) }

        let v1Schema = Schema(versionedSchema: SchemaV1.self)
        let v1Config = ModelConfiguration(schema: v1Schema, url: url)
        let v1Container = try ModelContainer(for: v1Schema, configurations: [v1Config])
        let v1Context = ModelContext(v1Container)
        let record = SchemaV1.SettingsRecord()
        record.defaultMatchTypeRaw = "cricket"
        v1Context.insert(record)
        try v1Context.save()

        let migrated = try ModelContainerFactory.makeContainer(mode: .customURL(url))
        let migratedContext = ModelContext(migrated)
        #expect(try migratedContext.fetchCount(FetchDescriptor<SchemaV2.SettingsRecord>()) == 1)

        let repository = SwiftDataSettingsRepository(container: migrated)
        let settings = try await repository.fetchSettings()
        #expect(settings.defaultMatchTypeRaw == "cricket")
        #expect(settings.instantBotTurnsEnabled == false)
    }

    @Test
    func migrationPlanIncludesV1ToV2Stage() {
        #expect(DartsMigrationPlan.schemas.count == 2)
        #expect(DartsMigrationPlan.stages.count == 1)
        #expect(SchemaLock.release_1_0_0 == Schema.Version(1, 0, 0))
        #expect(SchemaLock.release_1_1_0 == Schema.Version(2, 0, 0))
    }
}
