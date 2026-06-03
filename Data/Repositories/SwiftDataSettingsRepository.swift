import Foundation
import SwiftData

public actor SwiftDataSettingsRepository: SettingsRepository {
    private let container: ModelContainer

    public init(container: ModelContainer) {
        self.container = container
    }

    public func fetchSettings() async throws -> SettingsSummary {
        try dataCall {
            let context = ModelContext(container)
            if let record = try context.fetch(FetchDescriptor<SchemaV1.SettingsRecord>()).first {
                return mapSettings(record)
            }
            let created = SchemaV1.SettingsRecord()
            context.insert(created)
            try context.save()
            return mapSettings(created)
        }
    }

    public func seedDefaultsIfNeeded() async throws -> SettingsSummary {
        try await fetchSettings()
    }

    public func updateSettings(_ settings: SettingsSummary) async throws -> SettingsSummary {
        try dataCall {
            let context = ModelContext(container)
            let settingsId = settings.id
            let descriptor = FetchDescriptor<SchemaV1.SettingsRecord>(
                predicate: #Predicate<SchemaV1.SettingsRecord> { $0.id == settingsId }
            )
            let record: SchemaV1.SettingsRecord
            if let existing = try context.fetch(descriptor).first {
                record = existing
            } else {
                let created = SchemaV1.SettingsRecord(id: settings.id)
                context.insert(created)
                record = created
            }
            if record.modelContext == nil {
                context.insert(record)
            }
            record.appearanceModeRaw = settings.appearanceModeRaw
            record.hapticsEnabled = settings.hapticsEnabled
            record.soundEnabled = settings.soundEnabled
            record.turnTotalCallerEnabled = settings.turnTotalCallerEnabled
            record.defaultMatchTypeRaw = settings.defaultMatchTypeRaw
            record.defaultX01StartScore = settings.defaultX01StartScore
            record.defaultCheckoutModeRaw = settings.defaultCheckoutModeRaw
            record.defaultCheckInModeRaw = settings.defaultCheckInModeRaw
            record.defaultLegFormatRaw = settings.defaultLegFormatRaw
            record.defaultLegsToWin = settings.defaultLegsToWin
            record.defaultSetsEnabled = settings.defaultSetsEnabled
            record.botStaggerEnabled = settings.botStaggerEnabled
            record.botDartHapticsEnabled = settings.botDartHapticsEnabled
            record.updatedAt = settings.updatedAt
            try context.save()
            return mapSettings(record)
        }
    }

    public func resetPreferencesToDefaults() async throws {
        try dataCall {
            let context = ModelContext(container)
            let record: SchemaV1.SettingsRecord
            if let existing = try context.fetch(FetchDescriptor<SchemaV1.SettingsRecord>()).first {
                record = existing
            } else {
                let created = SchemaV1.SettingsRecord()
                context.insert(created)
                record = created
            }
            record.appearanceModeRaw = "system"
            record.hapticsEnabled = true
            record.soundEnabled = true
            record.turnTotalCallerEnabled = false
            record.defaultMatchTypeRaw = "x01"
            record.defaultX01StartScore = 501
            record.defaultCheckoutModeRaw = "doubleOut"
            record.defaultCheckInModeRaw = "straightIn"
            record.defaultLegFormatRaw = "firstTo"
            record.defaultLegsToWin = 3
            record.defaultSetsEnabled = false
            record.botStaggerEnabled = true
            record.botDartHapticsEnabled = true
            record.updatedAt = Date()
            try context.save()
        }
    }

    public func resetAllLocalData() async throws {
        try dataCall {
            let context = ModelContext(container)
            for player in try context.fetch(FetchDescriptor<SchemaV1.PlayerRecord>()) {
                context.delete(player)
            }
            for match in try context.fetch(FetchDescriptor<SchemaV1.MatchRecord>()) {
                context.delete(match)
            }
            for participant in try context.fetch(FetchDescriptor<SchemaV1.MatchParticipantRecord>()) {
                context.delete(participant)
            }
            for snapshot in try context.fetch(FetchDescriptor<SchemaV1.MatchSnapshotRecord>()) {
                context.delete(snapshot)
            }
            for event in try context.fetch(FetchDescriptor<SchemaV1.MatchEventRecord>()) {
                context.delete(event)
            }
            for setting in try context.fetch(FetchDescriptor<SchemaV1.SettingsRecord>()) {
                context.delete(setting)
            }
            context.insert(SchemaV1.SettingsRecord())
            try context.save()
        }
    }
}
