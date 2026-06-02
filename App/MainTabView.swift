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

    init(dependencies: AppDependencies) {
        self.dependencies = dependencies
        _preferencesStore = ObservedObject(wrappedValue: dependencies.userPreferencesStore)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            PlayRootView(dependencies: dependencies)
                .tag(RootTab.play)
                .tabItem { Label("Home", systemImage: "house.fill") }
            PlayersRootView(dependencies: dependencies)
                .tag(RootTab.players)
                .tabItem { Label("Players", systemImage: "person.2.fill") }
            StatisticsRootView(dependencies: dependencies)
                .tag(RootTab.statistics)
                .tabItem { Label("Statistics", systemImage: "chart.bar.fill") }
            HistoryRootView(dependencies: dependencies)
                .tag(RootTab.history)
                .tabItem { Label("All Games", systemImage: "clock.arrow.circlepath") }
            SettingsRootView(dependencies: dependencies)
                .tag(RootTab.settings)
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
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
        }
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
