import Foundation

/// The seven targets visited in sequence: 20 → 19 → 18 → 17 → 16 → 15 → bull.
public let americanCricketTargets: [CricketTarget] = [.t20, .t19, .t18, .t17, .t16, .t15, .bull]

public struct MatchConfigAmericanCricket: Codable, Equatable, Sendable {
    public static let currentPayloadVersion = 1

    public let payloadVersion: Int
    /// Raw value stored so new rulesets survive forward-compat decode.
    public let rulesetRaw: String
    public let pointsEnabled: Bool

    public var ruleset: String { rulesetRaw }

    public init(
        payloadVersion: Int = currentPayloadVersion,
        ruleset: String = "american_cricket_sequential",
        pointsEnabled: Bool = true
    ) {
        self.payloadVersion = payloadVersion
        self.rulesetRaw = ruleset
        self.pointsEnabled = pointsEnabled
    }
}

// MARK: - Events

public struct AmericanCricketDartEvent: Codable, Equatable, Sendable {
    public let dartOrder: Int
    public let segmentRaw: String
    public let multiplierRaw: String
    /// Marks contributed toward closing the active target (0 when miss or
    /// dart lands off the active target).
    public let marksAdded: Int
    /// Marks that overflowed the close threshold (used for scoring).
    public let overflowMarks: Int
    public let pointsAdded: Int
    public let wasMiss: Bool

    public init(
        dartOrder: Int,
        segmentRaw: String,
        multiplierRaw: String,
        marksAdded: Int,
        overflowMarks: Int,
        pointsAdded: Int,
        wasMiss: Bool
    ) {
        self.dartOrder = dartOrder
        self.segmentRaw = segmentRaw
        self.multiplierRaw = multiplierRaw
        self.marksAdded = marksAdded
        self.overflowMarks = overflowMarks
        self.pointsAdded = pointsAdded
        self.wasMiss = wasMiss
    }
}

public struct AmericanCricketTurnEvent: Codable, Equatable, Identifiable, Sendable {
    public let payloadVersion: Int
    public let id: UUID
    public let playerId: UUID
    public let turnIndex: Int
    /// The active target index (0…6) at the *start* of this turn.
    public let activeTargetIndex: Int
    /// The active target index at the *end* of this turn (may have advanced).
    public let activeTargetIndexAfter: Int
    public let totalPointsAdded: Int
    public let darts: [AmericanCricketDartEvent]
    public let timestamp: Date

    public var effectiveLegIndex: Int { 0 }
}

// MARK: - State

public struct AmericanCricketPlayerState: Codable, Equatable, Sendable {
    public let playerId: UUID
    /// Cumulative marks on each target, keyed by CricketTarget.rawValue.
    public var marks: [String: Int]
    public var cumulativePoints: Int

    public init(playerId: UUID, marks: [String: Int] = [:], cumulativePoints: Int = 0) {
        self.playerId = playerId
        self.marks = marks
        self.cumulativePoints = cumulativePoints
    }
}

public struct AmericanCricketState: Codable, Equatable, Sendable {
    public let config: MatchConfigAmericanCricket
    public var players: [AmericanCricketPlayerState]
    public var currentPlayerIndex: Int
    public var turnIndex: Int
    /// Index into `americanCricketTargets` (0 = 20 … 6 = bull).
    public var activeTargetIndex: Int
    public var winnerPlayerId: UUID?
    public var isComplete: Bool

    public var activeTarget: CricketTarget {
        americanCricketTargets[activeTargetIndex]
    }

    public init(
        config: MatchConfigAmericanCricket,
        players: [AmericanCricketPlayerState],
        currentPlayerIndex: Int = 0,
        turnIndex: Int = 0,
        activeTargetIndex: Int = 0,
        winnerPlayerId: UUID? = nil,
        isComplete: Bool = false
    ) {
        self.config = config
        self.players = players
        self.currentPlayerIndex = currentPlayerIndex
        self.turnIndex = turnIndex
        self.activeTargetIndex = activeTargetIndex
        self.winnerPlayerId = winnerPlayerId
        self.isComplete = isComplete
    }
}

