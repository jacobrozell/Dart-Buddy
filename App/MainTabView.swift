import SwiftUI

struct MainTabView: View {
    enum RootTab: String, CaseIterable {
        case play
        case history
        case players
        case statistics
        case settings
    }

    let dependencies: AppDependencies
    @ObservedObject private var preferencesStore: UserPreferencesStore
    @State private var selectedTab: RootTab = MainTabView.startupTab
    @State private var pendingPlayResume: MatchSummary?
    @State private var showsActiveMatchBadge = false

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _preferencesStore = ObservedObject(wrappedValue: dependencies.userPreferencesStore)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            PlayRootView(dependencies: dependencies, pendingResumeMatch: $pendingPlayResume)
                .tag(RootTab.play)
                .tabItem { Label(L10n.tabPlay, systemImage: "house.fill") }
            PlayersRootView(dependencies: dependencies)
                .tag(RootTab.players)
                .tabItem { Label(L10n.tabPlayers, systemImage: "person.2.fill") }
            StatisticsRootView(dependencies: dependencies, onStartMatch: { selectedTab = .play })
                .tag(RootTab.statistics)
                .tabItem { Label(L10n.tabStatistics, systemImage: "chart.bar.fill") }
            HistoryRootView(dependencies: dependencies, onResumeActiveMatch: { match in
                pendingPlayResume = match
                selectedTab = .play
            }, onStartMatch: { selectedTab = .play })
                .tag(RootTab.history)
                .tabItem { Label(L10n.tabHistory, systemImage: "clock.arrow.circlepath") }
                .badge(showsActiveMatchBadge ? " " : nil)
            SettingsRootView(dependencies: dependencies)
                .tag(RootTab.settings)
                .tabItem { Label(L10n.tabSettings, systemImage: "gearshape.fill") }
        }
        .tint(Brand.green)
        .preferredColorScheme(preferencesStore.preferredColorScheme)
        .background(Brand.background)
        .task {
            dependencies.logger.debug(
                .ui,
                eventName: "main_tab_presented",
                message: "Main tab shell rendered."
            )
            await refreshActiveMatchBadge()
        }
        .onChange(of: selectedTab) { _, _ in
            Task { await refreshActiveMatchBadge() }
        }
    }

    private func refreshActiveMatchBadge() async {
        showsActiveMatchBadge = (try? await dependencies.matchRepository.fetchActiveMatch()) != nil
    }

    private static var startupTab: RootTab {
        let arguments = ProcessInfo.processInfo.arguments
        guard let tabFlagIndex = arguments.firstIndex(of: "-snapshot_tab"),
              arguments.indices.contains(tabFlagIndex + 1),
              let tab = RootTab(rawValue: arguments[tabFlagIndex + 1]) else {
            return .play
        }
        return tab
    }
}
