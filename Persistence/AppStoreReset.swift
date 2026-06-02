import Foundation

enum AppStoreReset {
    static func deleteSQLiteStore() {
        guard let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return
        }
        let sqliteBase = base.appending(path: "DartsScoreboard.sqlite")
        let candidates = [
            sqliteBase,
            sqliteBase.appendingPathExtension("shm"),
            sqliteBase.appendingPathExtension("wal")
        ]
        for url in candidates where FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.removeItem(at: url)
        }
    }

    /// Deletes the on-disk store before container creation when UI tests or demo seeding request a clean slate.
    static func applyLaunchArgumentOverrides() {
        if ProcessInfo.processInfo.arguments.contains("-ui_test_reset") {
            deleteSQLiteStore()
        }
    }
}
