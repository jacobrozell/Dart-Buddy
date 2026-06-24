import Foundation

// MARK: - Config

public enum PressTargetCaller: String, Codable, CaseIterable, Sendable {
    case random
    case opponent
}

public struct MatchConfigPress: Codable, Equatable, Sendable {
    public static let currentPayloadVersion = 1
    /// Bank values at each ladder step (single → double → triple). Per spec the
    /// bank value REPLACES the round value when the next step is reached, so a
    /// triple-hit round always banks 7, not 1 + 3 + 7.
    public static let ladderBankValues: [Int] = [1, 3, 7]
    public static let allowedPointsToWin: [Int] = [30, 50, 100]

    public let payloadVersion: Int
    public let pointsToWin: Int
    public let targetCallerRaw: String

    public var targetCaller: PressTargetCaller {
        PressTargetCaller(rawValue: targetCallerRaw) ?? .random
    }

    public init(
        payloadVersion: Int = currentPayloadVersion,
        pointsToWin: Int = 50,
        targetCaller: PressTargetCaller = .random
    ) {
        self.payloadVersion = payloadVersion
        self.pointsToWin = pointsToWin
        self.targetCallerRaw = targetCaller.rawValue
    }
}

// MARK: - Turn state machine

public enum PressTurnPhase: String, Codable, Sendable {
    /// Caller still needs to choose a segment for this player's turn.
    case awaitingCall
    /// Segment chosen; player must throw at the current ladder step.
    case awaitingDart
    /// Player just hit the current step and must choose bank or press.
    case decision
}

// MARK: - Events and state

public enum PressTurnResolution: String, Codable, Sendable {
    case banked
    case bust
    case autoBanked  // triple hit, no press possible
}

public struct PressTurnEvent: Codable, Equatable, Identifiable, Sendable {
    public let payloadVersion: Int
    public let id: UUID
    public let playerId: UUID
    public let turnIndex: Int
    public let calledSegment: Int
    public let stepsAchieved: Int       // 0 = bust at step 0, 1 = single, 2 = double, 3 = triple
    public let pointsBanked: Int
    public let scoreAfter: Int
    public let resolution: PressTurnResolution
    public let matchCompleted: Bool
    public let timestamp: Date

    public init(
        payloadVersion: Int = 1,
        id: UUID = UUID(),
        playerId: UUID,
        turnIndex: Int,
        calledSegment: Int,
        stepsAchieved: Int,
        pointsBanked: Int,
        scoreAfter: Int,
        resolution: PressTurnResolution,
        matchCompleted: Bool,
        timestamp: Date
    ) {
        self.payloadVersion = payloadVersion
        self.id = id
        self.playerId = playerId
        self.turnIndex = turnIndex
        self.calledSegment = calledSegment
        self.stepsAchieved = stepsAchieved
        self.pointsBanked = pointsBanked
        self.scoreAfter = scoreAfter
        self.resolution = resolution
        self.matchCompleted = matchCompleted
        self.timestamp = timestamp
    }
}

public struct PressPlayerState: Codable, Equatable, Sendable {
    public let playerId: UUID
    public var score: Int

    public init(playerId: UUID, score: Int = 0) {
        self.playerId = playerId
        self.score = score
    }
}

public struct PressState: Codable, Equatable, Sendable {
    public let config: MatchConfigPress
    public var players: [PressPlayerState]
    public var currentPlayerIndex: Int
    public var turnIndex: Int
    public var phase: PressTurnPhase
    /// Segment 1…20 called for the active turn (nil while `phase == .awaitingCall`).
    public var calledSegment: Int?
    /// 0-based ladder step the player is about to attempt (the next required hit).
    public var ladderStep: Int
    /// Points pending bank — `0` until the first hit; replaced with the new
    /// step's bank value each time the player advances.
    public var roundValue: Int
    public var winnerPlayerId: UUID?
    public var isComplete: Bool

