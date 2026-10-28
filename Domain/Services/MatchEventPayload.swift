import Foundation

public enum MatchEventPayload: Codable, Equatable, Sendable {
    case x01Turn(X01TurnEvent)
    case cricketTurn(CricketTurnEvent)
    case baseballTurn(BaseballTurnEvent)
    case killerPick(KillerPickEvent)
    case killerTurn(KillerTurnEvent)
    case shanghaiTurn(ShanghaiTurnEvent)
    case americanCricketTurn(AmericanCricketTurnEvent)
    case mickeyMouseTurn(MickeyMouseTurnEvent)
    case mulliganTurn(MulliganTurnEvent)
    case englishCricketTurn(EnglishCricketTurnEvent)
    case knockoutTurn(KnockoutTurnEvent)
    case suddenDeathTurn(SuddenDeathTurnEvent)
    case fiftyOneByFivesTurn(FiftyOneByFivesTurnEvent)
    case golfTurn(GolfTurnEvent)
    case footballTurn(FootballTurnEvent)
    case grandNationalTurn(GrandNationalTurnEvent)
    case hareAndHoundsTurn(HareAndHoundsTurnEvent)
    case aroundTheClockTurn(AroundTheClockTurnEvent)
    case aroundTheClock180Turn(AroundTheClock180TurnEvent)
    case chaseTheDragonTurn(ChaseTheDragonTurnEvent)
    case nineLivesTurn(NineLivesTurnEvent)
    case fleetPlacement(FleetPlacementEvent)
    case fleetPlacementUI(FleetPlacementUIEvent)
    case fleetSonar(FleetSonarEvent)
    case fleetDart(FleetDartEvent)
    case raidVisit(RaidVisitEvent)
    case bobs27Round(Bobs27RoundEvent)
    case halveItRound(HalveItRoundEvent)
    case scamVisit(ScamVisitEvent)
    case snookerDart(SnookerDartEvent)
    case ticTacToeVisit(TicTacToeVisitEvent)
    case blindKillerTurn(BlindKillerTurnEvent)
    case followTheLeaderVisit(FollowTheLeaderVisitEvent)
    case loopVisit(LoopVisitEvent)
    case prisonerVisit(PrisonerVisitEvent)

    private enum CodingKeys: String, CodingKey {
        case kind
        case x01
        case cricket
        case baseball
        case killerPick
        case killerTurn
        case shanghai
        case americanCricket
        case mickeyMouse
        case mulligan
        case englishCricket
        case knockout
        case suddenDeath
        case fiftyOneByFives
        case golf
        case football
        case grandNational
        case hareAndHounds
        case aroundTheClock
        case aroundTheClock180
        case chaseTheDragon
        case nineLives
        case fleetPlacement
        case fleetPlacementUI
        case fleetSonar
        case fleetDart
        case raidVisit
        case bobs27Round
        case halveItRound
        case scamVisit
        case snookerDart
        case ticTacToeVisit
        case blindKiller
        case followTheLeader
        case loop
        case prisoner
    }

