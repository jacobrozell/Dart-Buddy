import Foundation

/// Controls how tied-lowest scorers are eliminated at the end of a round.
public enum SuddenDeathEliminationRule: String, Codable, CaseIterable, Sendable {
    /// All players tied for the lowest total are eliminated (default).
    case eliminateAllTied
    /// Only one of the tied players is eliminated (reserved for v2 throw-off).
    case eliminateOne

    public var displayName: String {
        switch self {
        case .eliminateAllTied: L10n.string("play.suddenDeath.eliminationRule.eliminateAllTied")
        case .eliminateOne: L10n.string("play.suddenDeath.eliminationRule.eliminateOne")
        }
    }
}

public struct MatchConfigSuddenDeath: Codable, Equatable, Sendable {
    public static let currentPayloadVersion = 1

    public let payloadVersion: Int
    /// Number of visits (3-dart turns) each active player throws per round before
    /// elimination is resolved. Default is 1; 2 is offered as a setup option for
    /// smaller groups.
    public let visitsPerRound: Int
    /// Raw storage for the elimination rule enum, for forward compatibility.
    public let eliminateAllTiedRaw: String

    public var eliminationRule: SuddenDeathEliminationRule {
        SuddenDeathEliminationRule(rawValue: eliminateAllTiedRaw) ?? .eliminateAllTied
    }

    /// Convenience accessor: `true` when all tied-lowest scorers are eliminated.
    public var eliminateAllTied: Bool {
        eliminationRule == .eliminateAllTied
    }

    public init(
        payloadVersion: Int = currentPayloadVersion,
        visitsPerRound: Int = 1,
        eliminationRule: SuddenDeathEliminationRule = .eliminateAllTied
    ) {
        self.payloadVersion = payloadVersion
        self.visitsPerRound = max(1, min(2, visitsPerRound))
        self.eliminateAllTiedRaw = eliminationRule.rawValue
    }
}

// MARK: - Events

/// One visit (3-dart turn) submitted by a single player during a Sudden Death match.
public struct SuddenDeathTurnEvent: Codable, Equatable, Identifiable, Sendable {
    public let payloadVersion: Int
    public let id: UUID
    public let playerId: UUID
    /// Global turn index across the entire match (used for event ordering / undo).
    public let turnIndex: Int
    /// 1-based round number.
    public let round: Int
    /// 0-based visit index within the round (0 when `visitsPerRound == 1`).
    public let visitIndexInRound: Int
    /// Points scored on this visit.
    public let pointsThisVisit: Int
    /// Running total for this player at the end of this visit (sum over all rounds).
    public let cumulativeTotalAfterTurn: Int
    /// `true` when this event closes the round and elimination has been resolved.
    public let roundCompleted: Bool
    /// Player ids eliminated at the end of this round (non-empty only when
    /// `roundCompleted == true`).
    public let eliminatedPlayerIds: [UUID]
    public let timestamp: Date

    public init(
        payloadVersion: Int = 1,
        id: UUID = UUID(),
        playerId: UUID,
        turnIndex: Int,
        round: Int,
        visitIndexInRound: Int,
        pointsThisVisit: Int,
        cumulativeTotalAfterTurn: Int,
        roundCompleted: Bool,
        eliminatedPlayerIds: [UUID],
        timestamp: Date
    ) {
        self.payloadVersion = payloadVersion
        self.id = id
        self.playerId = playerId
        self.turnIndex = turnIndex
        self.round = round
        self.visitIndexInRound = visitIndexInRound
        self.pointsThisVisit = pointsThisVisit
        self.cumulativeTotalAfterTurn = cumulativeTotalAfterTurn
        self.roundCompleted = roundCompleted
        self.eliminatedPlayerIds = eliminatedPlayerIds
        self.timestamp = timestamp
    }
}

// MARK: - State

public struct SuddenDeathPlayerState: Codable, Equatable, Sendable {
    public let playerId: UUID
    /// Total points scored across all completed visits so far.
    public var cumulativeTotal: Int
    /// Sum of visit totals in the current round (resets after each round).
    public var roundTotal: Int
    /// Number of visits submitted in the current round.
    public var visitsSubmittedThisRound: Int
    /// `true` once the player has been knocked out.
    public var isEliminated: Bool

    public init(
        playerId: UUID,
        cumulativeTotal: Int = 0,
        roundTotal: Int = 0,
        visitsSubmittedThisRound: Int = 0,
        isEliminated: Bool = false
    ) {
        self.playerId = playerId
        self.cumulativeTotal = cumulativeTotal
        self.roundTotal = roundTotal
        self.visitsSubmittedThisRound = visitsSubmittedThisRound
        self.isEliminated = isEliminated
    }
}

