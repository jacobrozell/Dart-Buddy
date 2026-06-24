import Foundation

// MARK: - Pallino target

public enum PallinoRing: String, Codable, CaseIterable, Sendable {
    case single
    case double
    case triple

    public var multiplier: DartMultiplier {
        switch self {
        case .single: return .single
        case .double: return .double
        case .triple: return .triple
        }
    }

    /// Rings adjacent on the wire: S↔D↔T.
    public var adjacentRings: [PallinoRing] {
        switch self {
        case .single: return [.double]
        case .double: return [.single, .triple]
        case .triple: return [.double]
        }
    }
}

/// The "pallino" — segment + ring — called for the round.
public struct PallinoTarget: Codable, Equatable, Hashable, Sendable {
    public let segment: Int
    public let ring: PallinoRing

    public init(segment: Int, ring: PallinoRing) {
        self.segment = segment
        self.ring = ring
    }
}

// MARK: - Config

public struct MatchConfigPallino: Codable, Equatable, Sendable {
    public static let currentPayloadVersion = 1
    public static let stonesPerPlayer = 3
    public static let allowedRoundsToWin: [Int] = [7, 11, 15]

    public let payloadVersion: Int
    public let roundsToWin: Int
    public let kissEnabled: Bool

    public init(
        payloadVersion: Int = currentPayloadVersion,
        roundsToWin: Int = 11,
        kissEnabled: Bool = true
    ) {
        self.payloadVersion = payloadVersion
        self.roundsToWin = roundsToWin
        self.kissEnabled = kissEnabled
    }
}

// MARK: - Stone + state

public enum PallinoPhase: String, Codable, Sendable {
    case awaitingPallino
    case throwing
}

public struct PallinoStone: Codable, Equatable, Hashable, Sendable {
    public let playerId: UUID
    public let distanceScore: Int
    public let isExact: Bool

    public init(playerId: UUID, distanceScore: Int, isExact: Bool) {
        self.playerId = playerId
        self.distanceScore = distanceScore
        self.isExact = isExact
    }
}

public struct PallinoRoundEvent: Codable, Equatable, Identifiable, Sendable {
    public let payloadVersion: Int
    public let id: UUID
    public let roundIndex: Int
    public let pallino: PallinoTarget
    public let stones: [PallinoStone]
    public let winnerPlayerId: UUID?
    public let isTie: Bool
    public let kissCount: Int
    public let roundWinsAfter: [UUID: Int]
    public let matchCompleted: Bool
    public let timestamp: Date

    public init(
        payloadVersion: Int = 1,
        id: UUID = UUID(),
        roundIndex: Int,
        pallino: PallinoTarget,
        stones: [PallinoStone],
        winnerPlayerId: UUID?,
        isTie: Bool,
        kissCount: Int,
        roundWinsAfter: [UUID: Int],
        matchCompleted: Bool,
        timestamp: Date
    ) {
        self.payloadVersion = payloadVersion
        self.id = id
        self.roundIndex = roundIndex
        self.pallino = pallino
        self.stones = stones
        self.winnerPlayerId = winnerPlayerId
        self.isTie = isTie
        self.kissCount = kissCount
        self.roundWinsAfter = roundWinsAfter
        self.matchCompleted = matchCompleted
        self.timestamp = timestamp
    }
}

public struct PallinoState: Codable, Equatable, Sendable {
    public let config: MatchConfigPallino
    public let playerIds: [UUID]
    public var roundWins: [UUID: Int]
    public var roundIndex: Int
    public var phase: PallinoPhase
    public var currentPallino: PallinoTarget?
    public var stones: [PallinoStone]
    public var throwInRound: Int
    public var winnerPlayerId: UUID?
    public var isComplete: Bool

    /// Total stones to be thrown in a round.
    public var stonesPerRound: Int { playerIds.count * MatchConfigPallino.stonesPerPlayer }

    public var currentPlayerId: UUID? {
        guard phase == .throwing else { return nil }
        return playerIds[throwInRound % playerIds.count]
    }

