import Foundation
import SwiftData

public enum ModelContainerFactory {
    public enum StorageMode: Sendable {
        case appDefault
        case inMemory
        case customURL(URL)
    }

    public static func makeContainer(mode: StorageMode = .appDefault) throws -> ModelContainer {
        let schema = Schema(DartsMigrationPlan.schemas)
        let isInMemory: Bool
        switch mode {
        case .inMemory:
            isInMemory = true
        default:
            isInMemory = false
        }
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: isInMemory,
            url: storeURL(for: mode)
        )
        return try ModelContainer(
            for: schema,
            migrationPlan: DartsMigrationPlan.self,
            configurations: [configuration]
        )
    }

    private static func storeURL(for mode: StorageMode) -> URL? {
        switch mode {
        case .appDefault:
            return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
                .first?
                .appending(path: "DartsScoreboard.sqlite")
        case .inMemory:
            return nil
        case let .customURL(url):
            return url
        }
    }
}
