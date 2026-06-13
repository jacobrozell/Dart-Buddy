import Foundation

/// The anticlockwise board order starting at 20, exactly as read from a standard dartboard.
public let grandNationalCourseOrder: [Int] = [
    20, 5, 12, 9, 14, 11, 8, 16, 7, 19, 3, 17, 2, 15, 10, 6, 13, 4, 18, 1
]

/// Rulesets available for Grand National.  Only `novice` ships in v1.
public enum GrandNationalRuleset: String, Codable, CaseIterable, Sendable {
    case novice
    case expert

    public var displayName: String {
        switch self {
        case .novice: L10n.string("play.grandNational.setup.ruleset.novice")
        case .expert: L10n.string("play.grandNational.setup.ruleset.expert")
        }
    }
}

/// Serialisable configuration for a Grand National match.
public struct MatchConfigGrandNational: Codable, Equatable, Sendable {
    public static let currentPayloadVersion = 1

    public let payloadVersion: Int
    public let rulesetRaw: String
    public let laps: Int

    public var ruleset: GrandNationalRuleset {
        GrandNationalRuleset(rawValue: rulesetRaw) ?? .novice
    }

    public init(
        payloadVersion: Int = currentPayloadVersion,
        ruleset: GrandNationalRuleset = .novice,
        laps: Int = 2
    ) {
        self.payloadVersion = payloadVersion
        self.rulesetRaw = ruleset.rawValue
        self.laps = max(1, min(10, laps))
    }
}

/// Immutable record of a single 3-dart visit in a Grand National match.
public struct GrandNationalTurnEvent: Codable, Equatable, Identifiable, Sendable {
    public let payloadVersion: Int
    public let id: UUID
    public let playerId: UUID
    public let turnIndex: Int
    /// Segment index (0…19 within the 20-segment course) before this visit.
    public let segmentIndexBefore: Int
    /// Segment index after this visit (advances by 1 on a hit).
    public let segmentIndexAfter: Int
    /// Number of completed laps before this visit.
    public let lapsCompletedBefore: Int
    /// Number of completed laps after this visit.
    public let lapsCompletedAfter: Int
    /// True when the player failed to hit the hurdle in this visit and was eliminated.
    public let eliminated: Bool
    /// True when this visit completed the required laps and won the match.
    public let matchCompleted: Bool
    public let timestamp: Date

    public init(
        payloadVersion: Int = 1,
        id: UUID = UUID(),
        playerId: UUID,
        turnIndex: Int,
        segmentIndexBefore: Int,
        segmentIndexAfter: Int,
        lapsCompletedBefore: Int,
        lapsCompletedAfter: Int,
        eliminated: Bool,
        matchCompleted: Bool,
        timestamp: Date
    ) {
        self.payloadVersion = payloadVersion
        self.id = id
        self.playerId = playerId
        self.turnIndex = turnIndex
        self.segmentIndexBefore = segmentIndexBefore
        self.segmentIndexAfter = segmentIndexAfter
        self.lapsCompletedBefore = lapsCompletedBefore
        self.lapsCompletedAfter = lapsCompletedAfter
        self.eliminated = eliminated
        self.matchCompleted = matchCompleted
        self.timestamp = timestamp
    }
}

/// Per-player mutable state for Grand National.
public struct GrandNationalPlayerState: Codable, Equatable, Sendable {
    public let playerId: UUID
    /// Index into `grandNationalCourseOrder` (0…19).
    public var segmentIndex: Int
    /// Number of full laps completed (started a second lap once this reaches the target).
    public var lapsCompleted: Int
    /// True once the player missed a hurdle visit (novice ruleset).
    public var isEliminated: Bool

    /// The board number the player must currently hit.
    public var currentHurdle: Int {
        grandNationalCourseOrder[segmentIndex % grandNationalCourseOrder.count]
    }

    public init(
        playerId: UUID,
        segmentIndex: Int = 0,
        lapsCompleted: Int = 0,
        isEliminated: Bool = false
    ) {
        self.playerId = playerId
        self.segmentIndex = segmentIndex
        self.lapsCompleted = lapsCompleted
        self.isEliminated = isEliminated
    }
}

/// Complete mutable game state for a Grand National match.
public struct GrandNationalState: Codable, Equatable, Sendable {
    public let config: MatchConfigGrandNational
    public var players: [GrandNationalPlayerState]
    public var currentPlayerIndex: Int
    public var turnIndex: Int
    public var winnerPlayerId: UUID?
    public var isComplete: Bool

    public init(
        config: MatchConfigGrandNational,
        players: [GrandNationalPlayerState],
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

    /// Count of players still in the race.
    public var activePlayers: [GrandNationalPlayerState] {
        players.filter { !$0.isEliminated }
    }
}

/// Result of a submitted Grand National visit.
public struct GrandNationalTurnOutcome: Sendable {
    public let updatedState: GrandNationalState
    public let event: GrandNationalTurnEvent
}

/// Pure engine for Grand National.  All state transitions are side-effect free.
public enum GrandNationalEngine {
    static let courseLength = grandNationalCourseOrder.count // 20

    // MARK: - Public API

