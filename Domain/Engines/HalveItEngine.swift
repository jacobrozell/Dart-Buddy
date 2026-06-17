import Foundation

/// Curated 6-round target sequence for Halve-It v1.
/// Each round target is the segment value 1…20; any multiplier counts and the
/// scoring darts on that segment are summed.
public enum HalveItTargetSequence: String, Codable, CaseIterable, Sendable {
    case standardTwentyToFifteen

    public var segments: [Int] {
        switch self {
        case .standardTwentyToFifteen: return [20, 19, 18, 17, 16, 15]
        }
    }
}

/// Serialisable configuration for a Halve-It match.
public struct MatchConfigHalveIt: Codable, Equatable, Sendable {
    public static let currentPayloadVersion = 1

    public let payloadVersion: Int
    public let startingScore: Int
    public let sequenceRaw: String

    public var sequence: HalveItTargetSequence {
        HalveItTargetSequence(rawValue: sequenceRaw) ?? .standardTwentyToFifteen
    }

    public var targets: [Int] { sequence.segments }

    public init(
        payloadVersion: Int = currentPayloadVersion,
        startingScore: Int = 301,
        sequence: HalveItTargetSequence = .standardTwentyToFifteen
    ) {
        self.payloadVersion = payloadVersion
        self.startingScore = startingScore
        self.sequenceRaw = sequence.rawValue
    }
}

/// Immutable record of one round (one player) in a Halve-It match.
public struct HalveItRoundEvent: Codable, Equatable, Identifiable, Sendable {
    public let payloadVersion: Int
    public let id: UUID
    public let playerId: UUID
    public let roundIndex: Int
    /// Segment 1…20 targeted in this round.
    public let target: Int
    /// Sum of scoring darts on the target segment this visit.
    public let visitScore: Int
    /// True when the visit failed to land any scoring dart on the target.
    public let halved: Bool
    public let totalBefore: Int
    public let totalAfter: Int
    public let matchCompleted: Bool
    public let timestamp: Date

    public init(
        payloadVersion: Int = 1,
        id: UUID = UUID(),
        playerId: UUID,
        roundIndex: Int,
        target: Int,
        visitScore: Int,
        halved: Bool,
        totalBefore: Int,
        totalAfter: Int,
        matchCompleted: Bool,
        timestamp: Date
    ) {
        self.payloadVersion = payloadVersion
        self.id = id
        self.playerId = playerId
        self.roundIndex = roundIndex
        self.target = target
        self.visitScore = visitScore
        self.halved = halved
        self.totalBefore = totalBefore
        self.totalAfter = totalAfter
        self.matchCompleted = matchCompleted
        self.timestamp = timestamp
    }
}

/// Per-player mutable state for Halve-It.
public struct HalveItPlayerState: Codable, Equatable, Sendable {
    public let playerId: UUID
    public var total: Int

    public init(playerId: UUID, total: Int) {
        self.playerId = playerId
        self.total = total
    }
}

/// Complete mutable game state for a Halve-It match.
public struct HalveItState: Codable, Equatable, Sendable {
    public let config: MatchConfigHalveIt
    public var players: [HalveItPlayerState]
    public var currentPlayerIndex: Int
    public var roundIndex: Int
    public var winnerPlayerId: UUID?
    public var isComplete: Bool

    /// Segment value of the current round, or `nil` if the match is over.
    public var currentTarget: Int? {
        guard roundIndex < config.targets.count else { return nil }
        return config.targets[roundIndex]
    }

    public init(
        config: MatchConfigHalveIt,
        players: [HalveItPlayerState],
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

/// Result of a submitted Halve-It visit.
public struct HalveItTurnOutcome: Sendable {
    public let updatedState: HalveItState
    public let event: HalveItRoundEvent
}

/// Pure engine for Halve-It. All state transitions are side-effect free.
public enum HalveItEngine {

    // MARK: - Public API

    public static func makeInitialState(
        config: MatchConfigHalveIt,
        playerIds: [UUID]
    ) throws -> HalveItState {
        guard !playerIds.isEmpty else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "setup.validation.halveItMinimumPlayers"
            )
        }
        guard config.startingScore >= 0 else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "setup.validation.halveItStartingScore"
            )
        }
        let players = playerIds.map {
            HalveItPlayerState(playerId: $0, total: config.startingScore)
        }
        return HalveItState(config: config, players: players)
    }

    public static func submitTurn(
        state: HalveItState,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> HalveItTurnOutcome {
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
        guard let target = state.currentTarget else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.completed"
            )
        }

        var updated = state
        let playerIndex = updated.currentPlayerIndex
        let playerId = updated.players[playerIndex].playerId
        let totalBefore = updated.players[playerIndex].total

        let visitScore = darts.reduce(0) { running, dart in
            running + scoreContribution(dart, target: target)
        }

        let halved: Bool
        let totalAfter: Int
        if visitScore > 0 {
            halved = false
            totalAfter = totalBefore + visitScore
        } else {
            halved = true
            totalAfter = totalBefore / 2
        }
        updated.players[playerIndex].total = totalAfter

        // Advance to the next player; only roll the round forward once every
        // player has thrown for the current target.
        var matchCompleted = false
        let nextPlayerIndex = (playerIndex + 1) % updated.players.count
        updated.currentPlayerIndex = nextPlayerIndex
        if nextPlayerIndex == 0 {
            updated.roundIndex += 1
            if updated.roundIndex >= updated.config.targets.count {
                finalize(&updated)
                matchCompleted = true
            }
        }

        let event = HalveItRoundEvent(
            playerId: playerId,
            roundIndex: state.roundIndex,
            target: target,
            visitScore: visitScore,
            halved: halved,
            totalBefore: totalBefore,
            totalAfter: totalAfter,
            matchCompleted: matchCompleted,
            timestamp: timestamp
        )
        return HalveItTurnOutcome(updatedState: updated, event: event)
    }

    public static func replay(
        config: MatchConfigHalveIt,
        playerIds: [UUID],
        events: [HalveItRoundEvent]
    ) throws -> HalveItState {
        var state = try makeInitialState(config: config, playerIds: playerIds)
        for event in events {
            guard let idx = state.players.firstIndex(where: { $0.playerId == event.playerId }) else {
                continue
            }
            state.players[idx].total = event.totalAfter
            let nextIndex = (idx + 1) % state.players.count
            state.currentPlayerIndex = nextIndex
            if nextIndex == 0 {
                state.roundIndex += 1
            }
            if event.matchCompleted {
                finalize(&state)
            }
        }
        return state
    }

    // MARK: - Helpers

    /// Points the dart contributes for the given target segment (1…20). Any
    /// multiplier counts: a triple-20 on the 20s round adds 60.
    static func scoreContribution(_ dart: DartInput, target: Int) -> Int {
        guard !dart.isMiss else { return 0 }
        guard case let .oneToTwenty(value) = dart.segment, value == target else { return 0 }
        return dart.points
    }

    private static func finalize(_ state: inout HalveItState) {
        state.isComplete = true
        // Highest total wins; ties leave winnerPlayerId nil (caller may rank).
        let sorted = state.players.sorted { $0.total > $1.total }
        if sorted.count == 1 {
            state.winnerPlayerId = sorted[0].playerId
        } else if sorted.count >= 2, sorted[0].total > sorted[1].total {
            state.winnerPlayerId = sorted[0].playerId
        }
    }
}
