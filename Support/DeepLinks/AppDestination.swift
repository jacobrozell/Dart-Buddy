import Foundation

enum AppDestination: Equatable {
    case tab(TabDestination)
    case play(PlayDeepLink)
    case activity(ActivityDeepLink)
    case players(PlayersDeepLink)
    case settings(SettingsDeepLink)
}

enum TabDestination: String, Equatable {
    case play
    case modes
    case players
    case activity
    case settings
}

enum PlayDeepLink: Equatable {
    case home
    case resumeActive
    case setup(SetupDeepLinkParams)
    case activeMatch(matchId: UUID)
    case matchSummary(matchId: UUID)
}

enum ActivityDeepLink: Equatable {
    case root(segment: ActivitySegment)
    case historyDetail(matchId: UUID)
}

enum PlayersDeepLink: Equatable {
    case detail(playerId: UUID)
}

enum SettingsDeepLink: Equatable {
    case root
}

struct SetupDeepLinkParams: Equatable {
    var catalogModeId: String?
    var matchType: MatchType?
    var startScore: Int?
    var playerIds: [UUID]?
}
