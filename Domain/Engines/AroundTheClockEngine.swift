import Foundation

/// Reset behaviour when a player fails to hit their current target in a visit.
public enum AroundTheClockResetPolicy: String, Codable, CaseIterable, Sendable {
    case noReset
    case resetOnThreeMisses
    case resetEntireSequence

    public var displayName: String {
        switch self {
        case .noReset: L10n.string("play.aroundTheClock.setup.resetPolicy.noReset")
        case .resetOnThreeMisses: L10n.string("play.aroundTheClock.setup.resetPolicy.resetOnThreeMisses")
        case .resetEntireSequence: L10n.string("play.aroundTheClock.setup.resetPolicy.resetEntireSequence")
        }
    }
}

/// Serialisable configuration for an Around the Clock match.
public struct MatchConfigAroundTheClock: Codable, Equatable, Sendable {
    public static let currentPayloadVersion = 1

    public let payloadVersion: Int
    public let includeBullFinish: Bool
    public let resetPolicyRaw: String

    public var resetPolicy: AroundTheClockResetPolicy {
        AroundTheClockResetPolicy(rawValue: resetPolicyRaw) ?? .noReset
    }

    public init(
        payloadVersion: Int = currentPayloadVersion,
        includeBullFinish: Bool = false,
        resetPolicy: AroundTheClockResetPolicy = .noReset
    ) {
        self.payloadVersion = payloadVersion
        self.includeBullFinish = includeBullFinish
        self.resetPolicyRaw = resetPolicy.rawValue
    }
}

/// Immutable record of a single visit in an Around the Clock match.
public struct AroundTheClockTurnEvent: Codable, Equatable, Identifiable, Sendable {
    public let payloadVersion: Int
    public let id: UUID
    public let playerId: UUID
    public let turnIndex: Int
    public let targetBefore: Int
    public let targetAfter: Int
    public let dartsThrown: Int
    public let resetApplied: Bool
    public let matchCompleted: Bool
    public let timestamp: Date

    public init(
        payloadVersion: Int = 1,
        id: UUID,
        playerId: UUID,
        turnIndex: Int,
        targetBefore: Int,
        targetAfter: Int,
        dartsThrown: Int,
        resetApplied: Bool,
        matchCompleted: Bool,
        timestamp: Date
    ) {
        self.payloadVersion = payloadVersion
        self.id = id
        self.playerId = playerId
        self.turnIndex = turnIndex
        self.targetBefore = targetBefore
        self.targetAfter = targetAfter
        self.dartsThrown = dartsThrown
        self.resetApplied = resetApplied
        self.matchCompleted = matchCompleted
        self.timestamp = timestamp
    }
}

/// Per-player mutable state for Around the Clock.
public struct AroundTheClockPlayerState: Codable, Equatable, Sendable {
    /// The player's UUID.
    public let playerId: UUID
    /// Current target index: 0 = segment 1, …, 19 = segment 20, 20 = bull (when enabled).
    public var targetIndex: Int
    /// Total darts thrown by this player (for solo time/accuracy tracking).
    public var dartsThrown: Int

    /// 1-based segment the player must next hit (1…20; 25 = bull).
    public var currentTarget: Int {
        targetIndex < 20 ? targetIndex + 1 : 25
    }

    public init(playerId: UUID, targetIndex: Int = 0, dartsThrown: Int = 0) {
        self.playerId = playerId
        self.targetIndex = targetIndex
        self.dartsThrown = dartsThrown
    }
}

/// Complete mutable game state for an Around the Clock match.
public struct AroundTheClockState: Codable, Equatable, Sendable {
    public let config: MatchConfigAroundTheClock
    public var players: [AroundTheClockPlayerState]
    public var currentPlayerIndex: Int
    public var turnIndex: Int
    public var winnerPlayerId: UUID?
    public var isComplete: Bool

    public init(
        config: MatchConfigAroundTheClock,
        players: [AroundTheClockPlayerState],
        currentPlayerIndex: Int = 0,
        turnIndex: Int = 0,
        winnerPlayerId: UUID? = nil,
        isComplete: Bool = false
    ) {
        self.config = config
        self.players = players
        self.currentPlayerIndex = currentPlayerIndex
        self.turnIndex = turnIndex
        self.winnerPlayerId = winnerPlayerId
        self.isComplete = isComplete
    }

    /// Number of targets in the sequence (20, or 21 when bull finish is enabled).
    public var sequenceLength: Int { config.includeBullFinish ? 21 : 20 }
}

/// Result of a submitted visit.
public struct AroundTheClockTurnOutcome: Sendable {
    public let updatedState: AroundTheClockState
    public let event: AroundTheClockTurnEvent
}

