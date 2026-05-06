import SwiftUI
import SwiftData

@main
struct DartsScoreboardApp: App {
    @State private var bootstrapResult: AppBootstrapResult = AppBootstrapper.bootstrap()

    var body: some Scene {
        WindowGroup {
            switch bootstrapResult {
            case let .ready(dependencies):
                MainTabView(dependencies: dependencies)
                    .modelContainer(dependencies.modelContainer)
            case let .migrationRecovery(context):
                MigrationRecoveryView(
                    context: context,
                    retryHandler: {
                        let result = AppBootstrapper.bootstrap()
                        bootstrapResult = result
                        if case .ready = result { return true }
                        return false
                    },
                    resetHandler: {
                        resetLocalStoreFiles()
                        bootstrapResult = AppBootstrapper.bootstrap()
                        if case .ready = bootstrapResult { return true }
                        return false
                    }
                )
            }
        }
    }

    private func resetLocalStoreFiles() {
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
}
