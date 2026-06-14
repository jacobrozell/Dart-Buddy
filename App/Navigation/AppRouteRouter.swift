import Foundation

enum RouteOutcome: Equatable {
    case applied
    case failed(DeepLinkError)
}

@MainActor
struct AppRouteRouter {
    struct Actions {
        var setSelectedTab: (MainTabView.RootTab) -> Void
        var setPendingPlayResume: (MatchSummary?) -> Void
        var resetPlayNavigation: () -> Void
    }

    let dependencies: AppDependencies

    func handle(_ destination: AppDestination, actions: Actions) async -> RouteOutcome {
        switch destination {
        case let .tab(tab):
            actions.setSelectedTab(tab.rootTab)
            return .applied

        case let .play(playLink):
            return await handlePlay(playLink, actions: actions)

        case .activity, .players, .settings:
            return .failed(.unknownPath)
        }
    }

    private func handlePlay(_ link: PlayDeepLink, actions: Actions) async -> RouteOutcome {
        switch link {
        case .home:
            actions.setSelectedTab(.play)
            actions.resetPlayNavigation()
            return .applied

        case .resumeActive:
            actions.setSelectedTab(.play)
            do {
                if let match = try await dependencies.matchRepository.fetchActiveMatch(),
                   ProductSurface.isMatchTypeReachable(match.type) {
                    actions.setPendingPlayResume(match)
                    return .applied
                }
                dependencies.logger.info(
                    .ui,
                    eventName: "deep_link_failed",
                    message: "Resume deep link with no active match.",
                    metadata: ["path": "play/resume", "version": DartBuddyURL.pathVersion]
                )
                return .failed(.unknownPath)
            } catch {
                dependencies.logger.info(
                    .ui,
                    eventName: "deep_link_failed",
                    message: "Resume deep link fetch failed.",
                    metadata: ["path": "play/resume", "version": DartBuddyURL.pathVersion]
                )
                return .failed(.unknownPath)
            }

        case .setup, .activeMatch, .matchSummary:
            return .failed(.unknownPath)
        }
    }
}

private extension TabDestination {
    var rootTab: MainTabView.RootTab {
        switch self {
        case .play: .play
        case .modes: ProductSurface.showsModesTab ? .modes : .play
        case .players: .players
        case .activity: .activity
        case .settings: .settings
        }
    }
}
