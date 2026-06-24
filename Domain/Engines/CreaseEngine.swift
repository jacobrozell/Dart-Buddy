import Foundation

// MARK: - Config

public struct MatchConfigCrease: Codable, Equatable, Sendable {
    public static let currentPayloadVersion = 1
    public static let allowedRoundsPerSide: [Int] = [3, 5, 7]
    /// Pool of segments the keeper may block — doubles 1…20 and the bull (D25).
    public static let blockPool: [Int] = Array(1 ... 20) + [25]
    /// Block-variety threshold: keepers must use this many distinct blocks
    /// before they may repeat.
    public static let varietyResetThreshold = 5

    public let payloadVersion: Int
    public let roundsPerSide: Int
    public let blockVarietyRule: Bool

    public init(
        payloadVersion: Int = currentPayloadVersion,
        roundsPerSide: Int = 5,
        blockVarietyRule: Bool = true
    ) {
        self.payloadVersion = payloadVersion
        self.roundsPerSide = roundsPerSide
        self.blockVarietyRule = blockVarietyRule
    }
}

// MARK: - State

public enum CreasePhase: String, Codable, Sendable {
    case awaitingBlock
    case awaitingShot
}

public enum CreaseShotResult: String, Codable, Sendable {
    case goal
    case save
    case miss
}

public struct CreasePlayerState: Codable, Equatable, Sendable {
    public let playerId: UUID
    public var goals: Int
    public var blockedHistory: Set<Int>

    public init(playerId: UUID, goals: Int = 0, blockedHistory: Set<Int> = []) {
        self.playerId = playerId
        self.goals = goals
        self.blockedHistory = blockedHistory
    }
}

public struct CreaseShotEvent: Codable, Equatable, Identifiable, Sendable {
    public let payloadVersion: Int
    public let id: UUID
    public let roundIndex: Int
    public let shooterId: UUID
    public let keeperId: UUID
    public let blockedDouble: Int
    public let resultRaw: String
    public let scoresAfter: [UUID: Int]
    public let suddenDeath: Bool
    public let matchCompleted: Bool
    public let timestamp: Date

    public var result: CreaseShotResult {
        CreaseShotResult(rawValue: resultRaw) ?? .miss
    }

    public init(
        payloadVersion: Int = 1,
        id: UUID = UUID(),
        roundIndex: Int,
        shooterId: UUID,
        keeperId: UUID,
        blockedDouble: Int,
        result: CreaseShotResult,
        scoresAfter: [UUID: Int],
        suddenDeath: Bool,
        matchCompleted: Bool,
        timestamp: Date
    ) {
        self.payloadVersion = payloadVersion
        self.id = id
        self.roundIndex = roundIndex
        self.shooterId = shooterId
        self.keeperId = keeperId
        self.blockedDouble = blockedDouble
        self.resultRaw = result.rawValue
        self.scoresAfter = scoresAfter
        self.suddenDeath = suddenDeath
        self.matchCompleted = matchCompleted
        self.timestamp = timestamp
    }
}

public struct CreaseState: Codable, Equatable, Sendable {
    public let config: MatchConfigCrease
    public var players: [CreasePlayerState]
    /// Round index, 0…∞. Rounds 0…2·roundsPerSide-1 are regulation; later
    /// rounds are sudden death.
    public var roundIndex: Int
    public var phase: CreasePhase
    public var currentBlockedDouble: Int?
    public var winnerPlayerId: UUID?
    public var isComplete: Bool

    public var regulationRounds: Int { config.roundsPerSide * 2 }
    public var isSuddenDeath: Bool { roundIndex >= regulationRounds }

    /// Player at even round index 0 = players[0]; player at odd index = players[1].
    public var shooterId: UUID {
        players[roundIndex % players.count].playerId
    }
    public var keeperId: UUID {
        players[(roundIndex + 1) % players.count].playerId
    }

    public init(
        config: MatchConfigCrease,
        players: [CreasePlayerState],
        roundIndex: Int = 0,
        phase: CreasePhase = .awaitingBlock,
        currentBlockedDouble: Int? = nil,
        winnerPlayerId: UUID? = nil,
        isComplete: Bool = false
    ) {
        self.config = config
        self.players = players
        self.roundIndex = roundIndex
        self.phase = phase
        self.currentBlockedDouble = currentBlockedDouble
        self.winnerPlayerId = winnerPlayerId
        self.isComplete = isComplete
    }
}

public struct CreaseShotOutcome: Sendable {
    public let updatedState: CreaseState
    public let event: CreaseShotEvent
}

// MARK: - Engine

public enum CreaseEngine {

