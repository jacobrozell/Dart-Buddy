import Foundation

/// Course lengths supported in Golf darts.
public enum GolfCourseLength: Int, Codable, CaseIterable, Sendable {
    case nine = 9
    case eighteen = 18

    public var displayName: String {
        switch self {
        case .nine: L10n.format("play.golf.setup.courseLength", 9)
        case .eighteen: L10n.format("play.golf.setup.courseLength", 18)
        }
    }
}

/// GLD last-dart ruleset identifier.
public enum GolfRuleset: String, Codable, CaseIterable, Sendable {
    case gldLastDart = "golf_gld_last_dart"

    public var displayName: String {
        L10n.string("play.golf.setup.ruleset.gldLastDart")
    }
}

/// Configuration for a Golf match (payload v1, GLD last-dart ruleset).
public struct MatchConfigGolf: Codable, Equatable, Sendable {
    public static let currentPayloadVersion = 1

    public let payloadVersion: Int
    public let courseLengthRaw: Int
    public let rulesetRaw: String

    /// Typed accessor for course length.
    public var courseLength: GolfCourseLength {
        GolfCourseLength(rawValue: courseLengthRaw) ?? .nine
    }

    /// Typed accessor for ruleset.
    public var ruleset: GolfRuleset {
        GolfRuleset(rawValue: rulesetRaw) ?? .gldLastDart
    }

    /// GLD rule: only the last dart thrown for the hole counts.
    public var lastDartOnly: Bool { true }

    public init(
        payloadVersion: Int = currentPayloadVersion,
        courseLength: GolfCourseLength = .nine,
        ruleset: GolfRuleset = .gldLastDart
    ) {
        self.payloadVersion = payloadVersion
        self.courseLengthRaw = courseLength.rawValue
        self.rulesetRaw = ruleset.rawValue
    }
}

// MARK: - Event types

/// One dart thrown within a golf hole turn.
public struct GolfDartEvent: Codable, Equatable, Sendable {
    public let dartOrder: Int
    public let segmentRaw: String
    public let multiplierRaw: String
    public let wasMiss: Bool
    public let hitTarget: Bool

    public init(
        dartOrder: Int,
        segmentRaw: String,
        multiplierRaw: String,
        wasMiss: Bool,
        hitTarget: Bool
    ) {
        self.dartOrder = dartOrder
        self.segmentRaw = segmentRaw
        self.multiplierRaw = multiplierRaw
        self.wasMiss = wasMiss
        self.hitTarget = hitTarget
    }
}

/// Immutable record of one player's turn on a single hole.
///
/// The GLD rule: only `strokesRecorded` (derived from the last dart) counts.
public struct GolfTurnEvent: Codable, Equatable, Identifiable, Sendable {
    public let payloadVersion: Int
    public let id: UUID
    public let playerId: UUID
    public let turnIndex: Int
    public let hole: Int
    /// Index into the events list for replay; mirrors `legIndex` in Shanghai.
    public let legIndex: Int
    public let strokesRecorded: Int
    public let runningTotalAfterHole: Int
    public let darts: [GolfDartEvent]
    public let endedEarly: Bool
    public let timestamp: Date
}

// MARK: - State types

/// Per-player state within a Golf match.
public struct GolfPlayerState: Codable, Equatable, Sendable {
    public let playerId: UUID
    /// Strokes per hole, indexed by hole number 1…courseLength. Keys are hole numbers.
    public var strokesByHole: [Int: Int]
    public var runningTotal: Int

    public init(
        playerId: UUID,
        strokesByHole: [Int: Int] = [:],
        runningTotal: Int = 0
    ) {
        self.playerId = playerId
        self.strokesByHole = strokesByHole
        self.runningTotal = runningTotal
    }
}

/// Full match state for a Golf game.
public struct GolfState: Codable, Equatable, Sendable {
    public let config: MatchConfigGolf
    public var players: [GolfPlayerState]
    public var currentPlayerIndex: Int
    public var turnIndex: Int
    public var currentHole: Int
    public var winnerPlayerId: UUID?
    public var isComplete: Bool

    public init(
        config: MatchConfigGolf,
        players: [GolfPlayerState],
        currentPlayerIndex: Int,
        turnIndex: Int,
        currentHole: Int,
        winnerPlayerId: UUID? = nil,
        isComplete: Bool = false
    ) {
        self.config = config
        self.players = players
        self.currentPlayerIndex = currentPlayerIndex
        self.turnIndex = turnIndex
        self.currentHole = currentHole
        self.winnerPlayerId = winnerPlayerId
        self.isComplete = isComplete
    }
}

/// Carries variable-length dart input for a Golf hole turn.
///
/// Because Golf allows 1–3 darts with an explicit "end turn early" affordance,
/// a plain `[DartInput]` is not sufficient to distinguish an intentional
/// early stop from a 3-dart completion. `endedEarly` captures that intent.
public struct GolfTurnInput: Sendable {
    /// The darts thrown this hole (1…3).
    public let darts: [DartInput]
    /// True when the player chose to end after fewer than 3 darts.
    public let endedEarly: Bool

    public init(darts: [DartInput], endedEarly: Bool = false) {
        self.darts = darts
        self.endedEarly = endedEarly
    }
}

/// Result of a submitted Golf turn.
public struct GolfTurnOutcome: Sendable {
    public let updatedState: GolfState
    public let event: GolfTurnEvent
}

// MARK: - Engine

