import Foundation

/// The role a participant holds during a given innings.
public enum EnglishCricketRole: String, Codable, CaseIterable, Sendable {
    case batter
    case bowler

    public var displayName: String {
        switch self {
        case .batter: L10n.string("play.englishCricket.role.batter")
        case .bowler: L10n.string("play.englishCricket.role.bowler")
        }
    }
}

/// Configuration for an English Cricket match (payload v1).
public struct MatchConfigEnglishCricket: Codable, Equatable, Sendable {
    public static let currentPayloadVersion = 1

    public let payloadVersion: Int
    /// Number of wickets required to end a batting innings (default 10).
    public let wicketsPerInnings: Int
    /// Runs subtracted from batter's visit total before scoring (default 40).
    public let runsThreshold: Int
    /// When `true` (default), the second innings ends early if the second batter
    /// passes the first batter's run total.
    public let endWhenTargetPassed: Bool

    public init(
        payloadVersion: Int = currentPayloadVersion,
        wicketsPerInnings: Int = 10,
        runsThreshold: Int = 40,
        endWhenTargetPassed: Bool = true
    ) {
        self.payloadVersion = payloadVersion
        self.wicketsPerInnings = wicketsPerInnings
        self.runsThreshold = max(0, runsThreshold)
        self.endWhenTargetPassed = endWhenTargetPassed
    }
}

/// Immutable record of a single three-dart visit (batter or bowler).
public struct EnglishCricketTurnEvent: Codable, Equatable, Identifiable, Sendable {
    public let payloadVersion: Int
    public let id: UUID
    public let playerId: UUID
    public let turnIndex: Int
    public let inningsIndex: Int
    public let roleRaw: String
    public let rawTotal: Int
    public let runsAdded: Int
    public let wicketsAdded: Int
    public let darts: [EnglishCricketDartEvent]
    public let timestamp: Date

    public var role: EnglishCricketRole {
        EnglishCricketRole(rawValue: roleRaw) ?? .batter
    }
}

/// Immutable record of a single dart within a visit.
public struct EnglishCricketDartEvent: Codable, Equatable, Sendable {
    public let dartOrder: Int
    public let segmentRaw: String
    public let multiplierRaw: String
    public let pointsAwarded: Int
    public let wasMiss: Bool
    public let isBull: Bool
}

/// Per-player mutable state.
public struct EnglishCricketPlayerState: Codable, Equatable, Sendable {
    public let playerId: UUID
    /// Cumulative batting runs across both innings.
    public var totalRuns: Int
    /// Runs scored in the current (or most recent) innings while batting.
    public var runsThisInnings: Int

    public init(playerId: UUID, totalRuns: Int = 0, runsThisInnings: Int = 0) {
        self.playerId = playerId
        self.totalRuns = totalRuns
        self.runsThisInnings = runsThisInnings
    }
}

/// Full match state for English Cricket.
public struct EnglishCricketState: Codable, Equatable, Sendable {
    public let config: MatchConfigEnglishCricket
    /// Always exactly 2 players: index 0 and index 1.
    public var players: [EnglishCricketPlayerState]
    /// 0 = first innings, 1 = second innings.
    public var inningsIndex: Int
    /// Phase of the current turn within an innings:
    /// - `batting` — the batter throws next.
    /// - `bowling` — the bowler throws next.
    public var phase: EnglishCricketPhase
    /// Wickets fallen in the current innings.
    public var wicketsFallen: Int
    /// Run total set by the first innings' batter (set at end of innings 0).
    public var opponentRunTarget: Int?
    /// Total turn count (each visit by batter or bowler increments this).
    public var turnIndex: Int
    public var winnerPlayerId: UUID?
    public var isComplete: Bool

    /// Index of the player currently batting.
    public var batterIndex: Int {
        // In innings 0: player 0 bats. In innings 1: player 1 bats.
        inningsIndex == 0 ? 0 : 1
    }

    /// Index of the player currently bowling.
    public var bowlerIndex: Int {
        inningsIndex == 0 ? 1 : 0
    }

    /// Convenience: ID of the current batter.
    public var batterPlayerId: UUID { players[batterIndex].playerId }
    /// Convenience: ID of the current bowler.
    public var bowlerPlayerId: UUID { players[bowlerIndex].playerId }

    /// ID of whichever player acts on the current phase.
    public var currentTurnPlayerId: UUID {
        switch phase {
        case .batting: return batterPlayerId
        case .bowling: return bowlerPlayerId
        }
    }

