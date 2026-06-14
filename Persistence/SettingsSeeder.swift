import Foundation
import SwiftData

public struct SettingsSeeder {
    private let logger: any AppLogger

    public init(logger: any AppLogger) {
        self.logger = logger
    }

    @discardableResult
    public func seedDefaultsIfNeeded(in context: ModelContext) throws -> SchemaV1.SettingsRecord {
        let descriptor = FetchDescriptor<SchemaV1.SettingsRecord>()
        if let existing = try context.fetch(descriptor).first {
            logger.debug(
                .settings,
                eventName: "settings_seed_skipped",
                message: "Settings record already exists.",
                metadata: ["settingsId": existing.id.uuidString]
            )
            return existing
        }

        let created = SchemaV1.SettingsRecord()
        context.insert(created)
        try context.save()
        logger.info(
            .settings,
            eventName: "settings_seeded",
            message: "Default settings were seeded.",
            metadata: ["settingsId": created.id.uuidString, "schemaVersion": "1"]
        )
        return created
    }
}
