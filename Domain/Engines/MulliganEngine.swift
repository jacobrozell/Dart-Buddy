import Foundation

/// Config payload for a Mulligan match (v1).
///
/// The target sequence is derived from `rngSeed` at creation time and stored as
/// `targetSequence` so replay is fully deterministic — the engine never re-runs the RNG.
public struct MatchConfigMulligan: Codable, Equatable, Sendable {
    public static let currentPayloadVersion = 1

    public let payloadVersion: Int
    /// Number of drawn segments before the bull finale (default 6).
    public let targetCount: Int
    /// Seed used to draw the initial sequence; preserved for audit trails.
    public let rngSeed: UInt64
    /// Resolved draw order: `targetCount` unique segments from 1–20 followed by `.outerBull`.
    /// Stored at creation so replay never depends on RNG re-execution.
    public let targetSequence: [MulliganSegment]

    public init(
        payloadVersion: Int = currentPayloadVersion,
        targetCount: Int = 6,
        rngSeed: UInt64,
        targetSequence: [MulliganSegment]
    ) {
        self.payloadVersion = payloadVersion
        self.targetCount = max(1, min(20, targetCount))
        self.rngSeed = rngSeed
        self.targetSequence = targetSequence
    }
}

// MARK: - Segment representation

/// A single Mulligan target — one of 1–20 or the bull finale.
public enum MulliganSegment: Codable, Equatable, Hashable, Sendable {
    case number(Int)
    case bull

    /// Stable string used as a dictionary key and for display.
    public var rawValue: String {
        switch self {
        case let .number(n): return String(n)
        case .bull: return "bull"
        }
    }

    /// Human-readable label.
    public var displayLabel: String {
        switch self {
        case let .number(n): return String(n)
        case .bull: return L10n.string("cricket.target.bull")
        }
    }

    public init?(rawValue: String) {
        if rawValue == "bull" {
            self = .bull
        } else if let n = Int(rawValue), (1 ... 20).contains(n) {
            self = .number(n)
        } else {
            return nil
        }
    }
}

// MARK: - Turn event

/// Per-dart detail for a Mulligan turn.
public struct MulliganDartEvent: Codable, Equatable, Sendable {
    public let dartOrder: Int
    public let segmentRaw: String
    public let multiplierRaw: String
    public let marksAdded: Int
    public let wasMiss: Bool
    public let hitActiveTarget: Bool

    public init(
        dartOrder: Int,
        segmentRaw: String,
        multiplierRaw: String,
        marksAdded: Int,
        wasMiss: Bool,
        hitActiveTarget: Bool
    ) {
        self.dartOrder = dartOrder
        self.segmentRaw = segmentRaw
        self.multiplierRaw = multiplierRaw
        self.marksAdded = marksAdded
        self.wasMiss = wasMiss
        self.hitActiveTarget = hitActiveTarget
    }
}

/// Immutable record of one player's three-dart visit.
public struct MulliganTurnEvent: Codable, Equatable, Identifiable, Sendable {
    public let payloadVersion: Int
    public let id: UUID
    public let playerId: UUID
    public let turnIndex: Int
    /// Target index at the start of the visit (before any advancement this turn).
    public let targetIndexAtTurnStart: Int
    /// Target index after processing this turn.
    public let targetIndexAfterTurn: Int
    public let darts: [MulliganDartEvent]
    public let timestamp: Date

    public var effectiveLegIndex: Int { targetIndexAtTurnStart }
}

// MARK: - State

/// Per-player marks on the current active target (resets to zero each time the target advances).
public struct MulliganPlayerState: Codable, Equatable, Sendable {
    public let playerId: UUID
    /// Marks scored on the current active target (max 3 to close).
    public var marksOnActiveTarget: Int

    public init(playerId: UUID, marksOnActiveTarget: Int = 0) {
        self.playerId = playerId
        self.marksOnActiveTarget = marksOnActiveTarget
    }
}

/// Full runtime state for a Mulligan match.
public struct MulliganState: Codable, Equatable, Sendable {
    public let config: MatchConfigMulligan
    public var players: [MulliganPlayerState]
    public var currentPlayerIndex: Int
    public var turnIndex: Int
    /// Index into `config.targetSequence`; shared across all players.
    public var currentTargetIndex: Int
    public var winnerPlayerId: UUID?
    public var isComplete: Bool

    public init(
        config: MatchConfigMulligan,
        players: [MulliganPlayerState],
        currentPlayerIndex: Int,
        turnIndex: Int,
        currentTargetIndex: Int = 0,
        winnerPlayerId: UUID? = nil,
        isComplete: Bool = false
    ) {
        self.config = config
        self.players = players
        self.currentPlayerIndex = currentPlayerIndex
        self.turnIndex = turnIndex
        self.currentTargetIndex = currentTargetIndex
        self.winnerPlayerId = winnerPlayerId
        self.isComplete = isComplete
    }

    /// The active target for the current turn.
    public var currentTarget: MulliganSegment? {
        guard currentTargetIndex < config.targetSequence.count else { return nil }
        return config.targetSequence[currentTargetIndex]
    }

    /// `true` when the active target is the bull finale.
    public var isOnBullFinale: Bool { currentTarget == .bull }
}

// MARK: - Outcome

