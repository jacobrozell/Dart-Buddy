import Foundation

public struct X01PlayerState: Codable, Equatable, Sendable {
    public let playerId: UUID
    public var remainingScore: Int
    public var legsWon: Int
    public var setsWon: Int
}

public struct X01State: Codable, Equatable, Sendable {
    public let config: MatchConfigX01
    public var players: [X01PlayerState]
    public var currentPlayerIndex: Int
    public var legIndex: Int
    public var setIndex: Int
    public var turnIndex: Int
    public var winnerPlayerId: UUID?
    public var isComplete: Bool
}

public struct X01DartEvent: Codable, Equatable, Sendable {
    public let dartOrder: Int
    public let multiplierRaw: String
    public let segmentRaw: String
    public let points: Int
    public let wasMiss: Bool
}

public struct X01TurnEvent: Codable, Equatable, Identifiable, Sendable {
    public let payloadVersion: Int
    public let id: UUID
    public let playerId: UUID
    public let turnIndex: Int
    public let legIndex: Int
    public let setIndex: Int
    public let startRemaining: Int
    public let enteredTotal: Int
    public let appliedTotal: Int
    public let endRemaining: Int
    public let isBust: Bool
    public let didCheckout: Bool
    public let checkoutModeRaw: String
    public let checkoutDartCount: Int?
    public let darts: [X01DartEvent]
    public let timestamp: Date
    /// Number of darts thrown this visit. For per-dart entry this equals
    /// `darts.count`; for total entry (no per-dart detail) it defaults to a
    /// full 3-dart visit so averages stay meaningful. Optional for backward
    /// compatibility with events persisted before this field existed.
    public let dartsThrown: Int?

    /// Darts thrown this visit, falling back to the recorded dart detail for
    /// legacy events that predate `dartsThrown`.
    public var effectiveDartsThrown: Int { dartsThrown ?? darts.count }
}

public struct X01TurnOutcome: Sendable {
    public let updatedState: X01State
    public let event: X01TurnEvent
}

