import SwiftUI

/// iPad root shell: persistent sidebar navigation with a full-width detail column.
struct IPadMainShell: View {
    @Binding var selectedTab: MainTabView.RootTab
    @Binding var pendingPlayResume: PendingMatchResume?
    var playNavigationResetTrigger: Int
    var activityRefreshToken: Int
    var showsActiveMatchBadge: Bool
    let dependencies: AppDependencies
    let preferences: UserPreferencesStore
    var onModeSelection: (GameModeCatalogEntry) -> Void

    var body: some View {
        NavigationSplitView {
            sidebar
                .navigationSplitViewColumnWidth(min: 240, ideal: 280, max: 320)
        } detail: {
            detailContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private var sidebar: some View {
        List {
            Section {
                sidebarRow(.play, title: L10n.tabPlay, systemImage: "house.fill", id: "tab_play")
                if ProductSurface.showsModesTab {
                    sidebarRow(.modes, title: L10n.tabModes, systemImage: "square.grid.2x2.fill", id: "tab_modes")
                }
                sidebarRow(.players, title: L10n.tabPlayers, systemImage: "person.2.fill", id: "tab_players")
                sidebarRow(
                    .activity,
                    title: L10n.tabActivity,
                    systemImage: "clock.arrow.circlepath",
                    id: "tab_activity",
                    badge: showsActiveMatchBadge && selectedTab != .activity ? 1 : nil
                )
                sidebarRow(.settings, title: L10n.tabSettings, systemImage: "gearshape.fill", id: "tab_settings")
            }
        }
        .listStyle(.sidebar)
        .navigationTitle(L10n.brandTitle)
    }

    private func sidebarRow(
        _ tab: MainTabView.RootTab,
        title: LocalizedStringKey,
        systemImage: String,
        id: String,
        badge: Int? = nil
    ) -> some View {
        Button {
            selectedTab = tab
        } label: {
            HStack {
                Label(title, systemImage: systemImage)
                Spacer(minLength: 0)
                if let badge, badge > 0 {
                    Text("\(badge)")
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(Brand.inkOnBright)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Brand.green, in: Capsule())
                }
            }
        }
        .buttonStyle(.plain)
        .listRowBackground(selectedTab == tab ? Brand.cardElevated : Color.clear)
        .accessibilityIdentifier(id)
        .accessibilityAddTraits(selectedTab == tab ? .isSelected : [])
    }

    @ViewBuilder
    private var detailContent: some View {
        switch selectedTab {
        case .play:
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
        case .modes:
            ModesRootView(onSelectMode: onModeSelection)
                .brandScoreboardChrome(appearanceModeRaw: preferences.appearanceModeRaw)
        case .players:
            PlayersRootView(dependencies: dependencies)
                .brandScoreboardChrome(appearanceModeRaw: preferences.appearanceModeRaw)
        case .activity:
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
        case .settings:
            SettingsRootView(dependencies: dependencies)
        }
    }
}
