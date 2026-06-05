import Foundation

public enum MatchEventPayload: Codable, Equatable, Sendable {
    case x01Turn(X01TurnEvent)
    case cricketTurn(CricketTurnEvent)
    case baseballTurn(BaseballTurnEvent)
    case killerPick(KillerPickEvent)
    case killerTurn(KillerTurnEvent)

    private enum CodingKeys: String, CodingKey {
        case kind
        case x01
        case cricket
        case baseball
        case killerPick
        case killerTurn
    }

    private enum Kind: String, Codable {
        case x01Turn
        case cricketTurn
        case baseballTurn
        case killerPick
        case killerTurn
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
    public var currentTurnPlayerId: UUID?
    public var currentLegIndex: Int
    public var currentSetIndex: Int
    public var eventCount: Int
    public var x01State: X01State?
    public var cricketState: CricketState?
    public var baseballState: BaseballState?
    public var killerState: KillerState?
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

    public static func createMatch(
        matchId: UUID = UUID(),
        type: MatchType,
        config: MatchConfigPayload,
        participants: [MatchParticipant],
        startedAt: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard participants.count >= 2 else {
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
            currentTurnPlayerId: ordered.first?.playerId ?? ordered.first?.id,
            currentLegIndex: 0,
            currentSetIndex: 0,
            eventCount: 0,
            x01State: nil,
            cricketState: nil,
            baseballState: nil,
            killerState: nil
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
        default:
            throw AppError(code: .validationFailed, layer: .domain, severity: .warning, isRecoverable: true, userMessageKey: "error.match.configMismatch")
        }

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
        return try appendAndProject(session: session, newEvent: envelope, x01State: x01State, cricketState: nil, baseballState: nil, killerState: nil, timestamp: timestamp)
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
        return try appendAndProject(session: session, newEvent: envelope, x01State: nil, cricketState: cricketState, baseballState: nil, killerState: nil, timestamp: timestamp)
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
        return try appendAndProject(session: session, newEvent: envelope, x01State: nil, cricketState: nil, baseballState: baseballState, killerState: nil, timestamp: timestamp)
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
        return try appendAndProject(session: session, newEvent: envelope, x01State: nil, cricketState: nil, baseballState: nil, killerState: killerState, timestamp: timestamp)
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
        return try appendAndProject(session: session, newEvent: envelope, x01State: nil, cricketState: nil, baseballState: nil, killerState: killerState, timestamp: timestamp)
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
        }
    }

    public static func rehydrate(snapshot: MatchSnapshot, tailEvents: [MatchEventEnvelope]) throws -> MatchLifecycleSession {
        let runtime = try CodablePayloadCoder.decode(MatchRuntimeState.self, from: snapshot.payload)
        var session = MatchLifecycleSession(runtime: runtime, events: [], latestSnapshot: snapshot)
        for event in tailEvents {
            switch event.payload {
            case let .x01Turn(turn):
                let darts = turn.darts.map {
                    DartInput(
                        multiplier: DartMultiplier(rawValue: $0.multiplierRaw) ?? .single,
                        segment: mapX01SegmentRaw($0.segmentRaw),
                        isMiss: $0.wasMiss
                    )
                }
                session = try submitX01Turn(session: session, enteredTotal: turn.enteredTotal, darts: darts, timestamp: event.timestamp)
            case let .cricketTurn(turn):
                let darts = turn.targetsTouched.map(CricketEngine.dartInput(from:))
                session = try submitCricketTurn(session: session, darts: darts, timestamp: event.timestamp)
            case let .baseballTurn(turn):
                let darts = turn.darts.map(BaseballEngine.dartInput(from:))
                session = try submitBaseballTurn(session: session, darts: darts, timestamp: event.timestamp)
            case let .killerPick(pick):
                let dart = KillerEngine.dartInput(from: pick)
                session = try submitKillerPick(session: session, dart: dart, timestamp: event.timestamp)
            case let .killerTurn(turn):
                let darts = turn.darts.map(KillerEngine.dartInput(from:))
                session = try submitKillerTurn(session: session, darts: darts, timestamp: event.timestamp)
            }
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
            switch event.payload {
            case let .x01Turn(turn):
                let darts = turn.darts.map {
                    DartInput(
                        multiplier: DartMultiplier(rawValue: $0.multiplierRaw) ?? .single,
                        segment: mapX01SegmentRaw($0.segmentRaw),
                        isMiss: $0.wasMiss
                    )
                }
                rebuilt = try submitX01Turn(session: rebuilt, enteredTotal: turn.enteredTotal, darts: darts, timestamp: event.timestamp)
            case let .cricketTurn(turn):
                let darts = turn.targetsTouched.map(CricketEngine.dartInput(from:))
                rebuilt = try submitCricketTurn(session: rebuilt, darts: darts, timestamp: event.timestamp)
            case let .baseballTurn(turn):
                let darts = turn.darts.map(BaseballEngine.dartInput(from:))
                rebuilt = try submitBaseballTurn(session: rebuilt, darts: darts, timestamp: event.timestamp)
            case let .killerPick(pick):
                let dart = KillerEngine.dartInput(from: pick)
                rebuilt = try submitKillerPick(session: rebuilt, dart: dart, timestamp: event.timestamp)
            case let .killerTurn(turn):
                let darts = turn.darts.map(KillerEngine.dartInput(from:))
                rebuilt = try submitKillerTurn(session: rebuilt, darts: darts, timestamp: event.timestamp)
            }
        }
        return rebuilt
    }

