import Foundation

/// Config for a Knockout match (payload v1).
public struct MatchConfigKnockout: Codable, Equatable, Sendable {
    public static let currentPayloadVersion = 1

    public let payloadVersion: Int
    /// Number of strikes required to eliminate a player (default 3).
    public let strikesToEliminate: Int
    /// Whether the current-high resets to 0 at the start of each new round.
    public let resetHighEachRound: Bool

    public init(
        payloadVersion: Int = currentPayloadVersion,
        strikesToEliminate: Int = 3,
        resetHighEachRound: Bool = true
    ) {
        self.payloadVersion = payloadVersion
        self.strikesToEliminate = strikesToEliminate
        self.resetHighEachRound = resetHighEachRound
    }
}

/// Per-dart detail captured during a Knockout visit (3-dart per-visit entry).
public struct KnockoutDartEvent: Codable, Equatable, Sendable {
    public let dartOrder: Int
    public let segmentRaw: String
    public let multiplierRaw: String
    public let pointsAwarded: Int
    public let wasMiss: Bool

    public init(
        dartOrder: Int,
        segmentRaw: String,
        multiplierRaw: String,
        pointsAwarded: Int,
        wasMiss: Bool
    ) {
        self.dartOrder = dartOrder
        self.segmentRaw = segmentRaw
        self.multiplierRaw = multiplierRaw
        self.pointsAwarded = pointsAwarded
        self.wasMiss = wasMiss
    }
}

/// Immutable record of one completed Knockout visit (one player's 3-dart turn).
public struct KnockoutTurnEvent: Codable, Equatable, Identifiable, Sendable {
    public let payloadVersion: Int
    public let id: UUID
    public let playerId: UUID
    public let turnIndex: Int
    public let round: Int
    public let visitTotal: Int
    public let beatHigh: Bool
    public let strikeAwarded: Bool
    public let highAfter: Int
    public let strikesAfter: Int
    public let wasEliminated: Bool
    public let darts: [KnockoutDartEvent]
    public let timestamp: Date

    public init(
        payloadVersion: Int = 1,
        id: UUID = UUID(),
        playerId: UUID,
        turnIndex: Int,
        round: Int,
        visitTotal: Int,
        beatHigh: Bool,
        strikeAwarded: Bool,
        highAfter: Int,
        strikesAfter: Int,
        wasEliminated: Bool,
        darts: [KnockoutDartEvent],
        timestamp: Date
    ) {
        self.payloadVersion = payloadVersion
        self.id = id
        self.playerId = playerId
        self.turnIndex = turnIndex
        self.round = round
        self.visitTotal = visitTotal
        self.beatHigh = beatHigh
        self.strikeAwarded = strikeAwarded
        self.highAfter = highAfter
        self.strikesAfter = strikesAfter
        self.wasEliminated = wasEliminated
        self.darts = darts
        self.timestamp = timestamp
    }
}

/// Per-player state for an in-progress Knockout match.
public struct KnockoutPlayerState: Codable, Equatable, Sendable {
    public let playerId: UUID
    public var strikes: Int
    public var isEliminated: Bool

    public init(playerId: UUID, strikes: Int = 0, isEliminated: Bool = false) {
        self.playerId = playerId
        self.strikes = strikes
        self.isEliminated = isEliminated
    }
}

/// Full mutable state of a Knockout match.
public struct KnockoutState: Codable, Equatable, Sendable {
    public let config: MatchConfigKnockout
    public var players: [KnockoutPlayerState]
    /// Turn index across the entire match.
    public var turnIndex: Int
    /// The current 1-based round number (increments after each full rotation).
    public var currentRound: Int
    /// Index into `players` for the active thrower.
    public var currentPlayerIndex: Int
    /// The best visit total set so far in this round. Resets to 0 at round start.
    public var currentHigh: Int
    /// PlayerId of the first thrower in the current round (the round leader sets the bench mark).
    public var roundLeaderPlayerId: UUID?
    public var winnerPlayerId: UUID?
    public var isComplete: Bool

