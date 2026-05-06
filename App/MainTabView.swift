import SwiftUI

struct MainTabView: View {
    enum RootTab: String, CaseIterable {
        case play
        case history
        case players
        case settings
    }

    let dependencies: AppDependencies
    @State private var selectedTab: RootTab = MainTabView.startupTab

    var body: some View {
        TabView(selection: $selectedTab) {
            PlayRootView(dependencies: dependencies)
                .tag(RootTab.play)
                .tabItem { Label("Play", systemImage: "target") }
            HistoryRootView(dependencies: dependencies)
                .tag(RootTab.history)
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
            PlayersRootView(dependencies: dependencies)
                .tag(RootTab.players)
                .tabItem { Label("Players", systemImage: "person.2") }
            SettingsRootView(dependencies: dependencies)
                .tag(RootTab.settings)
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
        .background(ThemeTokens.appBackground)
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
