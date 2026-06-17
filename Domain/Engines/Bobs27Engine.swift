import Foundation

/// Serialisable configuration for a Bob's 27 match.
///
/// Bob's 27 is a solo doubles-practice drill. The starting score is fixed at 27;
/// per the spec the only knobs are the bull-miss penalty (defaults to 27) and
/// whether a non-positive running score ends the game early.
public struct MatchConfigBobs27: Codable, Equatable, Sendable {
    public static let currentPayloadVersion = 1

    public let payloadVersion: Int
    public let bullSubtract: Int
    public let gameOverAtZero: Bool

    public init(
        payloadVersion: Int = currentPayloadVersion,
        bullSubtract: Int = 27,
        gameOverAtZero: Bool = true
    ) {
        self.payloadVersion = payloadVersion
        self.bullSubtract = bullSubtract
        self.gameOverAtZero = gameOverAtZero
    }
}

/// Round target — either a numbered double (1…20) or the bull on the final round.
public enum Bobs27Target: Equatable, Hashable, Sendable {
    case double(Int)
    case bull

    /// Display value used for both reward (per-hit value) and miss penalty in the
    /// non-bull rounds. For the bull, this is the inner-bull point value (50);
    /// the bull-miss penalty is configurable separately.
    public var hitValue: Int {
        switch self {
        case let .double(n): return n * 2
        case .bull: return 50
        }
    }

    public var missPenaltyForDouble: Int {
        switch self {
        case let .double(n): return n * 2
        case .bull: return 0
        }
    }
}

/// Immutable record of a single round in a Bob's 27 match.
public struct Bobs27RoundEvent: Codable, Equatable, Identifiable, Sendable {
    public let payloadVersion: Int
    public let id: UUID
    public let playerId: UUID
    public let roundIndex: Int
    /// `0…19` = double N+1; `20` = bull round.
    public let targetRoundNumber: Int
    /// Number of darts in the visit that hit the target.
    public let hitCount: Int
    /// Signed delta applied to the score this round.
    public let delta: Int
    public let scoreAfter: Int
    /// Match ended after this round (final round or score ≤ 0).
    public let matchCompleted: Bool
    /// Score dropped to / below zero this round.
    public let bustOut: Bool
    public let timestamp: Date

    public init(
        payloadVersion: Int = 1,
        id: UUID = UUID(),
        playerId: UUID,
        roundIndex: Int,
        targetRoundNumber: Int,
        hitCount: Int,
        delta: Int,
        scoreAfter: Int,
        matchCompleted: Bool,
        bustOut: Bool,
        timestamp: Date
    ) {
        self.payloadVersion = payloadVersion
        self.id = id
        self.playerId = playerId
        self.roundIndex = roundIndex
        self.targetRoundNumber = targetRoundNumber
        self.hitCount = hitCount
        self.delta = delta
        self.scoreAfter = scoreAfter
        self.matchCompleted = matchCompleted
        self.bustOut = bustOut
        self.timestamp = timestamp
    }
}

/// Mutable game state for a Bob's 27 match.
public struct Bobs27State: Codable, Equatable, Sendable {
    public let config: MatchConfigBobs27
    public let playerId: UUID
    public var roundIndex: Int
    public var score: Int
    public var isComplete: Bool
    public var bustOut: Bool

    /// Total number of rounds in a Bob's 27 match: D1…D20 + bull = 21.
    public static let totalRounds: Int = 21

    public var currentTarget: Bobs27Target {
        Bobs27Engine.target(forRoundIndex: roundIndex)
    }

    public init(
        config: MatchConfigBobs27,
        playerId: UUID,
        roundIndex: Int = 0,
        score: Int = 27,
        isComplete: Bool = false,
        bustOut: Bool = false
    ) {
        self.config = config
        self.playerId = playerId
        self.roundIndex = roundIndex
        self.score = score
        self.isComplete = isComplete
        self.bustOut = bustOut
    }
}

/// Result of a submitted Bob's 27 round.
public struct Bobs27TurnOutcome: Sendable {
    public let updatedState: Bobs27State
    public let event: Bobs27RoundEvent
}

/// Pure engine for Bob's 27. All state transitions are side-effect free.
public enum Bobs27Engine {

    // MARK: - Public API

    public static func makeInitialState(
        config: MatchConfigBobs27,
        playerIds: [UUID]
    ) throws -> Bobs27State {
        guard playerIds.count == 1 else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "setup.validation.bobs27SoloOnly"
            )
        }
        return Bobs27State(config: config, playerId: playerIds[0])
    }

    public static func submitTurn(
        state: Bobs27State,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> Bobs27TurnOutcome {
        guard !state.isComplete else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.bobs27.gameOver"
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
        let target = state.currentTarget
        let hits = darts.filter { dartHitsTarget($0, target: target) }.count

        let delta: Int = {
            switch target {
            case let .double(n):
                let value = n * 2
                return hits > 0 ? hits * value : -value
            case .bull:
                // Inner bull only counts as a hit for the bull round; each = 50.
                return hits > 0 ? hits * 50 : -state.config.bullSubtract
            }
        }()

        updated.score += delta
        let bustOut = state.config.gameOverAtZero && updated.score <= 0
        updated.bustOut = bustOut
        updated.roundIndex += 1

        let isFinalRound = updated.roundIndex >= Bobs27State.totalRounds
        let matchCompleted = bustOut || isFinalRound
        updated.isComplete = matchCompleted

        let targetRoundNumber: Int = {
            switch target {
            case let .double(n): return n
            case .bull: return 25
            }
        }()

        let event = Bobs27RoundEvent(
            playerId: state.playerId,
            roundIndex: state.roundIndex,
            targetRoundNumber: targetRoundNumber,
            hitCount: hits,
            delta: delta,
            scoreAfter: updated.score,
            matchCompleted: matchCompleted,
            bustOut: bustOut,
            timestamp: timestamp
        )
        return Bobs27TurnOutcome(updatedState: updated, event: event)
    }

    public static func replay(
        config: MatchConfigBobs27,
        playerIds: [UUID],
        events: [Bobs27RoundEvent]
    ) throws -> Bobs27State {
        var state = try makeInitialState(config: config, playerIds: playerIds)
        for event in events {
            state.score = event.scoreAfter
            state.roundIndex = event.roundIndex + 1
            state.bustOut = event.bustOut
            state.isComplete = event.matchCompleted
        }
        return state
    }

    // MARK: - Helpers

    /// Target for round index 0…20 (D1…D20 then bull).
    public static func target(forRoundIndex index: Int) -> Bobs27Target {
        if index >= 20 { return .bull }
        return .double(max(1, index + 1))
    }

    /// Whether the dart counts as a hit on the round's target.
    /// - Double rounds: requires the matching segment with a `.double` multiplier.
    /// - Bull round: requires `.innerBull` (50). Outer bull does not count for
    ///   Bob's 27 — the perfect score of 1437 depends on inner-bull-only.
    static func dartHitsTarget(_ dart: DartInput, target: Bobs27Target) -> Bool {
        guard !dart.isMiss else { return false }
        switch target {
        case let .double(n):
            guard dart.multiplier == .double else { return false }
            guard case let .oneToTwenty(value) = dart.segment else { return false }
            return value == n
        case .bull:
            if case .innerBull = dart.segment { return true }
            return false
        }
    }
}