    public init(
        config: MatchConfigKnockout,
        players: [KnockoutPlayerState],
        turnIndex: Int = 0,
        currentRound: Int = 1,
        currentPlayerIndex: Int = 0,
        currentHigh: Int = 0,
        roundLeaderPlayerId: UUID? = nil,
        winnerPlayerId: UUID? = nil,
        isComplete: Bool = false
    ) {
        self.config = config
        self.players = players
        self.turnIndex = turnIndex
        self.currentRound = currentRound
        self.currentPlayerIndex = currentPlayerIndex
        self.currentHigh = currentHigh
        self.roundLeaderPlayerId = roundLeaderPlayerId
        self.winnerPlayerId = winnerPlayerId
        self.isComplete = isComplete
    }
}

/// Return value from `KnockoutEngine.submitTurn`.
public struct KnockoutTurnOutcome: Sendable {
    public let updatedState: KnockoutState
    public let event: KnockoutTurnEvent
}

/// Pure domain engine for the Knockout game mode.
///
/// Rules: the first active thrower in a round sets the benchmark with their
/// 3-dart visit total. Each following player must **exceed** (strictly beat)
/// the current high or receive a strike. Three strikes (configurable) eliminates
/// a player. After all survivors in a round have thrown, the high resets and a
/// new round begins. Last player standing wins.
public enum KnockoutEngine {
    // MARK: - Initial state

