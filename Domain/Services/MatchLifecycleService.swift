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
    public static let snapshotInterval = 3

    private static let soloPracticeMatchTypes: Set<MatchType> = [
        .x01, .aroundTheClock, .aroundTheClock180, .chaseTheDragon
    ]

    public static func createMatch(
        matchId: UUID = UUID(),
        type: MatchType,
        config: MatchConfigPayload,
        participants: [MatchParticipant],
        startedAt: Date = Date()
    ) throws -> MatchLifecycleSession {
        let minimumParticipants = soloPracticeMatchTypes.contains(type) ? 1 : 2
        guard participants.count >= minimumParticipants else {
            throw AppError(code: .validationFailed, layer: .domain, severity: .warning, isRecoverable: true, userMessageKey: "error.match.players.minimum")
        }
        let ordered = participants.sorted(by: { $0.turnOrder < $1.turnOrder })
        let playerIds = ordered.map { $0.playerId ?? $0.id }
        var runtime = MatchRuntimeState(
            matchId: matchId,
            type: type,
            config: config,
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
            nineLivesState: nil
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
        default:
            throw AppError(code: .validationFailed, layer: .domain, severity: .warning, isRecoverable: true, userMessageKey: "error.match.configMismatch")
        }

        projectRuntime(&runtime, timestamp: startedAt)
        let initialSnapshot = try makeSnapshot(from: runtime, eventCount: 0, timestamp: startedAt)
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
        let snapshot = try makeSnapshot(from: runtime, eventCount: runtime.eventCount, timestamp: timestamp)
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
        let snapshot = try makeSnapshot(from: runtime, eventCount: runtime.eventCount, timestamp: timestamp)
        return MatchLifecycleSession(runtime: runtime, events: session.events, latestSnapshot: snapshot)
    }

    public static func submitX01Turn(
        session: MatchLifecycleSession,
        enteredTotal: Int?,
        darts: [DartInput]?,
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var x01State = session.runtime.x01State else {
            throw AppError(code: .invalidGameState, layer: .domain, severity: .error, isRecoverable: true, userMessageKey: "error.match.mode.x01Unavailable")
        }
        let outcome = try X01Engine.submitTurn(state: x01State, enteredTotal: enteredTotal, darts: darts, timestamp: timestamp)
        x01State = outcome.updatedState
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .x01Turn(outcome.event),
            timestamp: timestamp
        )
        return try appendAndProject(session: session, newEvent: envelope, timestamp: timestamp) { runtime in
            runtime.x01State = x01State
        }
    }

    public static func submitCricketTurn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var cricketState = session.runtime.cricketState else {
            throw AppError(code: .invalidGameState, layer: .domain, severity: .error, isRecoverable: true, userMessageKey: "error.match.mode.cricketUnavailable")
        }
        let outcome = try CricketEngine.submitTurn(state: cricketState, darts: darts, timestamp: timestamp)
        cricketState = outcome.updatedState
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .cricketTurn(outcome.event),
            timestamp: timestamp
        )
        return try appendAndProject(session: session, newEvent: envelope, timestamp: timestamp) { runtime in
            runtime.cricketState = cricketState
        }
    }

    public static func submitBaseballTurn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var baseballState = session.runtime.baseballState else {
            throw AppError(code: .invalidGameState, layer: .domain, severity: .error, isRecoverable: true, userMessageKey: "error.match.mode.baseballUnavailable")
        }
        let outcome = try BaseballEngine.submitTurn(state: baseballState, darts: darts, timestamp: timestamp)
        baseballState = outcome.updatedState
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .baseballTurn(outcome.event),
            timestamp: timestamp
        )
        return try appendAndProject(session: session, newEvent: envelope, timestamp: timestamp) { runtime in
            runtime.baseballState = baseballState
        }
    }

    public static func submitKillerPick(
        session: MatchLifecycleSession,
        dart: DartInput,
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var killerState = session.runtime.killerState else {
            throw AppError(code: .invalidGameState, layer: .domain, severity: .error, isRecoverable: true, userMessageKey: "error.match.mode.killerUnavailable")
        }
        let outcome = try KillerEngine.submitPick(state: killerState, dart: dart, timestamp: timestamp)
        killerState = outcome.updatedState
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .killerPick(outcome.event),
            timestamp: timestamp
        )
        return try appendAndProject(session: session, newEvent: envelope, timestamp: timestamp) { runtime in
            runtime.killerState = killerState
        }
    }

    public static func submitKillerTurn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var killerState = session.runtime.killerState else {
            throw AppError(code: .invalidGameState, layer: .domain, severity: .error, isRecoverable: true, userMessageKey: "error.match.mode.killerUnavailable")
        }
        let outcome = try KillerEngine.submitTurn(state: killerState, darts: darts, timestamp: timestamp)
        killerState = outcome.updatedState
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .killerTurn(outcome.event),
            timestamp: timestamp
        )
        return try appendAndProject(session: session, newEvent: envelope, timestamp: timestamp) { runtime in
            runtime.killerState = killerState
        }
    }

    public static func submitShanghaiTurn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var shanghaiState = session.runtime.shanghaiState else {
            throw AppError(code: .invalidGameState, layer: .domain, severity: .error, isRecoverable: true, userMessageKey: "error.match.mode.shanghaiUnavailable")
        }
        let outcome = try ShanghaiEngine.submitTurn(state: shanghaiState, darts: darts, timestamp: timestamp)
        shanghaiState = outcome.updatedState
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .shanghaiTurn(outcome.event),
            timestamp: timestamp
        )
        return try appendAndProject(session: session, newEvent: envelope, timestamp: timestamp) { runtime in
            runtime.shanghaiState = shanghaiState
        }
    }

    public static func submitAmericanCricketTurn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var state = session.runtime.americanCricketState else {
            throw AppError(code: .invalidGameState, layer: .domain, severity: .error, isRecoverable: true, userMessageKey: "error.match.mode.americanCricketUnavailable")
        }
        let outcome = try AmericanCricketEngine.submitTurn(state: state, darts: darts, timestamp: timestamp)
        state = outcome.updatedState
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .americanCricketTurn(outcome.event),
            timestamp: timestamp
        )
        return try appendAndProject(session: session, newEvent: envelope, timestamp: timestamp) { runtime in
            runtime.americanCricketState = state
        }
    }

    public static func submitMickeyMouseTurn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var state = session.runtime.mickeyMouseState else {
            throw AppError(code: .invalidGameState, layer: .domain, severity: .error, isRecoverable: true, userMessageKey: "error.match.mode.mickeyMouseUnavailable")
        }
        let outcome = try MickeyMouseEngine.submitTurn(state: state, darts: darts, timestamp: timestamp)
        state = outcome.updatedState
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .mickeyMouseTurn(outcome.event),
            timestamp: timestamp
        )
        return try appendAndProject(session: session, newEvent: envelope, timestamp: timestamp) { runtime in
            runtime.mickeyMouseState = state
        }
    }

    public static func submitMulliganTurn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var state = session.runtime.mulliganState else {
            throw AppError(code: .invalidGameState, layer: .domain, severity: .error, isRecoverable: true, userMessageKey: "error.match.mode.mulliganUnavailable")
        }
        let outcome = try MulliganEngine.submitTurn(state: state, darts: darts, timestamp: timestamp)
        state = outcome.updatedState
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .mulliganTurn(outcome.event),
            timestamp: timestamp
        )
        return try appendAndProject(session: session, newEvent: envelope, timestamp: timestamp) { runtime in
            runtime.mulliganState = state
        }
    }

    public static func submitEnglishCricketTurn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var state = session.runtime.englishCricketState else {
            throw AppError(code: .invalidGameState, layer: .domain, severity: .error, isRecoverable: true, userMessageKey: "error.match.mode.englishCricketUnavailable")
        }
        let outcome = try EnglishCricketEngine.submitTurn(state: state, darts: darts, timestamp: timestamp)
        state = outcome.updatedState
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .englishCricketTurn(outcome.event),
            timestamp: timestamp
        )
        return try appendAndProject(session: session, newEvent: envelope, timestamp: timestamp) { runtime in
            runtime.englishCricketState = state
        }
    }

    public static func submitKnockoutTurn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var state = session.runtime.knockoutState else {
            throw AppError(code: .invalidGameState, layer: .domain, severity: .error, isRecoverable: true, userMessageKey: "error.match.mode.knockoutUnavailable")
        }
        let outcome = try KnockoutEngine.submitTurn(state: state, darts: darts, timestamp: timestamp)
        state = outcome.updatedState
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .knockoutTurn(outcome.event),
            timestamp: timestamp
        )
        return try appendAndProject(session: session, newEvent: envelope, timestamp: timestamp) { runtime in
            runtime.knockoutState = state
        }
    }

    public static func submitSuddenDeathTurn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var state = session.runtime.suddenDeathState else {
            throw AppError(code: .invalidGameState, layer: .domain, severity: .error, isRecoverable: true, userMessageKey: "error.match.mode.suddenDeathUnavailable")
        }
        let outcome = try SuddenDeathEngine.submitTurn(state: state, darts: darts, timestamp: timestamp)
        state = outcome.updatedState
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .suddenDeathTurn(outcome.event),
            timestamp: timestamp
        )
        return try appendAndProject(session: session, newEvent: envelope, timestamp: timestamp) { runtime in
            runtime.suddenDeathState = state
        }
    }

    public static func submitFiftyOneByFivesTurn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var state = session.runtime.fiftyOneByFivesState else {
            throw AppError(code: .invalidGameState, layer: .domain, severity: .error, isRecoverable: true, userMessageKey: "error.match.mode.fiftyOneByFivesUnavailable")
        }
        let outcome = try FiftyOneByFivesEngine.submitTurn(state: state, darts: darts, timestamp: timestamp)
        state = outcome.updatedState
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .fiftyOneByFivesTurn(outcome.event),
            timestamp: timestamp
        )
        return try appendAndProject(session: session, newEvent: envelope, timestamp: timestamp) { runtime in
            runtime.fiftyOneByFivesState = state
        }
    }

    public static func submitGolfTurn(
        session: MatchLifecycleSession,
        input: GolfTurnInput,
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var state = session.runtime.golfState else {
            throw AppError(code: .invalidGameState, layer: .domain, severity: .error, isRecoverable: true, userMessageKey: "error.match.mode.golfUnavailable")
        }
        let outcome = try GolfEngine.submitTurn(state: state, input: input, timestamp: timestamp)
        state = outcome.updatedState
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .golfTurn(outcome.event),
            timestamp: timestamp
        )
        return try appendAndProject(session: session, newEvent: envelope, timestamp: timestamp) { runtime in
            runtime.golfState = state
        }
    }

    public static func submitFootballTurn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var state = session.runtime.footballState else {
            throw AppError(code: .invalidGameState, layer: .domain, severity: .error, isRecoverable: true, userMessageKey: "error.match.mode.footballUnavailable")
        }
        let outcome = try FootballEngine.submitTurn(state: state, darts: darts, timestamp: timestamp)
        state = outcome.updatedState
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .footballTurn(outcome.event),
            timestamp: timestamp
        )
        return try appendAndProject(session: session, newEvent: envelope, timestamp: timestamp) { runtime in
            runtime.footballState = state
        }
    }

    public static func submitGrandNationalTurn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var state = session.runtime.grandNationalState else {
            throw AppError(code: .invalidGameState, layer: .domain, severity: .error, isRecoverable: true, userMessageKey: "error.match.mode.grandNationalUnavailable")
        }
        let outcome = try GrandNationalEngine.submitTurn(state: state, darts: darts, timestamp: timestamp)
        state = outcome.updatedState
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .grandNationalTurn(outcome.event),
            timestamp: timestamp
        )
        return try appendAndProject(session: session, newEvent: envelope, timestamp: timestamp) { runtime in
            runtime.grandNationalState = state
        }
    }

    public static func submitHareAndHoundsTurn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var state = session.runtime.hareAndHoundsState else {
            throw AppError(code: .invalidGameState, layer: .domain, severity: .error, isRecoverable: true, userMessageKey: "error.match.mode.hareAndHoundsUnavailable")
        }
        let outcome = try HareAndHoundsEngine.submitTurn(state: state, darts: darts, timestamp: timestamp)
        state = outcome.updatedState
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .hareAndHoundsTurn(outcome.event),
            timestamp: timestamp
        )
        return try appendAndProject(session: session, newEvent: envelope, timestamp: timestamp) { runtime in
            runtime.hareAndHoundsState = state
        }
    }

    public static func submitAroundTheClockTurn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var state = session.runtime.aroundTheClockState else {
            throw AppError(code: .invalidGameState, layer: .domain, severity: .error, isRecoverable: true, userMessageKey: "error.match.mode.aroundTheClockUnavailable")
        }
        let outcome = try AroundTheClockEngine.submitTurn(state: state, darts: darts, timestamp: timestamp)
        state = outcome.updatedState
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .aroundTheClockTurn(outcome.event),
            timestamp: timestamp
        )
        return try appendAndProject(session: session, newEvent: envelope, timestamp: timestamp) { runtime in
            runtime.aroundTheClockState = state
        }
    }

    public static func submitAroundTheClock180Turn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var state = session.runtime.aroundTheClock180State else {
            throw AppError(code: .invalidGameState, layer: .domain, severity: .error, isRecoverable: true, userMessageKey: "error.match.mode.aroundTheClock180Unavailable")
        }
        let outcome = try AroundTheClock180Engine.submitTurn(state: state, darts: darts, timestamp: timestamp)
        state = outcome.updatedState
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .aroundTheClock180Turn(outcome.event),
            timestamp: timestamp
        )
        return try appendAndProject(session: session, newEvent: envelope, timestamp: timestamp) { runtime in
            runtime.aroundTheClock180State = state
        }
    }

    public static func submitChaseTheDragonTurn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var state = session.runtime.chaseTheDragonState else {
            throw AppError(code: .invalidGameState, layer: .domain, severity: .error, isRecoverable: true, userMessageKey: "error.match.mode.chaseTheDragonUnavailable")
        }
        let outcome = try ChaseTheDragonEngine.submitTurn(state: state, darts: darts, timestamp: timestamp)
        state = outcome.updatedState
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .chaseTheDragonTurn(outcome.event),
            timestamp: timestamp
        )
        return try appendAndProject(session: session, newEvent: envelope, timestamp: timestamp) { runtime in
            runtime.chaseTheDragonState = state
        }
    }

    public static func submitNineLivesTurn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var state = session.runtime.nineLivesState else {
            throw AppError(code: .invalidGameState, layer: .domain, severity: .error, isRecoverable: true, userMessageKey: "error.match.mode.nineLivesUnavailable")
        }
        let outcome = try NineLivesEngine.submitTurn(state: state, darts: darts, timestamp: timestamp)
        state = outcome.updatedState
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .nineLivesTurn(outcome.event),
            timestamp: timestamp
        )
        return try appendAndProject(session: session, newEvent: envelope, timestamp: timestamp) { runtime in
            runtime.nineLivesState = state
        }
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
                    segment: mapX01SegmentRaw($0.segmentRaw),
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
             .aroundTheClockTurn, .nineLivesTurn:
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
            let darts = turn.darts.map {
                DartInput(
                    multiplier: DartMultiplier(rawValue: $0.multiplierRaw) ?? .single,
                    segment: mapX01SegmentRaw($0.segmentRaw),
                    isMiss: $0.wasMiss
                )
            }
            return try submitX01Turn(session: session, enteredTotal: turn.enteredTotal, darts: darts, timestamp: event.timestamp)
        case let .cricketTurn(turn):
            let darts = turn.targetsTouched.map(CricketEngine.dartInput(from:))
            return try submitCricketTurn(session: session, darts: darts, timestamp: event.timestamp)
        case let .baseballTurn(turn):
            let darts = turn.darts.map(BaseballEngine.dartInput(from:))
            return try submitBaseballTurn(session: session, darts: darts, timestamp: event.timestamp)
        case let .killerPick(pick):
            let dart = KillerEngine.dartInput(from: pick)
            return try submitKillerPick(session: session, dart: dart, timestamp: event.timestamp)
        case let .killerTurn(turn):
            let darts = turn.darts.map(KillerEngine.dartInput(from:))
            return try submitKillerTurn(session: session, darts: darts, timestamp: event.timestamp)
        case let .shanghaiTurn(turn):
            let darts = turn.darts.map(ShanghaiEngine.dartInput(from:))
            return try submitShanghaiTurn(session: session, darts: darts, timestamp: event.timestamp)
        case let .americanCricketTurn(turn):
            let darts = turn.darts.map(AmericanCricketEngine.dartInput(from:))
            return try submitAmericanCricketTurn(session: session, darts: darts, timestamp: event.timestamp)
        case let .mickeyMouseTurn(turn):
            let darts = turn.darts.map(MickeyMouseEngine.dartInput(from:))
            return try submitMickeyMouseTurn(session: session, darts: darts, timestamp: event.timestamp)
        case let .mulliganTurn(turn):
            let darts = turn.darts.map(MulliganEngine.dartInput(from:))
            return try submitMulliganTurn(session: session, darts: darts, timestamp: event.timestamp)
        case let .englishCricketTurn(turn):
            let darts = turn.darts.map(EnglishCricketEngine.dartInput(from:))
            return try submitEnglishCricketTurn(session: session, darts: darts, timestamp: event.timestamp)
        case let .knockoutTurn(turn):
            let darts = turn.darts.map(KnockoutEngine.dartInput(from:))
            return try submitKnockoutTurn(session: session, darts: darts, timestamp: event.timestamp)
        case let .suddenDeathTurn(turn):
            return try submitSuddenDeathTurn(session: session, darts: suddenDeathReplayDarts(for: turn), timestamp: event.timestamp)
        case let .fiftyOneByFivesTurn(turn):
            return try submitFiftyOneByFivesTurn(session: session, darts: fiftyOneByFivesReplayDarts(for: turn), timestamp: event.timestamp)
        case let .golfTurn(turn):
            let darts = turn.darts.map(GolfEngine.dartInput(from:))
            let input = GolfTurnInput(darts: darts, endedEarly: turn.endedEarly)
            return try submitGolfTurn(session: session, input: input, timestamp: event.timestamp)
        case let .footballTurn(turn):
            let darts = turn.darts.map(FootballEngine.dartInput(from:))
            return try submitFootballTurn(session: session, darts: darts, timestamp: event.timestamp)
        case let .grandNationalTurn(turn):
            return try submitGrandNationalTurn(session: session, darts: grandNationalReplayDarts(for: turn), timestamp: event.timestamp)
        case let .hareAndHoundsTurn(turn):
            return try submitHareAndHoundsTurn(session: session, darts: hareAndHoundsReplayDarts(for: turn), timestamp: event.timestamp)
        case let .aroundTheClockTurn(turn):
            return try submitAroundTheClockTurn(session: session, darts: aroundTheClockReplayDarts(for: turn), timestamp: event.timestamp)
        case let .aroundTheClock180Turn(turn):
            let darts = turn.darts.map(AroundTheClock180Engine.dartInput(from:))
            return try submitAroundTheClock180Turn(session: session, darts: darts, timestamp: event.timestamp)
        case let .chaseTheDragonTurn(turn):
            let darts = turn.darts.map(ChaseTheDragonEngine.dartInput(from:))
            return try submitChaseTheDragonTurn(session: session, darts: darts, timestamp: event.timestamp)
        case let .nineLivesTurn(turn):
            return try submitNineLivesTurn(session: session, darts: nineLivesReplayDarts(for: turn), timestamp: event.timestamp)
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
        projectRuntime(&runtime, timestamp: timestamp)

        var events = session.events
        events.append(newEvent)
        var snapshot = session.latestSnapshot
        if runtime.eventCount % snapshotInterval == 0 || runtime.status == .completed {
            snapshot = try makeSnapshot(from: runtime, eventCount: runtime.eventCount, timestamp: timestamp)
        }
        return MatchLifecycleSession(runtime: runtime, events: events, latestSnapshot: snapshot)
    }

    private static func projectRuntime(_ runtime: inout MatchRuntimeState, timestamp: Date) {
        if let x01State = runtime.x01State {
            runtime.currentTurnPlayerId = x01State.players[x01State.currentPlayerIndex].playerId
            runtime.currentLegIndex = x01State.legIndex
            runtime.currentSetIndex = x01State.setIndex
            if x01State.isComplete {
                runtime.status = .completed
                runtime.endedAt = timestamp
                runtime.winnerPlayerId = x01State.winnerPlayerId
                runtime.currentTurnPlayerId = nil
            }
            return
        }
        if let cricketState = runtime.cricketState {
            runtime.currentTurnPlayerId = cricketState.players[cricketState.currentPlayerIndex].playerId
            runtime.currentLegIndex = cricketState.legIndex
            runtime.currentSetIndex = cricketState.setIndex
            if cricketState.isComplete {
                runtime.status = .completed
                runtime.endedAt = timestamp
                runtime.winnerPlayerId = cricketState.winnerPlayerId
                runtime.currentTurnPlayerId = nil
            }
            return
        }
        if let baseballState = runtime.baseballState {
            runtime.currentTurnPlayerId = baseballState.players[baseballState.currentPlayerIndex].playerId
            runtime.currentLegIndex = max(0, baseballState.currentInning - 1)
            runtime.currentSetIndex = 0
            if baseballState.isComplete {
                runtime.status = .completed
                runtime.endedAt = timestamp
                runtime.winnerPlayerId = baseballState.winnerPlayerId
                runtime.currentTurnPlayerId = nil
            }
            return
        }
        if let killerState = runtime.killerState {
            if killerState.phase == .numberPick, let pickerId = killerState.pickQueue.first {
                runtime.currentTurnPlayerId = pickerId
            } else if !killerState.isComplete {
                runtime.currentTurnPlayerId = killerState.players[killerState.currentPlayerIndex].playerId
            }
            runtime.currentLegIndex = 0
            runtime.currentSetIndex = 0
            if killerState.isComplete {
                runtime.status = .completed
                runtime.endedAt = timestamp
                runtime.winnerPlayerId = killerState.winnerPlayerId
                runtime.currentTurnPlayerId = nil
            }
            return
        }
        if let shanghaiState = runtime.shanghaiState {
            runtime.currentTurnPlayerId = shanghaiState.players[shanghaiState.currentPlayerIndex].playerId
            runtime.currentLegIndex = max(0, shanghaiState.currentRound - 1)
            runtime.currentSetIndex = 0
            if shanghaiState.isComplete {
                runtime.status = .completed
                runtime.endedAt = timestamp
                runtime.winnerPlayerId = shanghaiState.winnerPlayerId
                runtime.currentTurnPlayerId = nil
            }
            return
        }
        if let state = runtime.americanCricketState {
            projectStandardTurnState(
                &runtime,
                currentTurnPlayerId: state.players[state.currentPlayerIndex].playerId,
                isComplete: state.isComplete,
                winnerPlayerId: state.winnerPlayerId,
                timestamp: timestamp
            )
            return
        }
        if let state = runtime.mickeyMouseState {
            projectStandardTurnState(
                &runtime,
                currentTurnPlayerId: state.players[state.currentPlayerIndex].playerId,
                isComplete: state.isComplete,
                winnerPlayerId: state.winnerPlayerId,
                timestamp: timestamp
            )
            return
        }
        if let state = runtime.mulliganState {
            projectStandardTurnState(
                &runtime,
                currentTurnPlayerId: state.players[state.currentPlayerIndex].playerId,
                isComplete: state.isComplete,
                winnerPlayerId: state.winnerPlayerId,
                timestamp: timestamp
            )
            return
        }
        if let state = runtime.englishCricketState {
            runtime.currentTurnPlayerId = state.currentTurnPlayerId
            runtime.currentLegIndex = state.inningsIndex
            runtime.currentSetIndex = 0
            if state.isComplete {
                runtime.status = .completed
                runtime.endedAt = timestamp
                runtime.winnerPlayerId = state.winnerPlayerId
                runtime.currentTurnPlayerId = nil
            }
            return
        }
        if let state = runtime.knockoutState {
            runtime.currentTurnPlayerId = state.players[state.currentPlayerIndex].playerId
            runtime.currentLegIndex = max(0, state.currentRound - 1)
            runtime.currentSetIndex = 0
            if state.isComplete {
                runtime.status = .completed
                runtime.endedAt = timestamp
                runtime.winnerPlayerId = state.winnerPlayerId
                runtime.currentTurnPlayerId = nil
            }
            return
        }
        if let state = runtime.suddenDeathState {
            runtime.currentTurnPlayerId = state.players[state.currentPlayerIndex].playerId
            runtime.currentLegIndex = max(0, state.currentRound - 1)
            runtime.currentSetIndex = 0
            if state.isComplete {
                runtime.status = .completed
                runtime.endedAt = timestamp
                runtime.winnerPlayerId = state.winnerPlayerId
                runtime.currentTurnPlayerId = nil
            }
            return
        }
        if let state = runtime.fiftyOneByFivesState {
            projectStandardTurnState(
                &runtime,
                currentTurnPlayerId: state.players[state.currentPlayerIndex].playerId,
                isComplete: state.isComplete,
                winnerPlayerId: state.winnerPlayerId,
                timestamp: timestamp
            )
            return
        }
        if let state = runtime.golfState {
            runtime.currentTurnPlayerId = state.players[state.currentPlayerIndex].playerId
            runtime.currentLegIndex = max(0, state.currentHole - 1)
            runtime.currentSetIndex = 0
            if state.isComplete {
                runtime.status = .completed
                runtime.endedAt = timestamp
                runtime.winnerPlayerId = state.winnerPlayerId
                runtime.currentTurnPlayerId = nil
            }
            return
        }
        if let state = runtime.footballState {
            projectStandardTurnState(
                &runtime,
                currentTurnPlayerId: state.players[state.currentPlayerIndex].playerId,
                isComplete: state.isComplete,
                winnerPlayerId: state.winnerPlayerId,
                timestamp: timestamp
            )
            return
        }
        if let state = runtime.grandNationalState {
            projectStandardTurnState(
                &runtime,
                currentTurnPlayerId: state.players[state.currentPlayerIndex].playerId,
                isComplete: state.isComplete,
                winnerPlayerId: state.winnerPlayerId,
                timestamp: timestamp
            )
            return
        }
        if let state = runtime.hareAndHoundsState {
            projectStandardTurnState(
                &runtime,
                currentTurnPlayerId: state.players[state.currentPlayerIndex].playerId,
                isComplete: state.isComplete,
                winnerPlayerId: state.winnerPlayerId,
                timestamp: timestamp
            )
            return
        }
        if let state = runtime.aroundTheClockState {
            projectStandardTurnState(
                &runtime,
                currentTurnPlayerId: state.players[state.currentPlayerIndex].playerId,
                isComplete: state.isComplete,
                winnerPlayerId: state.winnerPlayerId,
                timestamp: timestamp
            )
            return
        }
        if let state = runtime.aroundTheClock180State {
            projectStandardTurnState(
                &runtime,
                currentTurnPlayerId: state.players[state.currentPlayerIndex].playerId,
                isComplete: state.isComplete,
                winnerPlayerId: state.winnerPlayerId,
                timestamp: timestamp
            )
            return
        }
        if let state = runtime.chaseTheDragonState {
            projectStandardTurnState(
                &runtime,
                currentTurnPlayerId: state.players[state.currentPlayerIndex].playerId,
                isComplete: state.isComplete,
                winnerPlayerId: state.winnerPlayerId,
                timestamp: timestamp
            )
            return
        }
        if let state = runtime.nineLivesState {
            projectStandardTurnState(
                &runtime,
                currentTurnPlayerId: state.players[state.currentPlayerIndex].playerId,
                isComplete: state.isComplete,
                winnerPlayerId: state.winnerPlayerId,
                timestamp: timestamp
            )
        }
    }

    private static func projectStandardTurnState(
        _ runtime: inout MatchRuntimeState,
        currentTurnPlayerId: UUID?,
        legIndex: Int = 0,
        setIndex: Int = 0,
        isComplete: Bool,
        winnerPlayerId: UUID?,
        timestamp: Date
    ) {
        runtime.currentTurnPlayerId = currentTurnPlayerId
        runtime.currentLegIndex = legIndex
        runtime.currentSetIndex = setIndex
        if isComplete {
            runtime.status = .completed
            runtime.endedAt = timestamp
            runtime.winnerPlayerId = winnerPlayerId
            runtime.currentTurnPlayerId = nil
        }
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
