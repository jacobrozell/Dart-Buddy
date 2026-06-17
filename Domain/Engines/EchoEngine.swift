import Foundation

// MARK: - Target and config

public enum EchoTargetKind: String, Codable, CaseIterable, Sendable {
    case singles
    case doubles
    case triples
    case mixed
}

public enum EchoVerificationMode: String, Codable, CaseIterable, Sendable {
    case opponentTap
    case companion
}

public struct EchoTarget: Codable, Equatable, Hashable, Sendable {
    public let segment: Int  // 1…20
    public let ring: PallinoRing  // reuse: .single / .double / .triple

    public init(segment: Int, ring: PallinoRing) {
        self.segment = segment
        self.ring = ring
    }
}

public struct MatchConfigEcho: Codable, Equatable, Sendable {
    public static let currentPayloadVersion = 1
    public static let allowedLives: [Int] = [3, 5]

    public let payloadVersion: Int
    public let lives: Int
    public let targetKindRaw: String
    public let verificationModeRaw: String

    public var targetKind: EchoTargetKind {
        EchoTargetKind(rawValue: targetKindRaw) ?? .doubles
    }

    public var verificationMode: EchoVerificationMode {
        EchoVerificationMode(rawValue: verificationModeRaw) ?? .opponentTap
    }

    public init(
        payloadVersion: Int = currentPayloadVersion,
        lives: Int = 3,
        targetKind: EchoTargetKind = .doubles,
        verificationMode: EchoVerificationMode = .opponentTap
    ) {
        self.payloadVersion = payloadVersion
        self.lives = lives
        self.targetKindRaw = targetKind.rawValue
        self.verificationModeRaw = verificationMode.rawValue
    }
}

// MARK: - State and events

public enum EchoPhase: String, Codable, Sendable {
    case awaitingDraw
    case awaitingVerification
}

public struct EchoPlayerState: Codable, Equatable, Sendable {
    public let playerId: UUID
    public var lives: Int

    public init(playerId: UUID, lives: Int) {
        self.playerId = playerId
        self.lives = lives
    }
}

public struct EchoRoundEvent: Codable, Equatable, Identifiable, Sendable {
    public let payloadVersion: Int
    public let id: UUID
    public let roundIndex: Int
    public let throwerId: UUID
    public let verifierId: UUID
    public let target: EchoTarget
    public let wasHit: Bool
    public let livesAfter: Int
    public let matchCompleted: Bool
    public let timestamp: Date

    public init(
        payloadVersion: Int = 1,
        id: UUID = UUID(),
        roundIndex: Int,
        throwerId: UUID,
        verifierId: UUID,
        target: EchoTarget,
        wasHit: Bool,
        livesAfter: Int,
        matchCompleted: Bool,
        timestamp: Date
    ) {
        self.payloadVersion = payloadVersion
        self.id = id
        self.roundIndex = roundIndex
        self.throwerId = throwerId
        self.verifierId = verifierId
        self.target = target
        self.wasHit = wasHit
        self.livesAfter = livesAfter
        self.matchCompleted = matchCompleted
        self.timestamp = timestamp
    }
}

public struct EchoState: Codable, Equatable, Sendable {
    public let config: MatchConfigEcho
    public var players: [EchoPlayerState]
    public var currentThrowerIndex: Int
    public var roundIndex: Int
    public var phase: EchoPhase
    public var currentTarget: EchoTarget?
    /// Pool of targets remaining in the current cycle. Refills + reshuffles
    /// on exhaustion per spec §5.2.
    public var remainingPool: [EchoTarget]
    public var winnerPlayerId: UUID?
    public var isComplete: Bool

    public var currentThrowerId: UUID { players[currentThrowerIndex].playerId }
    public var currentVerifierId: UUID {
        players[(currentThrowerIndex + 1) % players.count].playerId
    }

    public init(
        config: MatchConfigEcho,
        players: [EchoPlayerState],
        currentThrowerIndex: Int = 0,
        roundIndex: Int = 0,
        phase: EchoPhase = .awaitingDraw,
        currentTarget: EchoTarget? = nil,
        remainingPool: [EchoTarget] = [],
        winnerPlayerId: UUID? = nil,
        isComplete: Bool = false
    ) {
        self.config = config
        self.players = players
        self.currentThrowerIndex = currentThrowerIndex
        self.roundIndex = roundIndex
        self.phase = phase
        self.currentTarget = currentTarget
        self.remainingPool = remainingPool
        self.winnerPlayerId = winnerPlayerId
        self.isComplete = isComplete
    }
}

public struct EchoVerificationOutcome: Sendable {
    public let updatedState: EchoState
    public let event: EchoRoundEvent
}

// MARK: - Engine

public enum EchoEngine {

