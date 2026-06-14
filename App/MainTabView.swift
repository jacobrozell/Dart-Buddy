import SwiftUI

/// Root tab shell: Play, Modes, Players, Activity, Settings.
/// Tab order matches `specs/AppShellSpec.md`.
struct MainTabView: View {
    enum RootTab: String, CaseIterable {
        case play
        case modes
        case players
        case activity
        case settings

        init?(snapshotArgument: String) {
            switch snapshotArgument {
            case "history", "statistics":
                self = .activity
            default:
                guard let tab = RootTab(rawValue: snapshotArgument) else { return nil }
                if tab == .modes, !ProductSurface.showsModesTab {
                    self = .play
                } else {
                    self = tab
                }
            }
        }
    }

    let dependencies: AppDependencies
    @ObservedObject var pendingDeepLink: PendingAppDestination
    @ObservedObject private var preferences: UserPreferencesStore
    @State private var selectedTab: RootTab = MainTabView.startupTab
    @State private var pendingPlayResume: MatchSummary?
    @State private var playNavigationResetTrigger = 0
    @State private var showsActiveMatchBadge = false
    @State private var appStoreUpdateOffer: AppStoreUpdateOffer?
    @State private var showsOnboarding = false
    @Environment(\.openURL) private var openURL

    private let onboardingStore = OnboardingStore()

