import Foundation

/// Serialisable configuration for a Bob's 27 match.
///
/// Bob's 27 is a doubles-practice drill starting at 27 points. Groups take turns on
/// the same round target; per the spec the only knobs are the bull-miss penalty
/// (defaults to 27) and whether a non-positive running score eliminates a player.
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

/// Per-player Bob's 27 progress.
public struct Bobs27PlayerState: Codable, Equatable, Sendable {
    public let playerId: UUID
    public var score: Int
    public var bustOut: Bool

    public init(playerId: UUID, score: Int = 27, bustOut: Bool = false) {
        self.playerId = playerId
        self.score = score
        self.bustOut = bustOut
    }

    public var isActive: Bool { !bustOut }
}

/// Mutable game state for a Bob's 27 match.
public struct Bobs27State: Codable, Equatable, Sendable {
    public let config: MatchConfigBobs27
    public var players: [Bobs27PlayerState]
    public var currentPlayerIndex: Int
    public var roundIndex: Int
    public var winnerPlayerId: UUID?
    public var isComplete: Bool

    /// Total number of rounds in a Bob's 27 match: D1…D20 + bull = 21.
    public static let totalRounds: Int = 21

    public var currentTarget: Bobs27Target {
        Bobs27Engine.target(forRoundIndex: roundIndex)
    }

    public var currentPlayerId: UUID {
        players[currentPlayerIndex].playerId
    }

    public init(
        config: MatchConfigBobs27,
        players: [Bobs27PlayerState],
        currentPlayerIndex: Int = 0,
        roundIndex: Int = 0,
        winnerPlayerId: UUID? = nil,
        isComplete: Bool = false
    ) {
        self.config = config
        self.players = players
        self.currentPlayerIndex = currentPlayerIndex
        self.roundIndex = roundIndex
        self.winnerPlayerId = winnerPlayerId
        self.isComplete = isComplete
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
        guard !playerIds.isEmpty else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.players.minimum"
            )
        }
        let players = playerIds.map { Bobs27PlayerState(playerId: $0) }
        return Bobs27State(config: config, players: players)
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
        let playerIndex = updated.currentPlayerIndex
        let playerId = updated.players[playerIndex].playerId
        let target = updated.currentTarget
        let hits = darts.filter { dartHitsTarget($0, target: target) }.count

        let delta: Int = {
            switch target {
            case let .double(n):
                let value = n * 2
                return hits > 0 ? hits * value : -value
            case .bull:
                return hits > 0 ? hits * 50 : -updated.config.bullSubtract
            }
        }()

        updated.players[playerIndex].score += delta
        let bustOut = updated.config.gameOverAtZero && updated.players[playerIndex].score <= 0
        updated.players[playerIndex].bustOut = bustOut

        var matchCompleted = false
        if let nextIndex = nextActivePlayerIndex(after: playerIndex, in: updated.players) {
            updated.currentPlayerIndex = nextIndex
            if nextIndex == 0 {
                updated.roundIndex += 1
            }
        } else {
            matchCompleted = true
        }
        if updated.roundIndex >= Bobs27State.totalRounds {
            matchCompleted = true
        }

        if matchCompleted {
            finalize(&updated)
        } else {
            updated.isComplete = false
            updated.winnerPlayerId = nil
        }

        let targetRoundNumber: Int = {
            switch target {
            case let .double(n): return n
            case .bull: return 25
            }
        }()

        let event = Bobs27RoundEvent(
            playerId: playerId,
            roundIndex: state.roundIndex,
            targetRoundNumber: targetRoundNumber,
            hitCount: hits,
            delta: delta,
            scoreAfter: updated.players[playerIndex].score,
            matchCompleted: updated.isComplete,
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
            guard let idx = state.players.firstIndex(where: { $0.playerId == event.playerId }) else {
                continue
            }
            state.players[idx].score = event.scoreAfter
            state.players[idx].bustOut = event.bustOut
            if let nextIndex = nextActivePlayerIndex(after: idx, in: state.players) {
                state.currentPlayerIndex = nextIndex
                if nextIndex == 0 {
                    state.roundIndex += 1
                }
            }
            if event.matchCompleted {
                finalize(&state)
            }
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

    private static func activePlayers(in players: [Bobs27PlayerState]) -> [Bobs27PlayerState] {
        players.filter(\.isActive)
    }

    private static func nextActivePlayerIndex(
        after index: Int,
        in players: [Bobs27PlayerState]
    ) -> Int? {
        guard !players.isEmpty else { return nil }
        var cursor = index
        for _ in 0 ..< players.count {
            cursor = (cursor + 1) % players.count
            if players[cursor].isActive {
                return cursor
            }
        }
        return nil
    }

    private static func finalize(_ state: inout Bobs27State) {
        state.isComplete = true
        let active = activePlayers(in: state.players)
        let maxScore = active.map(\.score).max() ?? state.players.map(\.score).max() ?? 0
        let leaders = active.filter { $0.score == maxScore }
        state.winnerPlayerId = leaders.count == 1 ? leaders[0].playerId : nil
    }
}
