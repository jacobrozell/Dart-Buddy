import Foundation
import Testing
@testable import DartBuddy

@Suite("App store reset", .tags(.unit, .regression))
struct AppStoreResetTests {
    @Test
    func deleteSQLiteStoreIsSafeWhenFilesAreMissing() {
        AppStoreReset.deleteSQLiteStore()
    }

    @Test
    func deleteSQLiteStoreRemovesExistingStoreFiles() throws {
        let support = try #require(
            FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
        )
        let sqliteBase = support.appending(path: "DartBuddy.sqlite")
        let candidates = [
            sqliteBase,
            sqliteBase.appendingPathExtension("shm"),
            sqliteBase.appendingPathExtension("wal"),
        ]

        for url in candidates {
            try Data([0x00]).write(to: url)
            #expect(FileManager.default.fileExists(atPath: url.path))
        }

        AppStoreReset.deleteSQLiteStore()

        for url in candidates {
            #expect(!FileManager.default.fileExists(atPath: url.path))
        }
    }
}
