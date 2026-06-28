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

public struct MatchEventEnvelope: Codable, Equatable, Sendable {
    public let payloadVersion: Int
    public let eventIndex: Int
    public let payload: MatchEventPayload
    public let timestamp: Date

    public init(payloadVersion: Int = 1, eventIndex: Int, payload: MatchEventPayload, timestamp: Date) {
        self.payloadVersion = payloadVersion
        self.eventIndex = eventIndex
        self.payload = payload
        self.timestamp = timestamp
    }
}

public struct MatchRuntimeState: Codable, Equatable, Sendable {
    public let matchId: UUID
    public let type: MatchType
    public let config: MatchConfigPayload
    public let participants: [MatchParticipant]
    public var status: MatchLifecycleStatus
    public var startedAt: Date
    public var endedAt: Date?
    public var winnerPlayerId: UUID?
    public var forfeitedByPlayerId: UUID?
    public var currentTurnPlayerId: UUID?
    public var currentLegIndex: Int
    public var currentSetIndex: Int
    public var eventCount: Int
    public var x01State: X01State?
    public var cricketState: CricketState?
    public var baseballState: BaseballState?
    public var killerState: KillerState?
    public var shanghaiState: ShanghaiState?
    public var americanCricketState: AmericanCricketState?
    public var mickeyMouseState: MickeyMouseState?
    public var mulliganState: MulliganState?
    public var englishCricketState: EnglishCricketState?
    public var knockoutState: KnockoutState?
    public var suddenDeathState: SuddenDeathState?
    public var fiftyOneByFivesState: FiftyOneByFivesState?
    public var golfState: GolfState?
    public var footballState: FootballState?
    public var grandNationalState: GrandNationalState?
    public var hareAndHoundsState: HareAndHoundsState?
    public var aroundTheClockState: AroundTheClockState?
    public var aroundTheClock180State: AroundTheClock180State?
    public var chaseTheDragonState: ChaseTheDragonState?
    public var nineLivesState: NineLivesState?
    public var fleetState: FleetState?
    public var raidState: RaidState?
    public var bobs27State: Bobs27State?
    public var halveItState: HalveItState?
    public var scamState: ScamState?
    public var snookerState: SnookerState?
    public var ticTacToeState: TicTacToeState?
    public var blindKillerState: BlindKillerState?
    public var followTheLeaderState: FollowTheLeaderState?
    public var loopState: LoopState?
    public var prisonerState: PrisonerState?
}

public struct MatchLifecycleSession: Sendable {
    public var runtime: MatchRuntimeState
    public var events: [MatchEventEnvelope]
    public var latestSnapshot: MatchSnapshot
}

public struct UndoLastDartResult: Sendable {
    public let session: MatchLifecycleSession
    /// Remaining darts from the reverted visit, ready for continued entry.
    public let restoredDarts: [DartInput]
}

public enum MatchLifecycleService {
    public static let snapshotInterval = MatchLifecycleCoordinator.snapshotInterval

