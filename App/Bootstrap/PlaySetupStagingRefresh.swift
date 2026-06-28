import Foundation

@MainActor
enum PlaySetupStagingRefresh {
    /// Optional hook Play setup registers so pending roster IDs apply without relying on NotificationCenter under modal covers.
    static var refreshHandler: (() async -> Void)?

    /// Applies pending Play setup roster IDs once persisted players are visible to setup.
    static func applyPendingSelections(_ dependencies: AppDependencies, maxAttempts: Int = 24) async {
        for _ in 0 ..< maxAttempts {
            guard dependencies.pendingMatchPlayerSelections.hasPendingSetupPlayers else { return }
            dependencies.pendingMatchPlayerSelections.bumpForSetupRefresh()
            await refreshHandler?()
            NotificationCenter.default.post(
                name: PendingMatchPlayerSelections.shouldRefreshSetupNotification,
                object: nil
            )
            try? await Task.sleep(for: .milliseconds(150))
        }
    }
}
