import Foundation

public enum CricketTarget: String, CaseIterable, Codable, Sendable {
    case t20 = "20"
    case t19 = "19"
    case t18 = "18"
    case t17 = "17"
    case t16 = "16"
    case t15 = "15"
    case bull

    public var points: Int {
        switch self {
        case .bull:
            return 25
        case let target:
            return Int(target.rawValue) ?? 0
        }
    }
}

public struct CricketDartTouch: Codable, Equatable, Sendable {
    public let dartOrder: Int
    public let targetRaw: String
    public let multiplierRaw: String
    public let marksAdded: Int
    public let overflowMarks: Int
    public let pointsAdded: Int
    public let wasMiss: Bool
    /// The precise dart segment (e.g. "innerBull"/"outerBull"/"20"/"miss").
    /// `targetRaw` collapses both bulls to "bull", which is lossy for replay;
    /// this preserves the distinction so resume/undo are deterministic.
    /// Optional so historical events that predate the field still decode.
    public let segmentRaw: String?

    public init(
        dartOrder: Int,
        targetRaw: String,
        multiplierRaw: String,
        marksAdded: Int,
        overflowMarks: Int,
        pointsAdded: Int,
        wasMiss: Bool,
        segmentRaw: String? = nil
    ) {
        self.dartOrder = dartOrder
        self.targetRaw = targetRaw
        self.multiplierRaw = multiplierRaw
        self.marksAdded = marksAdded
        self.overflowMarks = overflowMarks
        self.pointsAdded = pointsAdded
        self.wasMiss = wasMiss
        self.segmentRaw = segmentRaw
    }
}

public struct CricketTurnEvent: Codable, Equatable, Identifiable, Sendable {
    public let payloadVersion: Int
    public let id: UUID
    public let playerId: UUID
    public let turnIndex: Int
    public let roundIndex: Int
    public let totalPointsAdded: Int
    public let targetsTouched: [CricketDartTouch]
    public let timestamp: Date
}

public struct CricketPlayerState: Codable, Equatable, Sendable {
    public let playerId: UUID
    public var score: Int
    public var marks: [String: Int]
}

public struct CricketState: Codable, Equatable, Sendable {
    public let config: MatchConfigCricket
    public var players: [CricketPlayerState]
    public var currentPlayerIndex: Int
    public var roundIndex: Int
    public var turnIndex: Int
    public var winnerPlayerId: UUID?
    public var isComplete: Bool
}

public struct CricketTurnOutcome: Sendable {
    public let updatedState: CricketState
    public let event: CricketTurnEvent
}

public enum CricketEngine {
    public static func makeInitialState(config: MatchConfigCricket, playerIds: [UUID]) throws -> CricketState {
        guard playerIds.count >= 2 else {
            throw AppError(code: .validationFailed, layer: .domain, severity: .warning, isRecoverable: true, userMessageKey: "error.match.players.minimum")
        }
        let marksSeed = Dictionary(uniqueKeysWithValues: CricketTarget.allCases.map { ($0.rawValue, 0) })
        let players = playerIds.map { CricketPlayerState(playerId: $0, score: 0, marks: marksSeed) }
        return CricketState(
            config: config,
            players: players,
            currentPlayerIndex: 0,
            roundIndex: 0,
            turnIndex: 0,
            winnerPlayerId: nil,
            isComplete: false
        )
    }

