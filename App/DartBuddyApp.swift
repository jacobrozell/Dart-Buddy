import SwiftUI
import SwiftData

@main
struct DartBuddyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var bootstrapResult: AppBootstrapResult?
    @State private var showsLaunchSplash = true
    @StateObject private var pendingDeepLink = PendingAppDestination()

    var body: some Scene {
        WindowGroup {
            ZStack {
                if let currentBootstrapResult = bootstrapResult {
                    bootstrapContent(currentBootstrapResult)
                        .opacity(showsLaunchSplash ? 0 : 1)
                }

                if showsLaunchSplash {
                    LaunchSplashView()
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
        async let bootstrap = AppBootstrapper.bootstrap()
        if shouldHoldLaunchSplashForMotion, showsLaunchSplash {
            try? await Task.sleep(for: .milliseconds(700))
        }
        bootstrapResult = await bootstrap
        guard bootstrapResult != nil else { return }
        if UIAccessibility.isReduceMotionEnabled {
            showsLaunchSplash = false
        } else {
            withAnimation(.easeInOut(duration: 0.3)) {
                showsLaunchSplash = false
            }
        }
    }

    private var shouldHoldLaunchSplashForMotion: Bool {
        guard !UIAccessibility.isReduceMotionEnabled else { return false }
        return !ProcessInfo.processInfo.arguments.contains("-ui_test_reset")
    }

    @ViewBuilder
    private func bootstrapContent(_ result: AppBootstrapResult) -> some View {
        switch result {
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
    }
}
