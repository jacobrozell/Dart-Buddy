import Foundation

/// Finish variant when `mustFinishExact` is enabled.
public enum FiftyOneByFivesMustFinishPolicy: String, Codable, CaseIterable, Sendable {
    /// Over-shooting the target wastes the visit; prior points are kept.
    case exactRequired

    public var displayName: String {
        L10n.string("play.fiftyOneByFives.setup.mustFinishExact")
    }
}

// MARK: - Config

public struct MatchConfigFiftyOneByFives: Codable, Equatable, Sendable {
    public static let currentPayloadVersion = 1

    public let payloadVersion: Int
    public let targetPoints: Int
    /// Raw-string storage for `mustFinishExact` so future enum cases survive
    /// forward-deserialization without crashing.
    public let mustFinishExactRaw: String

    public var mustFinishExact: Bool {
        mustFinishExactRaw == "true"
    }

    public init(
        payloadVersion: Int = currentPayloadVersion,
        targetPoints: Int = 51,
        mustFinishExact: Bool = false
    ) {
        self.payloadVersion = payloadVersion
        self.targetPoints = max(1, targetPoints)
        self.mustFinishExactRaw = mustFinishExact ? "true" : "false"
    }
}

// MARK: - Events

/// One recorded turn in a 51 By 5's match.
public struct FiftyOneByFivesTurnEvent: Codable, Equatable, Identifiable, Sendable {
    public let payloadVersion: Int
    public let id: UUID
    public let playerId: UUID
    public let turnIndex: Int
    /// Raw 3-dart visit total before divisibility check.
    public let rawTotal: Int
    /// Points awarded this visit (rawTotal ÷ 5 when divisible, else 0).
    public let pointsAwarded: Int
    /// Player's cumulative points after this visit.
    public let cumulativeAfter: Int
    public let timestamp: Date

    public init(
        payloadVersion: Int = 1,
        id: UUID = UUID(),
        playerId: UUID,
        turnIndex: Int,
        rawTotal: Int,
        pointsAwarded: Int,
        cumulativeAfter: Int,
        timestamp: Date
    ) {
        self.payloadVersion = payloadVersion
        self.id = id
        self.playerId = playerId
        self.turnIndex = turnIndex
        self.rawTotal = rawTotal
        self.pointsAwarded = pointsAwarded
        self.cumulativeAfter = cumulativeAfter
        self.timestamp = timestamp
    }
}

// MARK: - State

public struct FiftyOneByFivesPlayerState: Codable, Equatable, Sendable {
    public let playerId: UUID
    public var cumulativePoints: Int

    public init(playerId: UUID, cumulativePoints: Int = 0) {
        self.playerId = playerId
        self.cumulativePoints = cumulativePoints
    }
}

public struct FiftyOneByFivesState: Codable, Equatable, Sendable {
    public let config: MatchConfigFiftyOneByFives
    public var players: [FiftyOneByFivesPlayerState]
    public var currentPlayerIndex: Int
    public var turnIndex: Int
    public var winnerPlayerId: UUID?
    public var isComplete: Bool