    public init(
        config: MatchConfigPress,
        players: [PressPlayerState],
        currentPlayerIndex: Int = 0,
        turnIndex: Int = 0,
        phase: PressTurnPhase = .awaitingCall,
        calledSegment: Int? = nil,
        ladderStep: Int = 0,
        roundValue: Int = 0,
        winnerPlayerId: UUID? = nil,
        isComplete: Bool = false
    ) {
        self.config = config
        self.players = players
        self.currentPlayerIndex = currentPlayerIndex
        self.turnIndex = turnIndex
        self.phase = phase
        self.calledSegment = calledSegment
        self.ladderStep = ladderStep
        self.roundValue = roundValue
        self.winnerPlayerId = winnerPlayerId
        self.isComplete = isComplete
    }

    public var currentPlayerId: UUID { players[currentPlayerIndex].playerId }
}

public struct PressDartOutcome: Sendable {
    public let updatedState: PressState
    /// Set only on bust / auto-bank — the turn ended with the dart.
    public let event: PressTurnEvent?
}

public struct PressBankOutcome: Sendable {
    public let updatedState: PressState
    public let event: PressTurnEvent
}

// MARK: - Engine

public enum PressEngine {

    public static func makeInitialState(
        config: MatchConfigPress,
        playerIds: [UUID]
    ) throws -> PressState {
        guard (2 ... 4).contains(playerIds.count) else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "setup.validation.pressPlayerCount"
            )
        }
        guard MatchConfigPress.allowedPointsToWin.contains(config.pointsToWin) else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "setup.validation.pressPointsToWin"
            )
        }
        let players = playerIds.map { PressPlayerState(playerId: $0) }
        return PressState(config: config, players: players)
    }

    /// Set the called segment (1…20) for the current player's turn.
    public static func callSegment(
        state: PressState,
        segment: Int
    ) throws -> PressState {
        guard !state.isComplete else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.completed"
            )
        }
        guard state.phase == .awaitingCall else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.press.callOutOfPhase"
            )
        }
        guard (1 ... 20).contains(segment) else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.press.invalidSegment"
            )
        }
        var updated = state
        updated.calledSegment = segment
        updated.phase = .awaitingDart
        updated.ladderStep = 0
        updated.roundValue = 0
        return updated
    }

    /// Throw a dart at the current ladder step.
    /// - On hit at step 0 or 1: advances to `.decision`.
    /// - On hit at step 2 (triple): auto-banks 7, ends the turn.
    /// - On miss at any step: bust, ends the turn with 0 added.
    public static func submitDart(
        state: PressState,
        dart: DartInput,
        timestamp: Date = Date()
    ) throws -> PressDartOutcome {
        guard !state.isComplete else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.completed"
            )
        }
        guard state.phase == .awaitingDart else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.press.dartOutOfPhase"
            )
        }
        guard let segment = state.calledSegment else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.press.missingSegment"
            )
        }

        var updated = state
        let stepBefore = state.ladderStep
        let requiredMultiplier = requiredMultiplier(forStep: stepBefore)
        let isHit = dart.isHit(segment: segment, multiplier: requiredMultiplier)

        if !isHit {
            // Bust: lose the round value, end turn.
            let event = endTurn(
                state: &updated,
                playerId: state.currentPlayerId,
                stepsAchieved: stepBefore,
                pointsBanked: 0,
                resolution: .bust,
                timestamp: timestamp
            )
            return PressDartOutcome(updatedState: updated, event: event)
        }

        // Hit: update round value to this step's bank value.
        updated.roundValue = MatchConfigPress.ladderBankValues[stepBefore]

        if stepBefore == MatchConfigPress.ladderBankValues.count - 1 {
            // Triple-hit: auto-bank.
            let event = endTurn(
                state: &updated,
                playerId: state.currentPlayerId,
                stepsAchieved: stepBefore + 1,
                pointsBanked: updated.roundValue,
                resolution: .autoBanked,
                timestamp: timestamp
            )
            return PressDartOutcome(updatedState: updated, event: event)
        }

        updated.ladderStep = stepBefore + 1
        updated.phase = .decision
        return PressDartOutcome(updatedState: updated, event: nil)
    }

    /// Bank the current round value and end the turn.
    public static func bank(
        state: PressState,
        timestamp: Date = Date()
    ) throws -> PressBankOutcome {
        guard !state.isComplete else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.completed"
            )
        }
        guard state.phase == .decision else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.press.bankOutOfPhase"
            )
        }
        var updated = state
        let event = endTurn(
            state: &updated,
            playerId: state.currentPlayerId,
            stepsAchieved: state.ladderStep,   // ladderStep was advanced past the last hit
            pointsBanked: state.roundValue,
            resolution: .banked,
            timestamp: timestamp
        )
        return PressBankOutcome(updatedState: updated, event: event)
    }

    /// Continue climbing the ladder (next dart targets the next multiplier).
    public static func press(state: PressState) throws -> PressState {
        guard !state.isComplete else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.completed"
            )
        }
        guard state.phase == .decision else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.press.pressOutOfPhase"
            )
        }
        var updated = state
        updated.phase = .awaitingDart
        return updated
    }

    public static func replay(
        config: MatchConfigPress,
        playerIds: [UUID],
        events: [PressTurnEvent]
    ) throws -> PressState {
        var state = try makeInitialState(config: config, playerIds: playerIds)
        for event in events {
            if let idx = state.players.firstIndex(where: { $0.playerId == event.playerId }) {
                state.players[idx].score = event.scoreAfter
            }
            state.turnIndex += 1
            if event.matchCompleted {
                state.isComplete = true
                state.winnerPlayerId = event.playerId
            } else {
                state.currentPlayerIndex = (state.currentPlayerIndex + 1) % state.players.count
                state.phase = .awaitingCall
                state.calledSegment = nil
                state.ladderStep = 0
                state.roundValue = 0
            }
        }
        return state
    }

    // MARK: - Helpers

    public static func requiredMultiplier(forStep step: Int) -> DartMultiplier {
        switch step {
        case 0: return .single
        case 1: return .double
        default: return .triple
        }
    }

    /// Bank value the player would receive if they stopped at the *current*
    /// step (i.e. just hit it). Returns `0` before the first hit.
    public static func currentRoundValue(state: PressState) -> Int {
        state.roundValue
    }

    private static func endTurn(
        state: inout PressState,
        playerId: UUID,
        stepsAchieved: Int,
        pointsBanked: Int,
        resolution: PressTurnResolution,
        timestamp: Date
    ) -> PressTurnEvent {
        let segment = state.calledSegment ?? 0
        let turnIndex = state.turnIndex
        let idx = state.currentPlayerIndex
        state.players[idx].score += pointsBanked
        let scoreAfter = state.players[idx].score
        let matchCompleted = scoreAfter >= state.config.pointsToWin

        state.turnIndex += 1
        if matchCompleted {
            state.isComplete = true
            state.winnerPlayerId = playerId
        } else {
            state.currentPlayerIndex = (idx + 1) % state.players.count
            state.phase = .awaitingCall
            state.calledSegment = nil
            state.ladderStep = 0
            state.roundValue = 0
        }

        return PressTurnEvent(
            playerId: playerId,
            turnIndex: turnIndex,
            calledSegment: segment,
            stepsAchieved: stepsAchieved,
            pointsBanked: pointsBanked,
            scoreAfter: scoreAfter,
            resolution: resolution,
            matchCompleted: matchCompleted,
            timestamp: timestamp
        )
    }
}

// MARK: - DartInput convenience

private extension DartInput {
    func isHit(segment: Int, multiplier: DartMultiplier) -> Bool {
        guard !isMiss else { return false }
        guard case let .oneToTwenty(value) = self.segment else { return false }
        return value == segment && self.multiplier == multiplier
    }
}
