import SwiftUI
import SwiftData

@main
struct DartsScoreboardApp: App {
    @State private var bootstrapResult: AppBootstrapResult?

    var body: some Scene {
        WindowGroup {
            Group {
                if let currentBootstrapResult = bootstrapResult {
                    switch currentBootstrapResult {
                    case let .ready(dependencies):
                        MainTabView(dependencies: dependencies)
                            .modelContainer(dependencies.modelContainer)
                    case let .migrationRecovery(context):
                        MigrationRecoveryView(
                            context: context,
                            retryHandler: {
                                await refreshBootstrapResult()
                                if case .ready = self.bootstrapResult { return true }
                                return false
                            },
                            resetHandler: {
                                resetLocalStoreFiles()
                                await refreshBootstrapResult()
                                if case .ready = self.bootstrapResult { return true }
                                return false
                            }
                        )
                    }
                } else {
                    ProgressView(L10n.loading)
                }
            }
            .task {
                guard bootstrapResult == nil else { return }
                await refreshBootstrapResult()
            }
        }
    }

    @MainActor
    private func refreshBootstrapResult() async {
        bootstrapResult = await AppBootstrapper.bootstrap()
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
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                #if DEBUG
                    print("Failed to remove local store file: \(url.lastPathComponent), error: \(error)")
                #endif
            }
        }
    }
}