    public static func makeInitialState(
        config: MatchConfigEcho,
        playerIds: [UUID]
    ) throws -> EchoState {
        guard playerIds.count == 2 else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "setup.validation.echoExactTwoPlayers"
            )
        }
        guard MatchConfigEcho.allowedLives.contains(config.lives) else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "setup.validation.echoLives"
            )
        }
        let players = playerIds.map { EchoPlayerState(playerId: $0, lives: config.lives) }
        return EchoState(config: config, players: players)
    }

    /// Pool of every target the config can call.
    public static func fullPool(for kind: EchoTargetKind) -> [EchoTarget] {
        switch kind {
        case .singles: return (1 ... 20).map { EchoTarget(segment: $0, ring: .single) }
        case .doubles: return (1 ... 20).map { EchoTarget(segment: $0, ring: .double) }
        case .triples: return (1 ... 20).map { EchoTarget(segment: $0, ring: .triple) }
        case .mixed:
            return (1 ... 20).flatMap { n -> [EchoTarget] in
                [.single, .double, .triple].map { EchoTarget(segment: n, ring: $0) }
            }
        }
    }

    /// Draw the next target. Caller supplies the RNG so production code can use
    /// `SystemRandomNumberGenerator` while tests use a deterministic seed.
    public static func drawTarget<G: RandomNumberGenerator>(
        state: EchoState,
        using rng: inout G
    ) throws -> EchoState {
        guard !state.isComplete else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.completed"
            )
        }
        guard state.phase == .awaitingDraw else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.echo.drawOutOfPhase"
            )
        }
        var updated = state
        if updated.remainingPool.isEmpty {
            updated.remainingPool = fullPool(for: state.config.targetKind).shuffled(using: &rng)
        }
        // Remove a random remaining target. shuffling already happened on refill
        // so popping from the end gives uniform draw without repetition.
        let target = updated.remainingPool.removeLast()
        updated.currentTarget = target
        updated.phase = .awaitingVerification
        return updated
    }

    /// Convenience: set the next target explicitly (for tests / replays).
    public static func setTarget(
        state: EchoState,
        target: EchoTarget
    ) throws -> EchoState {
        guard !state.isComplete else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.completed"
            )
        }
        guard state.phase == .awaitingDraw else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.echo.drawOutOfPhase"
            )
        }
        guard (1 ... 20).contains(target.segment) else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.echo.invalidTarget"
            )
        }
        var updated = state
        updated.currentTarget = target
        updated.phase = .awaitingVerification
        return updated
    }

    /// Verifier marks the throw as a hit or miss.
    public static func submitVerification(
        state: EchoState,
        wasHit: Bool,
        timestamp: Date = Date()
    ) throws -> EchoVerificationOutcome {
        guard !state.isComplete else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.completed"
            )
        }
        guard state.phase == .awaitingVerification, let target = state.currentTarget else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.echo.verifyOutOfPhase"
            )
        }

        var updated = state
        let throwerIndex = state.currentThrowerIndex
        let throwerId = updated.players[throwerIndex].playerId
        let verifierId = updated.currentVerifierId

        if !wasHit {
            updated.players[throwerIndex].lives = max(0, updated.players[throwerIndex].lives - 1)
        }
        let livesAfter = updated.players[throwerIndex].lives

        let matchCompleted: Bool = {
            let aliveCount = updated.players.filter { $0.lives > 0 }.count
            return aliveCount <= 1
        }()

        updated.roundIndex += 1
        if matchCompleted {
            updated.isComplete = true
            updated.winnerPlayerId = updated.players.first(where: { $0.lives > 0 })?.playerId
        } else {
            updated.currentThrowerIndex = (throwerIndex + 1) % updated.players.count
            updated.phase = .awaitingDraw
            updated.currentTarget = nil
        }

        let event = EchoRoundEvent(
            roundIndex: state.roundIndex,
            throwerId: throwerId,
            verifierId: verifierId,
            target: target,
            wasHit: wasHit,
            livesAfter: livesAfter,
            matchCompleted: matchCompleted,
            timestamp: timestamp
        )
        return EchoVerificationOutcome(updatedState: updated, event: event)
    }

    public static func replay(
        config: MatchConfigEcho,
        playerIds: [UUID],
        events: [EchoRoundEvent]
    ) throws -> EchoState {
        var state = try makeInitialState(config: config, playerIds: playerIds)
        for event in events {
            if let idx = state.players.firstIndex(where: { $0.playerId == event.throwerId }) {
                state.players[idx].lives = event.livesAfter
            }
            state.roundIndex += 1
            if event.matchCompleted {
                state.isComplete = true
                state.winnerPlayerId = state.players.first(where: { $0.lives > 0 })?.playerId
                state.phase = .awaitingDraw
                state.currentTarget = nil
            } else {
                state.currentThrowerIndex = (state.currentThrowerIndex + 1) % state.players.count
                state.phase = .awaitingDraw
                state.currentTarget = nil
            }
        }
        return state
    }
}
