import Foundation
import SwiftData
import Testing
@testable import DartBuddy

@Suite("Schema V2 baseline", .tags(.migration, .swiftdata, .critical, .regression))
struct SchemaV2BaselineTests {
    @Test
    func freshDiskBackedStoreOpensAtV2() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("dartbuddy-v2-baseline-\(UUID().uuidString).sqlite")
        defer { try? FileManager.default.removeItem(at: url) }

        let container = try ModelContainerFactory.makeContainer(mode: .customURL(url))
        let context = ModelContext(container)
        context.insert(SchemaV2.SettingsRecord())
        try context.save()

        let reopened = try ModelContainerFactory.makeContainer(mode: .customURL(url))
        let reopenedContext = ModelContext(reopened)
        #expect(try reopenedContext.fetchCount(FetchDescriptor<SchemaV2.SettingsRecord>()) == 1)
    }
}
