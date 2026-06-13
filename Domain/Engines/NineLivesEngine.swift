import Foundation

/// Starting lives option for a Nine Lives match.
public enum NineLivesStartingLives: String, Codable, CaseIterable, Sendable {
    case nine
    case three

    public var count: Int {
        switch self {
        case .nine: return 9
        case .three: return 3
        }
    }

    public var displayName: String {
        switch self {
        case .nine: L10n.string("play.nineLives.setup.startingLives.nine")
        case .three: L10n.string("play.nineLives.setup.startingLives.three")
        }
    }
}

/// Serialisable configuration for a Nine Lives match.
public struct MatchConfigNineLives: Codable, Equatable, Sendable {
    public static let currentPayloadVersion = 1

    public let payloadVersion: Int
    public let startingLivesRaw: String

    public var startingLives: NineLivesStartingLives {
        NineLivesStartingLives(rawValue: startingLivesRaw) ?? .nine
    }

    public init(
        payloadVersion: Int = currentPayloadVersion,
        startingLives: NineLivesStartingLives = .nine
    ) {
        self.payloadVersion = payloadVersion
        self.startingLivesRaw = startingLives.rawValue
    }
}

/// Immutable record of a single visit in a Nine Lives match.
public struct NineLivesTurnEvent: Codable, Equatable, Identifiable, Sendable {
    public let payloadVersion: Int
    public let id: UUID
    public let playerId: UUID
    public let turnIndex: Int
    /// Target index (0-based) before this visit.
    public let targetIndexBefore: Int
    /// Target index (0-based) after this visit.
    public let targetIndexAfter: Int
    /// Whether the player advanced at least once this visit.
    public let advanced: Bool
    /// Whether a life was lost this visit (did not advance).
    public let lifeLost: Bool
    /// Lives remaining after this visit.
    public let livesAfter: Int
    /// Whether the player was eliminated by this turn (lives hit 0).
    public let eliminated: Bool
    /// Whether the match completed after this turn.
    public let matchCompleted: Bool
    public let timestamp: Date

    public init(
        payloadVersion: Int = 1,
        id: UUID = UUID(),
        playerId: UUID,
        turnIndex: Int,
        targetIndexBefore: Int,
        targetIndexAfter: Int,
        advanced: Bool,
        lifeLost: Bool,
        livesAfter: Int,
        eliminated: Bool,
        matchCompleted: Bool,
        timestamp: Date
    ) {
        self.payloadVersion = payloadVersion
        self.id = id
        self.playerId = playerId
        self.turnIndex = turnIndex
        self.targetIndexBefore = targetIndexBefore
        self.targetIndexAfter = targetIndexAfter
        self.advanced = advanced
        self.lifeLost = lifeLost
        self.livesAfter = livesAfter
        self.eliminated = eliminated
        self.matchCompleted = matchCompleted
        self.timestamp = timestamp
    }
}

/// Per-player mutable state for Nine Lives.
public struct NineLivesPlayerState: Codable, Equatable, Sendable {
    public let playerId: UUID
    /// Zero-based index into 1…20 sequence. Value 20 means the player has completed the sequence.
    public var targetIndex: Int
    /// Lives remaining. Reaches 0 on elimination.
    public var lives: Int
    /// Whether this player has been eliminated (lives == 0).
    public var isEliminated: Bool

    /// 1-based segment the player must next hit (1…20).
    public var currentTarget: Int { targetIndex + 1 }

    /// Whether this player has completed the full 1–20 sequence.
    public var hasCompleted: Bool { targetIndex >= 20 }

    public init(playerId: UUID, targetIndex: Int = 0, lives: Int, isEliminated: Bool = false) {
        self.playerId = playerId
        self.targetIndex = targetIndex
        self.lives = lives
        self.isEliminated = isEliminated
    }
}

/// Complete mutable game state for a Nine Lives match.
public struct NineLivesState: Codable, Equatable, Sendable {
    public let config: MatchConfigNineLives
    public var players: [NineLivesPlayerState]
    public var currentPlayerIndex: Int
    public var turnIndex: Int
    public var winnerPlayerId: UUID?
    public var isComplete: Bool

    public init(
        config: MatchConfigNineLives,
        players: [NineLivesPlayerState],
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
}

/// Result of a submitted Nine Lives visit.
public struct NineLivesTurnOutcome: Sendable {
    public let updatedState: NineLivesState
    public let event: NineLivesTurnEvent
}

/// Pure engine for Nine Lives. All state transitions are side-effect free.
public enum NineLivesEngine {

    // MARK: - Public API