    public static func createMatch(
        matchId: UUID = UUID(),
        type: MatchType,
        config: MatchConfigPayload,
        participants: [MatchParticipant],
        startedAt: Date = Date()
    ) throws -> MatchLifecycleSession {
        let minimumParticipants = GameModeCatalog.entry(for: type)?.minimumPlayers ?? 2
        guard participants.count >= minimumParticipants else {
            throw AppError(code: .validationFailed, layer: .domain, severity: .warning, isRecoverable: true, userMessageKey: "error.match.players.minimum")
        }
        let ordered = participants.sorted(by: { $0.turnOrder < $1.turnOrder })
        let playerIds = ordered.map { $0.playerId ?? $0.id }
        let effectiveConfig: MatchConfigPayload
        if case let (.blindKiller, .blindKiller(cfg)) = (type, config) {
            effectiveConfig = .blindKiller(BlindKillerEngine.resolvedConfig(cfg, playerIds: playerIds))
        } else {
            effectiveConfig = config
        }
        var runtime = MatchRuntimeState(
            matchId: matchId,
            type: type,
            config: effectiveConfig,
            participants: ordered,
            status: .inProgress,
            startedAt: startedAt,
            endedAt: nil,
            winnerPlayerId: nil,
            forfeitedByPlayerId: nil,
            currentTurnPlayerId: ordered.first?.playerId ?? ordered.first?.id,
            currentLegIndex: 0,
            currentSetIndex: 0,
            eventCount: 0,
            x01State: nil,
            cricketState: nil,
            baseballState: nil,
            killerState: nil,
            shanghaiState: nil,
            americanCricketState: nil,
            mickeyMouseState: nil,
            mulliganState: nil,
            englishCricketState: nil,
            knockoutState: nil,
            suddenDeathState: nil,
            fiftyOneByFivesState: nil,
            golfState: nil,
            footballState: nil,
            grandNationalState: nil,
            hareAndHoundsState: nil,
            aroundTheClockState: nil,
            aroundTheClock180State: nil,
            chaseTheDragonState: nil,
            nineLivesState: nil,
            fleetState: nil,
            raidState: nil,
            bobs27State: nil,
            halveItState: nil,
            scamState: nil,
            snookerState: nil,
            ticTacToeState: nil,
            blindKillerState: nil,
            followTheLeaderState: nil,
            loopState: nil,
            prisonerState: nil
        )

        switch (type, config) {
        case let (.x01, .x01(cfg)):
            runtime.x01State = try X01Engine.makeInitialState(config: cfg, playerIds: playerIds)
        case let (.cricket, .cricket(cfg)):
            runtime.cricketState = try CricketEngine.makeInitialState(config: cfg, playerIds: playerIds)
        case let (.baseball, .baseball(cfg)):
            runtime.baseballState = try BaseballEngine.makeInitialState(config: cfg, playerIds: playerIds)
        case let (.killer, .killer(cfg)):
            runtime.killerState = try KillerEngine.makeInitialState(config: cfg, playerIds: playerIds)
        case let (.shanghai, .shanghai(cfg)):
            runtime.shanghaiState = try ShanghaiEngine.makeInitialState(config: cfg, playerIds: playerIds)
        case let (.americanCricket, .americanCricket(cfg)):
            runtime.americanCricketState = try AmericanCricketEngine.makeInitialState(config: cfg, playerIds: playerIds)
        case let (.mickeyMouse, .mickeyMouse(cfg)):
            runtime.mickeyMouseState = try MickeyMouseEngine.makeInitialState(config: cfg, playerIds: playerIds)
        case let (.mulligan, .mulligan(cfg)):
            runtime.mulliganState = try MulliganEngine.makeInitialState(config: cfg, playerIds: playerIds)
        case let (.englishCricket, .englishCricket(cfg)):
            runtime.englishCricketState = try EnglishCricketEngine.makeInitialState(config: cfg, playerIds: playerIds)
        case let (.knockout, .knockout(cfg)):
            runtime.knockoutState = try KnockoutEngine.makeInitialState(config: cfg, playerIds: playerIds)
        case let (.suddenDeath, .suddenDeath(cfg)):
            runtime.suddenDeathState = try SuddenDeathEngine.makeInitialState(config: cfg, playerIds: playerIds)
        case let (.fiftyOneByFives, .fiftyOneByFives(cfg)):
            runtime.fiftyOneByFivesState = try FiftyOneByFivesEngine.makeInitialState(config: cfg, playerIds: playerIds)
        case let (.golf, .golf(cfg)):
            runtime.golfState = try GolfEngine.makeInitialState(config: cfg, playerIds: playerIds)
        case let (.football, .football(cfg)):
            runtime.footballState = try FootballEngine.makeInitialState(config: cfg, playerIds: playerIds)
        case let (.grandNational, .grandNational(cfg)):
            runtime.grandNationalState = try GrandNationalEngine.makeInitialState(config: cfg, playerIds: playerIds)
        case let (.hareAndHounds, .hareAndHounds(cfg)):
            runtime.hareAndHoundsState = try HareAndHoundsEngine.makeInitialState(config: cfg, playerIds: playerIds)
        case let (.aroundTheClock, .aroundTheClock(cfg)):
            runtime.aroundTheClockState = try AroundTheClockEngine.makeInitialState(config: cfg, playerIds: playerIds)
        case let (.aroundTheClock180, .aroundTheClock180(cfg)):
            runtime.aroundTheClock180State = try AroundTheClock180Engine.makeInitialState(config: cfg, playerIds: playerIds)
        case let (.chaseTheDragon, .chaseTheDragon(cfg)):
            runtime.chaseTheDragonState = try ChaseTheDragonEngine.makeInitialState(config: cfg, playerIds: playerIds)
        case let (.nineLives, .nineLives(cfg)):
            runtime.nineLivesState = try NineLivesEngine.makeInitialState(config: cfg, playerIds: playerIds)
        case let (.fleet, .fleet(cfg)):
            runtime.fleetState = try FleetEngine.makeInitialState(config: cfg, playerIds: playerIds)
        case let (.raid, .raid(cfg)):
            runtime.raidState = try RaidEngine.makeInitialState(config: cfg, playerIds: playerIds)
        case let (.bobs27, .bobs27(cfg)):
            runtime.bobs27State = try Bobs27Engine.makeInitialState(config: cfg, playerIds: playerIds)
        case let (.halveIt, .halveIt(cfg)):
            runtime.halveItState = try HalveItEngine.makeInitialState(config: cfg, playerIds: playerIds)
        case let (.scam, .scam(cfg)):
            runtime.scamState = try ScamEngine.makeInitialState(config: cfg, playerIds: playerIds)
        case let (.snooker, .snooker(cfg)):
            runtime.snookerState = try SnookerEngine.makeInitialState(config: cfg, playerIds: playerIds)
        case let (.ticTacToe, .ticTacToe(cfg)):
            runtime.ticTacToeState = try TicTacToeEngine.makeInitialState(config: cfg, playerIds: playerIds)
        case let (.blindKiller, .blindKiller(cfg)):
            runtime.blindKillerState = try BlindKillerEngine.makeInitialState(config: cfg, playerIds: playerIds)
        case let (.followTheLeader, .followTheLeader(cfg)):
            runtime.followTheLeaderState = try FollowTheLeaderEngine.makeInitialState(config: cfg, playerIds: playerIds)
        case let (.loop, .loop(cfg)):
            runtime.loopState = try LoopEngine.makeInitialState(config: cfg, playerIds: playerIds)
        case let (.prisoner, .prisoner(cfg)):
            runtime.prisonerState = try PrisonerEngine.makeInitialState(config: cfg, playerIds: playerIds)
        default:
            throw AppError(code: .validationFailed, layer: .domain, severity: .warning, isRecoverable: true, userMessageKey: "error.match.configMismatch")
        }

        MatchRuntimeProjection.project(&runtime, timestamp: startedAt)
        let initialSnapshot = try MatchLifecycleCoordinator.makeSnapshot(from: runtime, eventCount: 0, timestamp: startedAt)
        return MatchLifecycleSession(runtime: runtime, events: [], latestSnapshot: initialSnapshot)
    }

    /// Marks an in-progress match as abandoned (e.g. the player left mid-match).
    /// Completed matches are returned unchanged so we never overwrite a result.
    public static func abandon(
        session: MatchLifecycleSession,
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard session.runtime.status == .inProgress else { return session }
        var runtime = session.runtime
        runtime.status = .abandoned
        runtime.endedAt = timestamp
        runtime.currentTurnPlayerId = nil
        let snapshot = try MatchLifecycleCoordinator.makeSnapshot(from: runtime, eventCount: runtime.eventCount, timestamp: timestamp)
        return MatchLifecycleSession(runtime: runtime, events: session.events, latestSnapshot: snapshot)
    }