    public init(
        config: MatchConfigEnglishCricket,
        players: [EnglishCricketPlayerState],
        inningsIndex: Int = 0,
        phase: EnglishCricketPhase = .batting,
        wicketsFallen: Int = 0,
        opponentRunTarget: Int? = nil,
        turnIndex: Int = 0,
        winnerPlayerId: UUID? = nil,
        isComplete: Bool = false
    ) {
        self.config = config
        self.players = players
        self.inningsIndex = inningsIndex
        self.phase = phase
        self.wicketsFallen = wicketsFallen
        self.opponentRunTarget = opponentRunTarget
        self.turnIndex = turnIndex
        self.winnerPlayerId = winnerPlayerId
        self.isComplete = isComplete
    }
}

/// Phase within a single innings.
public enum EnglishCricketPhase: String, Codable, Sendable {
    case batting
    case bowling
}

/// Result of a successful `EnglishCricketEngine.submitTurn` call.
public struct EnglishCricketTurnOutcome: Sendable {
    public let updatedState: EnglishCricketState
    public let event: EnglishCricketTurnEvent
    /// `true` if the innings just ended (triggering a swap or match completion).
    public let inningsJustCompleted: Bool
}

// MARK: - Engine

/// Pure functional engine for English Cricket.
public enum EnglishCricketEngine {

    // MARK: Lifecycle

