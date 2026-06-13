import Foundation

/// Laps option for Chase the Dragon — 1 standard lap or 3 for the three-headed dragon variant.
public enum ChaseTheDragonLaps: Int, Codable, CaseIterable, Sendable {
    case one = 1
    case three = 3

    public var displayName: String {
        switch self {
        case .one: L10n.string("play.chaseTheDragon.setup.laps.one")
        case .three: L10n.string("play.chaseTheDragon.setup.laps.three")
        }
    }
}

/// Configuration payload for a Chase the Dragon match.
public struct MatchConfigChaseTheDragon: Codable, Equatable, Sendable {
    public static let currentPayloadVersion = 1

    public let payloadVersion: Int
    /// Total laps to complete. Raw integer stored for forward compatibility.
    public let lapsRaw: Int

    public var laps: ChaseTheDragonLaps {
        ChaseTheDragonLaps(rawValue: lapsRaw) ?? .one
    }

    public init(
        payloadVersion: Int = currentPayloadVersion,
        laps: ChaseTheDragonLaps = .one
    ) {
        self.payloadVersion = payloadVersion
        self.lapsRaw = laps.rawValue
    }
}

/// Immutable record of one dart in a Chase the Dragon visit.
public struct ChaseTheDragonDartEvent: Codable, Equatable, Sendable {
    public let dartOrder: Int
    public let segmentRaw: String
    public let multiplierRaw: String
    public let isQualifyingHit: Bool
    public let wasMiss: Bool

    public init(
        dartOrder: Int,
        segmentRaw: String,
        multiplierRaw: String,
        isQualifyingHit: Bool,
        wasMiss: Bool
    ) {
        self.dartOrder = dartOrder
        self.segmentRaw = segmentRaw
        self.multiplierRaw = multiplierRaw
        self.isQualifyingHit = isQualifyingHit
        self.wasMiss = wasMiss
    }
}

/// Immutable record of one turn in a Chase the Dragon match.
public struct ChaseTheDragonTurnEvent: Codable, Equatable, Identifiable, Sendable {
    public let payloadVersion: Int
    public let id: UUID
    public let playerId: UUID
    public let turnIndex: Int
    /// Sequence step index before this turn was played (0-based).
    public let stepBefore: Int
    /// Sequence step index after this turn was played.
    public let stepAfter: Int
    /// Current lap index (0-based) at the time the turn was played.
    public let lap: Int
    public let darts: [ChaseTheDragonDartEvent]
    public let timestamp: Date
}

/// Per-player mutable state.
public struct ChaseTheDragonPlayerState: Codable, Equatable, Sendable {
    public let playerId: UUID
    /// Current position in the 13-step sequence (0…12 active; 13 = lap complete).
    public var stepIndex: Int
    /// Number of laps fully completed.
    public var lapsCompleted: Int
    /// Total darts thrown across all turns (for solo drill statistics).
    public var totalDartsThrown: Int

    public init(
        playerId: UUID,
        stepIndex: Int = 0,
        lapsCompleted: Int = 0,
        totalDartsThrown: Int = 0
    ) {
        self.playerId = playerId
        self.stepIndex = stepIndex
        self.lapsCompleted = lapsCompleted
        self.totalDartsThrown = totalDartsThrown
    }
}

/// Full mutable match state.
public struct ChaseTheDragonState: Codable, Equatable, Sendable {
    public let config: MatchConfigChaseTheDragon
    public var players: [ChaseTheDragonPlayerState]
    public var currentPlayerIndex: Int
    public var turnIndex: Int
    public var winnerPlayerId: UUID?
    public var isComplete: Bool
    /// Wall-clock start time used for solo elapsed-time tracking.
    public let startedAt: Date

    public init(
        config: MatchConfigChaseTheDragon,
        players: [ChaseTheDragonPlayerState],
        currentPlayerIndex: Int = 0,
        turnIndex: Int = 0,
        winnerPlayerId: UUID? = nil,
        isComplete: Bool = false,
        startedAt: Date = Date()
    ) {
        self.config = config
        self.players = players
        self.currentPlayerIndex = currentPlayerIndex
        self.turnIndex = turnIndex
        self.winnerPlayerId = winnerPlayerId
        self.isComplete = isComplete
        self.startedAt = startedAt
    }
}

/// Return value from `ChaseTheDragonEngine.submitTurn`.
public struct ChaseTheDragonTurnOutcome: Sendable {
    public let updatedState: ChaseTheDragonState
    public let event: ChaseTheDragonTurnEvent
}

// MARK: - Sequence definition

extension ChaseTheDragonEngine {
    /// The fixed 13-step dragon sequence.
    public static let dragonSequence: [DragonStep] = [
        .treble(10), .treble(11), .treble(12), .treble(13), .treble(14),
        .treble(15), .treble(16), .treble(17), .treble(18), .treble(19),
        .treble(20), .outerBull, .innerBull,
    ]

    /// A single step in the dragon sequence.
    public enum DragonStep: Equatable, Sendable {
        case treble(Int)
        case outerBull
        case innerBull

        /// Returns `true` when `dart` qualifies for this step.
        public func isQualifyingHit(_ dart: DartInput) -> Bool {
            guard !dart.isMiss else { return false }
            switch self {
            case let .treble(number):
                guard case let .oneToTwenty(value) = dart.segment, value == number else { return false }
                return dart.multiplier == .triple
            case .outerBull:
                return dart.segment == .outerBull && !dart.isMiss
            case .innerBull:
                return dart.segment == .innerBull && !dart.isMiss
            }
        }

