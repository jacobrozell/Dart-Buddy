import Foundation
import SwiftData
import Testing
@testable import DartBuddy

@Suite("Schema V1 baseline", .tags(.migration, .swiftdata, .critical, .regression))
struct SchemaV1BaselineTests {
    @Test
    func diskBackedStoreOpensWithoutMigrationStages() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("dartbuddy-v1-baseline-\(UUID().uuidString).sqlite")
        defer { try? FileManager.default.removeItem(at: url) }

        let container = try ModelContainerFactory.makeContainer(mode: .customURL(url))
        let context = ModelContext(container)
        context.insert(SchemaV1.SettingsRecord())
        try context.save()

        let reopened = try ModelContainerFactory.makeContainer(mode: .customURL(url))
        let reopenedContext = ModelContext(reopened)
        #expect(try reopenedContext.fetchCount(FetchDescriptor<SchemaV1.SettingsRecord>()) == 1)
    }

    @Test
    func migrationPlanIsSingleSchemaPreRelease() {
        #expect(DartsMigrationPlan.schemas.count == 1)
        #expect(DartsMigrationPlan.stages.isEmpty)
        #expect(SchemaLock.release_1_0_0 == Schema.Version(1, 0, 0))
    }
}
