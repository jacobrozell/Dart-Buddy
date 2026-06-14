import Foundation

enum AppStoreReset {
    static var sqliteStoreBaseURL: URL? {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first?
            .appending(path: "DartBuddy.sqlite")
    }

    static func storeFileURLs(for sqliteBase: URL) -> [URL] {
        [
            sqliteBase,
            sqliteBase.appendingPathExtension("shm"),
            sqliteBase.appendingPathExtension("wal")
        ]
    }

    @discardableResult
    static func backupSQLiteStore() -> String? {
        guard let sqliteBase = sqliteStoreBaseURL,
              FileManager.default.fileExists(atPath: sqliteBase.path) else {
            return nil
        }

        let stamp = ISO8601DateFormatter().string(from: Date())
            .replacingOccurrences(of: ":", with: "-")
        let backupBase = sqliteBase
            .deletingLastPathComponent()
            .appending(path: "DartBuddy-recovery-\(stamp).sqlite")

        do {
            for source in storeFileURLs(for: sqliteBase) where FileManager.default.fileExists(atPath: source.path) {
                let destination: URL
                if source == sqliteBase {
                    destination = backupBase
                } else {
                    let suffix = source.pathExtension
                    destination = backupBase.appendingPathExtension(suffix)
                }
                if FileManager.default.fileExists(atPath: destination.path) {
                    try FileManager.default.removeItem(at: destination)
                }
                try FileManager.default.copyItem(at: source, to: destination)
            }
            return backupBase.path
        } catch {
            return nil
        }
    }

    static func deleteSQLiteStore() {
        guard let sqliteBase = sqliteStoreBaseURL else { return }
        deleteSQLiteStore(at: sqliteBase)
    }

    static func deleteSQLiteStore(at sqliteBase: URL) {
        for url in storeFileURLs(for: sqliteBase) where FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }
    }

    /// Deletes the on-disk store before container creation when UI tests or demo seeding request a clean slate.
    static func applyLaunchArgumentOverrides() {
        if ProcessInfo.processInfo.arguments.contains("-ui_test_reset") {
            LocalAppStateReset.clearAllPersistedAuxiliaryState()
            deleteSQLiteStore()
        }
    }
}