    public static func makeInitialState(
        config: MatchConfigGrandNational,
        playerIds: [UUID]
    ) throws -> GrandNationalState {
        guard playerIds.count >= 2 else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.players.minimum"
            )
        }
        guard playerIds.count <= 8 else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "setup.validation.grandNationalMinimumPlayers"
            )
        }
        let players = playerIds.map { GrandNationalPlayerState(playerId: $0) }
        return GrandNationalState(config: config, players: players)
    }

    /// Submit a 3-dart visit for the current player.
    /// A hit on the current hurdle segment (any multiplier, any dart) advances the
    /// player one position.  Failing to hit in all three darts eliminates the player
    /// under the novice ruleset.
    public static func submitTurn(
        state: GrandNationalState,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> GrandNationalTurnOutcome {
        guard !state.isComplete else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.completed"
            )
        }
        guard darts.count >= 1, darts.count <= 3 else {
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
        let segmentIndexBefore = updated.players[playerIndex].segmentIndex
        let lapsCompletedBefore = updated.players[playerIndex].lapsCompleted
        let hurdle = updated.players[playerIndex].currentHurdle

        let hitHurdle = darts.contains { dartHitsHurdle($0, hurdle: hurdle) }

        var eliminated = false
        var matchCompleted = false

        if hitHurdle {
            // Advance one position; wrap to complete a lap.
            let newIndex = segmentIndexBefore + 1
            if newIndex >= courseLength {
                updated.players[playerIndex].segmentIndex = 0
                updated.players[playerIndex].lapsCompleted += 1
            } else {
                updated.players[playerIndex].segmentIndex = newIndex
            }

            // Check win: first player to reach the required laps wins.
            if updated.players[playerIndex].lapsCompleted >= updated.config.laps {
                completeMatch(&updated, winnerId: playerId)
                matchCompleted = true
            }
        } else {
            // Missed the hurdle — eliminated under novice ruleset.
            updated.players[playerIndex].isEliminated = true
            eliminated = true

            // Last survivor also wins.
            if let survivorId = lastSurvivorId(in: updated.players) {
                completeMatch(&updated, winnerId: survivorId)
                matchCompleted = true
            }
        }

        let segmentIndexAfter = updated.players[playerIndex].segmentIndex
        let lapsCompletedAfter = updated.players[playerIndex].lapsCompleted

        updated.turnIndex += 1

        if !matchCompleted {
            advanceTurn(&updated)
        }

        let event = GrandNationalTurnEvent(
            playerId: playerId,
            turnIndex: state.turnIndex,
            segmentIndexBefore: segmentIndexBefore,
            segmentIndexAfter: segmentIndexAfter,
            lapsCompletedBefore: lapsCompletedBefore,
            lapsCompletedAfter: lapsCompletedAfter,
            eliminated: eliminated,
            matchCompleted: matchCompleted,
            timestamp: timestamp
        )
        return GrandNationalTurnOutcome(updatedState: updated, event: event)
    }

    /// Replay a sequence of events from scratch to reconstruct state.
    public static func replay(
        config: MatchConfigGrandNational,
        playerIds: [UUID],
        events: [GrandNationalTurnEvent]
    ) throws -> GrandNationalState {
        var state = try makeInitialState(config: config, playerIds: playerIds)
        for event in events {
            guard let idx = state.players.firstIndex(where: { $0.playerId == event.playerId }) else {
                continue
            }
            state.players[idx].segmentIndex = event.segmentIndexAfter
            state.players[idx].lapsCompleted = event.lapsCompletedAfter
            if event.eliminated {
                state.players[idx].isEliminated = true
            }
            state.turnIndex += 1
            if event.matchCompleted {
                completeMatch(&state, winnerId: event.playerId)
            } else if event.eliminated {
                if let survivorId = lastSurvivorId(in: state.players) {
                    completeMatch(&state, winnerId: survivorId)
                } else {
                    advanceTurn(&state)
                }
            } else {
                advanceTurn(&state)
            }
        }
        return state
    }

    // MARK: - Private helpers

    /// Returns true if a dart lands on the given hurdle number (any multiplier counts).
    private static func dartHitsHurdle(_ dart: DartInput, hurdle: Int) -> Bool {
        guard !dart.isMiss else { return false }
        guard case let .oneToTwenty(value) = dart.segment else { return false }
        return value == hurdle
    }

    /// Advances `currentPlayerIndex` to the next non-eliminated player (skipping eliminated ones).
    private static func advanceTurn(_ state: inout GrandNationalState) {
        guard !state.isComplete else { return }
        let count = state.players.count
        var next = (state.currentPlayerIndex + 1) % count
        for _ in 0 ..< count {
            if !state.players[next].isEliminated {
                state.currentPlayerIndex = next
                return
            }
            next = (next + 1) % count
        }
        // All players eliminated — should have been caught by lastSurvivorId, but guard anyway.
    }

    private static func completeMatch(_ state: inout GrandNationalState, winnerId: UUID) {
        state.winnerPlayerId = winnerId
        state.isComplete = true
    }

    /// Returns the sole remaining active player's id when exactly one is left; nil otherwise.
    private static func lastSurvivorId(in players: [GrandNationalPlayerState]) -> UUID? {
        let active = players.filter { !$0.isEliminated }
        guard active.count == 1 else { return nil }
        return active[0].playerId
    }
}