    public static func makeInitialState(
        config: MatchConfigCrease,
        playerIds: [UUID]
    ) throws -> CreaseState {
        guard playerIds.count == 2 else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "setup.validation.creaseExactTwoPlayers"
            )
        }
        guard MatchConfigCrease.allowedRoundsPerSide.contains(config.roundsPerSide) else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "setup.validation.creaseRoundsPerSide"
            )
        }
        let players = playerIds.map { CreasePlayerState(playerId: $0) }
        return CreaseState(config: config, players: players)
    }

    /// Picks the segment to block. Respects the variety rule when enabled.
    public static func selectBlock(
        state: CreaseState,
        segment: Int
    ) throws -> CreaseState {
        guard !state.isComplete else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.completed"
            )
        }
        guard state.phase == .awaitingBlock else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.crease.blockOutOfPhase"
            )
        }
        guard MatchConfigCrease.blockPool.contains(segment) else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.crease.invalidBlock"
            )
        }

        if state.config.blockVarietyRule {
            let keeperIndex = (state.roundIndex + 1) % state.players.count
            let history = state.players[keeperIndex].blockedHistory
            if history.count < MatchConfigCrease.varietyResetThreshold,
               history.contains(segment) {
                throw AppError(
                    code: .validationFailed,
                    layer: .domain,
                    severity: .warning,
                    isRecoverable: true,
                    userMessageKey: "error.crease.blockRepeat"
                )
            }
        }

        var updated = state
        updated.currentBlockedDouble = segment
        updated.phase = .awaitingShot
        return updated
    }

    public static func submitShot(
        state: CreaseState,
        dart: DartInput,
        timestamp: Date = Date()
    ) throws -> CreaseShotOutcome {
        guard !state.isComplete else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.completed"
            )
        }
        guard state.phase == .awaitingShot, let blocked = state.currentBlockedDouble else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.crease.shotOutOfPhase"
            )
        }

        var updated = state
        let shooterId = state.shooterId
        let keeperIndex = (state.roundIndex + 1) % state.players.count
        let keeperId = updated.players[keeperIndex].playerId
        let result = resolveShot(dart: dart, blockedSegment: blocked)

        // Record keeper's block in history, resetting if threshold hit.
        if state.config.blockVarietyRule {
            var history = updated.players[keeperIndex].blockedHistory
            history.insert(blocked)
            if history.count >= MatchConfigCrease.varietyResetThreshold {
                history.removeAll()
            }
            updated.players[keeperIndex].blockedHistory = history
        }

        if result == .goal {
            if let shooterIndex = updated.players.firstIndex(where: { $0.playerId == shooterId }) {
                updated.players[shooterIndex].goals += 1
            }
        }

        updated.roundIndex += 1
        updated.phase = .awaitingBlock
        updated.currentBlockedDouble = nil

        // Resolution after regulation or each sudden-death round.
        let matchCompleted = checkCompletion(state: &updated)

        let scoresAfter = Dictionary(uniqueKeysWithValues: updated.players.map { ($0.playerId, $0.goals) })

        let event = CreaseShotEvent(
            roundIndex: state.roundIndex,
            shooterId: shooterId,
            keeperId: keeperId,
            blockedDouble: blocked,
            result: result,
            scoresAfter: scoresAfter,
            suddenDeath: state.isSuddenDeath,
            matchCompleted: matchCompleted,
            timestamp: timestamp
        )
        return CreaseShotOutcome(updatedState: updated, event: event)
    }

    public static func replay(
        config: MatchConfigCrease,
        playerIds: [UUID],
        events: [CreaseShotEvent]
    ) throws -> CreaseState {
        var state = try makeInitialState(config: config, playerIds: playerIds)
        for event in events {
            if config.blockVarietyRule,
               let keeperIndex = state.players.firstIndex(where: { $0.playerId == event.keeperId }) {
                var history = state.players[keeperIndex].blockedHistory
                history.insert(event.blockedDouble)
                if history.count >= MatchConfigCrease.varietyResetThreshold {
                    history.removeAll()
                }
                state.players[keeperIndex].blockedHistory = history
            }
            for (id, score) in event.scoresAfter {
                if let idx = state.players.firstIndex(where: { $0.playerId == id }) {
                    state.players[idx].goals = score
                }
            }
            state.roundIndex += 1
            if event.matchCompleted {
                _ = checkCompletion(state: &state)
            }
        }
        return state
    }

    // MARK: - Helpers

    /// Determines whether the dart is a goal, save, or miss given the blocked
    /// segment. Per spec: doubles 1-20 and bull (25). Inner bull is treated
    /// as D25. Singles never score regardless of segment.
    static func resolveShot(dart: DartInput, blockedSegment: Int) -> CreaseShotResult {
        guard !dart.isMiss else { return .miss }
        switch dart.segment {
        case let .oneToTwenty(value):
            switch dart.multiplier {
            case .double, .triple:
                return value == blockedSegment ? .save : .goal
            case .single:
                return .miss
            }
        case .innerBull:
            return blockedSegment == 25 ? .save : .goal
        case .outerBull, .miss:
            return .miss
        }
    }

    @discardableResult
    private static func checkCompletion(state: inout CreaseState) -> Bool {
        guard state.roundIndex >= state.regulationRounds else { return false }
        // Regulation finished. If sudden death active, both sides must complete
        // the same pair of rounds (one shot each) before declaring a winner.
        let pairsComplete = state.roundIndex % state.players.count == 0
        guard pairsComplete else { return false }
        let scores = state.players.map(\.goals)
        guard scores.count == 2 else { return false }
        if scores[0] != scores[1] {
            state.isComplete = true
            state.winnerPlayerId = scores[0] > scores[1] ? state.players[0].playerId : state.players[1].playerId
            return true
        }
        return false
    }
}