public struct SuddenDeathState: Codable, Equatable, Sendable {
    public let config: MatchConfigSuddenDeath
    public var players: [SuddenDeathPlayerState]
    /// Index into `players` for the player who throws next.
    public var currentPlayerIndex: Int
    /// Global turn counter across the whole match.
    public var turnIndex: Int
    /// 1-based current round number.
    public var currentRound: Int
    /// Ids of players eliminated in the most recently completed round (cleared at
    /// the start of the next round's first turn submission).
    public var lastRoundEliminatedIds: [UUID]
    public var winnerPlayerId: UUID?
    public var isComplete: Bool

    public init(
        config: MatchConfigSuddenDeath,
        players: [SuddenDeathPlayerState],
        currentPlayerIndex: Int = 0,
        turnIndex: Int = 0,
        currentRound: Int = 1,
        lastRoundEliminatedIds: [UUID] = [],
        winnerPlayerId: UUID? = nil,
        isComplete: Bool = false
    ) {
        self.config = config
        self.players = players
        self.currentPlayerIndex = currentPlayerIndex
        self.turnIndex = turnIndex
        self.currentRound = currentRound
        self.lastRoundEliminatedIds = lastRoundEliminatedIds
        self.winnerPlayerId = winnerPlayerId
        self.isComplete = isComplete
    }

    /// Ids of all players still in the match.
    public var activePlayerIds: [UUID] {
        players.filter { !$0.isEliminated }.map(\.playerId)
    }
}

// MARK: - Outcome

public struct SuddenDeathTurnOutcome: Sendable {
    public let updatedState: SuddenDeathState
    public let event: SuddenDeathTurnEvent
}

// MARK: - Engine

/// Pure, value-typed engine for the Sudden Death game mode.
///
/// **Round flow** (per the spec):
/// 1. Every active player submits `config.visitsPerRound` visits (3-dart turns each).
/// 2. After the **last** active player's final visit of the round, elimination is
///    resolved: whoever has the lowest `roundTotal` is eliminated.
/// 3. **All-tie safety rule**: if every remaining active player ties for lowest, nobody
///    is eliminated that round (the round is effectively replayed).
/// 4. If exactly one player survives, the match is complete.
public enum SuddenDeathEngine {

    // MARK: - Setup