public struct MulliganTurnOutcome: Sendable {
    public let updatedState: MulliganState
    public let event: MulliganTurnEvent
}

// MARK: - Engine

/// Rules engine for the Mulligan game mode.
///
/// Mulligan is a shared-sequence mark-closure race: six random numbers are drawn
/// at match creation plus bull as the finale. All players work through the same
/// target in order — 3 marks closes it for everyone. The first player to close
/// the bull wins.
public enum MulliganEngine {
    static let marksToClose = 3

    // MARK: Initial state

    public static func makeInitialState(config: MatchConfigMulligan, playerIds: [UUID]) throws -> MulliganState {
        guard config.targetCount > 0 else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.mulligan.invalidDraw"
            )
        }
        guard !config.targetSequence.isEmpty else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.mulligan.invalidDraw"
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
        let players = playerIds.map { MulliganPlayerState(playerId: $0) }
        return MulliganState(
            config: config,
            players: players,
            currentPlayerIndex: 0,
            turnIndex: 0,
            currentTargetIndex: 0
        )
    }

    // MARK: Submit turn

    public static func submitTurn(
        state: MulliganState,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MulliganTurnOutcome {
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
        guard let activeTarget = state.currentTarget else {
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
        let targetIndexBefore = updated.currentTargetIndex
        var dartEvents: [MulliganDartEvent] = []

        for (offset, dart) in darts.enumerated() {
            let marksAdded = marksForDart(dart, target: activeTarget)
            let hitActive = marksAdded > 0

            dartEvents.append(
                MulliganDartEvent(
                    dartOrder: offset + 1,
                    segmentRaw: segmentRaw(for: dart.segment),
                    multiplierRaw: dart.multiplier.rawValue,
                    marksAdded: marksAdded,
                    wasMiss: dart.isMiss,
                    hitActiveTarget: hitActive
                )
            )

            // Accumulate marks for this player; clamp at marksToClose
            let before = updated.players[playerIndex].marksOnActiveTarget
            updated.players[playerIndex].marksOnActiveTarget = min(marksToClose, before + marksAdded)
        }

        // Check whether this player closed the active target with this visit
        if updated.players[playerIndex].marksOnActiveTarget >= marksToClose {
            let closedTarget = updated.config.targetSequence[updated.currentTargetIndex]
            if closedTarget == .bull {
                // Bull closure = win
                updated.winnerPlayerId = playerId
                updated.isComplete = true
            } else {
                // Advance shared target; reset all players' marks on the new target
                updated.currentTargetIndex += 1
                for i in updated.players.indices {
                    updated.players[i].marksOnActiveTarget = 0
                }
            }
        }

        // Advance turn unless match is complete
        let targetIndexAfter = updated.currentTargetIndex
        if !updated.isComplete {
            updated.turnIndex += 1
            updated.currentPlayerIndex = (playerIndex + 1) % updated.players.count
        }

        let event = MulliganTurnEvent(
            payloadVersion: 1,
            id: UUID(),
            playerId: playerId,
            turnIndex: state.turnIndex,
            targetIndexAtTurnStart: targetIndexBefore,
            targetIndexAfterTurn: targetIndexAfter,
            darts: dartEvents,
            timestamp: timestamp
        )

        return MulliganTurnOutcome(updatedState: updated, event: event)
    }

    // MARK: Replay

    public static func replay(
        config: MatchConfigMulligan,
        playerIds: [UUID],
        events: [MulliganTurnEvent]
    ) throws -> MulliganState {
        var state = try makeInitialState(config: config, playerIds: playerIds)
        for event in events {
            let darts = event.darts.map(dartInput(from:))
            state = try submitTurn(state: state, darts: darts, timestamp: event.timestamp).updatedState
        }
        return state
    }

    // MARK: Sequence generation

    /// Draws `count` unique segments from 1–20 using the provided RNG, then appends
    /// `.bull` as the final target.  Callers must store the result in the config so
    /// replay never re-executes the RNG.
    public static func generateSequence(count: Int, rng: inout some RandomNumberGenerator) -> [MulliganSegment] {
        var pool = Array(1 ... 20)
        var result: [MulliganSegment] = []
        let drawCount = max(1, min(20, count))
        for _ in 0 ..< drawCount {
            guard !pool.isEmpty else { break }
            let idx = Int.random(in: 0 ..< pool.count, using: &rng)
            result.append(.number(pool.remove(at: idx)))
        }
        result.append(.bull)
        return result
    }

    // MARK: Reconstruction helpers

    public static func dartInput(from event: MulliganDartEvent) -> DartInput {
        DartInput(
            multiplier: DartMultiplier(rawValue: event.multiplierRaw) ?? .single,
            segment: segment(fromRaw: event.segmentRaw),
            isMiss: event.wasMiss
        )
    }

    // MARK: - Private helpers

    /// Returns how many marks the dart scores on `target` (0 = miss/wrong bed).
    private static func marksForDart(_ dart: DartInput, target: MulliganSegment) -> Int {
        guard !dart.isMiss else { return 0 }
        switch target {
        case let .number(n):
            guard case let .oneToTwenty(value) = dart.segment, value == n else { return 0 }
            return dart.multiplier.markValue
        case .bull:
            switch dart.segment {
            case .innerBull: return 2
            case .outerBull: return 1
            default: return 0
            }
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