    public static func makeInitialState(
        config: MatchConfigNineLives,
        playerIds: [UUID]
    ) throws -> NineLivesState {
        guard playerIds.count >= 2 else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "setup.validation.nineLivesMinimumPlayers"
            )
        }
        let startingLives = config.startingLives.count
        let players = playerIds.map {
            NineLivesPlayerState(playerId: $0, lives: startingLives)
        }
        return NineLivesState(config: config, players: players)
    }

    public static func submitTurn(
        state: NineLivesState,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> NineLivesTurnOutcome {
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
        let targetIndexBefore = updated.players[playerIndex].targetIndex

        // Each hit on the current target advances the player for the rest of the visit.
        var advanced = false
        for dart in darts {
            guard updated.players[playerIndex].targetIndex < 20 else { break }
            if dartHitsTarget(dart, targetIndex: updated.players[playerIndex].targetIndex) {
                updated.players[playerIndex].targetIndex += 1
                advanced = true
            }
        }

        // No advance → lose 1 life.
        var lifeLost = false
        var eliminated = false
        if !advanced {
            updated.players[playerIndex].lives = max(0, updated.players[playerIndex].lives - 1)
            lifeLost = true
            if updated.players[playerIndex].lives == 0 {
                updated.players[playerIndex].isEliminated = true
                eliminated = true
            }
        }

        let targetIndexAfter = updated.players[playerIndex].targetIndex
        let livesAfter = updated.players[playerIndex].lives

        updated.turnIndex += 1

        // Win condition 1: player just completed 20.
        var matchCompleted = false
        if updated.players[playerIndex].hasCompleted {
            // First finisher wins.
            completeMatch(&updated, winnerId: playerId)
            matchCompleted = true
        } else {
            // Win condition 2: check if only one (or zero) players remain.
            checkLastStanding(&updated)
            if updated.isComplete {
                matchCompleted = true
            } else {
                advanceTurn(&updated)
            }
        }

        let event = NineLivesTurnEvent(
            playerId: playerId,
            turnIndex: state.turnIndex,
            targetIndexBefore: targetIndexBefore,
            targetIndexAfter: targetIndexAfter,
            advanced: advanced,
            lifeLost: lifeLost,
            livesAfter: livesAfter,
            eliminated: eliminated,
            matchCompleted: matchCompleted,
            timestamp: timestamp
        )
        return NineLivesTurnOutcome(updatedState: updated, event: event)
    }

    public static func replay(
        config: MatchConfigNineLives,
        playerIds: [UUID],
        events: [NineLivesTurnEvent]
    ) throws -> NineLivesState {
        var state = try makeInitialState(config: config, playerIds: playerIds)
        for event in events {
            guard let idx = state.players.firstIndex(where: { $0.playerId == event.playerId }) else {
                continue
            }
            state.players[idx].targetIndex = event.targetIndexAfter
            state.players[idx].lives = event.livesAfter
            state.players[idx].isEliminated = event.eliminated || (event.livesAfter == 0)
            state.turnIndex += 1
            if event.matchCompleted {
                completeMatch(&state, winnerId: event.playerId)
            } else {
                let nextIndex = nextActivePlayerIndex(after: idx, in: state)
                state.currentPlayerIndex = nextIndex ?? idx
            }
        }
        return state
    }

    // MARK: - Helpers

    /// Returns `true` if the dart lands on the player's current target (segments 1–20, any multiplier).
    static func dartHitsTarget(_ dart: DartInput, targetIndex: Int) -> Bool {
        guard !dart.isMiss else { return false }
        guard targetIndex < 20 else { return false }
        guard case let .oneToTwenty(value) = dart.segment else { return false }
        return value == targetIndex + 1
    }

    private static func advanceTurn(_ state: inout NineLivesState) {
        guard !state.isComplete else { return }
        guard let nextIdx = nextActivePlayerIndex(after: state.currentPlayerIndex, in: state) else {
            // Everyone is eliminated — should not normally reach here after checkLastStanding.
            state.isComplete = true
            return
        }
        state.currentPlayerIndex = nextIdx
    }

    private static func nextActivePlayerIndex(after index: Int, in state: NineLivesState) -> Int? {
        let count = state.players.count
        guard count > 0 else { return nil }
        var cursor = (index + 1) % count
        for _ in 0 ..< count {
            if !state.players[cursor].isEliminated {
                return cursor
            }
            cursor = (cursor + 1) % count
        }
        return nil
    }

    private static func checkLastStanding(_ state: inout NineLivesState) {
        let survivors = state.players.filter { !$0.isEliminated }
        guard survivors.count == 1 else { return }
        completeMatch(&state, winnerId: survivors[0].playerId)
    }

    private static func completeMatch(_ state: inout NineLivesState, winnerId: UUID) {
        state.winnerPlayerId = winnerId
        state.isComplete = true
        if let idx = state.players.firstIndex(where: { $0.playerId == winnerId }) {
            state.currentPlayerIndex = idx
        }
    }
}
