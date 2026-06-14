import Foundation
import SwiftData
import Testing
@testable import DartBuddy

@Test(.tags(.unit, .settings, .swiftdata, .regression))
func settingsSeederIsIdempotent() throws {
    let container = try ModelContainerFactory.makeContainer(mode: .inMemory)
    let context = ModelContext(container)
    let sink = RecordingSink()
    let logger = DefaultAppLogger(minimumLevel: .debug, sink: sink)
    let seeder = SettingsSeeder(logger: logger)

    let first = try seeder.seedDefaultsIfNeeded(in: context)
    let second = try seeder.seedDefaultsIfNeeded(in: context)

    #expect(first.id == second.id)
    let allSettings = try context.fetch(FetchDescriptor<SchemaV1.SettingsRecord>())
    #expect(allSettings.count == 1)
}

private final class RecordingSink: LogSink, @unchecked Sendable {
    var entries: [LogEntry] = []

    func write(_ entry: LogEntry) {
        entries.append(entry)
    }
}