    /// Constructs the starting state for a new English Cricket match.
    ///
    /// - Parameters:
    ///   - config: Validated match configuration.
    ///   - playerIds: Exactly 2 player UUIDs.
    /// - Throws: `AppError` when the configuration is invalid or the player count is wrong.
    public static func makeInitialState(
        config: MatchConfigEnglishCricket,
        playerIds: [UUID]
    ) throws -> EnglishCricketState {
        guard config.wicketsPerInnings >= 1 else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.englishCricket.invalidWicketsPerInnings"
            )
        }
        guard playerIds.count == 2 else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "setup.validation.englishCricketExactTwoPlayers"
            )
        }
        let players = playerIds.map { EnglishCricketPlayerState(playerId: $0) }
        return EnglishCricketState(config: config, players: players)
    }

    /// Submits a three-dart visit for the current phase (batting or bowling).
    ///
    /// - Parameters:
    ///   - state: The current match state.
    ///   - darts: Up to 3 dart inputs. Batting accepts any segment; bowling counts bull hits.
    ///   - timestamp: Event timestamp (defaults to now).
    /// - Returns: An `EnglishCricketTurnOutcome` containing the updated state and the recorded event.
    /// - Throws: `AppError` for invalid game state or wrong inputs.
    public static func submitTurn(
        state: EnglishCricketState,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> EnglishCricketTurnOutcome {
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

        switch state.phase {
        case .batting:
            return try submitBatterTurn(state: state, darts: darts, timestamp: timestamp)
        case .bowling:
            return try submitBowlerTurn(state: state, darts: darts, timestamp: timestamp)
        }
    }

    /// Replays a sequence of events from an initial state to reconstruct game state.
    public static func replay(
        config: MatchConfigEnglishCricket,
        playerIds: [UUID],
        events: [EnglishCricketTurnEvent]
    ) throws -> EnglishCricketState {
        var state = try makeInitialState(config: config, playerIds: playerIds)
        for event in events {
            let darts = event.darts.map(dartInput(from:))
            state = try submitTurn(state: state, darts: darts, timestamp: event.timestamp).updatedState
        }
        return state
    }

    // MARK: - Batter Turn

    private static func submitBatterTurn(
        state: EnglishCricketState,
        darts: [DartInput],
        timestamp: Date
    ) throws -> EnglishCricketTurnOutcome {
        var updated = state
        let batterIndex = updated.batterIndex
        let playerId = updated.batterPlayerId

        let rawTotal = darts.reduce(0) { $0 + $1.points }
        let runsAdded = max(0, rawTotal - updated.config.runsThreshold)

        updated.players[batterIndex].runsThisInnings += runsAdded
        updated.players[batterIndex].totalRuns += runsAdded

        let dartEvents = makeDartEvents(darts: darts)
        let event = EnglishCricketTurnEvent(
            payloadVersion: 1,
            id: UUID(),
            playerId: playerId,
            turnIndex: updated.turnIndex,
            inningsIndex: updated.inningsIndex,
            roleRaw: EnglishCricketRole.batter.rawValue,
            rawTotal: rawTotal,
            runsAdded: runsAdded,
            wicketsAdded: 0,
            darts: dartEvents,
            timestamp: timestamp
        )

        updated.turnIndex += 1

        // Check early-target condition (innings 1 only): second batter has passed target.
        let inningsJustCompleted: Bool
        if updated.config.endWhenTargetPassed,
           updated.inningsIndex == 1,
           let target = updated.opponentRunTarget,
           updated.players[batterIndex].runsThisInnings > target {
            // Second batter has passed the target — innings ends immediately.
            inningsJustCompleted = true
            finaliseInnings(&updated)
        } else {
            // Normal batter turn: switch to bowling phase.
            updated.phase = .bowling
            inningsJustCompleted = false
        }

        return EnglishCricketTurnOutcome(
            updatedState: updated,
            event: event,
            inningsJustCompleted: inningsJustCompleted
        )
    }

    // MARK: - Bowler Turn

    private static func submitBowlerTurn(
        state: EnglishCricketState,
        darts: [DartInput],
        timestamp: Date
    ) throws -> EnglishCricketTurnOutcome {
        var updated = state
        let playerId = updated.bowlerPlayerId

        let wicketsAdded = darts.filter { isBull($0) }.count
        updated.wicketsFallen += wicketsAdded

        let dartEvents = makeDartEvents(darts: darts)
        let event = EnglishCricketTurnEvent(
            payloadVersion: 1,
            id: UUID(),
            playerId: playerId,
            turnIndex: updated.turnIndex,
            inningsIndex: updated.inningsIndex,
            roleRaw: EnglishCricketRole.bowler.rawValue,
            rawTotal: darts.reduce(0) { $0 + $1.points },
            runsAdded: 0,
            wicketsAdded: wicketsAdded,
            darts: dartEvents,
            timestamp: timestamp
        )

        updated.turnIndex += 1

        // Check if innings ends due to wickets reaching the cap.
        let inningsJustCompleted: Bool
        if updated.wicketsFallen >= updated.config.wicketsPerInnings {
            inningsJustCompleted = true
            finaliseInnings(&updated)
        } else {
            // Normal bowler turn: switch back to batting phase for next visit.
            updated.phase = .batting
            inningsJustCompleted = false
        }

        return EnglishCricketTurnOutcome(
            updatedState: updated,
            event: event,
            inningsJustCompleted: inningsJustCompleted
        )
    }

    // MARK: - Innings Finalisation

    /// Called when an innings ends (wickets cap or target-passed). Advances innings or completes match.
    private static func finaliseInnings(_ state: inout EnglishCricketState) {
        if state.inningsIndex == 0 {
            // End of innings 0: record run target and start innings 1.
            state.opponentRunTarget = state.players[state.batterIndex].runsThisInnings
            state.inningsIndex = 1
            state.phase = .batting
            state.wicketsFallen = 0
            // Reset runsThisInnings for the innings-1 batter (player 1).
            state.players[state.batterIndex].runsThisInnings = 0
        } else {
            // End of innings 1: determine winner.
            let p0Runs = state.players[0].totalRuns
            let p1Runs = state.players[1].totalRuns
            if p0Runs > p1Runs {
                completeMatch(&state, winnerId: state.players[0].playerId)
            } else if p1Runs > p0Runs {
                completeMatch(&state, winnerId: state.players[1].playerId)
            } else {
                // Tie — no winner (draw).
                completeMatch(&state, winnerId: nil)
            }
        }
    }

    private static func completeMatch(_ state: inout EnglishCricketState, winnerId: UUID?) {
        state.winnerPlayerId = winnerId
        state.isComplete = true
    }

    // MARK: - Helpers

    /// Returns `true` if the dart hit the bull (inner or outer).
    static func isBull(_ dart: DartInput) -> Bool {
        guard !dart.isMiss else { return false }
        return dart.segment == .innerBull || dart.segment == .outerBull
    }

    /// Reconstructs a `DartInput` from a stored dart event.
    public static func dartInput(from event: EnglishCricketDartEvent) -> DartInput {
        DartInput(
            multiplier: DartMultiplier(rawValue: event.multiplierRaw) ?? .single,
            segment: segment(fromRaw: event.segmentRaw),
            isMiss: event.wasMiss
        )
    }

    private static func makeDartEvents(darts: [DartInput]) -> [EnglishCricketDartEvent] {
        darts.enumerated().map { offset, dart in
            EnglishCricketDartEvent(
                dartOrder: offset + 1,
                segmentRaw: segmentRaw(for: dart.segment),
                multiplierRaw: dart.multiplier.rawValue,
                pointsAwarded: dart.points,
                wasMiss: dart.isMiss,
                isBull: isBull(dart)
            )
        }
    }

    private static func segmentRaw(for segment: DartSegment) -> String {
        switch segment {
        case let .oneToTwenty(value): return String(value)
        case .outerBull: return "outerBull"
        case .innerBull: return "innerBull"
        case .miss: return "miss"
        }
    }

    static func segment(fromRaw raw: String) -> DartSegment {
        if let value = Int(raw), (1 ... 20).contains(value) {
            return .oneToTwenty(value)
        }
        switch raw {
        case "outerBull": return .outerBull
        case "innerBull": return .innerBull
        default: return .miss
        }
    }
}