/// Pure engine for Around the Clock. All state transitions are side-effect free.
public enum AroundTheClockEngine {

    // MARK: - Public API

    public static func makeInitialState(
        config: MatchConfigAroundTheClock,
        playerIds: [UUID]
    ) throws -> AroundTheClockState {
        guard playerIds.count >= 1 else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.players.minimum"
            )
        }
        let players = playerIds.map { AroundTheClockPlayerState(playerId: $0) }
        return AroundTheClockState(config: config, players: players)
    }

    public static func submitTurn(
        state: AroundTheClockState,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> AroundTheClockTurnOutcome {
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
        let targetBefore = updated.players[playerIndex].targetIndex

        // Count hits on the current target — first hit advances the index.
        var advancedThisTurn = false
        var missCount = 0

        for dart in darts {
            let hits = dartHitsTarget(dart, player: updated.players[playerIndex], config: updated.config)
            if hits && !advancedThisTurn {
                updated.players[playerIndex].targetIndex += 1
                advancedThisTurn = true
            } else if !hits && !dart.isMiss {
                // Not a miss per se but wrong segment — count as visit miss for reset policy
                missCount += 1
            } else if dart.isMiss {
                missCount += 1
            }
        }
        updated.players[playerIndex].dartsThrown += darts.count

        // Apply reset policy when the player did not advance.
        var resetApplied = false
        if !advancedThisTurn {
            let allDartsMissed = missCount == darts.count
            switch updated.config.resetPolicy {
            case .noReset:
                break
            case .resetOnThreeMisses:
                // Three misses = all three darts missed the current target in this visit.
                if darts.count == 3 && allDartsMissed {
                    updated.players[playerIndex].targetIndex = 0
                    resetApplied = true
                }
            case .resetEntireSequence:
                if !darts.isEmpty {
                    updated.players[playerIndex].targetIndex = 0
                    resetApplied = true
                }
            }
        }

        let targetAfter = updated.players[playerIndex].targetIndex
        let sequenceLength = updated.config.includeBullFinish ? 21 : 20
        var matchCompleted = false

        if targetAfter >= sequenceLength {
            completeMatch(&updated, winnerId: playerId)
            matchCompleted = true
        } else {
            advanceTurn(&updated)
        }

        let event = AroundTheClockTurnEvent(
            id: UUID(),
            playerId: playerId,
            turnIndex: state.turnIndex,
            targetBefore: targetBefore,
            targetAfter: min(targetAfter, sequenceLength),
            dartsThrown: darts.count,
            resetApplied: resetApplied,
            matchCompleted: matchCompleted,
            timestamp: timestamp
        )
        return AroundTheClockTurnOutcome(updatedState: updated, event: event)
    }

    public static func replay(
        config: MatchConfigAroundTheClock,
        playerIds: [UUID],
        events: [AroundTheClockTurnEvent]
    ) throws -> AroundTheClockState {
        var state = try makeInitialState(config: config, playerIds: playerIds)
        for event in events {
            // Replay by restoring indices directly from the event (avoids re-deriving darts).
            let playerIndex = state.players.firstIndex { $0.playerId == event.playerId }
            guard let idx = playerIndex else { continue }
            state.players[idx].targetIndex = event.targetAfter
            state.players[idx].dartsThrown += event.dartsThrown
            state.turnIndex += 1
            if event.matchCompleted {
                completeMatch(&state, winnerId: event.playerId)
            } else {
                let playerCount = state.players.count
                state.currentPlayerIndex = (idx + 1) % playerCount
            }
        }
        return state
    }

    // MARK: - Helpers

    /// Returns `true` if the dart lands on the player's current target.
    static func dartHitsTarget(
        _ dart: DartInput,
        player: AroundTheClockPlayerState,
        config: MatchConfigAroundTheClock
    ) -> Bool {
        guard !dart.isMiss else { return false }
        let target = player.targetIndex
        if target < 20 {
            // Segments 1–20
            guard case let .oneToTwenty(value) = dart.segment else { return false }
            return value == target + 1
        } else if config.includeBullFinish {
            // Bull finish: outer bull or inner bull both count
            return dart.segment == .outerBull || dart.segment == .innerBull
        }
        return false
    }

    private static func advanceTurn(_ state: inout AroundTheClockState) {
        state.turnIndex += 1
        let playerCount = state.players.count
        state.currentPlayerIndex = (state.currentPlayerIndex + 1) % playerCount
    }

    private static func completeMatch(_ state: inout AroundTheClockState, winnerId: UUID) {
        state.winnerPlayerId = winnerId
        state.isComplete = true
        state.currentPlayerIndex = 0
        state.turnIndex += 1
    }
}