    public init(
        config: MatchConfigFiftyOneByFives,
        players: [FiftyOneByFivesPlayerState],
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

// MARK: - Outcome

public struct FiftyOneByFivesTurnOutcome: Sendable {
    public let updatedState: FiftyOneByFivesState
    public let event: FiftyOneByFivesTurnEvent
}

// MARK: - Engine

/// Pure rules engine for the 51 By 5's (All Fives) game mode.
///
/// Turn rule: throw 3 darts, compute the raw visit total. If the total is
/// divisible by 5, award `total ÷ 5` points; otherwise award 0. First player
/// to reach ≥ `targetPoints` (default 51) wins. With `mustFinishExact`, a
/// visit that would push the player over the target scores 0 for that visit
/// (no bust rollback — prior cumulative points are preserved).
public enum FiftyOneByFivesEngine {
    // MARK: - Public API

    public static func makeInitialState(
        config: MatchConfigFiftyOneByFives,
        playerIds: [UUID]
    ) throws -> FiftyOneByFivesState {
        guard config.targetPoints > 0 else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.fiftyOneByFives.invalidTargetPoints"
            )
        }
        guard playerIds.count >= 2 else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.players.minimum"
            )
        }
        let players = playerIds.map { FiftyOneByFivesPlayerState(playerId: $0) }
        return FiftyOneByFivesState(config: config, players: players)
    }

    public static func submitTurn(
        state: FiftyOneByFivesState,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> FiftyOneByFivesTurnOutcome {
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

        // Step 1: compute raw visit total.
        let rawTotal = darts.reduce(0) { $0 + dartPoints($1) }

        // Step 2: apply divisibility gate.
        let divisor = 5
        let isDivisible = rawTotal % divisor == 0

        // Step 3: compute points awarded this visit.
        //   - All-miss (rawTotal == 0) is divisible by 5 but awards 0 (0 ÷ 5 == 0).
        //   - Non-divisible visit awards 0.
        //   - mustFinishExact: if awarded would push cumulative over target, award 0.
        var pointsAwarded = isDivisible ? rawTotal / divisor : 0

        if pointsAwarded > 0, updated.config.mustFinishExact {
            let projectedTotal = updated.players[playerIndex].cumulativePoints + pointsAwarded
            if projectedTotal > updated.config.targetPoints {
                pointsAwarded = 0
            }
        }

        updated.players[playerIndex].cumulativePoints += pointsAwarded
        let cumulativeAfter = updated.players[playerIndex].cumulativePoints

        // Step 4: check win condition.
        let hasWon = updated.config.mustFinishExact
            ? cumulativeAfter == updated.config.targetPoints
            : cumulativeAfter >= updated.config.targetPoints

        if hasWon {
            completeMatch(&updated, winnerId: playerId)
        } else {
            advanceTurn(&updated)
        }

        let event = FiftyOneByFivesTurnEvent(
            playerId: playerId,
            turnIndex: state.turnIndex,
            rawTotal: rawTotal,
            pointsAwarded: pointsAwarded,
            cumulativeAfter: cumulativeAfter,
            timestamp: timestamp
        )
        return FiftyOneByFivesTurnOutcome(updatedState: updated, event: event)
    }

    public static func replay(
        config: MatchConfigFiftyOneByFives,
        playerIds: [UUID],
        events: [FiftyOneByFivesTurnEvent]
    ) throws -> FiftyOneByFivesState {
        var state = try makeInitialState(config: config, playerIds: playerIds)
        for event in events {
            // Reconstruct a minimal dart array whose total matches the recorded rawTotal.
            // The engine only uses the total; replay just needs a valid submission.
            let darts = replayDarts(for: event.rawTotal)
            state = try submitTurn(state: state, darts: darts, timestamp: event.timestamp).updatedState
        }
        return state
    }

    // MARK: - Private helpers

    private static func dartPoints(_ dart: DartInput) -> Int {
        guard !dart.isMiss else { return 0 }
        switch dart.segment {
        case let .oneToTwenty(value):
            switch dart.multiplier {
            case .single: return value
            case .double: return value * 2
            case .triple: return value * 3
            }
        case .outerBull:
            return 25
        case .innerBull:
            return 50
        case .miss:
            return 0
        }
    }

    private static func advanceTurn(_ state: inout FiftyOneByFivesState) {
        state.turnIndex += 1
        let playerCount = state.players.count
        state.currentPlayerIndex = (state.currentPlayerIndex + 1) % playerCount
    }

    private static func completeMatch(_ state: inout FiftyOneByFivesState, winnerId: UUID) {
        state.winnerPlayerId = winnerId
        state.isComplete = true
        state.currentPlayerIndex = 0
    }

    /// Reconstructs a single dart whose face value equals `total` for replay.
    /// Uses triple-20 combinations to build exact totals without emitting
    /// invalid dart counts; falls back to a zero-total miss set for total == 0.
    static func replayDarts(for total: Int) -> [DartInput] {
        if total == 0 {
            return [
                DartInput(multiplier: .single, segment: .miss, isMiss: true),
                DartInput(multiplier: .single, segment: .miss, isMiss: true),
                DartInput(multiplier: .single, segment: .miss, isMiss: true),
            ]
        }
        // Represent the total as a single dart on a bull combo if possible,
        // otherwise as three single darts each scoring total/3 (clamped to 1..20).
        // For replay correctness the only requirement is rawTotal == total.
        if total <= 20 {
            return [DartInput(multiplier: .single, segment: .oneToTwenty(total))]
        }
        if total <= 40, total % 2 == 0 {
            return [DartInput(multiplier: .double, segment: .oneToTwenty(total / 2))]
        }
        if total <= 60, total % 3 == 0 {
            return [DartInput(multiplier: .triple, segment: .oneToTwenty(total / 3))]
        }
        // Decompose into up to three darts summing to total.
        let perDart = min(20, total / 3)
        let remainder = total - perDart * 2
        if remainder >= 1, remainder <= 20 {
            return [
                DartInput(multiplier: .single, segment: .oneToTwenty(perDart)),
                DartInput(multiplier: .single, segment: .oneToTwenty(perDart)),
                DartInput(multiplier: .single, segment: .oneToTwenty(remainder)),
            ]
        }
        // Fallback: three triple-20s worth 180. Only reached by impossible totals.
        return [
            DartInput(multiplier: .triple, segment: .oneToTwenty(20)),
            DartInput(multiplier: .triple, segment: .oneToTwenty(20)),
            DartInput(multiplier: .triple, segment: .oneToTwenty(20)),
        ]
    }
}
