import Foundation

public enum MatchEventPayload: Codable, Equatable, Sendable {
    case x01Turn(X01TurnEvent)
    case cricketTurn(CricketTurnEvent)

    private enum CodingKeys: String, CodingKey {
        case kind
        case x01
        case cricket
    }

    private enum Kind: String, Codable {
        case x01Turn
        case cricketTurn
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        switch kind {
        case .x01Turn:
            self = .x01Turn(try container.decode(X01TurnEvent.self, forKey: .x01))
        case .cricketTurn:
            self = .cricketTurn(try container.decode(CricketTurnEvent.self, forKey: .cricket))
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
}

public struct MatchLifecycleSession: Sendable {
    public var runtime: MatchRuntimeState
    public var events: [MatchEventEnvelope]
    public var latestSnapshot: MatchSnapshot
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
            cricketState: nil
        )

        switch (type, config) {
        case let (.x01, .x01(cfg)):
            runtime.x01State = try X01Engine.makeInitialState(config: cfg, playerIds: playerIds)
        case let (.cricket, .cricket(cfg)):
            runtime.cricketState = try CricketEngine.makeInitialState(config: cfg, playerIds: playerIds)
        default:
            throw AppError(code: .validationFailed, layer: .domain, severity: .warning, isRecoverable: true, userMessageKey: "error.match.configMismatch")
        }

        let initialSnapshot = try makeSnapshot(from: runtime, eventCount: 0, timestamp: startedAt)
        return MatchLifecycleSession(runtime: runtime, events: [], latestSnapshot: initialSnapshot)
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
        return try appendAndProject(session: session, newEvent: envelope, x01State: x01State, cricketState: nil, timestamp: timestamp)
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
        return try appendAndProject(session: session, newEvent: envelope, x01State: nil, cricketState: cricketState, timestamp: timestamp)
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
                let darts = turn.targetsTouched.map {
                    DartInput(
                        multiplier: DartMultiplier(rawValue: $0.multiplierRaw) ?? .single,
                        segment: mapCricketTargetRaw($0.targetRaw),
                        isMiss: $0.wasMiss
                    )
                }
                session = try submitCricketTurn(session: session, darts: darts, timestamp: event.timestamp)
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
                let darts = turn.targetsTouched.map {
                    DartInput(
                        multiplier: DartMultiplier(rawValue: $0.multiplierRaw) ?? .single,
                        segment: mapCricketTargetRaw($0.targetRaw),
                        isMiss: $0.wasMiss
                    )
                }
                rebuilt = try submitCricketTurn(session: rebuilt, darts: darts, timestamp: event.timestamp)
            }
        }
        return rebuilt
    }

    private static func appendAndProject(
        session: MatchLifecycleSession,
        newEvent: MatchEventEnvelope,
        x01State: X01State?,
        cricketState: CricketState?,
        timestamp: Date
    ) throws -> MatchLifecycleSession {
        var runtime = session.runtime
        runtime.eventCount += 1
        runtime.x01State = x01State ?? runtime.x01State
        runtime.cricketState = cricketState ?? runtime.cricketState

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
            if cricketState.isComplete {
                runtime.status = .completed
                runtime.endedAt = timestamp
                runtime.winnerPlayerId = cricketState.winnerPlayerId
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

    private static func mapCricketTargetRaw(_ raw: String) -> DartSegment {
        if let value = Int(raw), (15 ... 20).contains(value) {
            return .oneToTwenty(value)
        }
        if raw == "bull" { return .outerBull }
        return .miss
    }
}