public struct AmericanCricketTurnOutcome: Sendable {
    public let updatedState: AmericanCricketState
    public let event: AmericanCricketTurnEvent
}

// MARK: - Engine

/// Pure value-type engine for American Cricket.
///
/// Targets are visited in order 20→19→18→17→16→15→bull.
/// A player closes the active target with 3 cumulative marks; after closing,
/// overflow marks score face-value points while any opponent has not yet closed.
/// When **all** players have closed the active target the game advances to the
/// next. The game ends once the bull sequence resolves; highest points wins.
public enum AmericanCricketEngine {

    public static func makeInitialState(
        config: MatchConfigAmericanCricket,
        playerIds: [UUID]
    ) throws -> AmericanCricketState {
        guard playerIds.count >= 2 else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.players.minimum"
            )
        }
        let marksSeed = Dictionary(uniqueKeysWithValues: CricketTarget.allCases.map { ($0.rawValue, 0) })
        let players = playerIds.map { AmericanCricketPlayerState(playerId: $0, marks: marksSeed) }
        return AmericanCricketState(config: config, players: players)
    }

    public static func submitTurn(
        state: AmericanCricketState,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> AmericanCricketTurnOutcome {
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
        let activeTarget = updated.activeTarget
        var dartEvents: [AmericanCricketDartEvent] = []
        var totalPointsAdded = 0

        for (offset, dart) in darts.enumerated() {
            let order = offset + 1
            let segRaw = segmentRaw(for: dart.segment)

            // Only hits on the active target are meaningful.
            guard !dart.isMiss, isOnActiveTarget(dart: dart, target: activeTarget) else {
                dartEvents.append(AmericanCricketDartEvent(
                    dartOrder: order,
                    segmentRaw: segRaw,
                    multiplierRaw: dart.multiplier.rawValue,
                    marksAdded: 0,
                    overflowMarks: 0,
                    pointsAdded: 0,
                    wasMiss: dart.isMiss || !isOnActiveTarget(dart: dart, target: activeTarget)
                ))
                continue
            }

            let incoming = marksForDart(dart: dart)
            let before = updated.players[playerIndex].marks[activeTarget.rawValue] ?? 0
            let neededToClose = max(0, 3 - before)
            let marksAdded = min(neededToClose, incoming)
            let overflow = max(0, incoming - marksAdded)
            updated.players[playerIndex].marks[activeTarget.rawValue] = min(3, before + incoming)

            var pointsAdded = 0
            if overflow > 0, updated.config.pointsEnabled {
                let anyOpponentOpen = updated.players.enumerated().contains { idx, player in
                    guard idx != playerIndex else { return false }
                    return (player.marks[activeTarget.rawValue] ?? 0) < 3
                }
                if anyOpponentOpen {
                    pointsAdded = overflow * pointValuePerMark(target: activeTarget, dart: dart)
                    updated.players[playerIndex].cumulativePoints += pointsAdded
                }
            }

            totalPointsAdded += pointsAdded
            dartEvents.append(AmericanCricketDartEvent(
                dartOrder: order,
                segmentRaw: segRaw,
                multiplierRaw: dart.multiplier.rawValue,
                marksAdded: marksAdded,
                overflowMarks: overflow,
                pointsAdded: pointsAdded,
                wasMiss: false
            ))
        }

        // After applying darts, check whether to advance the active target.
        let activeTargetIndexBefore = updated.activeTargetIndex
        maybeAdvanceTarget(&updated)

        // Advance turn.
        updated.currentPlayerIndex = (playerIndex + 1) % updated.players.count
        updated.turnIndex += 1

        // Check end of game (all targets including bull resolved).
        if updated.isComplete == false, updated.activeTargetIndex > americanCricketTargets.count - 1 {
            resolveWinner(&updated)
        }

        let event = AmericanCricketTurnEvent(
            payloadVersion: 1,
            id: UUID(),
            playerId: playerId,
            turnIndex: state.turnIndex,
            activeTargetIndex: activeTargetIndexBefore,
            activeTargetIndexAfter: updated.activeTargetIndex,
            totalPointsAdded: totalPointsAdded,
            darts: dartEvents,
            timestamp: timestamp
        )
        return AmericanCricketTurnOutcome(updatedState: updated, event: event)
    }

    public static func replay(
        config: MatchConfigAmericanCricket,
        playerIds: [UUID],
        events: [AmericanCricketTurnEvent]
    ) throws -> AmericanCricketState {
        var state = try makeInitialState(config: config, playerIds: playerIds)
        for event in events {
            let darts = event.darts.map(dartInput(from:))
            state = try submitTurn(state: state, darts: darts, timestamp: event.timestamp).updatedState
        }
        return state
    }

    /// Reconstructs the original `DartInput` from a persisted dart event.
    public static func dartInput(from event: AmericanCricketDartEvent) -> DartInput {
        let multiplier = DartMultiplier(rawValue: event.multiplierRaw) ?? .single
        let segment = segment(fromRaw: event.segmentRaw)
        return DartInput(multiplier: multiplier, segment: segment, isMiss: event.wasMiss)
    }

    // MARK: - Target advancement

    /// Advances `activeTargetIndex` while all players have closed the current target.
    /// Also resolves winner when the final target (bull) is fully closed.
    private static func maybeAdvanceTarget(_ state: inout AmericanCricketState) {
        while state.activeTargetIndex < americanCricketTargets.count {
            let target = americanCricketTargets[state.activeTargetIndex]
            let allClosed = state.players.allSatisfy { ($0.marks[target.rawValue] ?? 0) >= 3 }
            guard allClosed else { break }
            state.activeTargetIndex += 1
        }
        if state.activeTargetIndex >= americanCricketTargets.count {
            resolveWinner(&state)
        }
    }

    private static func resolveWinner(_ state: inout AmericanCricketState) {
        guard let maxPoints = state.players.map(\.cumulativePoints).max() else { return }
        let leaders = state.players.filter { $0.cumulativePoints == maxPoints }
        // Tie: no single winner — game is complete but winnerPlayerId remains nil.
        if leaders.count == 1 {
            state.winnerPlayerId = leaders[0].playerId
        }
        state.isComplete = true
    }

    // MARK: - Helpers

    private static func isOnActiveTarget(dart: DartInput, target: CricketTarget) -> Bool {
        switch target {
        case .bull:
            return dart.segment == .outerBull || dart.segment == .innerBull
        case .t20, .t19, .t18, .t17, .t16, .t15:
            guard let value = Int(target.rawValue) else { return false }
            if case let .oneToTwenty(v) = dart.segment { return v == value }
            return false
        }
    }

    /// Marks contributed by a single dart toward the active target.
    private static func marksForDart(dart: DartInput) -> Int {
        guard !dart.isMiss else { return 0 }
        switch dart.segment {
        case .innerBull: return 2
        case .outerBull: return 1
        case .oneToTwenty: return dart.multiplier.markValue
        case .miss: return 0
        }
    }

    /// Points value per overflow mark.  For bulls each hit uses its own face value
    /// (outerBull = 25, innerBull = 50); for numbers it's the target value per mark.
    private static func pointValuePerMark(target: CricketTarget, dart: DartInput) -> Int {
        switch target {
        case .bull:
            // Each overflow mark's point value equals the hit's own face value.
            switch dart.segment {
            case .innerBull: return 50
            case .outerBull: return 25
            default: return 25
            }
        default:
            return target.points
        }
    }

    static func segmentRaw(for segment: DartSegment) -> String {
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
