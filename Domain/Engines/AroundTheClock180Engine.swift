import Foundation

/// ATC-180 point-per-dart values for the current number.
/// Treble = 3, single = 1, double = 1 (poor throw), miss = 0.
private enum ATC180DartScore: Int {
    case miss = 0
    case singleOrDouble = 1
    case treble = 3
}

public struct MatchConfigAroundTheClock180: Codable, Equatable, Sendable {
    public static let currentPayloadVersion = 1

    public let payloadVersion: Int
    /// Optional solo par target (e.g. 60 / 75 / 80). `nil` means beat-your-best.
    public let parScore: Int?

    public init(
        payloadVersion: Int = currentPayloadVersion,
        parScore: Int? = nil
    ) {
        self.payloadVersion = payloadVersion
        if let p = parScore {
            self.parScore = max(0, min(180, p))
        } else {
            self.parScore = nil
        }
    }
}

/// One dart within a turn event, stored for replay and history display.
public struct AroundTheClock180DartEvent: Codable, Equatable, Sendable {
    public let dartOrder: Int
    public let segmentRaw: String
    public let multiplierRaw: String
    public let pointsAwarded: Int
    public let wasMiss: Bool
    public let hitTarget: Bool

    public init(
        dartOrder: Int,
        segmentRaw: String,
        multiplierRaw: String,
        pointsAwarded: Int,
        wasMiss: Bool,
        hitTarget: Bool
    ) {
        self.dartOrder = dartOrder
        self.segmentRaw = segmentRaw
        self.multiplierRaw = multiplierRaw
        self.pointsAwarded = pointsAwarded
        self.wasMiss = wasMiss
        self.hitTarget = hitTarget
    }
}

/// One submitted visit (3 darts on one number). Conforms to `Identifiable` for
/// event-sourced replay and history timeline use.
public struct AroundTheClock180TurnEvent: Codable, Equatable, Identifiable, Sendable {
    public let payloadVersion: Int
    public let id: UUID
    public let playerId: UUID
    public let turnIndex: Int
    /// The number (1–20) that was targeted this visit.
    public let number: Int
    public let pointsThisVisit: Int
    public let cumulativePointsAfterTurn: Int
    public let darts: [AroundTheClock180DartEvent]
    public let timestamp: Date
}

public struct AroundTheClock180PlayerState: Codable, Equatable, Sendable {
    public let playerId: UUID
    public var cumulativePoints: Int

    public init(playerId: UUID, cumulativePoints: Int = 0) {
        self.playerId = playerId
        self.cumulativePoints = cumulativePoints
    }
}

public struct AroundTheClock180State: Codable, Equatable, Sendable {
    public let config: MatchConfigAroundTheClock180
    public var players: [AroundTheClock180PlayerState]
    public var currentPlayerIndex: Int
    public var turnIndex: Int
    /// The number currently being targeted (1–20).
    public var currentNumber: Int
    public var winnerPlayerId: UUID?
    public var isComplete: Bool

    public init(
        config: MatchConfigAroundTheClock180,
        players: [AroundTheClock180PlayerState],
        currentPlayerIndex: Int = 0,
        turnIndex: Int = 0,
        currentNumber: Int = 1,
        winnerPlayerId: UUID? = nil,
        isComplete: Bool = false
    ) {
        self.config = config
        self.players = players
        self.currentPlayerIndex = currentPlayerIndex
        self.turnIndex = turnIndex
        self.currentNumber = currentNumber
        self.winnerPlayerId = winnerPlayerId
        self.isComplete = isComplete
    }
}

public struct AroundTheClock180TurnOutcome: Sendable {
    public let updatedState: AroundTheClock180State
    public let event: AroundTheClock180TurnEvent
}

/// Engine for 180 Around the Clock — 3 darts per number 1–20, scoring
/// treble = 3 / single = 1 / double = 1 / miss = 0. Perfect total = 180.
public enum AroundTheClock180Engine {
    public static let totalNumbers = 20
    public static let dartsPerNumber = 3
    public static let perfectScore = 180

    // MARK: - Initialisation