public enum X01Engine {
    public static func makeInitialState(config: MatchConfigX01, playerIds: [UUID]) throws -> X01State {
        guard [301, 401, 501, 601].contains(config.startScore) else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.x01.invalidStartScore"
            )
        }
        guard config.legsToWin > 0 else {
            throw AppError(code: .validationFailed, layer: .domain, severity: .warning, isRecoverable: true, userMessageKey: "error.match.x01.invalidLegCount")
        }
        if config.setsEnabled, (config.setsToWin ?? 0) <= 0 {
            throw AppError(code: .validationFailed, layer: .domain, severity: .warning, isRecoverable: true, userMessageKey: "error.match.x01.invalidSetCount")
        }
        guard playerIds.count >= 2 else {
            throw AppError(code: .validationFailed, layer: .domain, severity: .warning, isRecoverable: true, userMessageKey: "error.match.players.minimum")
        }
        let players = playerIds.map {
            X01PlayerState(playerId: $0, remainingScore: config.startScore, legsWon: 0, setsWon: 0)
        }
        return X01State(
            config: config,
            players: players,
            currentPlayerIndex: 0,
            legIndex: 0,
            setIndex: 0,
            turnIndex: 0,
            winnerPlayerId: nil,
            isComplete: false
        )
    }

    public static func submitTurn(
        state: X01State,
        enteredTotal: Int?,
        darts: [DartInput]?,
        timestamp: Date = Date()
    ) throws -> X01TurnOutcome {
        guard !state.isComplete else {
            throw AppError(code: .invalidGameState, layer: .domain, severity: .warning, isRecoverable: true, userMessageKey: "error.match.completed")
        }
        var updated = state
        let darts = darts ?? []
        let dartTotal = darts.reduce(0) { $0 + $1.points }
        let turnTotal = enteredTotal ?? dartTotal
        if enteredTotal != nil, !darts.isEmpty, enteredTotal != dartTotal {
            throw AppError(code: .validationFailed, layer: .domain, severity: .warning, isRecoverable: true, userMessageKey: "error.turn.totalMismatch")
        }
        guard (0 ... 180).contains(turnTotal) else {
            throw AppError(code: .validationFailed, layer: .domain, severity: .warning, isRecoverable: true, userMessageKey: "error.turn.invalidTotal")
        }

        let playerIndex = updated.currentPlayerIndex
        let startRemaining = updated.players[playerIndex].remainingScore
        var isBust = false
        var didCheckout = false
        var appliedTotal = turnTotal
        var endRemaining = startRemaining - turnTotal

        if endRemaining < 0 {
            isBust = true
            appliedTotal = 0
            endRemaining = startRemaining
        } else if endRemaining == 1, updated.config.checkoutMode == .doubleOut {
            // The lowest legal double-out finish is D1 (2), so leaving exactly 1
            // can never be checked out — treat it as a bust.
            isBust = true
            appliedTotal = 0
            endRemaining = startRemaining
        } else if endRemaining == 0 {
            switch updated.config.checkoutMode {
            case .singleOut:
                didCheckout = true
            case .doubleOut:
                let finalDart = darts.last
                // With per-dart entry the finishing dart must be a double (or
                // inner bull). With total entry we have no per-dart detail, so
                // trust an exact finish — the player asserts a legal checkout.
                if darts.isEmpty || finalDart?.multiplier == .double || finalDart?.segment == .innerBull {
                    didCheckout = true
                } else {
                    isBust = true
                    appliedTotal = 0
                    endRemaining = startRemaining
                }
            }
        }

        if !isBust {
            updated.players[playerIndex].remainingScore = endRemaining
        }

        if didCheckout {
            updated.players[playerIndex].legsWon += 1
            updated.legIndex += 1
            for index in updated.players.indices {
                updated.players[index].remainingScore = updated.config.startScore
            }
            if updated.players[playerIndex].legsWon >= updated.config.legsToWin {
                if updated.config.setsEnabled {
                    updated.players[playerIndex].setsWon += 1
                    for index in updated.players.indices {
                        updated.players[index].legsWon = 0
                    }
                    updated.setIndex += 1
                    if updated.players[playerIndex].setsWon >= (updated.config.setsToWin ?? 1) {
                        updated.winnerPlayerId = updated.players[playerIndex].playerId
                        updated.isComplete = true
                    }
                } else {
                    updated.winnerPlayerId = updated.players[playerIndex].playerId
                    updated.isComplete = true
                }
            }
        }

        if !updated.isComplete {
            updated.currentPlayerIndex = (playerIndex + 1) % updated.players.count
        }
        updated.turnIndex += 1

        let dartEvents: [X01DartEvent] = darts.enumerated().map { offset, dart in
            X01DartEvent(
                dartOrder: offset + 1,
                multiplierRaw: dart.multiplier.rawValue,
                segmentRaw: segmentRaw(for: dart.segment),
                points: dart.points,
                wasMiss: dart.isMiss
            )
        }
        let event = X01TurnEvent(
            payloadVersion: 1,
            id: UUID(),
            playerId: state.players[playerIndex].playerId,
            turnIndex: state.turnIndex,
            legIndex: state.legIndex,
            setIndex: state.setIndex,
            startRemaining: startRemaining,
            enteredTotal: turnTotal,
            appliedTotal: appliedTotal,
            endRemaining: endRemaining,
            isBust: isBust,
            didCheckout: didCheckout,
            checkoutModeRaw: state.config.checkoutMode.rawValue,
            checkoutDartCount: didCheckout ? max(1, darts.count) : nil,
            darts: dartEvents,
            timestamp: timestamp,
            dartsThrown: darts.isEmpty ? 3 : darts.count
        )
        return X01TurnOutcome(updatedState: updated, event: event)
    }

    public static func replay(config: MatchConfigX01, playerIds: [UUID], events: [X01TurnEvent]) throws -> X01State {
        var state = try makeInitialState(config: config, playerIds: playerIds)
        for event in events {
            let reconstructedDarts = event.darts.map { dartEvent in
                DartInput(
                    multiplier: DartMultiplier(rawValue: dartEvent.multiplierRaw) ?? .single,
                    segment: parseSegmentRaw(dartEvent.segmentRaw),
                    isMiss: dartEvent.wasMiss
                )
            }
            state = try submitTurn(state: state, enteredTotal: event.enteredTotal, darts: reconstructedDarts, timestamp: event.timestamp).updatedState
        }
        return state
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

    private static func parseSegmentRaw(_ raw: String) -> DartSegment {
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
