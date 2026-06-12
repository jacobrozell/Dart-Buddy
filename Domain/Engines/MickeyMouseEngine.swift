import Foundation

/// The fixed descending target sequence for Mickey Mouse: 20 → 19 → 18 → 17 → 16 → 15 → 14 → 13 → 12 → Bull.
public enum MickeyMouseRuleset: String, Codable, CaseIterable, Sendable {
    case mickeyMouseRace = "mickey_mouse_race"
}

public struct MatchConfigMickeyMouse: Codable, Equatable, Sendable {
    public static let currentPayloadVersion = 1

    public let payloadVersion: Int
    public let rulesetRaw: String
    public let scoringEnabled: Bool

    public var ruleset: MickeyMouseRuleset {
        MickeyMouseRuleset(rawValue: rulesetRaw) ?? .mickeyMouseRace
    }

    public init(
        payloadVersion: Int = currentPayloadVersion,
        ruleset: MickeyMouseRuleset = .mickeyMouseRace,
        scoringEnabled: Bool = false
    ) {
        self.payloadVersion = payloadVersion
        self.rulesetRaw = ruleset.rawValue
        self.scoringEnabled = scoringEnabled
    }
}

// MARK: - Per-dart event

public struct MickeyMouseDartEvent: Codable, Equatable, Sendable {
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

// MARK: - Turn event

/// One submitted visit (up to 3 darts) by a single player.
public struct MickeyMouseTurnEvent: Codable, Equatable, Identifiable, Sendable {
    public let payloadVersion: Int
    public let id: UUID
    public let playerId: UUID
    public let turnIndex: Int
    /// Index into `MickeyMouseEngine.targets` at the start of this turn.
    public let targetIndexAtTurnStart: Int
    /// Whether the active target advanced during this turn.
    public let advancedTarget: Bool
    public let marksThisVisit: Int
    public let darts: [MickeyMouseDartEvent]
    public let timestamp: Date
}

// MARK: - Player state

public struct MickeyMousePlayerState: Codable, Equatable, Sendable {
    public let playerId: UUID
    /// Marks accumulated on each target (index matches `MickeyMouseEngine.targets`).
    public var marksByTarget: [Int]

    public init(playerId: UUID, targetCount: Int) {
        self.playerId = playerId
        self.marksByTarget = Array(repeating: 0, count: targetCount)
    }

    /// Returns true when this player has 3+ marks on target at `index`.
    public func hasClosedTarget(at index: Int) -> Bool {
        guard index < marksByTarget.count else { return false }
        return marksByTarget[index] >= 3
    }
}

// MARK: - Match state

public struct MickeyMouseState: Codable, Equatable, Sendable {
    public let config: MatchConfigMickeyMouse
    public var players: [MickeyMousePlayerState]
    public var currentPlayerIndex: Int
    public var turnIndex: Int
    /// Index into `MickeyMouseEngine.targets` — the same for all players.
    public var currentTargetIndex: Int
    public var winnerPlayerId: UUID?
    public var isComplete: Bool

    public init(
        config: MatchConfigMickeyMouse,
        players: [MickeyMousePlayerState],
        currentPlayerIndex: Int,
        turnIndex: Int,
        currentTargetIndex: Int,
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
}

// MARK: - Turn outcome

public struct MickeyMouseTurnOutcome: Sendable {
    public let updatedState: MickeyMouseState
    public let event: MickeyMouseTurnEvent
}

// MARK: - Engine

/// Pure functional engine for Mickey Mouse.
///
/// Targets descend 20→19→18→17→16→15→14→13→12→Bull.
/// Three marks close a target. S/D/T add 1/2/3 marks; outer bull = 1 mark, inner bull = 2 marks on the bull target.
/// The active target is **shared** — when any player achieves 3 marks the target advances for everyone.
/// First player to close the bull wins.
public enum MickeyMouseEngine {
    /// The fixed descending sequence, index 0 = 20, index 9 = bull.
    public static let targets: [MickeyMouseTarget] = [
        .number(20), .number(19), .number(18), .number(17), .number(16),
        .number(15), .number(14), .number(13), .number(12), .bull
    ]

    public static let marksToClose = 3
    public static let bullTargetIndex = targets.count - 1

    public static func makeInitialState(
        config: MatchConfigMickeyMouse,
        playerIds: [UUID]
    ) throws -> MickeyMouseState {
        guard playerIds.count >= 2 else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.players.minimum"
            )
        }
        let players = playerIds.map { MickeyMousePlayerState(playerId: $0, targetCount: targets.count) }
        return MickeyMouseState(
            config: config,
            players: players,
            currentPlayerIndex: 0,
            turnIndex: 0,
            currentTargetIndex: 0
        )
    }

