import SwiftUI
import SwiftData

@main
struct DartBuddyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var bootstrapResult: AppBootstrapResult?
    @StateObject private var pendingDeepLink = PendingAppDestination()

    var body: some Scene {
        WindowGroup {
            Group {
                if let currentBootstrapResult = bootstrapResult {
                    switch currentBootstrapResult {
                    case let .ready(dependencies):
                        MainTabView(dependencies: dependencies, pendingDeepLink: pendingDeepLink)
                            .modelContainer(dependencies.modelContainer)
                            .uiTestAccessibilityDynamicTypeOverride()
                    case let .migrationRecovery(context):
                        MigrationRecoveryView(
                            context: context,
                            retryHandler: {
                                await refreshBootstrapResult()
                                if case .ready = self.bootstrapResult { return true }
                                return false
                            },
                            resetHandler: {
                                AppStoreReset.deleteSQLiteStore()
                                LocalAppStateReset.clearAllPersistedAuxiliaryState()
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
            .task {
                SnapshotOrientationLock.applyIfNeeded()
            }
            .onAppear {
                IntentRoutingBridge.setPendingDeepLink(pendingDeepLink)
            }
            .onOpenURL { url in
                handleIncomingURL(url)
            }
        }
    }

    @MainActor
    private func handleIncomingURL(_ url: URL) {
        switch DeepLinkParser.parse(url) {
        case let .success(destination):
            pendingDeepLink.enqueue(destination)
        case .failure:
            break
        }
    }

    @MainActor
    private func refreshBootstrapResult() async {
        bootstrapResult = await AppBootstrapper.bootstrap()
    }
}
