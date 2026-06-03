import Foundation
import SwiftData

public enum ModelContainerFactory {
    public enum StorageMode: Sendable {
        case appDefault
        case inMemory
        case customURL(URL)
    }

    public static func makeContainer(mode: StorageMode = .appDefault) throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let configuration: ModelConfiguration
        switch mode {
        case .inMemory:
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        case .appDefault, .customURL:
            guard let url = storeURL(for: mode) else {
                preconditionFailure("storeURL must return a URL for \(mode)")
            }
            configuration = ModelConfiguration(schema: schema, url: url)
        }
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
                .appending(path: "DartBuddy.sqlite")
        case .inMemory:
            return nil
        case let .customURL(url):
            return url
        }
    }
}
