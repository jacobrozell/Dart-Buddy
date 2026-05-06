import SwiftUI

struct MainTabView: View {
    let dependencies: AppDependencies

    var body: some View {
        TabView {
            PlayRootView(dependencies: dependencies)
                .tabItem { Label("Play", systemImage: "figure.darts") }
            HistoryRootView(dependencies: dependencies)
                .tabItem { Label("History", systemImage: "clock.arrow.circlepath") }
            PlayersRootView(dependencies: dependencies)
                .tabItem { Label("Players", systemImage: "person.2") }
            SettingsRootView(dependencies: dependencies)
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
}