        /// Human-readable label used for display and accessibility.
        public var displayLabel: String {
            switch self {
            case let .treble(n): return L10n.format("play.chaseTheDragon.step.trebleFormat", n)
            case .outerBull: return L10n.string("play.chaseTheDragon.step.outerBull")
            case .innerBull: return L10n.string("play.chaseTheDragon.step.innerBull")
            }
        }
    }
}

// MARK: - Engine

/// Pure-functional rules engine for Chase the Dragon.
public enum ChaseTheDragonEngine {
    /// Total steps in one full lap.
    public static let stepsPerLap = dragonSequence.count // 13

    public static func makeInitialState(
        config: MatchConfigChaseTheDragon,
        playerIds: [UUID],
        startedAt: Date = Date()
    ) throws -> ChaseTheDragonState {
        guard !playerIds.isEmpty else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.players.minimum"
            )
        }
        let players = playerIds.map { ChaseTheDragonPlayerState(playerId: $0) }
        return ChaseTheDragonState(
            config: config,
            players: players,
            startedAt: startedAt
        )
    }

    public static func submitTurn(
        state: ChaseTheDragonState,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> ChaseTheDragonTurnOutcome {
        guard !state.isComplete else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.completed"
            )
        }
        guard darts.count <= 3 else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.turn.maxDarts"
            )
        }

        var updated = state
        let playerIndex = updated.currentPlayerIndex
        let playerId = updated.players[playerIndex].playerId
        let stepBefore = updated.players[playerIndex].stepIndex
        let lapBefore = updated.players[playerIndex].lapsCompleted

        var dartEvents: [ChaseTheDragonDartEvent] = []
        var stepIndex = stepBefore

        for (offset, dart) in darts.enumerated() {
            let step = dragonSequence[stepIndex]
            let hit = step.isQualifyingHit(dart)
            dartEvents.append(
                ChaseTheDragonDartEvent(
                    dartOrder: offset + 1,
                    segmentRaw: segmentRaw(for: dart.segment),
                    multiplierRaw: dart.multiplier.rawValue,
                    isQualifyingHit: hit,
                    wasMiss: dart.isMiss
                )
            )
            if hit {
                stepIndex += 1
                if stepIndex == stepsPerLap {
                    updated.players[playerIndex].lapsCompleted += 1
                    let lapsNeeded = updated.config.laps.rawValue
                    if updated.players[playerIndex].lapsCompleted >= lapsNeeded {
                        updated.players[playerIndex].stepIndex = stepIndex
                        updated.players[playerIndex].totalDartsThrown += darts.count
                        updated.turnIndex += 1
                        completeMatch(&updated, winnerId: playerId)
                        let event = makeTurnEvent(
                            state: state,
                            playerId: playerId,
                            stepBefore: stepBefore,
                            stepAfter: stepIndex,
                            lap: lapBefore,
                            darts: dartEvents,
                            timestamp: timestamp
                        )
                        return ChaseTheDragonTurnOutcome(updatedState: updated, event: event)
                    }
                    stepIndex = 0
                }
            }
        }

        updated.players[playerIndex].stepIndex = stepIndex
        updated.players[playerIndex].totalDartsThrown += darts.count
        advanceTurn(&updated)

        let event = makeTurnEvent(
            state: state,
            playerId: playerId,
            stepBefore: stepBefore,
            stepAfter: stepIndex,
            lap: lapBefore,
            darts: dartEvents,
            timestamp: timestamp
        )
        return ChaseTheDragonTurnOutcome(updatedState: updated, event: event)
    }

    public static func replay(
        config: MatchConfigChaseTheDragon,
        playerIds: [UUID],
        events: [ChaseTheDragonTurnEvent]
    ) throws -> ChaseTheDragonState {
        let startedAt = events.first?.timestamp ?? Date()
        var state = try makeInitialState(config: config, playerIds: playerIds, startedAt: startedAt)
        for event in events {
            let darts = event.darts.map(dartInput(from:))
            state = try submitTurn(state: state, darts: darts, timestamp: event.timestamp).updatedState
        }
        return state
    }

    // MARK: - Internal helpers

    public static func dartInput(from event: ChaseTheDragonDartEvent) -> DartInput {
        DartInput(
            multiplier: DartMultiplier(rawValue: event.multiplierRaw) ?? .single,
            segment: segment(fromRaw: event.segmentRaw),
            isMiss: event.wasMiss
        )
    }

    private static func advanceTurn(_ state: inout ChaseTheDragonState) {
        state.turnIndex += 1
        guard !state.isComplete else { return }
        let playerCount = state.players.count
        state.currentPlayerIndex = (state.currentPlayerIndex + 1) % playerCount
    }

    private static func completeMatch(_ state: inout ChaseTheDragonState, winnerId: UUID) {
        state.winnerPlayerId = winnerId
        state.isComplete = true
        state.currentPlayerIndex = 0
    }

    private static func makeTurnEvent(
        state: ChaseTheDragonState,
        playerId: UUID,
        stepBefore: Int,
        stepAfter: Int,
        lap: Int,
        darts: [ChaseTheDragonDartEvent],
        timestamp: Date
    ) -> ChaseTheDragonTurnEvent {
        ChaseTheDragonTurnEvent(
            payloadVersion: 1,
            id: UUID(),
            playerId: playerId,
            turnIndex: state.turnIndex,
            stepBefore: stepBefore,
            stepAfter: stepAfter,
            lap: lap,
            darts: darts,
            timestamp: timestamp
        )
    }

    private static func segmentRaw(for segment: DartSegment) -> String {
        switch segment {
        case let .oneToTwenty(value): return String(value)
        case .outerBull: return "outerBull"
        case .innerBull: return "innerBull"
        case .miss: return "miss"
        }
    }

    static func segment(fromRaw raw: String) -> DartSegment {
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