    public static func makeInitialState(
        config: MatchConfigAroundTheClock180,
        playerIds: [UUID]
    ) throws -> AroundTheClock180State {
        guard !playerIds.isEmpty else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.players.minimum"
            )
        }
        let players = playerIds.map { AroundTheClock180PlayerState(playerId: $0) }
        return AroundTheClock180State(
            config: config,
            players: players
        )
    }

    // MARK: - Turn submission

    public static func submitTurn(
        state: AroundTheClock180State,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> AroundTheClock180TurnOutcome {
        guard !state.isComplete else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.completed"
            )
        }
        guard darts.count <= dartsPerNumber else {
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
        let target = updated.currentNumber
        var dartEvents: [AroundTheClock180DartEvent] = []
        var visitPoints = 0

        for (offset, dart) in darts.enumerated() {
            let pts = score(dart, target: target)
            visitPoints += pts
            dartEvents.append(
                AroundTheClock180DartEvent(
                    dartOrder: offset + 1,
                    segmentRaw: segmentRaw(for: dart.segment),
                    multiplierRaw: dart.multiplier.rawValue,
                    pointsAwarded: pts,
                    wasMiss: dart.isMiss,
                    hitTarget: !dart.isMiss && segmentValue(dart.segment) == target
                )
            )
        }

        updated.players[playerIndex].cumulativePoints += visitPoints
        let cumulativeAfter = updated.players[playerIndex].cumulativePoints

        let event = AroundTheClock180TurnEvent(
            payloadVersion: 1,
            id: UUID(),
            playerId: playerId,
            turnIndex: state.turnIndex,
            number: target,
            pointsThisVisit: visitPoints,
            cumulativePointsAfterTurn: cumulativeAfter,
            darts: dartEvents,
            timestamp: timestamp
        )

        advanceTurn(&updated)

        return AroundTheClock180TurnOutcome(updatedState: updated, event: event)
    }

    // MARK: - Replay

    public static func replay(
        config: MatchConfigAroundTheClock180,
        playerIds: [UUID],
        events: [AroundTheClock180TurnEvent]
    ) throws -> AroundTheClock180State {
        var state = try makeInitialState(config: config, playerIds: playerIds)
        for event in events {
            let darts = event.darts.map(dartInput(from:))
            state = try submitTurn(state: state, darts: darts, timestamp: event.timestamp).updatedState
        }
        return state
    }

    // MARK: - Helpers for replay reconstruction

    public static func dartInput(from event: AroundTheClock180DartEvent) -> DartInput {
        DartInput(
            multiplier: DartMultiplier(rawValue: event.multiplierRaw) ?? .single,
            segment: segment(fromRaw: event.segmentRaw),
            isMiss: event.wasMiss
        )
    }

    // MARK: - Scoring

    /// ATC-180 scoring table for a single dart: treble = 3 pts, single/double = 1 pt, miss = 0.
    private static func score(_ dart: DartInput, target: Int) -> Int {
        guard !dart.isMiss else { return ATC180DartScore.miss.rawValue }
        guard segmentValue(dart.segment) == target else { return ATC180DartScore.miss.rawValue }
        switch dart.multiplier {
        case .triple: return ATC180DartScore.treble.rawValue
        case .single, .double: return ATC180DartScore.singleOrDouble.rawValue
        }
    }

    // MARK: - Progression

    private static func advanceTurn(_ state: inout AroundTheClock180State) {
        state.turnIndex += 1
        guard !state.isComplete else { return }

        let playerCount = state.players.count
        let wasLastPlayer = state.currentPlayerIndex == playerCount - 1
        state.currentPlayerIndex = (state.currentPlayerIndex + 1) % playerCount

        guard wasLastPlayer else { return }

        // All players have completed the current number.
        let completedNumber = state.currentNumber
        if completedNumber >= totalNumbers {
            // Match complete: find leader(s).
            if let winnerId = singleLeader(in: state.players) {
                completeMatch(&state, winnerId: winnerId)
            } else {
                // Tie: no winner determined in v1 (spec defers tie-break to future).
                state.isComplete = true
                state.winnerPlayerId = nil
            }
        } else {
            state.currentNumber = completedNumber + 1
        }
    }

    private static func completeMatch(_ state: inout AroundTheClock180State, winnerId: UUID) {
        state.winnerPlayerId = winnerId
        state.isComplete = true
        state.currentPlayerIndex = 0
    }

    private static func singleLeader(in players: [AroundTheClock180PlayerState]) -> UUID? {
        guard let maxPts = players.map(\.cumulativePoints).max() else { return nil }
        let leaders = players.filter { $0.cumulativePoints == maxPts }
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
