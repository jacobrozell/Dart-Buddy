import Foundation
import SwiftData
import Testing
@testable import DartBuddy

@Suite("Bootstrap store recovery", .tags(.integration, .migration, .swiftdata, .critical, .regression))
struct BootstrapStoreRecoveryTests {
    @Test
    func repairsNonContiguousEventIndexesInsteadOfFailing() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("dartbuddy-repair-\(UUID().uuidString).sqlite")
        defer { try? FileManager.default.removeItem(at: url) }

        let container = try ModelContainerFactory.makeContainer(mode: .customURL(url))
        let context = ModelContext(container)
        let matchId = UUID()
        context.insert(
            SchemaV1.MatchRecord(
                id: matchId,
                typeRaw: MatchType.x01.rawValue,
                statusRaw: MatchStatus.completed.rawValue,
                startedAt: Date(),
                endedAt: Date(),
                configPayload: Data("{}".utf8),
                eventCount: 3
            )
        )
        for index in [0, 2] {
            context.insert(
                SchemaV1.MatchEventRecord(
                    matchId: matchId,
                    eventIndex: index,
                    eventTypeRaw: "x01Turn",
                    eventPayload: Data("{}".utf8)
                )
            )
        }
        try context.save()

        let logger = DefaultAppLogger(minimumLevel: .fault, sink: SilentLogSink())
        let reopened = try BootstrapStoreRecovery.openRecoveredContainer(
            mode: .customURL(url),
            logger: logger
        )
        let reopenedContext = ModelContext(reopened)
        let events = try reopenedContext.fetch(
            FetchDescriptor<SchemaV1.MatchEventRecord>(
                predicate: #Predicate<SchemaV1.MatchEventRecord> { $0.matchId == matchId },
                sortBy: [SortDescriptor(\.eventIndex, order: .forward)]
            )
        )
        #expect(events.map(\.eventIndex) == [0, 1])
        let match = try #require(
            try reopenedContext.fetch(FetchDescriptor<SchemaV1.MatchRecord>()).first { $0.id == matchId }
        )
        #expect(match.eventCount == 2)
    }

    @Test
    func recreatesUnreadableStoreOnDisk() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("dartbuddy-corrupt-\(UUID().uuidString).sqlite")
        defer { try? FileManager.default.removeItem(at: url) }

        try Data("not a sqlite database".utf8).write(to: url)

        let logger = DefaultAppLogger(minimumLevel: .fault, sink: SilentLogSink())
        let container = try BootstrapStoreRecovery.openRecoveredContainer(
            mode: .customURL(url),
            logger: logger
        )
        let context = ModelContext(container)
        #expect(try context.fetchCount(FetchDescriptor<SchemaV1.SettingsRecord>()) >= 0)
    }
}

private final class SilentLogSink: LogSink, @unchecked Sendable {
    func write(_: LogEntry) {}
}