    public static func makeInitialState(
        config: MatchConfigKnockout,
        playerIds: [UUID]
    ) throws -> KnockoutState {
        guard playerIds.count >= 2 else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "setup.validation.knockoutMinimumPlayers"
            )
        }
        guard config.strikesToEliminate >= 1 else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.knockout.invalidStrikesToEliminate"
            )
        }
        let players = playerIds.map { KnockoutPlayerState(playerId: $0) }
        let leaderId = players.first?.playerId
        return KnockoutState(
            config: config,
            players: players,
            currentPlayerIndex: 0,
            currentHigh: 0,
            roundLeaderPlayerId: leaderId
        )
    }

    // MARK: - Submit turn

    public static func submitTurn(
        state: KnockoutState,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> KnockoutTurnOutcome {
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

        // Build dart events and sum visit total.
        let (dartEvents, visitTotal) = buildDartEvents(darts)

        // Determine beat/strike logic.
        // The first thrower in a round (roundLeaderPlayerId == playerId) always
        // sets the high; they never receive a strike for this turn regardless of
        // the total (the spec says they set the benchmark).
        let isRoundLeader = updated.roundLeaderPlayerId == playerId
        let beatHigh: Bool
        let strikeAwarded: Bool

        if isRoundLeader {
            // Round leader sets the bench mark; always "beats" (no strike).
            beatHigh = true
            strikeAwarded = false
            updated.currentHigh = visitTotal
        } else if visitTotal > updated.currentHigh {
            beatHigh = true
            strikeAwarded = false
            updated.currentHigh = visitTotal
        } else {
            // Ties do not beat — spec: "must EXCEED".
            beatHigh = false
            strikeAwarded = true
            updated.players[playerIndex].strikes += 1
        }

        // Check elimination.
        let strikesAfter = updated.players[playerIndex].strikes
        var wasEliminated = false
        if strikesAfter >= updated.config.strikesToEliminate {
            updated.players[playerIndex].isEliminated = true
            wasEliminated = true
        }

        let highAfter = updated.currentHigh
        updated.turnIndex += 1

        let event = KnockoutTurnEvent(
            payloadVersion: 1,
            id: UUID(),
            playerId: playerId,
            turnIndex: state.turnIndex,
            round: state.currentRound,
            visitTotal: visitTotal,
            beatHigh: beatHigh,
            strikeAwarded: strikeAwarded,
            highAfter: highAfter,
            strikesAfter: strikesAfter,
            wasEliminated: wasEliminated,
            darts: dartEvents,
            timestamp: timestamp
        )

        advanceTurn(&updated)
        return KnockoutTurnOutcome(updatedState: updated, event: event)
    }

    // MARK: - Replay

    public static func replay(
        config: MatchConfigKnockout,
        playerIds: [UUID],
        events: [KnockoutTurnEvent]
    ) throws -> KnockoutState {
        var state = try makeInitialState(config: config, playerIds: playerIds)
        for event in events {
            let darts = event.darts.map(dartInput(from:))
            state = try submitTurn(state: state, darts: darts, timestamp: event.timestamp).updatedState
        }
        return state
    }

    // MARK: - Dart reconstruction

    public static func dartInput(from event: KnockoutDartEvent) -> DartInput {
        DartInput(
            multiplier: DartMultiplier(rawValue: event.multiplierRaw) ?? .single,
            segment: segment(fromRaw: event.segmentRaw),
            isMiss: event.wasMiss
        )
    }

    // MARK: - Private helpers

    private static func buildDartEvents(_ darts: [DartInput]) -> (events: [KnockoutDartEvent], total: Int) {
        var total = 0
        var events: [KnockoutDartEvent] = []
        for (offset, dart) in darts.enumerated() {
            let points = dart.points
            total += points
            events.append(KnockoutDartEvent(
                dartOrder: offset + 1,
                segmentRaw: segmentRaw(for: dart.segment),
                multiplierRaw: dart.multiplier.rawValue,
                pointsAwarded: points,
                wasMiss: dart.isMiss
            ))
        }
        return (events, total)
    }

    /// Advances `currentPlayerIndex` to the next active (non-eliminated) player,
    /// wrapping to a new round when the rotation completes.
    private static func advanceTurn(_ state: inout KnockoutState) {
        guard !state.isComplete else { return }

        // Check win condition: single survivor.
        completeIfSingleSurvivor(&state)
        guard !state.isComplete else { return }

        let count = state.players.count
        let startIndex = state.currentPlayerIndex
        // Find next active player (skip eliminated).
        var cursor = (startIndex + 1) % count
        var steps = 0
        while state.players[cursor].isEliminated, steps < count {
            cursor = (cursor + 1) % count
            steps += 1
        }

        // Detect round completion: when cursor wraps back to or past the
        // round leader index, we have completed a full rotation.
        let wrappedPastLeader: Bool = {
            // Simple: did we wrap around (cursor <= startIndex) and the
            // round leader is at or before the cursor?
            if cursor <= startIndex {
                return true
            }
            return false
        }()

        if wrappedPastLeader {
            // Start a new round among survivors.
            state.currentRound += 1
            if state.config.resetHighEachRound {
                state.currentHigh = 0
            }
            // New round leader is the first active player from cursor position.
            state.roundLeaderPlayerId = state.players[cursor].playerId
        }

        state.currentPlayerIndex = cursor

        // Final survivor check after potential elimination during turn.
        completeIfSingleSurvivor(&state)
    }

    private static func completeIfSingleSurvivor(_ state: inout KnockoutState) {
        let survivors = state.players.filter { !$0.isEliminated }
        guard survivors.count == 1 else { return }
        state.winnerPlayerId = survivors[0].playerId
        state.isComplete = true
        state.currentPlayerIndex = state.players.firstIndex(where: {
            $0.playerId == survivors[0].playerId
        }) ?? 0
    }

    // MARK: - Segment serialization

    private static func segmentRaw(for segment: DartSegment) -> String {
        switch segment {
        case let .oneToTwenty(value):
            return String(value)
        case .outerBull:
            return "outerBull"
        case .innerBull:
            return "innerBull"
        case .miss:
            return "miss"
        }
    }

    static func segment(fromRaw raw: String) -> DartSegment {
        if let value = Int(raw), (1 ... 20).contains(value) {
            return .oneToTwenty(value)
        }
        switch raw {
        case "outerBull":
            return .outerBull
        case "innerBull":
            return .innerBull
        default:
            return .miss
        }
    }
}