    /// Ends an in-progress match early while preserving scored events.
    public static func forfeit(
        session: MatchLifecycleSession,
        forfeitingPlayerId: UUID,
        winnerPlayerId: UUID?,
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        let status = session.runtime.status
        guard status == .inProgress else { return session }
        guard session.runtime.eventCount >= 1 else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.forfeit.invalid"
            )
        }

        let participantKeys = session.runtime.participants.map { $0.playerId ?? $0.id }
        guard participantKeys.contains(forfeitingPlayerId) else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.forfeit.invalid"
            )
        }

        let isSolo = session.runtime.participants.count == 1
        if isSolo {
            if let winnerPlayerId, winnerPlayerId != forfeitingPlayerId {
                throw AppError(
                    code: .validationFailed,
                    layer: .domain,
                    severity: .warning,
                    isRecoverable: true,
                    userMessageKey: "error.match.forfeit.invalid"
                )
            }
        } else {
            guard let winnerPlayerId, winnerPlayerId != forfeitingPlayerId else {
                throw AppError(
                    code: .validationFailed,
                    layer: .domain,
                    severity: .warning,
                    isRecoverable: true,
                    userMessageKey: "error.match.forfeit.invalid"
                )
            }
            guard participantKeys.contains(winnerPlayerId) else {
                throw AppError(
                    code: .validationFailed,
                    layer: .domain,
                    severity: .warning,
                    isRecoverable: true,
                    userMessageKey: "error.match.forfeit.invalid"
                )
            }
        }

        var runtime = session.runtime
        runtime.status = .forfeited
        runtime.endedAt = timestamp
        runtime.forfeitedByPlayerId = forfeitingPlayerId
        runtime.winnerPlayerId = winnerPlayerId
        runtime.currentTurnPlayerId = nil
        let snapshot = try MatchLifecycleCoordinator.makeSnapshot(from: runtime, eventCount: runtime.eventCount, timestamp: timestamp)
        return MatchLifecycleSession(runtime: runtime, events: session.events, latestSnapshot: snapshot)
    }

    public static func submitX01Turn(
        session: MatchLifecycleSession,
        enteredTotal: Int?,
        darts: [DartInput]?,
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        try X01MatchLifecycleHandler.submitTurn(
            session: session,
            enteredTotal: enteredTotal,
            darts: darts,
            timestamp: timestamp
        )
    }

    public static func submitCricketTurn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        try CricketMatchLifecycleHandler.submitTurn(session: session, darts: darts, timestamp: timestamp)
    }

    public static func submitBaseballTurn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        try BaseballMatchLifecycleHandler.submitTurn(session: session, darts: darts, timestamp: timestamp)
    }

    public static func submitKillerPick(
        session: MatchLifecycleSession,
        dart: DartInput,
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        try KillerMatchLifecycleHandler.submitPick(session: session, dart: dart, timestamp: timestamp)
    }

    public static func submitKillerTurn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        try KillerMatchLifecycleHandler.submitTurn(session: session, darts: darts, timestamp: timestamp)
    }

    public static func submitShanghaiTurn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        try ShanghaiMatchLifecycleHandler.submitTurn(session: session, darts: darts, timestamp: timestamp)
    }

    public static func submitAmericanCricketTurn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        try AmericanCricketMatchLifecycleHandler.submitTurn(session: session, darts: darts, timestamp: timestamp)
    }

    public static func submitMickeyMouseTurn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        try MickeyMouseMatchLifecycleHandler.submitTurn(session: session, darts: darts, timestamp: timestamp)
    }

    public static func submitMulliganTurn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        try MulliganMatchLifecycleHandler.submitTurn(session: session, darts: darts, timestamp: timestamp)
    }

    public static func submitEnglishCricketTurn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        try EnglishCricketMatchLifecycleHandler.submitTurn(session: session, darts: darts, timestamp: timestamp)
    }

    public static func submitKnockoutTurn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        try KnockoutMatchLifecycleHandler.submitTurn(session: session, darts: darts, timestamp: timestamp)
    }

    public static func submitSuddenDeathTurn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        try SuddenDeathMatchLifecycleHandler.submitTurn(session: session, darts: darts, timestamp: timestamp)
    }

    public static func submitFiftyOneByFivesTurn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        try FiftyOneByFivesMatchLifecycleHandler.submitTurn(session: session, darts: darts, timestamp: timestamp)
    }

    public static func submitGolfTurn(
        session: MatchLifecycleSession,
        input: GolfTurnInput,
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        try GolfMatchLifecycleHandler.submitTurn(session: session, input: input, timestamp: timestamp)
    }

    public static func submitFootballTurn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        try FootballMatchLifecycleHandler.submitTurn(session: session, darts: darts, timestamp: timestamp)
    }

    public static func submitGrandNationalTurn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        try GrandNationalMatchLifecycleHandler.submitTurn(session: session, darts: darts, timestamp: timestamp)
    }

    public static func submitHareAndHoundsTurn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        try HareAndHoundsMatchLifecycleHandler.submitTurn(session: session, darts: darts, timestamp: timestamp)
    }

    public static func submitAroundTheClockTurn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        try AroundTheClockMatchLifecycleHandler.submitTurn(session: session, darts: darts, timestamp: timestamp)
    }

    public static func submitAroundTheClock180Turn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        try AroundTheClock180MatchLifecycleHandler.submitTurn(session: session, darts: darts, timestamp: timestamp)
    }

    public static func submitChaseTheDragonTurn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        try ChaseTheDragonMatchLifecycleHandler.submitTurn(session: session, darts: darts, timestamp: timestamp)
    }

    public static func submitNineLivesTurn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        try NineLivesMatchLifecycleHandler.submitTurn(session: session, darts: darts, timestamp: timestamp)
    }

    public static func submitBobs27Turn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var state = session.runtime.bobs27State else {
            throw AppError(code: .invalidGameState, layer: .domain, severity: .error, isRecoverable: true, userMessageKey: "error.match.mode.bobs27Unavailable")
        }
        let outcome = try Bobs27Engine.submitTurn(state: state, darts: darts, timestamp: timestamp)
        state = outcome.updatedState
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .bobs27Round(outcome.event),
            timestamp: timestamp
        )
        return try appendAndProject(session: session, newEvent: envelope, timestamp: timestamp) { runtime in
            runtime.bobs27State = state
        }
    }

    public static func submitHalveItTurn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var state = session.runtime.halveItState else {
            throw AppError(code: .invalidGameState, layer: .domain, severity: .error, isRecoverable: true, userMessageKey: "error.match.mode.halveItUnavailable")
        }
        let outcome = try HalveItEngine.submitTurn(state: state, darts: darts, timestamp: timestamp)
        state = outcome.updatedState
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .halveItRound(outcome.event),
            timestamp: timestamp
        )
        return try appendAndProject(session: session, newEvent: envelope, timestamp: timestamp) { runtime in
            runtime.halveItState = state
        }
    }

    public static func submitScamVisit(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var state = session.runtime.scamState else {
            throw AppError(code: .invalidGameState, layer: .domain, severity: .error, isRecoverable: true, userMessageKey: "error.match.mode.scamUnavailable")
        }
        let outcome = try ScamEngine.submitVisit(state: state, darts: darts, timestamp: timestamp)
        state = outcome.updatedState
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .scamVisit(outcome.event),
            timestamp: timestamp
        )
        return try appendAndProject(session: session, newEvent: envelope, timestamp: timestamp) { runtime in
            runtime.scamState = state
        }
    }

    public static func submitSnookerDart(
        session: MatchLifecycleSession,
        dart: DartInput,
        nominatedColour: SnookerColour? = nil,
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var state = session.runtime.snookerState else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .error,
                isRecoverable: true,
                userMessageKey: "error.match.mode.snookerUnavailable"
            )
        }
        if case .awaitingNomination = state.phase, let colour = nominatedColour {
            state = try SnookerEngine.nominateColour(state: state, colour: colour)
        }
        let outcome = try SnookerEngine.submitDart(state: state, dart: dart, timestamp: timestamp)
        state = outcome.updatedState
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .snookerDart(outcome.event),
            timestamp: timestamp
        )
        return try appendAndProject(session: session, newEvent: envelope, timestamp: timestamp) { runtime in
            runtime.snookerState = state
        }
    }

    public static func submitTicTacToeVisit(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var state = session.runtime.ticTacToeState else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .error,
                isRecoverable: true,
                userMessageKey: "error.match.mode.ticTacToeUnavailable"
            )
        }
        let outcome = try TicTacToeEngine.submitTurn(state: state, darts: darts, timestamp: timestamp)
        state = outcome.updatedState
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .ticTacToeVisit(outcome.event),
            timestamp: timestamp
        )
        return try appendAndProject(session: session, newEvent: envelope, timestamp: timestamp) { runtime in
            runtime.ticTacToeState = state
        }
    }

    public static func submitBlindKillerTurn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var state = session.runtime.blindKillerState else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .error,
                isRecoverable: true,
                userMessageKey: "error.match.mode.blindKillerUnavailable"
            )
        }
        let outcome = try BlindKillerEngine.submitTurn(state: state, darts: darts, timestamp: timestamp)
        state = outcome.updatedState
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .blindKillerTurn(outcome.event),
            timestamp: timestamp
        )
        return try appendAndProject(session: session, newEvent: envelope, timestamp: timestamp) { runtime in
            runtime.blindKillerState = state
        }
    }

    public static func submitFollowTheLeaderVisit(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var state = session.runtime.followTheLeaderState else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .error,
                isRecoverable: true,
                userMessageKey: "error.match.mode.followTheLeaderUnavailable"
            )
        }
        let outcome = try FollowTheLeaderEngine.submitVisit(state: state, darts: darts, timestamp: timestamp)
        state = outcome.updatedState
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .followTheLeaderVisit(outcome.event),
            timestamp: timestamp
        )
        return try appendAndProject(session: session, newEvent: envelope, timestamp: timestamp) { runtime in
            runtime.followTheLeaderState = state
        }
    }

    public static func submitFollowTheLeaderPass(
        session: MatchLifecycleSession,
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var state = session.runtime.followTheLeaderState else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .error,
                isRecoverable: true,
                userMessageKey: "error.match.mode.followTheLeaderUnavailable"
            )
        }
        let outcome = try FollowTheLeaderEngine.submitPass(state: state, timestamp: timestamp)
        state = outcome.updatedState
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .followTheLeaderVisit(outcome.event),
            timestamp: timestamp
        )
        return try appendAndProject(session: session, newEvent: envelope, timestamp: timestamp) { runtime in
            runtime.followTheLeaderState = state
        }
    }

    public static func submitLoopVisit(
        session: MatchLifecycleSession,
        darts: [LoopSubmittedDart],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var state = session.runtime.loopState else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .error,
                isRecoverable: true,
                userMessageKey: "error.match.mode.loopUnavailable"
            )
        }
        let outcome = try LoopEngine.submitVisit(state: state, darts: darts, timestamp: timestamp)
        state = outcome.updatedState
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .loopVisit(outcome.event),
            timestamp: timestamp
        )
        return try appendAndProject(session: session, newEvent: envelope, timestamp: timestamp) { runtime in
            runtime.loopState = state
        }
    }

    public static func submitLoopPass(
        session: MatchLifecycleSession,
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var state = session.runtime.loopState else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .error,
                isRecoverable: true,
                userMessageKey: "error.match.mode.loopUnavailable"
            )
        }
        let outcome = try LoopEngine.submitPass(state: state, timestamp: timestamp)
        state = outcome.updatedState
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .loopVisit(outcome.event),
            timestamp: timestamp
        )
        return try appendAndProject(session: session, newEvent: envelope, timestamp: timestamp) { runtime in
            runtime.loopState = state
        }
    }

    public static func submitPrisonerVisit(
        session: MatchLifecycleSession,
        hits: [PrisonerDartHit],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var state = session.runtime.prisonerState else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .error,
                isRecoverable: true,
                userMessageKey: "error.match.mode.prisonerUnavailable"
            )
        }
        let outcome = try PrisonerEngine.submitVisit(state: state, hits: hits, timestamp: timestamp)
        state = outcome.updatedState
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .prisonerVisit(outcome.event),
            timestamp: timestamp
        )
        return try appendAndProject(session: session, newEvent: envelope, timestamp: timestamp) { runtime in
            runtime.prisonerState = state
        }
    }

    public static func submitRaidVisit(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        try RaidMatchLifecycleHandler.submitVisit(session: session, darts: darts, timestamp: timestamp)
    }

    public static func confirmFleetHandoff(
        session: MatchLifecycleSession,
        playerId: UUID,
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        try FleetMatchLifecycleHandler.confirmHandoff(session: session, playerId: playerId, timestamp: timestamp)
    }

    public static func confirmFleetPassDevice(
        session: MatchLifecycleSession,
        playerId: UUID,
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        try FleetMatchLifecycleHandler.confirmPassDevice(session: session, playerId: playerId, timestamp: timestamp)
    }

    public static func toggleFleetPlacementCell(
        session: MatchLifecycleSession,
        playerId: UUID,
        cell: FleetBoardCell
    ) throws -> MatchLifecycleSession {
        try FleetMatchLifecycleHandler.togglePlacementCell(session: session, playerId: playerId, cell: cell)
    }

    public static func clearFleetPlacement(
        session: MatchLifecycleSession,
        playerId: UUID
    ) throws -> MatchLifecycleSession {
        try FleetMatchLifecycleHandler.clearPlacement(session: session, playerId: playerId)
    }

    public static func submitFleetPlacementLock(
        session: MatchLifecycleSession,
        playerId: UUID,
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        try FleetMatchLifecycleHandler.submitPlacementLock(session: session, playerId: playerId, timestamp: timestamp)
    }

    public static func submitFleetSonar(
        session: MatchLifecycleSession,
        playerId: UUID,
        cell: FleetBoardCell,
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        try FleetMatchLifecycleHandler.submitSonar(session: session, playerId: playerId, cell: cell, timestamp: timestamp)
    }

    public static func submitFleetDart(
        session: MatchLifecycleSession,
        playerId: UUID,
        callCell: FleetBoardCell,
        dart: DartInput,
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        try FleetMatchLifecycleHandler.submitDart(
            session: session,
            playerId: playerId,
            callCell: callCell,
            dart: dart,
            timestamp: timestamp
        )
    }

    public static func undoLastTurn(session: MatchLifecycleSession) throws -> MatchLifecycleSession {
        guard !session.events.isEmpty else { return session }
        let trimmed = Array(session.events.dropLast())
        return try replayFromStart(
            type: session.runtime.type,
            config: session.runtime.config,
            participants: session.runtime.participants,
            matchId: session.runtime.matchId,
            startedAt: session.runtime.startedAt,
            events: trimmed
        )
    }

    /// Reverts the last accepted throw. When the last turn recorded per-dart detail,
    /// the visit is reopened with the remaining darts; otherwise the whole turn is removed.
    public static func undoLastDart(session: MatchLifecycleSession) throws -> UndoLastDartResult {
        guard let last = session.events.last else {
            return UndoLastDartResult(session: session, restoredDarts: [])
        }
        guard let darts = darts(from: last.payload), darts.count > 1 else {
            let undone = try undoLastTurn(session: session)
            return UndoLastDartResult(session: undone, restoredDarts: [])
        }
        let restoredDarts = Array(darts.dropLast())
        let undone = try undoLastTurn(session: session)
        return UndoLastDartResult(session: undone, restoredDarts: restoredDarts)
    }

    private static func darts(from payload: MatchEventPayload) -> [DartInput]? {
        switch payload {
        case let .x01Turn(turn):
            guard !turn.darts.isEmpty else { return nil }
            return turn.darts.map {
                DartInput(
                    multiplier: DartMultiplier(rawValue: $0.multiplierRaw) ?? .single,
                    segment: X01MatchLifecycleHandler.mapSegmentRaw($0.segmentRaw),
                    isMiss: $0.wasMiss
                )
            }
        case let .cricketTurn(turn):
            guard !turn.targetsTouched.isEmpty else { return nil }
            return turn.targetsTouched.map(CricketEngine.dartInput(from:))
        case let .baseballTurn(turn):
            guard !turn.darts.isEmpty else { return nil }
            return turn.darts.map(BaseballEngine.dartInput(from:))
        case let .killerPick(pick):
            return [KillerEngine.dartInput(from: pick)]
        case let .killerTurn(turn):
            guard !turn.darts.isEmpty else { return nil }
            return turn.darts.map(KillerEngine.dartInput(from:))
        case let .shanghaiTurn(turn):
            guard !turn.darts.isEmpty else { return nil }
            return turn.darts.map(ShanghaiEngine.dartInput(from:))
        case let .americanCricketTurn(turn):
            guard !turn.darts.isEmpty else { return nil }
            return turn.darts.map(AmericanCricketEngine.dartInput(from:))
        case let .mickeyMouseTurn(turn):
            guard !turn.darts.isEmpty else { return nil }
            return turn.darts.map(MickeyMouseEngine.dartInput(from:))
        case let .mulliganTurn(turn):
            guard !turn.darts.isEmpty else { return nil }
            return turn.darts.map(MulliganEngine.dartInput(from:))
        case let .englishCricketTurn(turn):
            guard !turn.darts.isEmpty else { return nil }
            return turn.darts.map(EnglishCricketEngine.dartInput(from:))
        case let .knockoutTurn(turn):
            guard !turn.darts.isEmpty else { return nil }
            return turn.darts.map(KnockoutEngine.dartInput(from:))
        case let .golfTurn(turn):
            guard !turn.darts.isEmpty else { return nil }
            return turn.darts.map(GolfEngine.dartInput(from:))
        case let .footballTurn(turn):
            guard !turn.darts.isEmpty else { return nil }
            return turn.darts.map(FootballEngine.dartInput(from:))
        case let .aroundTheClock180Turn(turn):
            guard !turn.darts.isEmpty else { return nil }
            return turn.darts.map(AroundTheClock180Engine.dartInput(from:))
        case let .chaseTheDragonTurn(turn):
            guard !turn.darts.isEmpty else { return nil }
            return turn.darts.map(ChaseTheDragonEngine.dartInput(from:))
        case .suddenDeathTurn, .fiftyOneByFivesTurn, .grandNationalTurn, .hareAndHoundsTurn,
             .aroundTheClockTurn, .nineLivesTurn, .bobs27Round, .halveItRound, .scamVisit, .snookerDart, .ticTacToeVisit, .blindKillerTurn, .followTheLeaderVisit, .loopVisit, .prisonerVisit, .raidVisit, .fleetPlacement, .fleetPlacementUI, .fleetSonar,
             .fleetDart:
            return nil
        }
    }

    public static func rehydrate(
        snapshot: MatchSnapshot,
        tailEvents: [MatchEventEnvelope],
        persistedEvents: [MatchEventEnvelope] = []
    ) throws -> MatchLifecycleSession {
        let runtime = try CodablePayloadCoder.decode(MatchRuntimeState.self, from: snapshot.payload)
        let baselineEvents = persistedEvents.filter { $0.eventIndex < snapshot.eventCount }
        var session = MatchLifecycleSession(
            runtime: runtime,
            events: baselineEvents.sorted { $0.eventIndex < $1.eventIndex },
            latestSnapshot: snapshot
        )
        for event in tailEvents.sorted(by: { $0.eventIndex < $1.eventIndex }) {
            session = try applyEvent(event, to: session)
        }
        return session
    }

    private static func replayFromStart(
        type: MatchType,
        config: MatchConfigPayload,
        participants: [MatchParticipant],
        matchId: UUID,
        startedAt: Date,
        events: [MatchEventEnvelope]
    ) throws -> MatchLifecycleSession {
        var rebuilt = try createMatch(
            matchId: matchId,
            type: type,
            config: config,
            participants: participants,
            startedAt: startedAt
        )
        for event in events {
            rebuilt = try applyEvent(event, to: rebuilt)
        }
        return rebuilt
    }

    private static func applyEvent(_ event: MatchEventEnvelope, to session: MatchLifecycleSession) throws -> MatchLifecycleSession {
        switch event.payload {
        case let .x01Turn(turn):
            return try X01MatchLifecycleHandler.replayTurn(turn, session: session, timestamp: event.timestamp)
        case let .cricketTurn(turn):
            return try CricketMatchLifecycleHandler.replayTurn(turn, session: session, timestamp: event.timestamp)
        case let .baseballTurn(turn):
            return try BaseballMatchLifecycleHandler.replayTurn(turn, session: session, timestamp: event.timestamp)
        case let .killerPick(pick):
            return try KillerMatchLifecycleHandler.replayPick(pick, session: session, timestamp: event.timestamp)
        case let .killerTurn(turn):
            return try KillerMatchLifecycleHandler.replayTurn(turn, session: session, timestamp: event.timestamp)
        case let .shanghaiTurn(turn):
            return try ShanghaiMatchLifecycleHandler.replayTurn(turn, session: session, timestamp: event.timestamp)
        case let .americanCricketTurn(turn):
            return try AmericanCricketMatchLifecycleHandler.replayTurn(turn, session: session, timestamp: event.timestamp)
        case let .mickeyMouseTurn(turn):
            return try MickeyMouseMatchLifecycleHandler.replayTurn(turn, session: session, timestamp: event.timestamp)
        case let .mulliganTurn(turn):
            return try MulliganMatchLifecycleHandler.replayTurn(turn, session: session, timestamp: event.timestamp)
        case let .englishCricketTurn(turn):
            return try EnglishCricketMatchLifecycleHandler.replayTurn(turn, session: session, timestamp: event.timestamp)
        case let .knockoutTurn(turn):
            return try KnockoutMatchLifecycleHandler.replayTurn(turn, session: session, timestamp: event.timestamp)
        case let .suddenDeathTurn(turn):
            return try SuddenDeathMatchLifecycleHandler.replayTurn(turn, session: session, timestamp: event.timestamp)
        case let .fiftyOneByFivesTurn(turn):
            return try FiftyOneByFivesMatchLifecycleHandler.replayTurn(turn, session: session, timestamp: event.timestamp)
        case let .golfTurn(turn):
            return try GolfMatchLifecycleHandler.replayTurn(turn, session: session, timestamp: event.timestamp)
        case let .footballTurn(turn):
            return try FootballMatchLifecycleHandler.replayTurn(turn, session: session, timestamp: event.timestamp)
        case let .grandNationalTurn(turn):
            return try GrandNationalMatchLifecycleHandler.replayTurn(turn, session: session, timestamp: event.timestamp)
        case let .hareAndHoundsTurn(turn):
            return try HareAndHoundsMatchLifecycleHandler.replayTurn(turn, session: session, timestamp: event.timestamp)
        case let .aroundTheClockTurn(turn):
            return try AroundTheClockMatchLifecycleHandler.replayTurn(turn, session: session, timestamp: event.timestamp)
        case let .aroundTheClock180Turn(turn):
            return try AroundTheClock180MatchLifecycleHandler.replayTurn(turn, session: session, timestamp: event.timestamp)
        case let .chaseTheDragonTurn(turn):
            return try ChaseTheDragonMatchLifecycleHandler.replayTurn(turn, session: session, timestamp: event.timestamp)
        case let .nineLivesTurn(turn):
            return try NineLivesMatchLifecycleHandler.replayTurn(turn, session: session, timestamp: event.timestamp)
        case let .bobs27Round(round):
            return try submitBobs27Turn(session: session, darts: bobs27ReplayDarts(for: round), timestamp: event.timestamp)
        case let .halveItRound(round):
            return try submitHalveItTurn(session: session, darts: halveItReplayDarts(for: round), timestamp: event.timestamp)
        case let .scamVisit(visit):
            return try submitScamVisit(session: session, darts: scamReplayDarts(for: visit), timestamp: event.timestamp)
        case let .snookerDart(dartEvent):
            let replay = snookerReplaySubmission(for: dartEvent)
            return try submitSnookerDart(
                session: session,
                dart: replay.dart,
                nominatedColour: replay.nominatedColour,
                timestamp: dartEvent.timestamp
            )
        case let .ticTacToeVisit(visit):
            let cells = session.runtime.ticTacToeState?.config.cells
                ?? MatchConfigTicTacToe().cells
            return try submitTicTacToeVisit(
                session: session,
                darts: ticTacToeReplayDarts(for: visit, cells: cells),
                timestamp: event.timestamp
            )
        case let .blindKillerTurn(turn):
            let darts = turn.darts.map(BlindKillerEngine.dartInput(from:))
            return try submitBlindKillerTurn(session: session, darts: darts, timestamp: event.timestamp)
        case let .followTheLeaderVisit(visit):
            if visit.passed {
                return try submitFollowTheLeaderPass(session: session, timestamp: event.timestamp)
            }
            let darts = visit.darts.map(FollowTheLeaderEngine.dartInput(from:))
            return try submitFollowTheLeaderVisit(session: session, darts: darts, timestamp: event.timestamp)
        case let .loopVisit(visit):
            if visit.passed {
                return try submitLoopPass(session: session, timestamp: event.timestamp)
            }
            let darts = visit.darts.map(LoopEngine.submittedDart(from:))
            return try submitLoopVisit(session: session, darts: darts, timestamp: event.timestamp)
        case let .prisonerVisit(visit):
            return try submitPrisonerVisit(session: session, hits: visit.hits, timestamp: event.timestamp)
        case let .raidVisit(visit):
            return try RaidMatchLifecycleHandler.replayVisit(visit, session: session, timestamp: event.timestamp)
        case let .fleetPlacement(placement):
            return try FleetMatchLifecycleHandler.replayPlacement(placement, session: session)
        case let .fleetPlacementUI(ui):
            return try FleetMatchLifecycleHandler.replayPlacementUI(ui, session: session)
        case let .fleetSonar(sonar):
            return try FleetMatchLifecycleHandler.replaySonar(sonar, session: session)
        case let .fleetDart(dart):
            return try FleetMatchLifecycleHandler.replayDart(dart, session: session)
        }
    }

    private static func appendAndProject(
        session: MatchLifecycleSession,
        newEvent: MatchEventEnvelope,
        timestamp: Date,
        update: (inout MatchRuntimeState) -> Void
    ) throws -> MatchLifecycleSession {
        var runtime = session.runtime
        runtime.eventCount += 1
        update(&runtime)
        MatchRuntimeProjection.project(&runtime, timestamp: timestamp)

        var events = session.events
        events.append(newEvent)
        var snapshot = session.latestSnapshot
        if runtime.eventCount % snapshotInterval == 0 || runtime.status == .completed {
            snapshot = try makeSnapshot(from: runtime, eventCount: runtime.eventCount, timestamp: timestamp)
        }
        return MatchLifecycleSession(runtime: runtime, events: events, latestSnapshot: snapshot)
    }

    private static func suddenDeathReplayDarts(for turn: SuddenDeathTurnEvent) -> [DartInput] {
        guard turn.pointsThisVisit > 0 else { return [DartInput(multiplier: .single, segment: .miss, isMiss: true)] }
        let perDart = turn.pointsThisVisit / 3
        let remainder = turn.pointsThisVisit % 3
        return (0 ..< 3).map { index in
            let points = perDart + (index < remainder ? 1 : 0)
            guard points > 0 else {
                return DartInput(multiplier: .single, segment: .miss, isMiss: true)
            }
            return DartInput(multiplier: .single, segment: .oneToTwenty(min(20, max(1, points))), isMiss: false)
        }
    }

    private static func fiftyOneByFivesReplayDarts(for turn: FiftyOneByFivesTurnEvent) -> [DartInput] {
        guard turn.rawTotal > 0 else {
            return [DartInput(multiplier: .single, segment: .miss, isMiss: true)]
        }
        return synthesizeReplayDarts(forRawTotal: turn.rawTotal)
    }

    private static func synthesizeReplayDarts(forRawTotal rawTotal: Int) -> [DartInput] {
        if rawTotal <= 20 {
            return [DartInput(multiplier: .single, segment: .oneToTwenty(rawTotal), isMiss: false)]
        }
        if rawTotal <= 40, rawTotal % 2 == 0 {
            let segment = rawTotal / 2
            return [DartInput(multiplier: .double, segment: .oneToTwenty(segment), isMiss: false)]
        }
        if rawTotal <= 60, rawTotal % 3 == 0 {
            let segment = rawTotal / 3
            return [DartInput(multiplier: .triple, segment: .oneToTwenty(segment), isMiss: false)]
        }
        return [DartInput(multiplier: .single, segment: .oneToTwenty(min(20, rawTotal)), isMiss: false)]
    }

    private static func grandNationalReplayDarts(for turn: GrandNationalTurnEvent) -> [DartInput] {
        if turn.segmentIndexAfter > turn.segmentIndexBefore {
            let segment = grandNationalCourseOrder[turn.segmentIndexBefore]
            return [DartInput(multiplier: .single, segment: .oneToTwenty(segment), isMiss: false)]
        }
        return [DartInput(multiplier: .single, segment: .miss, isMiss: true)]
    }

    private static func hareAndHoundsReplayDarts(for turn: HareAndHoundsTurnEvent) -> [DartInput] {
        if turn.positionAfter > turn.positionBefore {
            let segment = MatchConfigHareAndHounds.clockwiseCourse[turn.positionBefore]
            return [DartInput(multiplier: .single, segment: .oneToTwenty(segment), isMiss: false)]
        }
        return [DartInput(multiplier: .single, segment: .miss, isMiss: true)]
    }

    private static func aroundTheClockReplayDarts(for turn: AroundTheClockTurnEvent) -> [DartInput] {
        if turn.targetAfter > turn.targetBefore {
            let segment: DartSegment
            if turn.targetBefore < 20 {
                segment = .oneToTwenty(turn.targetBefore + 1)
            } else {
                segment = .outerBull
            }
            return [DartInput(multiplier: .single, segment: segment, isMiss: false)]
        }
        return Array(
            repeating: DartInput(multiplier: .single, segment: .miss, isMiss: true),
            count: max(1, turn.dartsThrown)
        )
    }

    private static func nineLivesReplayDarts(for turn: NineLivesTurnEvent) -> [DartInput] {
        if turn.advanced {
            let target = turn.targetIndexBefore + 1
            return [DartInput(multiplier: .single, segment: .oneToTwenty(min(20, max(1, target))), isMiss: false)]
        }
        return [DartInput(multiplier: .single, segment: .miss, isMiss: true)]
    }

    private static func bobs27ReplayDarts(for round: Bobs27RoundEvent) -> [DartInput] {
        let target = Bobs27Engine.target(forRoundIndex: round.roundIndex)
        var darts: [DartInput] = []
        for _ in 0 ..< round.hitCount {
            darts.append(bobs27HitDart(for: target))
        }
        while darts.count < 3 {
            darts.append(DartInput(multiplier: .single, segment: .miss, isMiss: true))
        }
        return Array(darts.prefix(3))
    }

    private static func bobs27HitDart(for target: Bobs27Target) -> DartInput {
        switch target {
        case let .double(segment):
            return DartInput(multiplier: .double, segment: .oneToTwenty(segment), isMiss: false)
        case .bull:
            return DartInput(multiplier: .single, segment: .innerBull, isMiss: false)
        }
    }

    private static func halveItReplayDarts(for round: HalveItRoundEvent) -> [DartInput] {
        if round.halved || round.visitScore == 0 {
            return Array(
                repeating: DartInput(multiplier: .single, segment: .miss, isMiss: true),
                count: 3
            )
        }
        var remaining = round.visitScore
        let target = round.target
        var darts: [DartInput] = []
        for multiplier in [DartMultiplier.triple, .double, .single] {
            let perDart = target * multiplier.markValue
            guard perDart > 0 else { continue }
            while remaining >= perDart, darts.count < 3 {
                darts.append(
                    DartInput(multiplier: multiplier, segment: .oneToTwenty(target), isMiss: false)
                )
                remaining -= perDart
            }
        }
        while darts.count < 3 {
            darts.append(DartInput(multiplier: .single, segment: .miss, isMiss: true))
        }
        return Array(darts.prefix(3))
    }

    private static func scamReplayDarts(for visit: ScamVisitEvent) -> [DartInput] {
        switch visit.role {
        case .stopper:
            var darts = visit.segmentsClosedThisVisit.map {
                DartInput(multiplier: .single, segment: .oneToTwenty($0), isMiss: false)
            }
            while darts.count < 3 {
                darts.append(DartInput(multiplier: .single, segment: .miss, isMiss: true))
            }
            return Array(darts.prefix(3))
        case .scorer:
            guard let target = visit.highestOpenSegmentAtVisitStart, visit.pointsAdded > 0 else {
                return Array(
                    repeating: DartInput(multiplier: .single, segment: .miss, isMiss: true),
                    count: 3
                )
            }
            var remaining = visit.pointsAdded
            var darts: [DartInput] = []
            for multiplier in [DartMultiplier.triple, .double, .single] {
                let perDart = target * multiplier.markValue
                guard perDart > 0 else { continue }
                while remaining >= perDart, darts.count < 3 {
                    darts.append(
                        DartInput(multiplier: multiplier, segment: .oneToTwenty(target), isMiss: false)
                    )
                    remaining -= perDart
                }
            }
            while darts.count < 3 {
                darts.append(DartInput(multiplier: .single, segment: .miss, isMiss: true))
            }
            return Array(darts.prefix(3))
        }
    }

    private static func ticTacToeReplayDarts(
        for visit: TicTacToeVisitEvent,
        cells: [TicTacToeCellTarget]
    ) -> [DartInput] {
        var darts = visit.claimsThisVisit.map { claim in
            representativeDart(for: cells[claim.cellIndex])
        }
        while darts.count < 3 {
            darts.append(DartInput(multiplier: .single, segment: .miss, isMiss: true))
        }
        return Array(darts.prefix(3))
    }

    private static func representativeDart(for target: TicTacToeCellTarget) -> DartInput {
        switch target {
        case .innerBull:
            return DartInput(multiplier: .single, segment: .innerBull, isMiss: false)
        case .outerBull:
            return DartInput(multiplier: .single, segment: .outerBull, isMiss: false)
        case .anyBull:
            return DartInput(multiplier: .single, segment: .innerBull, isMiss: false)
        case let .single(segment):
            return DartInput(multiplier: .single, segment: .oneToTwenty(segment), isMiss: false)
        case let .double(segment):
            return DartInput(multiplier: .double, segment: .oneToTwenty(segment), isMiss: false)
        case let .triple(segment):
            return DartInput(multiplier: .triple, segment: .oneToTwenty(segment), isMiss: false)
        case let .anySegment(segment):
            return DartInput(multiplier: .single, segment: .oneToTwenty(segment), isMiss: false)
        }
    }

    private static func snookerReplaySubmission(for event: SnookerDartEvent) -> (dart: DartInput, nominatedColour: SnookerColour?) {
        switch event.ballType {
        case .red:
            if let segment = event.segmentPocketed {
                return (
                    DartInput(multiplier: .single, segment: .oneToTwenty(segment), isMiss: false),
                    nil
                )
            }
            return (DartInput(multiplier: .single, segment: .miss, isMiss: true), nil)
        case .colour:
            let colour = event.nominatedColour ?? .yellow
            guard event.points > 0 else {
                return (DartInput(multiplier: .single, segment: .miss, isMiss: true), colour)
            }
            if colour == .black {
                return (
                    DartInput(multiplier: .double, segment: .innerBull, isMiss: false),
                    colour
                )
            }
            let segment = event.segmentPocketed ?? colour.targetSegment ?? 16
            return (
                DartInput(multiplier: .single, segment: .oneToTwenty(segment), isMiss: false),
                colour
            )
        }
    }

    private static func fleetReplayDart(for event: FleetDartEvent) -> DartInput {
        FleetEngine.dartInput(from: event)
    }

    private static func projectFleetUIStep(
        session: MatchLifecycleSession,
        ui: FleetPlacementUIEvent
    ) throws -> MatchLifecycleSession {
        guard var state = session.runtime.fleetState else { throw fleetUnavailable() }
        state.placementUIStep = ui.step
        state.placementAudience = nil
        if case let .placing(playerId) = ui.step {
            state.placementAudience = playerId
        }
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .fleetPlacementUI(ui),
            timestamp: ui.timestamp
        )
        return try appendAndProject(session: session, newEvent: envelope, timestamp: ui.timestamp) { runtime in
            runtime.fleetState = state
        }
    }

    private static func fleetUnavailable() -> AppError {
        AppError(
            code: .invalidGameState,
            layer: .domain,
            severity: .error,
            isRecoverable: true,
            userMessageKey: "error.match.mode.fleetUnavailable"
        )
    }

    private static func makeSnapshot(from runtime: MatchRuntimeState, eventCount: Int, timestamp: Date) throws -> MatchSnapshot {
        MatchSnapshot(
            payloadVersion: 1,
            eventCount: eventCount,
            createdAt: timestamp,
            payload: try CodablePayloadCoder.encode(runtime)
        )
    }

    private static func mapX01SegmentRaw(_ raw: String) -> DartSegment {
        if let value = Int(raw), (1 ... 20).contains(value) {
            return .oneToTwenty(value)
        }
        switch raw {
        case "outerBull": return .outerBull
        case "innerBull": return .innerBull
        default: return .miss
        }
    }
}