    private static func appendAndProject(
        session: MatchLifecycleSession,
        newEvent: MatchEventEnvelope,
        x01State: X01State?,
        cricketState: CricketState?,
        baseballState: BaseballState?,
        killerState: KillerState?,
        timestamp: Date
    ) throws -> MatchLifecycleSession {
        var runtime = session.runtime
        runtime.eventCount += 1
        runtime.x01State = x01State ?? runtime.x01State
        runtime.cricketState = cricketState ?? runtime.cricketState
        runtime.baseballState = baseballState ?? runtime.baseballState
        runtime.killerState = killerState ?? runtime.killerState

        if let x01State {
            runtime.currentTurnPlayerId = x01State.players[x01State.currentPlayerIndex].playerId
            runtime.currentLegIndex = x01State.legIndex
            runtime.currentSetIndex = x01State.setIndex
            if x01State.isComplete {
                runtime.status = .completed
                runtime.endedAt = timestamp
                runtime.winnerPlayerId = x01State.winnerPlayerId
                runtime.currentTurnPlayerId = nil
            }
        }
        if let cricketState {
            runtime.currentTurnPlayerId = cricketState.players[cricketState.currentPlayerIndex].playerId
            runtime.currentLegIndex = cricketState.legIndex
            runtime.currentSetIndex = cricketState.setIndex
            if cricketState.isComplete {
                runtime.status = .completed
                runtime.endedAt = timestamp
                runtime.winnerPlayerId = cricketState.winnerPlayerId
                runtime.currentTurnPlayerId = nil
            }
        }
        if let baseballState {
            runtime.currentTurnPlayerId = baseballState.players[baseballState.currentPlayerIndex].playerId
            runtime.currentLegIndex = max(0, baseballState.currentInning - 1)
            runtime.currentSetIndex = 0
            if baseballState.isComplete {
                runtime.status = .completed
                runtime.endedAt = timestamp
                runtime.winnerPlayerId = baseballState.winnerPlayerId
                runtime.currentTurnPlayerId = nil
            }
        }
        if let killerState {
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
        }

        var events = session.events
        events.append(newEvent)
        var snapshot = session.latestSnapshot
        if runtime.eventCount % snapshotInterval == 0 || runtime.status == .completed {
            snapshot = try makeSnapshot(from: runtime, eventCount: runtime.eventCount, timestamp: timestamp)
        }
        return MatchLifecycleSession(runtime: runtime, events: events, latestSnapshot: snapshot)
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