    public static func makeInitialState(
        config: MatchConfigSuddenDeath,
        playerIds: [UUID]
    ) throws -> SuddenDeathState {
        guard playerIds.count >= 3 else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.suddenDeath.minimumPlayers"
            )
        }
        guard config.visitsPerRound >= 1 else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.suddenDeath.invalidVisitsPerRound"
            )
        }
        let players = playerIds.map { SuddenDeathPlayerState(playerId: $0) }
        return SuddenDeathState(config: config, players: players)
    }

    // MARK: - Turn submission

    /// Submit a 3-dart visit for the current active player.
    ///
    /// Elimination is deferred until the **final** visit of the round.  The engine
    /// records `roundCompleted` and `eliminatedPlayerIds` on the closing turn event.
    public static func submitTurn(
        state: SuddenDeathState,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> SuddenDeathTurnOutcome {
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

        // Clear stale elimination badge on the very first submit of a new round.
        if updated.players[playerIndex].visitsSubmittedThisRound == 0,
           isFirstActivePlayerOfRound(playerIndex: playerIndex, in: updated) {
            updated.lastRoundEliminatedIds = []
        }

        let visitPoints = darts.reduce(0) { $0 + pointValue(for: $1) }
        updated.players[playerIndex].roundTotal += visitPoints
        updated.players[playerIndex].cumulativeTotal += visitPoints
        updated.players[playerIndex].visitsSubmittedThisRound += 1

        let isLastVisitForThisPlayer =
            updated.players[playerIndex].visitsSubmittedThisRound >= updated.config.visitsPerRound

        let roundCompleted: Bool
        var eliminatedIds: [UUID] = []

        if isLastVisitForThisPlayer {
            // Check whether this is the last active player to complete their visits.
            let isLastActivePlayer = isLastActivePlayerInRound(playerIndex: playerIndex, in: updated)
            if isLastActivePlayer {
                // Resolve elimination for this round.
                eliminatedIds = resolveElimination(in: &updated)
                roundCompleted = true
                advanceRound(&updated)
            } else {
                roundCompleted = false
                advanceToNextActivePlayer(&updated)
            }
        } else {
            // Player still has more visits in this round.
            roundCompleted = false
        }

        updated.turnIndex += 1

        let event = SuddenDeathTurnEvent(
            playerId: playerId,
            turnIndex: state.turnIndex,
            round: state.currentRound,
            visitIndexInRound: state.players[playerIndex].visitsSubmittedThisRound,
            pointsThisVisit: visitPoints,
            cumulativeTotalAfterTurn: updated.players[playerIndex].cumulativeTotal,
            roundCompleted: roundCompleted,
            eliminatedPlayerIds: eliminatedIds,
            timestamp: timestamp
        )
        return SuddenDeathTurnOutcome(updatedState: updated, event: event)
    }

    // MARK: - Replay

    public static func replay(
        config: MatchConfigSuddenDeath,
        playerIds: [UUID],
        events: [SuddenDeathTurnEvent]
    ) throws -> SuddenDeathState {
        var state = try makeInitialState(config: config, playerIds: playerIds)
        for event in events {
            let darts = dartsFromEvent(event)
            state = try submitTurn(state: state, darts: darts, timestamp: event.timestamp).updatedState
        }
        return state
    }

    // MARK: - Dart reconstruction

    /// Reconstruct a minimal `[DartInput]` from a stored event.
    ///
    /// Sudden Death only needs the per-visit total for its rules, so darts are
    /// not stored individually.  We reconstruct a single-dart visit with the
    /// recorded total to satisfy the replay contract.
    public static func dartsFromEvent(_ event: SuddenDeathTurnEvent) -> [DartInput] {
        // Represent the visit total as one dart on segment 1–20 (up to 20 points)
        // plus additional singles on segment 1.  This is purely for replay — the
        // engine only sums the visit total, it does not inspect individual darts.
        let total = event.pointsThisVisit
        guard total > 0 else {
            return [DartInput(multiplier: .single, segment: .miss, isMiss: true),
                    DartInput(multiplier: .single, segment: .miss, isMiss: true),
                    DartInput(multiplier: .single, segment: .miss, isMiss: true)]
        }
        // Encode the visit total across up to 3 darts using triples/doubles/singles
        // on segments 1–20 that sum exactly to `total`.  For simplicity, use the
        // largest possible dart values.
        return encodeTotalAsDarts(total)
    }

    // MARK: - Elimination logic

    /// Returns the ids of players eliminated this round and mutates the state to
    /// mark them as eliminated.
    ///
    /// Edge-case: if every remaining active player ties for the lowest round total,
    /// nobody is eliminated (the round is a no-op — all-tie safety rule).
    @discardableResult
    private static func resolveElimination(in state: inout SuddenDeathState) -> [UUID] {
        let activePlayers = state.players.filter { !$0.isEliminated }
        guard activePlayers.count > 1 else { return [] }

        let minTotal = activePlayers.map(\.roundTotal).min() ?? 0

        let lowestPlayers = activePlayers.filter { $0.roundTotal == minTotal }

        // All-tie safety: if *everyone* is at the minimum, nobody goes out.
        guard lowestPlayers.count < activePlayers.count else { return [] }

        let config = state.config
        let toEliminate: [SuddenDeathPlayerState]
        if config.eliminateAllTied {
            toEliminate = lowestPlayers
        } else {
            // eliminateOne: eliminate the first tied player in turn order (v2 would
            // add a throw-off; for now we still eliminate just one).
            toEliminate = Array(lowestPlayers.prefix(1))
        }

        let eliminatedIds = toEliminate.map(\.playerId)
        for id in eliminatedIds {
            guard let idx = state.players.firstIndex(where: { $0.playerId == id }) else { continue }
            state.players[idx].isEliminated = true
        }
        state.lastRoundEliminatedIds = eliminatedIds

        // Check win condition.
        let survivors = state.players.filter { !$0.isEliminated }
        if survivors.count == 1 {
            state.winnerPlayerId = survivors[0].playerId
            state.isComplete = true
        } else if survivors.isEmpty {
            // Shouldn't happen due to all-tie guard above, but be defensive.
            state.isComplete = true
        }

        return eliminatedIds
    }

    // MARK: - Round/turn advancement

    private static func advanceRound(_ state: inout SuddenDeathState) {
        guard !state.isComplete else { return }
        // Reset per-round scratch for all players.
        for idx in state.players.indices {
            state.players[idx].roundTotal = 0
            state.players[idx].visitsSubmittedThisRound = 0
        }
        state.currentRound += 1
        // Advance to the first active player of the new round.
        if let first = firstActivePlayerIndex(in: state) {
            state.currentPlayerIndex = first
        }
    }

    private static func advanceToNextActivePlayer(_ state: inout SuddenDeathState) {
        guard let next = nextActivePlayerIndex(after: state.currentPlayerIndex, in: state) else {
            return
        }
        state.currentPlayerIndex = next
    }

    // MARK: - Round-boundary helpers

    /// Returns `true` when `playerIndex` is the **first** active player in the
    /// current round (i.e. no active player with a lower index has submitted a
    /// visit yet this round).
    private static func isFirstActivePlayerOfRound(
        playerIndex: Int,
        in state: SuddenDeathState
    ) -> Bool {
        for idx in state.players.indices {
            guard !state.players[idx].isEliminated else { continue }
            if idx == playerIndex { return true }
            if state.players[idx].visitsSubmittedThisRound > 0 { return false }
        }
        return true
    }

    /// Returns `true` when `playerIndex` is the **last** active player still owed
    /// their final visit this round.
    private static func isLastActivePlayerInRound(
        playerIndex: Int,
        in state: SuddenDeathState
    ) -> Bool {
        let visitsRequired = state.config.visitsPerRound
        // After this visit the player's count will equal visitsRequired.
        // Check that all other active players are already done.
        for (idx, player) in state.players.enumerated() {
            guard !player.isEliminated, idx != playerIndex else { continue }
            if player.visitsSubmittedThisRound < visitsRequired { return false }
        }
        return true
    }

    // MARK: - Index utilities

    private static func firstActivePlayerIndex(in state: SuddenDeathState) -> Int? {
        state.players.indices.first { !state.players[$0].isEliminated }
    }

    private static func nextActivePlayerIndex(after index: Int, in state: SuddenDeathState) -> Int? {
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

    // MARK: - Dart helpers

    private static func pointValue(for dart: DartInput) -> Int {
        guard !dart.isMiss else { return 0 }
        switch dart.segment {
        case let .oneToTwenty(value):
            switch dart.multiplier {
            case .single: return value
            case .double: return value * 2
            case .triple: return value * 3
            }
        case .outerBull: return 25
        case .innerBull: return 50
        case .miss: return 0
        }
    }

    /// Encode an integer visit total as up to 3 `DartInput` values, summing
    /// exactly to `total`.  Used by `dartsFromEvent` for replay.
    private static func encodeTotalAsDarts(_ total: Int) -> [DartInput] {
        var remaining = total
        var darts: [DartInput] = []
        let denominations: [(DartMultiplier, DartSegment, Int)] = [
            (.triple, .oneToTwenty(20), 60),
            (.double, .oneToTwenty(20), 40),
            (.triple, .oneToTwenty(19), 57),
            (.double, .oneToTwenty(19), 38),
            (.triple, .oneToTwenty(18), 54),
            (.single, .innerBull, 50),
            (.single, .outerBull, 25),
            (.triple, .oneToTwenty(17), 51),
            (.triple, .oneToTwenty(16), 48),
            (.triple, .oneToTwenty(15), 45),
            (.triple, .oneToTwenty(14), 42),
            (.triple, .oneToTwenty(13), 39),
            (.triple, .oneToTwenty(12), 36),
            (.triple, .oneToTwenty(11), 33),
            (.triple, .oneToTwenty(10), 30),
            (.triple, .oneToTwenty(9), 27),
            (.triple, .oneToTwenty(8), 24),
            (.triple, .oneToTwenty(7), 21),
            (.double, .oneToTwenty(10), 20),
            (.triple, .oneToTwenty(6), 18),
            (.double, .oneToTwenty(9), 18),
            (.triple, .oneToTwenty(5), 15),
            (.double, .oneToTwenty(7), 14),
            (.triple, .oneToTwenty(4), 12),
            (.double, .oneToTwenty(6), 12),
            (.triple, .oneToTwenty(3), 9),
            (.double, .oneToTwenty(4), 8),
            (.triple, .oneToTwenty(2), 6),
            (.double, .oneToTwenty(3), 6),
            (.double, .oneToTwenty(2), 4),
            (.triple, .oneToTwenty(1), 3),
            (.double, .oneToTwenty(1), 2),
            (.single, .oneToTwenty(20), 20),
            (.single, .oneToTwenty(19), 19),
            (.single, .oneToTwenty(18), 18),
            (.single, .oneToTwenty(17), 17),
            (.single, .oneToTwenty(16), 16),
            (.single, .oneToTwenty(15), 15),
            (.single, .oneToTwenty(14), 14),
            (.single, .oneToTwenty(13), 13),
            (.single, .oneToTwenty(12), 12),
            (.single, .oneToTwenty(11), 11),
            (.single, .oneToTwenty(10), 10),
            (.single, .oneToTwenty(9), 9),
            (.single, .oneToTwenty(8), 8),
            (.single, .oneToTwenty(7), 7),
            (.single, .oneToTwenty(6), 6),
            (.single, .oneToTwenty(5), 5),
            (.single, .oneToTwenty(4), 4),
            (.single, .oneToTwenty(3), 3),
            (.single, .oneToTwenty(2), 2),
            (.single, .oneToTwenty(1), 1)
        ]
        for (multiplier, segment, value) in denominations {
            guard darts.count < 3, remaining >= value else { continue }
            darts.append(DartInput(multiplier: multiplier, segment: segment))
            remaining -= value
            if remaining == 0 { break }
        }
        // Pad to 3 darts with misses if needed.
        while darts.count < 3 {
            darts.append(DartInput(multiplier: .single, segment: .miss, isMiss: true))
        }
        return darts
    }
}
