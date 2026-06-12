import Foundation
import SwiftData

public enum ModelContainerFactory {
    public enum StorageMode: Sendable {
        case appDefault
        case inMemory
        case customURL(URL)
    }

    public static func makeContainer(mode: StorageMode = .appDefault) throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV3.self)
        let configuration: ModelConfiguration
        switch mode {
        case .inMemory:
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        case .appDefault, .customURL:
            guard let url = storeURL(for: mode) else {
                preconditionFailure("storeURL must return a URL for \(mode)")
            }
            try ensureParentDirectoryExists(for: url)
            configuration = ModelConfiguration(schema: schema, url: url)
        }
        return try ModelContainer(
            for: schema,
            migrationPlan: DartsMigrationPlan.self,
            configurations: [configuration]
        )
    }

    /// UI tests pass `-ui_test_reset`; use an in-memory store to avoid simulator sandbox / CI filesystem issues.
    public static func storageModeForCurrentProcess() -> StorageMode {
        if ProcessInfo.processInfo.arguments.contains("-ui_test_reset") {
            return .inMemory
        }
        return .appDefault
    }

    private static func ensureParentDirectoryExists(for storeURL: URL) throws {
        let directory = storeURL.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
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
