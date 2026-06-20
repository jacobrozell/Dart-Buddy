import SwiftUI

/// iPhone root shell: bottom tab bar (unchanged from pre-iPad redesign).
struct PhoneTabShell: View {
    @Binding var selectedTab: MainTabView.RootTab
    @Binding var pendingPlayResume: PendingMatchResume?
    var playNavigationResetTrigger: Int
    var activityRefreshToken: Int
    var showsActiveMatchBadge: Bool
    let dependencies: AppDependencies
    let preferences: UserPreferencesStore
    var onModeSelection: (GameModeCatalogEntry) -> Void

    var body: some View {
        TabView(selection: $selectedTab) {
            PlayRootView(
                dependencies: dependencies,
                pendingResumeMatch: $pendingPlayResume,
                navigationResetTrigger: playNavigationResetTrigger,
                onChangeMode: {
                    if ProductSurface.showsModesTab {
                        selectedTab = .modes
                    }
                }
            )
            .brandScoreboardChrome(appearanceModeRaw: preferences.appearanceModeRaw)
            .tag(MainTabView.RootTab.play)
            .tabItem {
                Label(L10n.tabPlay, systemImage: "house.fill")
                    .accessibilityIdentifier("tab_play")
            }
            if ProductSurface.showsModesTab {
                ModesRootView(onSelectMode: onModeSelection)
                    .brandScoreboardChrome(appearanceModeRaw: preferences.appearanceModeRaw)
                    .tag(MainTabView.RootTab.modes)
                    .tabItem {
                        Label(L10n.tabModes, systemImage: "square.grid.2x2.fill")
                            .accessibilityIdentifier("tab_modes")
                    }
            }
            PlayersRootView(dependencies: dependencies)
                .brandScoreboardChrome(appearanceModeRaw: preferences.appearanceModeRaw)
                .tag(MainTabView.RootTab.players)
                .tabItem {
                    Label(L10n.tabPlayers, systemImage: "person.2.fill")
                        .accessibilityIdentifier("tab_players")
                }
            ActivityRootView(
                dependencies: dependencies,
                refreshToken: activityRefreshToken,
                onResumeActiveMatch: { match in
                    guard ProductSurface.isMatchTypeReachable(match.type) else { return }
                    pendingPlayResume = PendingMatchResume(match: match, startSource: .resume)
                    selectedTab = .play
                },
                onStartMatch: { selectedTab = .play }
            )
            .brandScoreboardChrome(appearanceModeRaw: preferences.appearanceModeRaw)
            .tag(MainTabView.RootTab.activity)
            .tabItem {
                Label(L10n.tabActivity, systemImage: "clock.arrow.circlepath")
                    .accessibilityIdentifier("tab_activity")
            }
            .badge(showsActiveMatchBadge && selectedTab != .activity ? 1 : 0)
            SettingsRootView(dependencies: dependencies)
                .tag(MainTabView.RootTab.settings)
                .tabItem {
                    Label(L10n.tabSettings, systemImage: "gearshape.fill")
                        .accessibilityIdentifier("tab_settings")
                }
        }
    }
}