    private enum Kind: String, Codable {
        case x01Turn
        case cricketTurn
        case baseballTurn
        case killerPick
        case killerTurn
        case shanghaiTurn
        case americanCricketTurn
        case mickeyMouseTurn
        case mulliganTurn
        case englishCricketTurn
        case knockoutTurn
        case suddenDeathTurn
        case fiftyOneByFivesTurn
        case golfTurn
        case footballTurn
        case grandNationalTurn
        case hareAndHoundsTurn
        case aroundTheClockTurn
        case aroundTheClock180Turn
        case chaseTheDragonTurn
        case nineLivesTurn
        case fleetPlacement
        case fleetPlacementUI
        case fleetSonar
        case fleetDart
        case raidVisit
        case bobs27Round
        case halveItRound
        case scamVisit
        case snookerDart
        case ticTacToeVisit
        case blindKillerTurn
        case followTheLeaderVisit
        case loopVisit
        case prisonerVisit
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        switch kind {
        case .x01Turn:
            self = .x01Turn(try container.decode(X01TurnEvent.self, forKey: .x01))
        case .cricketTurn:
            self = .cricketTurn(try container.decode(CricketTurnEvent.self, forKey: .cricket))
        case .baseballTurn:
            self = .baseballTurn(try container.decode(BaseballTurnEvent.self, forKey: .baseball))
        case .killerPick:
            self = .killerPick(try container.decode(KillerPickEvent.self, forKey: .killerPick))
        case .killerTurn:
            self = .killerTurn(try container.decode(KillerTurnEvent.self, forKey: .killerTurn))
        case .shanghaiTurn:
            self = .shanghaiTurn(try container.decode(ShanghaiTurnEvent.self, forKey: .shanghai))
        case .americanCricketTurn:
            self = .americanCricketTurn(try container.decode(AmericanCricketTurnEvent.self, forKey: .americanCricket))
        case .mickeyMouseTurn:
            self = .mickeyMouseTurn(try container.decode(MickeyMouseTurnEvent.self, forKey: .mickeyMouse))
        case .mulliganTurn:
            self = .mulliganTurn(try container.decode(MulliganTurnEvent.self, forKey: .mulligan))
        case .englishCricketTurn:
            self = .englishCricketTurn(try container.decode(EnglishCricketTurnEvent.self, forKey: .englishCricket))
        case .knockoutTurn:
            self = .knockoutTurn(try container.decode(KnockoutTurnEvent.self, forKey: .knockout))
        case .suddenDeathTurn:
            self = .suddenDeathTurn(try container.decode(SuddenDeathTurnEvent.self, forKey: .suddenDeath))
        case .fiftyOneByFivesTurn:
            self = .fiftyOneByFivesTurn(try container.decode(FiftyOneByFivesTurnEvent.self, forKey: .fiftyOneByFives))
        case .golfTurn:
            self = .golfTurn(try container.decode(GolfTurnEvent.self, forKey: .golf))
        case .footballTurn:
            self = .footballTurn(try container.decode(FootballTurnEvent.self, forKey: .football))
        case .grandNationalTurn:
            self = .grandNationalTurn(try container.decode(GrandNationalTurnEvent.self, forKey: .grandNational))
        case .hareAndHoundsTurn:
            self = .hareAndHoundsTurn(try container.decode(HareAndHoundsTurnEvent.self, forKey: .hareAndHounds))
        case .aroundTheClockTurn:
            self = .aroundTheClockTurn(try container.decode(AroundTheClockTurnEvent.self, forKey: .aroundTheClock))
        case .aroundTheClock180Turn:
            self = .aroundTheClock180Turn(try container.decode(AroundTheClock180TurnEvent.self, forKey: .aroundTheClock180))
        case .chaseTheDragonTurn:
            self = .chaseTheDragonTurn(try container.decode(ChaseTheDragonTurnEvent.self, forKey: .chaseTheDragon))
        case .nineLivesTurn:
            self = .nineLivesTurn(try container.decode(NineLivesTurnEvent.self, forKey: .nineLives))
        case .fleetPlacement:
            self = .fleetPlacement(try container.decode(FleetPlacementEvent.self, forKey: .fleetPlacement))
        case .fleetPlacementUI:
            self = .fleetPlacementUI(try container.decode(FleetPlacementUIEvent.self, forKey: .fleetPlacementUI))
        case .fleetSonar:
            self = .fleetSonar(try container.decode(FleetSonarEvent.self, forKey: .fleetSonar))
        case .fleetDart:
            self = .fleetDart(try container.decode(FleetDartEvent.self, forKey: .fleetDart))
        case .raidVisit:
            self = .raidVisit(try container.decode(RaidVisitEvent.self, forKey: .raidVisit))
        case .bobs27Round:
            self = .bobs27Round(try container.decode(Bobs27RoundEvent.self, forKey: .bobs27Round))
        case .halveItRound:
            self = .halveItRound(try container.decode(HalveItRoundEvent.self, forKey: .halveItRound))
        case .scamVisit:
            self = .scamVisit(try container.decode(ScamVisitEvent.self, forKey: .scamVisit))
        case .snookerDart:
            self = .snookerDart(try container.decode(SnookerDartEvent.self, forKey: .snookerDart))
        case .ticTacToeVisit:
            self = .ticTacToeVisit(try container.decode(TicTacToeVisitEvent.self, forKey: .ticTacToeVisit))
        case .blindKillerTurn:
            self = .blindKillerTurn(try container.decode(BlindKillerTurnEvent.self, forKey: .blindKiller))
        case .followTheLeaderVisit:
            self = .followTheLeaderVisit(try container.decode(FollowTheLeaderVisitEvent.self, forKey: .followTheLeader))
        case .loopVisit:
            self = .loopVisit(try container.decode(LoopVisitEvent.self, forKey: .loop))
        case .prisonerVisit:
            self = .prisonerVisit(try container.decode(PrisonerVisitEvent.self, forKey: .prisoner))
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .x01Turn(event):
            try container.encode(Kind.x01Turn, forKey: .kind)
            try container.encode(event, forKey: .x01)
        case let .cricketTurn(event):
            try container.encode(Kind.cricketTurn, forKey: .kind)
            try container.encode(event, forKey: .cricket)
        case let .baseballTurn(event):
            try container.encode(Kind.baseballTurn, forKey: .kind)
            try container.encode(event, forKey: .baseball)
        case let .killerPick(event):
            try container.encode(Kind.killerPick, forKey: .kind)
            try container.encode(event, forKey: .killerPick)
        case let .killerTurn(event):
            try container.encode(Kind.killerTurn, forKey: .kind)
            try container.encode(event, forKey: .killerTurn)
        case let .shanghaiTurn(event):
            try container.encode(Kind.shanghaiTurn, forKey: .kind)
            try container.encode(event, forKey: .shanghai)
        case let .americanCricketTurn(event):
            try container.encode(Kind.americanCricketTurn, forKey: .kind)
            try container.encode(event, forKey: .americanCricket)
        case let .mickeyMouseTurn(event):
            try container.encode(Kind.mickeyMouseTurn, forKey: .kind)
            try container.encode(event, forKey: .mickeyMouse)
        case let .mulliganTurn(event):
            try container.encode(Kind.mulliganTurn, forKey: .kind)
            try container.encode(event, forKey: .mulligan)
        case let .englishCricketTurn(event):
            try container.encode(Kind.englishCricketTurn, forKey: .kind)
            try container.encode(event, forKey: .englishCricket)
        case let .knockoutTurn(event):
            try container.encode(Kind.knockoutTurn, forKey: .kind)
            try container.encode(event, forKey: .knockout)
        case let .suddenDeathTurn(event):
            try container.encode(Kind.suddenDeathTurn, forKey: .kind)
            try container.encode(event, forKey: .suddenDeath)
        case let .fiftyOneByFivesTurn(event):
            try container.encode(Kind.fiftyOneByFivesTurn, forKey: .kind)
            try container.encode(event, forKey: .fiftyOneByFives)
        case let .golfTurn(event):
            try container.encode(Kind.golfTurn, forKey: .kind)
            try container.encode(event, forKey: .golf)
        case let .footballTurn(event):
            try container.encode(Kind.footballTurn, forKey: .kind)
            try container.encode(event, forKey: .football)
        case let .grandNationalTurn(event):
            try container.encode(Kind.grandNationalTurn, forKey: .kind)
            try container.encode(event, forKey: .grandNational)
        case let .hareAndHoundsTurn(event):
            try container.encode(Kind.hareAndHoundsTurn, forKey: .kind)
            try container.encode(event, forKey: .hareAndHounds)
        case let .aroundTheClockTurn(event):
            try container.encode(Kind.aroundTheClockTurn, forKey: .kind)
            try container.encode(event, forKey: .aroundTheClock)
        case let .aroundTheClock180Turn(event):
            try container.encode(Kind.aroundTheClock180Turn, forKey: .kind)
            try container.encode(event, forKey: .aroundTheClock180)
        case let .chaseTheDragonTurn(event):
            try container.encode(Kind.chaseTheDragonTurn, forKey: .kind)
            try container.encode(event, forKey: .chaseTheDragon)
        case let .nineLivesTurn(event):
            try container.encode(Kind.nineLivesTurn, forKey: .kind)
            try container.encode(event, forKey: .nineLives)
        case let .fleetPlacement(event):
            try container.encode(Kind.fleetPlacement, forKey: .kind)
            try container.encode(event, forKey: .fleetPlacement)
        case let .fleetPlacementUI(event):
            try container.encode(Kind.fleetPlacementUI, forKey: .kind)
            try container.encode(event, forKey: .fleetPlacementUI)
        case let .fleetSonar(event):
            try container.encode(Kind.fleetSonar, forKey: .kind)
            try container.encode(event, forKey: .fleetSonar)
        case let .fleetDart(event):
            try container.encode(Kind.fleetDart, forKey: .kind)
            try container.encode(event, forKey: .fleetDart)
        case let .raidVisit(event):
            try container.encode(Kind.raidVisit, forKey: .kind)
            try container.encode(event, forKey: .raidVisit)
        case let .bobs27Round(event):
            try container.encode(Kind.bobs27Round, forKey: .kind)
            try container.encode(event, forKey: .bobs27Round)
        case let .halveItRound(event):
            try container.encode(Kind.halveItRound, forKey: .kind)
            try container.encode(event, forKey: .halveItRound)
        case let .scamVisit(event):
            try container.encode(Kind.scamVisit, forKey: .kind)
            try container.encode(event, forKey: .scamVisit)
        case let .snookerDart(event):
            try container.encode(Kind.snookerDart, forKey: .kind)
            try container.encode(event, forKey: .snookerDart)
        case let .ticTacToeVisit(event):
            try container.encode(Kind.ticTacToeVisit, forKey: .kind)
            try container.encode(event, forKey: .ticTacToeVisit)
        case let .blindKillerTurn(event):
            try container.encode(Kind.blindKillerTurn, forKey: .kind)
            try container.encode(event, forKey: .blindKiller)
        case let .followTheLeaderVisit(event):
            try container.encode(Kind.followTheLeaderVisit, forKey: .kind)
            try container.encode(event, forKey: .followTheLeader)
        case let .loopVisit(event):
            try container.encode(Kind.loopVisit, forKey: .kind)
            try container.encode(event, forKey: .loop)
        case let .prisonerVisit(event):
            try container.encode(Kind.prisonerVisit, forKey: .kind)
            try container.encode(event, forKey: .prisoner)
        }
    }
}