    public static func submitTurn(
        state: MickeyMouseState,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MickeyMouseTurnOutcome {
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
        let targetIndexAtStart = updated.currentTargetIndex
        let activeTarget = targets[targetIndexAtStart]
        var dartEvents: [MickeyMouseDartEvent] = []
        var totalMarksThisVisit = 0

        for (offset, dart) in darts.enumerated() {
            let marks = marksForTarget(dart: dart, activeTarget: activeTarget)
            let hitTarget = marks > 0
            let beforeMarks = updated.players[playerIndex].marksByTarget[updated.currentTargetIndex]
            let marksToAdd = min(marks, max(0, marksToClose - beforeMarks))
            updated.players[playerIndex].marksByTarget[updated.currentTargetIndex] =
                min(marksToClose, beforeMarks + marks)
            totalMarksThisVisit += marksToAdd
            dartEvents.append(
                MickeyMouseDartEvent(
                    dartOrder: offset + 1,
                    segmentRaw: segmentRaw(for: dart.segment),
                    multiplierRaw: dart.multiplier.rawValue,
                    marksAdded: marksToAdd,
                    wasMiss: dart.isMiss,
                    hitActiveTarget: hitTarget
                )
            )
        }

        // Determine if this player just closed the current target.
        let playerNowClosed = updated.players[playerIndex].marksByTarget[updated.currentTargetIndex] >= marksToClose

        // Check if any player (including this one) has closed the current target → advance globally.
        let anyPlayerClosed = updated.players.contains {
            $0.marksByTarget[updated.currentTargetIndex] >= marksToClose
        }

        var advancedTarget = false
        if anyPlayerClosed {
            let nextIndex = updated.currentTargetIndex + 1
            if nextIndex < targets.count {
                updated.currentTargetIndex = nextIndex
                advancedTarget = true
            }
            // Bull target: if the current player just closed it, they win.
            if updated.currentTargetIndex == targets.count && playerNowClosed {
                // Player closed bull — this player wins.
                updated.winnerPlayerId = playerId
                updated.isComplete = true
            } else if updated.currentTargetIndex == targets.count {
                // Someone else already closed bull before — check if any player has
                // closed all targets (unlikely mid-turn, but safe).
            }
        }

        // Win condition: first player to close the bull (last target, index 9).
        // The bull index is bullTargetIndex = targets.count - 1.
        // After advancing, currentTargetIndex will be targets.count (out of range),
        // indicating all targets exhausted. Check directly.
        if !updated.isComplete {
            if updated.players[playerIndex].marksByTarget[bullTargetIndex] >= marksToClose {
                updated.winnerPlayerId = playerId
                updated.isComplete = true
            }
        }

        // Advance turn (player rotation).
        if !updated.isComplete {
            let playerCount = updated.players.count
            updated.currentPlayerIndex = (playerIndex + 1) % playerCount
        }
        updated.turnIndex += 1

        let event = MickeyMouseTurnEvent(
            payloadVersion: 1,
            id: UUID(),
            playerId: playerId,
            turnIndex: state.turnIndex,
            targetIndexAtTurnStart: targetIndexAtStart,
            advancedTarget: advancedTarget,
            marksThisVisit: totalMarksThisVisit,
            darts: dartEvents,
            timestamp: timestamp
        )
        return MickeyMouseTurnOutcome(updatedState: updated, event: event)
    }

    public static func replay(
        config: MatchConfigMickeyMouse,
        playerIds: [UUID],
        events: [MickeyMouseTurnEvent]
    ) throws -> MickeyMouseState {
        var state = try makeInitialState(config: config, playerIds: playerIds)
        for event in events {
            let darts = event.darts.map(dartInput(from:))
            state = try submitTurn(state: state, darts: darts, timestamp: event.timestamp).updatedState
        }
        return state
    }

    /// Reconstructs the original `DartInput` from a persisted dart event.
    public static func dartInput(from event: MickeyMouseDartEvent) -> DartInput {
        DartInput(
            multiplier: DartMultiplier(rawValue: event.multiplierRaw) ?? .single,
            segment: segment(fromRaw: event.segmentRaw),
            isMiss: event.wasMiss
        )
    }

    // MARK: - Mark resolution

    /// Returns the number of marks a dart adds on the given active target.
    /// Only darts hitting the active segment count.
    static func marksForTarget(dart: DartInput, activeTarget: MickeyMouseTarget) -> Int {
        guard !dart.isMiss else { return 0 }
        switch activeTarget {
        case let .number(value):
            guard case let .oneToTwenty(segValue) = dart.segment, segValue == value else { return 0 }
            return dart.multiplier.markValue
        case .bull:
            switch dart.segment {
            case .innerBull: return 2
            case .outerBull: return 1
            default: return 0
            }
        }
    }

    // MARK: - Segment helpers

    static func segmentRaw(for segment: DartSegment) -> String {
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

// MARK: - Target type

/// A single target in the Mickey Mouse sequence.
public enum MickeyMouseTarget: Equatable, Sendable {
    case number(Int)
    case bull

    /// Short display label used on the target strip.
    public var displayLabel: String {
        switch self {
        case let .number(value): return String(value)
        case .bull: return L10n.string("mickeyMouse.targetStrip.bull")
        }
    }

    /// Accessibility description for the target.
    public var accessibilityLabel: String {
        switch self {
        case let .number(value): return String(value)
        case .bull: return L10n.string("cricket.target.bull")
        }
    }
}
