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

    @Test
    func backupAndRestoreRoundTripPreservesBytes() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("dartbuddy-backup-\(UUID().uuidString)", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let sqliteBase = directory.appending(path: "DartBuddy.sqlite")
        let payload = Data("store-bytes-\(UUID().uuidString)".utf8)
        try payload.write(to: sqliteBase)
        try Data([0x01]).write(to: sqliteBase.appendingPathExtension("wal"))

        let backupPath = try #require(AppStoreReset.backupSQLiteStore(at: sqliteBase))
        #expect(FileManager.default.fileExists(atPath: backupPath))

        AppStoreReset.deleteSQLiteStore(at: sqliteBase)
        #expect(!FileManager.default.fileExists(atPath: sqliteBase.path))

        #expect(AppStoreReset.restoreSQLiteStore(fromBackupPath: backupPath, to: sqliteBase))
        #expect(try Data(contentsOf: sqliteBase) == payload)
        #expect(FileManager.default.fileExists(atPath: sqliteBase.appendingPathExtension("wal").path))
    }
}
