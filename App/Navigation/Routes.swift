import Foundation

enum PlayRoute: Hashable {
    case setup
    case x01Match(matchId: UUID)
    case cricketMatch(matchId: UUID)
    case baseballMatch(matchId: UUID)
    case killerMatch(matchId: UUID)
    case shanghaiMatch(matchId: UUID)
    case americanCricketMatch(matchId: UUID)
    case mickeyMouseMatch(matchId: UUID)
    case mulliganMatch(matchId: UUID)
    case englishCricketMatch(matchId: UUID)
    case blindKillerMatch(matchId: UUID)
    case knockoutMatch(matchId: UUID)
    case suddenDeathMatch(matchId: UUID)
    case fiftyOneByFivesMatch(matchId: UUID)
    case golfMatch(matchId: UUID)
    case footballMatch(matchId: UUID)
    case grandNationalMatch(matchId: UUID)
    case hareAndHoundsMatch(matchId: UUID)
    case followTheLeaderMatch(matchId: UUID)
    case loopMatch(matchId: UUID)
    case prisonerMatch(matchId: UUID)
    case scamMatch(matchId: UUID)
    case snookerMatch(matchId: UUID)
    case ticTacToeMatch(matchId: UUID)
    case aroundTheClockMatch(matchId: UUID)
    case aroundTheClock180Match(matchId: UUID)
    case chaseTheDragonMatch(matchId: UUID)
    case nineLivesMatch(matchId: UUID)
    case bobs27Match(matchId: UUID)
    case halveItMatch(matchId: UUID)
    case matchSummary(matchId: UUID)
    case historyDetail(matchId: UUID)
}

extension MatchType {
    func playRoute(matchId: UUID) -> PlayRoute {
        switch self {
        case .x01: .x01Match(matchId: matchId)
        case .cricket: .cricketMatch(matchId: matchId)
        case .baseball: .baseballMatch(matchId: matchId)
        case .killer: .killerMatch(matchId: matchId)
        case .shanghai: .shanghaiMatch(matchId: matchId)
        case .americanCricket: .americanCricketMatch(matchId: matchId)
        case .mickeyMouse: .mickeyMouseMatch(matchId: matchId)
        case .mulligan: .mulliganMatch(matchId: matchId)
        case .englishCricket: .englishCricketMatch(matchId: matchId)
        case .blindKiller: .blindKillerMatch(matchId: matchId)
        case .knockout: .knockoutMatch(matchId: matchId)
        case .suddenDeath: .suddenDeathMatch(matchId: matchId)
        case .fiftyOneByFives: .fiftyOneByFivesMatch(matchId: matchId)
        case .golf: .golfMatch(matchId: matchId)
        case .football: .footballMatch(matchId: matchId)
        case .grandNational: .grandNationalMatch(matchId: matchId)
        case .hareAndHounds: .hareAndHoundsMatch(matchId: matchId)
        case .followTheLeader: .followTheLeaderMatch(matchId: matchId)
        case .loop: .loopMatch(matchId: matchId)
        case .prisoner: .prisonerMatch(matchId: matchId)
        case .scam: .scamMatch(matchId: matchId)
        case .snooker: .snookerMatch(matchId: matchId)
        case .ticTacToe: .ticTacToeMatch(matchId: matchId)
        case .aroundTheClock: .aroundTheClockMatch(matchId: matchId)
        case .aroundTheClock180: .aroundTheClock180Match(matchId: matchId)
        case .chaseTheDragon: .chaseTheDragonMatch(matchId: matchId)
        case .nineLives: .nineLivesMatch(matchId: matchId)
        case .bobs27: .bobs27Match(matchId: matchId)
        case .halveIt: .halveItMatch(matchId: matchId)
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
    case matchDetail(matchId: UUID)
}

enum SettingsRoute: Hashable {
    case root
}
