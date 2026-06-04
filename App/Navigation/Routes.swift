import Foundation

enum PlayRoute: Hashable {
    case setup
    case x01Match(matchId: UUID)
    case cricketMatch(matchId: UUID)
    case baseballMatch(matchId: UUID)
    case matchSummary(matchId: UUID)
    case historyDetail(matchId: UUID)
    case quickAddPlayer
}

extension MatchType {
    func playRoute(matchId: UUID) -> PlayRoute {
        switch self {
        case .x01: .x01Match(matchId: matchId)
        case .cricket: .cricketMatch(matchId: matchId)
        case .baseball: .baseballMatch(matchId: matchId)
        }
    }
}

enum HistoryRoute: Hashable {
    case list
    case detail(matchId: UUID)
}

enum PlayersRoute: Hashable {
    case list
    case detail(playerId: UUID)
    case edit(playerId: UUID?)
}

enum SettingsRoute: Hashable {
    case root
}
