import Foundation
import SwiftData
import Testing
@testable import DartBuddy

/// Disk-backed V2 stores must migrate cleanly to SchemaV3 (`forfeitedByPlayerId` additive).
@Suite(.serialized)
struct SchemaV2ToV3MigrationTests {
    @Test(.tags(.migration, .swiftdata, .critical, .regression))
    func migratesCompletedMatchWithNilForfeitedByPlayerId() throws {
        let url = FileManager.default.temporaryDirectory
            .appending(path: "dartbuddy-migration-v3-\(UUID().uuidString).sqlite")
        defer { try? FileManager.default.removeItem(at: url) }

        let matchId = UUID()
        let winnerId = UUID()
        let endedAt = Date()

        let v2Schema = Schema(versionedSchema: SchemaV2.self)
        let v2Configuration = ModelConfiguration(schema: v2Schema, url: url)
        let v2Container = try ModelContainer(for: v2Schema, configurations: [v2Configuration])
        let v2Context = ModelContext(v2Container)

        v2Context.insert(
            SchemaV2.MatchRecord(
                id: matchId,
                typeRaw: MatchType.x01.rawValue,
                statusRaw: MatchStatus.completed.rawValue,
                startedAt: endedAt.addingTimeInterval(-600),
                endedAt: endedAt,
                winnerPlayerId: winnerId,
                configPayload: Data("{}".utf8),
                eventCount: 3
            )
        )
        try v2Context.save()

        let migratedContainer = try ModelContainerFactory.makeContainer(mode: .customURL(url))
        let context = ModelContext(migratedContainer)

        let match = try #require(
            try context.fetch(FetchDescriptor<SchemaV3.MatchRecord>()).first { $0.id == matchId }
        )
        #expect(match.statusRaw == MatchStatus.completed.rawValue)
        #expect(match.winnerPlayerId == winnerId)
        #expect(match.forfeitedByPlayerId == nil)
        #expect(match.eventCount == 3)
    }

    @Test(.tags(.migration, .swiftdata, .regression))
    func migratesInProgressMatchPreservesStatusWithoutForfeitMetadata() throws {
        let url = FileManager.default.temporaryDirectory
            .appending(path: "dartbuddy-migration-v3-active-\(UUID().uuidString).sqlite")
        defer { try? FileManager.default.removeItem(at: url) }

        let matchId = UUID()
        let v2Schema = Schema(versionedSchema: SchemaV2.self)
        let v2Configuration = ModelConfiguration(schema: v2Schema, url: url)
        let v2Container = try ModelContainer(for: v2Schema, configurations: [v2Configuration])
        let v2Context = ModelContext(v2Container)

        v2Context.insert(
            SchemaV2.MatchRecord(
                id: matchId,
                typeRaw: MatchType.cricket.rawValue,
                statusRaw: MatchStatus.inProgress.rawValue,
                configPayload: Data("{}".utf8),
                eventCount: 1
            )
        )
        try v2Context.save()

        let migratedContainer = try ModelContainerFactory.makeContainer(mode: .customURL(url))
        let context = ModelContext(migratedContainer)

        let match = try #require(
            try context.fetch(FetchDescriptor<SchemaV3.MatchRecord>()).first { $0.id == matchId }
        )
        #expect(match.statusRaw == MatchStatus.inProgress.rawValue)
        #expect(match.forfeitedByPlayerId == nil)
        #expect(match.endedAt == nil)
    }
}
