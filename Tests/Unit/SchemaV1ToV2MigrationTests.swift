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
    func diskBackedV1StoreMigratesPlayersMatchesAndEvents() async throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("dartbuddy-v1-to-v2-entities-\(UUID().uuidString).sqlite")
        defer { try? FileManager.default.removeItem(at: url) }

        let playerID = UUID()
        let matchID = UUID()
        let eventID = UUID()

        let v1Schema = Schema(versionedSchema: SchemaV1.self)
        let v1Config = ModelConfiguration(schema: v1Schema, url: url)
        let v1Container = try ModelContainer(for: v1Schema, configurations: [v1Config])
        let v1Context = ModelContext(v1Container)

        v1Context.insert(SchemaV1.PlayerRecord(id: playerID, name: "Alex"))
        v1Context.insert(
            SchemaV1.MatchRecord(
                id: matchID,
                typeRaw: "x01",
                statusRaw: "completed",
                configPayload: Data([0x01]),
                eventCount: 1
            )
        )
        v1Context.insert(
            SchemaV1.MatchEventRecord(
                id: eventID,
                matchId: matchID,
                eventIndex: 0,
                eventTypeRaw: "visit",
                eventPayload: Data([0x02])
            )
        )
        try v1Context.save()

        let migrated = try ModelContainerFactory.makeContainer(mode: .customURL(url))
        let migratedContext = ModelContext(migrated)

        #expect(try migratedContext.fetchCount(FetchDescriptor<SchemaV2.PlayerRecord>()) == 1)
        #expect(try migratedContext.fetchCount(FetchDescriptor<SchemaV2.MatchRecord>()) == 1)
        #expect(try migratedContext.fetchCount(FetchDescriptor<SchemaV2.MatchEventRecord>()) == 1)

        let players = try migratedContext.fetch(FetchDescriptor<SchemaV2.PlayerRecord>())
        #expect(players.first?.id == playerID)
        #expect(players.first?.name == "Alex")

        let matches = try migratedContext.fetch(FetchDescriptor<SchemaV2.MatchRecord>())
        #expect(matches.first?.id == matchID)
        #expect(matches.first?.typeRaw == "x01")
        #expect(matches.first?.eventCount == 1)

        let events = try migratedContext.fetch(FetchDescriptor<SchemaV2.MatchEventRecord>())
        #expect(events.first?.id == eventID)
        #expect(events.first?.matchId == matchID)
        #expect(events.first?.eventTypeRaw == "visit")
    }

    @Test
    func migrationPlanIncludesV1ToV2Stage() {
        #expect(DartsMigrationPlan.schemas.count == 2)
        #expect(DartsMigrationPlan.stages.count == 1)
        #expect(SchemaLock.release_1_0_0 == Schema.Version(1, 0, 0))
        #expect(SchemaLock.release_1_1_0 == Schema.Version(2, 0, 0))
    }
}