/// Pure domain logic for Golf darts (GLD last-dart ruleset).
///
/// Rules summary:
/// - Holes are segments 1 → courseLength (9 or 18).
/// - Each player throws 1–3 darts at the current hole's segment.
/// - Only the **last** dart thrown counts: double = 1 stroke, triple = 2,
///   single = 3, miss = 5.
/// - Lowest running total after all holes wins.
public enum GolfEngine {

    // MARK: - Public API

    public static func makeInitialState(
        config: MatchConfigGolf,
        playerIds: [UUID]
    ) throws -> GolfState {
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
                userMessageKey: "error.match.players.maximum"
            )
        }
        guard GolfCourseLength(rawValue: config.courseLengthRaw) != nil else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.golf.invalidCourseLength"
            )
        }
        let players = playerIds.map { GolfPlayerState(playerId: $0) }
        return GolfState(
            config: config,
            players: players,
            currentPlayerIndex: 0,
            turnIndex: 0,
            currentHole: 1
        )
    }

    public static func submitTurn(
        state: GolfState,
        input: GolfTurnInput,
        timestamp: Date = Date()
    ) throws -> GolfTurnOutcome {
        guard !state.isComplete else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.completed"
            )
        }
        guard !input.darts.isEmpty else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.turn.noDarts"
            )
        }
        guard input.darts.count <= 3 else {
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
        let hole = updated.currentHole

        // Build dart events
        var dartEvents: [GolfDartEvent] = []
        for (offset, dart) in input.darts.enumerated() {
            let hitTarget = !dart.isMiss && segmentValue(dart.segment) == hole
            dartEvents.append(
                GolfDartEvent(
                    dartOrder: offset + 1,
                    segmentRaw: segmentRaw(for: dart.segment),
                    multiplierRaw: dart.multiplier.rawValue,
                    wasMiss: dart.isMiss,
                    hitTarget: hitTarget
                )
            )
        }

        // GLD: only the last dart thrown counts (non-empty guarded above)
        let lastDart = input.darts[input.darts.count - 1]
        let strokes = strokesForLastDart(lastDart, holeSegment: hole)

        updated.players[playerIndex].strokesByHole[hole] = strokes
        updated.players[playerIndex].runningTotal += strokes

        let runningTotalAfter = updated.players[playerIndex].runningTotal

        advanceTurn(&updated)

        let event = GolfTurnEvent(
            payloadVersion: 1,
            id: UUID(),
            playerId: playerId,
            turnIndex: state.turnIndex,
            hole: hole,
            legIndex: hole - 1,
            strokesRecorded: strokes,
            runningTotalAfterHole: runningTotalAfter,
            darts: dartEvents,
            endedEarly: input.endedEarly,
            timestamp: timestamp
        )
        return GolfTurnOutcome(updatedState: updated, event: event)
    }

    public static func replay(
        config: MatchConfigGolf,
        playerIds: [UUID],
        events: [GolfTurnEvent]
    ) throws -> GolfState {
        var state = try makeInitialState(config: config, playerIds: playerIds)
        for event in events {
            let darts = event.darts.map(dartInput(from:))
            let input = GolfTurnInput(darts: darts, endedEarly: event.endedEarly)
            state = try submitTurn(state: state, input: input, timestamp: event.timestamp).updatedState
        }
        return state
    }

    public static func dartInput(from event: GolfDartEvent) -> DartInput {
        DartInput(
            multiplier: DartMultiplier(rawValue: event.multiplierRaw) ?? .single,
            segment: segment(fromRaw: event.segmentRaw),
            isMiss: event.wasMiss
        )
    }

    // MARK: - Stroke resolution

    /// Converts the last-thrown dart into a stroke count per GLD rules.
    ///
    /// On target segment: double = 1, triple = 2, single = 3.
    /// Off-target or miss = 5 strokes.
    public static func strokesForLastDart(_ dart: DartInput, holeSegment: Int) -> Int {
        guard !dart.isMiss, segmentValue(dart.segment) == holeSegment else {
            return 5
        }
        switch dart.multiplier {
        case .double: return 1
        case .triple: return 2
        case .single: return 3
        }
    }

    // MARK: - Progression

    private static func advanceTurn(_ state: inout GolfState) {
        state.turnIndex += 1
        guard !state.isComplete else { return }

        let playerCount = state.players.count
        let wasLastPlayerInHole = state.currentPlayerIndex == playerCount - 1
        state.currentPlayerIndex = (state.currentPlayerIndex + 1) % playerCount

        guard wasLastPlayerInHole else { return }

        let completedHole = state.currentHole

        if completedHole >= state.config.courseLength.rawValue {
            // All holes complete — find winner (lowest total)
            if let winnerId = lowestStrokesLeader(in: state.players) {
                completeMatch(&state, winnerId: winnerId)
            } else {
                // Tie: no winner declared in v1 (future: extra holes option)
                state.isComplete = true
            }
        } else {
            state.currentHole = completedHole + 1
        }
    }

    private static func completeMatch(_ state: inout GolfState, winnerId: UUID) {
        state.winnerPlayerId = winnerId
        state.isComplete = true
        state.currentPlayerIndex = 0
    }

    /// Returns the player with the strictly lowest running total, or nil on a tie.
    private static func lowestStrokesLeader(in players: [GolfPlayerState]) -> UUID? {
        guard let minStrokes = players.map(\.runningTotal).min() else { return nil }
        let leaders = players.filter { $0.runningTotal == minStrokes }
        guard leaders.count == 1 else { return nil }
        return leaders[0].playerId
    }

    // MARK: - Segment helpers

    private static func segmentValue(_ segment: DartSegment) -> Int? {
        switch segment {
        case let .oneToTwenty(value): return value
        default: return nil
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