    public static func submitTurn(
        state: CricketState,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> CricketTurnOutcome {
        guard !state.isComplete else {
            throw AppError(code: .invalidGameState, layer: .domain, severity: .warning, isRecoverable: true, userMessageKey: "error.match.completed")
        }
        guard darts.count <= 3 else {
            throw AppError(code: .validationFailed, layer: .domain, severity: .warning, isRecoverable: true, userMessageKey: "error.turn.maxDarts")
        }

        var updated = state
        let playerIndex = updated.currentPlayerIndex
        let playerId = updated.players[playerIndex].playerId
        var touches: [CricketDartTouch] = []
        var totalPointsAdded = 0

        for (offset, dart) in darts.enumerated() {
            let order = offset + 1
            guard let targetRaw = dart.segment.cricketTargetRaw, let target = cricketTarget(from: targetRaw) else {
                touches.append(
                    CricketDartTouch(
                        dartOrder: order,
                        targetRaw: "miss",
                        multiplierRaw: dart.multiplier.rawValue,
                        marksAdded: 0,
                        overflowMarks: 0,
                        pointsAdded: 0,
                        wasMiss: true,
                        segmentRaw: segmentRaw(for: dart.segment)
                    )
                )
                continue
            }

            let incomingMarks = marksForCricket(dart: dart)
            let beforeMarks = updated.players[playerIndex].marks[target.rawValue] ?? 0
            let neededToClose = max(0, 3 - beforeMarks)
            let marksAdded = min(neededToClose, incomingMarks)
            let overflow = max(0, incomingMarks - marksAdded)
            updated.players[playerIndex].marks[target.rawValue] = min(3, beforeMarks + incomingMarks)

            let pointsAdded = overflowPoints(
                target: target,
                overflowMarks: overflow,
                actingPlayerIndex: playerIndex,
                state: updated
            )
            updated.players[playerIndex].score += pointsAdded
            totalPointsAdded += pointsAdded

            touches.append(
                CricketDartTouch(
                    dartOrder: order,
                    targetRaw: target.rawValue,
                    multiplierRaw: dart.multiplier.rawValue,
                    marksAdded: marksAdded,
                    overflowMarks: overflow,
                    pointsAdded: pointsAdded,
                    wasMiss: dart.isMiss,
                    segmentRaw: segmentRaw(for: dart.segment)
                )
            )
        }

        if isPlayerClosedAllTargets(updated.players[playerIndex]) &&
            updated.players[playerIndex].score >= updated.players.map(\.score).max() ?? 0 {
            updated.isComplete = true
            updated.winnerPlayerId = playerId
        }

        if !updated.isComplete {
            updated.currentPlayerIndex = (playerIndex + 1) % updated.players.count
            if updated.currentPlayerIndex == 0 {
                updated.roundIndex += 1
            }
        }
        updated.turnIndex += 1

        let event = CricketTurnEvent(
            payloadVersion: 1,
            id: UUID(),
            playerId: playerId,
            turnIndex: state.turnIndex,
            roundIndex: state.roundIndex,
            totalPointsAdded: totalPointsAdded,
            targetsTouched: touches,
            timestamp: timestamp
        )
        return CricketTurnOutcome(updatedState: updated, event: event)
    }

    public static func replay(
        config: MatchConfigCricket,
        playerIds: [UUID],
        events: [CricketTurnEvent]
    ) throws -> CricketState {
        var state = try makeInitialState(config: config, playerIds: playerIds)
        for event in events {
            let darts = event.targetsTouched.map(dartInput(from:))
            state = try submitTurn(state: state, darts: darts, timestamp: event.timestamp).updatedState
        }
        return state
    }

    /// Reconstructs the original `DartInput` from a persisted touch.
    /// Prefers the precise `segmentRaw` (so inner vs outer bull survives);
    /// falls back to the lossy target mapping only for legacy events.
    public static func dartInput(from touch: CricketDartTouch) -> DartInput {
        let multiplier = DartMultiplier(rawValue: touch.multiplierRaw) ?? .single
        let segment = touch.segmentRaw.map(segment(fromRaw:)) ?? parseTargetToSegment(touch.targetRaw)
        return DartInput(multiplier: multiplier, segment: segment, isMiss: touch.wasMiss)
    }

    private static func marksForCricket(dart: DartInput) -> Int {
        guard !dart.isMiss else { return 0 }
        switch dart.segment {
        case .innerBull:
            return 2
        case .outerBull:
            return 1
        case .oneToTwenty:
            return dart.multiplier.markValue
        case .miss:
            return 0
        }
    }

    private static func overflowPoints(
        target: CricketTarget,
        overflowMarks: Int,
        actingPlayerIndex: Int,
        state: CricketState
    ) -> Int {
        guard overflowMarks > 0 else { return 0 }
        let anyOpponentOpen = state.players.enumerated().contains { index, player in
            guard index != actingPlayerIndex else { return false }
            return (player.marks[target.rawValue] ?? 0) < 3
        }
        guard anyOpponentOpen else { return 0 }
        return overflowMarks * target.points
    }

    private static func isPlayerClosedAllTargets(_ player: CricketPlayerState) -> Bool {
        CricketTarget.allCases.allSatisfy { (player.marks[$0.rawValue] ?? 0) >= 3 }
    }

    private static func cricketTarget(from raw: String) -> CricketTarget? {
        CricketTarget(rawValue: raw)
    }

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

    private static func parseTargetToSegment(_ raw: String) -> DartSegment {
        switch raw {
        case "bull":
            return .outerBull
        default:
            if let value = Int(raw), (15 ... 20).contains(value) {
                return .oneToTwenty(value)
            }
            return .miss
        }
    }
}