    public init(
        config: MatchConfigPallino,
        playerIds: [UUID],
        roundWins: [UUID: Int]? = nil,
        roundIndex: Int = 0,
        phase: PallinoPhase = .awaitingPallino,
        currentPallino: PallinoTarget? = nil,
        stones: [PallinoStone] = [],
        throwInRound: Int = 0,
        winnerPlayerId: UUID? = nil,
        isComplete: Bool = false
    ) {
        self.config = config
        self.playerIds = playerIds
        self.roundWins = roundWins ?? Dictionary(uniqueKeysWithValues: playerIds.map { ($0, 0) })
        self.roundIndex = roundIndex
        self.phase = phase
        self.currentPallino = currentPallino
        self.stones = stones
        self.throwInRound = throwInRound
        self.winnerPlayerId = winnerPlayerId
        self.isComplete = isComplete
    }
}

public struct PallinoDartOutcome: Sendable {
    public let updatedState: PallinoState
    public let stone: PallinoStone
    /// Non-nil when the dart was the last in the round.
    public let roundEvent: PallinoRoundEvent?
}

// MARK: - Engine

public enum PallinoEngine {

    public static func makeInitialState(
        config: MatchConfigPallino,
        playerIds: [UUID]
    ) throws -> PallinoState {
        guard (2 ... 4).contains(playerIds.count) else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "setup.validation.pallinoPlayerCount"
            )
        }
        guard MatchConfigPallino.allowedRoundsToWin.contains(config.roundsToWin) else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "setup.validation.pallinoRoundsToWin"
            )
        }
        return PallinoState(config: config, playerIds: playerIds)
    }

    /// Caller-supplied pallino. A `randomPallino(using:)` helper is provided for
    /// production use; tests pin the pallino explicitly.
    public static func setPallino(
        state: PallinoState,
        pallino: PallinoTarget
    ) throws -> PallinoState {
        guard !state.isComplete else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.completed"
            )
        }
        guard state.phase == .awaitingPallino else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.pallino.outOfPhase"
            )
        }
        guard (1 ... 20).contains(pallino.segment) else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.pallino.invalidSegment"
            )
        }
        var updated = state
        updated.currentPallino = pallino
        updated.phase = .throwing
        updated.stones = []
        updated.throwInRound = 0
        return updated
    }

    public static func submitDart(
        state: PallinoState,
        dart: DartInput,
        timestamp: Date = Date()
    ) throws -> PallinoDartOutcome {
        guard !state.isComplete else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.completed"
            )
        }
        guard state.phase == .throwing, let pallino = state.currentPallino,
              let playerId = state.currentPlayerId else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.pallino.dartOutOfPhase"
            )
        }

        var updated = state
        let (distance, isExact) = distanceScore(dart: dart, pallino: pallino)
        let stone = PallinoStone(playerId: playerId, distanceScore: distance, isExact: isExact)

        if isExact, state.config.kissEnabled {
            // Find the highest-scoring stone from any other player and remove it.
            if let kissIndex = updated.stones
                .enumerated()
                .filter({ $0.element.playerId != playerId })
                .max(by: { $0.element.distanceScore < $1.element.distanceScore })?
                .offset {
                updated.stones.remove(at: kissIndex)
            }
        }

        updated.stones.append(stone)
        updated.throwInRound += 1

        var roundEvent: PallinoRoundEvent?
        if updated.throwInRound >= updated.stonesPerRound {
            roundEvent = resolveRound(state: &updated, timestamp: timestamp)
        }

        return PallinoDartOutcome(
            updatedState: updated,
            stone: stone,
            roundEvent: roundEvent
        )
    }

    public static func replay(
        config: MatchConfigPallino,
        playerIds: [UUID],
        events: [PallinoRoundEvent]
    ) throws -> PallinoState {
        var state = try makeInitialState(config: config, playerIds: playerIds)
        for event in events {
            state.roundIndex += 1
            for (id, wins) in event.roundWinsAfter {
                state.roundWins[id] = wins
            }
            if event.matchCompleted {
                state.isComplete = true
                state.winnerPlayerId = event.winnerPlayerId
                state.phase = .awaitingPallino
                state.currentPallino = nil
                state.stones = []
                state.throwInRound = 0
            } else {
                state.phase = .awaitingPallino
                state.currentPallino = nil
                state.stones = []
                state.throwInRound = 0
            }
        }
        return state
    }

    // MARK: - Distance scoring

    /// Proxy distance score per spec §5.3.
    public static func distanceScore(dart: DartInput, pallino: PallinoTarget) -> (score: Int, isExact: Bool) {
        guard !dart.isMiss else { return (0, false) }
        switch dart.segment {
        case let .oneToTwenty(value):
            let isSameSegment = value == pallino.segment
            let isAdjacentSegment = isAdjacentSegment(value, pallino.segment)
            let dartRing: PallinoRing = {
                switch dart.multiplier {
                case .single: return .single
                case .double: return .double
                case .triple: return .triple
                }
            }()
            if isSameSegment, dartRing == pallino.ring {
                return (100, true)
            }
            if isSameSegment, pallino.ring.adjacentRings.contains(dartRing) {
                return (70, false)
            }
            if dartRing == pallino.ring, isAdjacentSegment {
                return (50, false)
            }
            if isSameSegment {
                return (40, false)
            }
            return (0, false)
        case .innerBull, .outerBull, .miss:
            return (0, false)
        }
    }

    static func isAdjacentSegment(_ a: Int, _ b: Int) -> Bool {
        guard (1 ... 20).contains(a), (1 ... 20).contains(b) else { return false }
        if a == b { return false }
        let diff = abs(a - b)
        return diff == 1 || diff == 19   // 20 ↔ 1 wraps
    }

    // MARK: - Pallino generation (production helper)

    /// Draws a random pallino. Singles are weighted more heavily per spec to
    /// favour tighter play. Tests pass an explicit RNG so the draw is repeatable.
    public static func randomPallino<G: RandomNumberGenerator>(
        using rng: inout G,
        singlesWeight: Double = 0.6
    ) -> PallinoTarget {
        let segment = Int(rng.next() % 20) + 1
        let roll = Double(rng.next() % 1_000_000) / 1_000_000
        let ring: PallinoRing
        if roll < singlesWeight {
            ring = .single
        } else {
            // Remaining mass split evenly between double and triple.
            let half = singlesWeight + (1.0 - singlesWeight) / 2.0
            ring = roll < half ? .double : .triple
        }
        return PallinoTarget(segment: segment, ring: ring)
    }

    // MARK: - Round resolution

    private static func resolveRound(
        state: inout PallinoState,
        timestamp: Date
    ) -> PallinoRoundEvent {
        var bestByPlayer: [UUID: Int] = [:]
        var kissCount = 0
        for stone in state.stones {
            bestByPlayer[stone.playerId] = max(bestByPlayer[stone.playerId] ?? 0, stone.distanceScore)
            if stone.isExact { kissCount += 1 }
        }
        let topScore = bestByPlayer.values.max() ?? 0
        let leaders = bestByPlayer.filter { $0.value == topScore }.keys.sorted(by: { $0.uuidString < $1.uuidString })
        let isTie = leaders.count > 1
        let winnerId = (isTie || topScore == 0) ? nil : leaders.first

        let roundIndex = state.roundIndex
        let pallino = state.currentPallino!  // resolved only inside throwing phase

        if let winnerId {
            state.roundWins[winnerId, default: 0] += 1
        }

        let matchCompleted: Bool = {
            guard let winnerId else { return false }
            return (state.roundWins[winnerId] ?? 0) >= state.config.roundsToWin
        }()

        let event = PallinoRoundEvent(
            roundIndex: roundIndex,
            pallino: pallino,
            stones: state.stones,
            winnerPlayerId: winnerId,
            isTie: isTie,
            kissCount: kissCount,
            roundWinsAfter: state.roundWins,
            matchCompleted: matchCompleted,
            timestamp: timestamp
        )

        state.roundIndex += 1
        if matchCompleted {
            state.isComplete = true
            state.winnerPlayerId = winnerId
        }
        state.phase = .awaitingPallino
        state.currentPallino = nil
        state.stones = []
        state.throwInRound = 0
        return event
    }
}