    init(dependencies: AppDependencies, pendingDeepLink: PendingAppDestination) {
        self.dependencies = dependencies
        self.pendingDeepLink = pendingDeepLink
        _preferences = ObservedObject(wrappedValue: dependencies.userPreferencesStore)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            PlayRootView(
                dependencies: dependencies,
                pendingResumeMatch: $pendingPlayResume,
                navigationResetTrigger: playNavigationResetTrigger,
                onChangeMode: { if ProductSurface.showsModesTab { selectedTab = .modes } }
            )
                .brandScoreboardChrome(appearanceModeRaw: preferences.appearanceModeRaw)
                .tag(RootTab.play)
                .tabItem {
                    Label(L10n.tabPlay, systemImage: "house.fill")
                        .accessibilityIdentifier("tab_play")
                }
            if ProductSurface.showsModesTab {
                ModesRootView(onSelectMode: handleModeSelection)
                    .brandScoreboardChrome(appearanceModeRaw: preferences.appearanceModeRaw)
                    .tag(RootTab.modes)
                    .tabItem {
                        Label(L10n.tabModes, systemImage: "square.grid.2x2.fill")
                            .accessibilityIdentifier("tab_modes")
                    }
            }
            PlayersRootView(dependencies: dependencies)
                .brandScoreboardChrome(appearanceModeRaw: preferences.appearanceModeRaw)
                .tag(RootTab.players)
                .tabItem {
                    Label(L10n.tabPlayers, systemImage: "person.2.fill")
                        .accessibilityIdentifier("tab_players")
                }
            ActivityRootView(
                dependencies: dependencies,
                onResumeActiveMatch: { match in
                    guard ProductSurface.isMatchTypeReachable(match.type) else { return }
                    pendingPlayResume = match
                    selectedTab = .play
                },
                onStartMatch: { selectedTab = .play }
            )
                .brandScoreboardChrome(appearanceModeRaw: preferences.appearanceModeRaw)
                .tag(RootTab.activity)
                .tabItem {
                    Label(L10n.tabActivity, systemImage: "clock.arrow.circlepath")
                        .accessibilityIdentifier("tab_activity")
                }
                .badge(showsActiveMatchBadge && selectedTab != .activity ? 1 : 0)
            SettingsRootView(dependencies: dependencies)
                .tag(RootTab.settings)
                .tabItem {
                    Label(L10n.tabSettings, systemImage: "gearshape.fill")
                        .accessibilityIdentifier("tab_settings")
                }
        }
        .preferredColorScheme(preferences.preferredColorScheme)
        .tint(Brand.green)
        .alert(L10n.updateAvailableTitle, isPresented: appStoreUpdateAlertBinding) {
            Button(L10n.updateAvailableUpdate) {
                if let offer = appStoreUpdateOffer {
                    openURL(offer.storeURL)
                }
            }
            Button(L10n.updateAvailableNotNow, role: .cancel) {
                if let offer = appStoreUpdateOffer {
                    AppStoreUpdateChecker().recordDismissal(for: offer)
                }
                appStoreUpdateOffer = nil
            }
        } message: {
            Text(L10n.updateAvailableMessage)
        }
        .fullScreenCover(isPresented: $showsOnboarding) {
            OnboardingFlowView(
                mode: .firstLaunch,
                dependencies: dependencies,
                store: onboardingStore,
                logger: dependencies.logger,
                preferredColorScheme: preferences.preferredColorScheme,
                onFinished: {
                    showsOnboarding = false
                    selectedTab = .play
                    Task {
                        await checkForAppStoreUpdate()
                        await consumePendingDeepLink()
                    }
                }
            )
        }
        .task {
            configureIntentRouting()
            ClientEnvironmentMonitor.startReportingChanges(using: dependencies.logger)
            dependencies.logger.info(
                .ui,
                eventName: "main_tab_presented",
                message: "Main tab shell rendered."
            )
            await refreshActiveMatchBadge()
            if onboardingStore.shouldPresentOnLaunch, !showsOnboarding {
                showsOnboarding = true
            } else if !onboardingStore.shouldPresentOnLaunch {
                await checkForAppStoreUpdate()
            }
            await consumePendingDeepLink()
        }
        .onChange(of: selectedTab) { _, _ in
            Task { await refreshActiveMatchBadge() }
        }
        .onChange(of: pendingDeepLink.changeCount) { _, _ in
            Task { await consumePendingDeepLink() }
        }
        .onReceive(NotificationCenter.default.publisher(for: LocalAppStateReset.didResetNotification)) { _ in
            appStoreUpdateOffer = nil
            if onboardingStore.shouldPresentOnLaunch {
                showsOnboarding = true
            }
        }
    }

    private func handleModeSelection(_ entry: GameModeCatalogEntry) {
        guard ProductSurface.showsModesTab else { return }
        guard let selection = entry.pendingModeSelection else { return }
        if selection.setupCategory == .party, !ProductSurface.showsPartyModes { return }
        dependencies.pendingMatchPlayerSelections.enqueueModeSelection(selection)
        selectedTab = .play
    }

    private func checkForAppStoreUpdate() async {
        guard appStoreUpdateOffer == nil else { return }
        appStoreUpdateOffer = await AppStoreUpdateChecker().checkForUpdate()
    }

    private var appStoreUpdateAlertBinding: Binding<Bool> {
        Binding(
            get: { appStoreUpdateOffer != nil },
            set: { isPresented in
                if !isPresented {
                    appStoreUpdateOffer = nil
                }
            }
        )
    }

    private func refreshActiveMatchBadge() async {
        let active = try? await dependencies.matchRepository.fetchActiveMatch()
        showsActiveMatchBadge = active.map { ProductSurface.isMatchTypeReachable($0.type) } ?? false
    }

    private func consumePendingDeepLink() async {
        configureIntentRouting()
        guard !showsOnboarding else {
            if pendingDeepLink.hasPending {
                dependencies.logger.info(
                    .ui,
                    eventName: "deep_link_deferred",
                    message: "Deep link waiting for onboarding.",
                    metadata: ["version": DartBuddyURL.pathVersion]
                )
            }
            return
        }
        guard let destination = pendingDeepLink.consumeIfReady(
            bootstrapReady: true,
            onboardingComplete: true
        ) else { return }

        dependencies.logger.info(
            .ui,
            eventName: "deep_link_received",
            message: "Applying deep link.",
            metadata: ["version": DartBuddyURL.pathVersion]
        )

        let router = AppRouteRouter(dependencies: dependencies)
        let outcome = await router.handle(destination, actions: makeRouteActions())

        switch outcome {
        case .applied:
            dependencies.logger.info(
                .ui,
                eventName: "deep_link_applied",
                message: "Deep link routed.",
                metadata: ["version": DartBuddyURL.pathVersion]
            )
        case .failed:
            break
        }
    }

    private func makeRouteActions() -> AppRouteRouter.Actions {
        AppRouteRouter.Actions(
            setSelectedTab: { selectedTab = $0 },
            setPendingPlayResume: { pendingPlayResume = $0 },
            resetPlayNavigation: { playNavigationResetTrigger += 1 }
        )
    }

    private func configureIntentRouting() {
        IntentRoutingBridge.configure(dependencies: dependencies, actions: makeRouteActions())
    }

    private static var startupTab: RootTab {
        let arguments = ProcessInfo.processInfo.arguments
        guard let tabFlagIndex = arguments.firstIndex(of: "-snapshot_tab"),
              arguments.indices.contains(tabFlagIndex + 1),
              let tab = RootTab(snapshotArgument: arguments[tabFlagIndex + 1]) else {
            return .play
        }
        return tab
    }
}
