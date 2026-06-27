import Foundation

// MARK: - Hit type

/// Where on the board the dart landed for Prisoner scoring. The richer enum is
/// necessary because `DartInput` cannot distinguish inner-single from
/// outer-single, and Prisoner cares about that ring. UI callers translate user
/// input into this enum; a best-effort `from(_:)` adapter is provided for
/// callers that only have a `DartInput`.
public enum PrisonerDartHit: Codable, Equatable, Hashable, Sendable {
    /// Triple, outer-single, or double on a numbered segment 1…20.
    case playable(segment: Int)
    /// Inner single (between bull and triple ring) on a numbered segment 1…20.
    case innerSingle(segment: Int)
    /// Any bull (inner or outer); tracked as segment 25.
    case bull
    /// Outside-double or bounce-out — dart stays on board for one turn.
    case outsideDouble
}

public extension PrisonerDartHit {
    /// Best-effort interpretation from a `DartInput`. Cannot distinguish
    /// inner-single from outer-single rings — all S/D/T hits become `.playable`.
    static func from(_ dart: DartInput) -> PrisonerDartHit {
        if dart.isMiss { return .outsideDouble }
        switch dart.segment {
        case .innerBull, .outerBull: return .bull
        case .miss: return .outsideDouble
        case let .oneToTwenty(n): return .playable(segment: n)
        }
    }
}

// MARK: - Config

public struct MatchConfigPrisoner: Codable, Equatable, Sendable {
    public static let currentPayloadVersion = 1
    public static let basePoolSize = 3
    /// Standard dartboard clockwise order starting from segment 1.
    public static let clockwiseSequence: [Int] = [
        1, 18, 4, 13, 6, 10, 15, 2, 17, 3,
        19, 7, 16, 8, 11, 14, 9, 12, 5, 20,
    ]
    public static let bullSegment = 25

    public let payloadVersion: Int

    public init(payloadVersion: Int = currentPayloadVersion) {
        self.payloadVersion = payloadVersion
    }
}

// MARK: - State

public struct PrisonerOnBoard: Codable, Equatable, Hashable, Sendable {
    public let segment: Int          // 1…20 or 25 (bull)
    public let ownerPlayerId: UUID

    public init(segment: Int, ownerPlayerId: UUID) {
        self.segment = segment
        self.ownerPlayerId = ownerPlayerId
    }
}

public struct PrisonerPlayerState: Codable, Equatable, Sendable {
    public let playerId: UUID
    /// 0…20 — index into `clockwiseSequence`. 20 means the player has finished.
    public var progressIndex: Int
    /// Total darts the player owns (starts at 3; ±1 on prisoner mechanics).
    public var pool: Int
    /// Darts left on the board from the previous visit; unavailable this visit.
    /// Recovered after this visit ends.
    public var stuckOnBoard: Int

    public init(
        playerId: UUID,
        progressIndex: Int = 0,
        pool: Int = MatchConfigPrisoner.basePoolSize,
        stuckOnBoard: Int = 0
    ) {
        self.playerId = playerId
        self.progressIndex = progressIndex
        self.pool = pool
        self.stuckOnBoard = stuckOnBoard
    }

    public var currentTarget: Int? {
        guard progressIndex < MatchConfigPrisoner.clockwiseSequence.count else { return nil }
        return MatchConfigPrisoner.clockwiseSequence[progressIndex]
    }

    public var hasFinished: Bool {
        progressIndex >= MatchConfigPrisoner.clockwiseSequence.count
    }
}

public struct PrisonerVisitEvent: Codable, Equatable, Identifiable, Sendable {
    public let payloadVersion: Int
    public let id: UUID
    public let playerId: UUID
    public let turnIndex: Int
    public let progressIndexBefore: Int
    public let progressIndexAfter: Int
    public let prisonersCreated: [Int]
    public let prisonersCaptured: [Int]
    public let dartsLost: Int
    public let poolAfter: Int
    public let hits: [PrisonerDartHit]
    public let matchCompleted: Bool
    public let timestamp: Date

    public init(
        payloadVersion: Int = 1,
        id: UUID = UUID(),
        playerId: UUID,
        turnIndex: Int,
        progressIndexBefore: Int,
        progressIndexAfter: Int,
        prisonersCreated: [Int],
        prisonersCaptured: [Int],
        dartsLost: Int,
        poolAfter: Int,
        hits: [PrisonerDartHit],
        matchCompleted: Bool,
        timestamp: Date
    ) {
        self.payloadVersion = payloadVersion
        self.id = id
        self.playerId = playerId
        self.turnIndex = turnIndex
        self.progressIndexBefore = progressIndexBefore
        self.progressIndexAfter = progressIndexAfter
        self.prisonersCreated = prisonersCreated
        self.prisonersCaptured = prisonersCaptured
        self.dartsLost = dartsLost
        self.poolAfter = poolAfter
        self.hits = hits
        self.matchCompleted = matchCompleted
        self.timestamp = timestamp
    }
}

public struct PrisonerState: Codable, Equatable, Sendable {
    public let config: MatchConfigPrisoner
    public var players: [PrisonerPlayerState]
    public var currentPlayerIndex: Int
    public var turnIndex: Int
    public var prisoners: [PrisonerOnBoard]
    public var winnerPlayerId: UUID?
    public var isComplete: Bool

    public init(
        config: MatchConfigPrisoner,
        players: [PrisonerPlayerState],
        currentPlayerIndex: Int = 0,
        turnIndex: Int = 0,
        prisoners: [PrisonerOnBoard] = [],
        winnerPlayerId: UUID? = nil,
        isComplete: Bool = false
    ) {
        self.config = config
        self.players = players
        self.currentPlayerIndex = currentPlayerIndex
        self.turnIndex = turnIndex
        self.prisoners = prisoners
        self.winnerPlayerId = winnerPlayerId
        self.isComplete = isComplete
    }

    public var currentPlayer: PrisonerPlayerState { players[currentPlayerIndex] }

    /// Darts the current player may throw this visit (pool minus darts
    /// currently stuck on the board from their previous visit).
    public var dartsAvailableThisVisit: Int {
        max(0, currentPlayer.pool - currentPlayer.stuckOnBoard)
    }
}

public struct PrisonerVisitOutcome: Sendable {
    public let updatedState: PrisonerState
    public let event: PrisonerVisitEvent
}

// MARK: - Engine

public enum PrisonerEngine {

    public static func makeInitialState(
        config: MatchConfigPrisoner,
        playerIds: [UUID]
    ) throws -> PrisonerState {
        guard playerIds.count >= 2, playerIds.count <= 8 else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "setup.validation.prisonerMinimumPlayers"
            )
        }
        let players = playerIds.map { PrisonerPlayerState(playerId: $0) }
        return PrisonerState(config: config, players: players)
    }

    public static func submitVisit(
        state: PrisonerState,
        hits: [PrisonerDartHit],
        timestamp: Date = Date()
    ) throws -> PrisonerVisitOutcome {
        guard !state.isComplete else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.completed"
            )
        }
        let allowed = state.dartsAvailableThisVisit
        guard hits.count <= allowed else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.prisoner.tooManyDarts"
            )
        }

        var updated = state
        let playerIndex = state.currentPlayerIndex
        let playerId = updated.players[playerIndex].playerId
        let progressBefore = updated.players[playerIndex].progressIndex

        var prisonersCreated: [Int] = []
        var prisonersCaptured: [Int] = []
        var dartsLost = 0

        for hit in hits {
            // Player already finished — remaining darts have no effect.
            if updated.players[playerIndex].hasFinished { break }

            switch hit {
            case let .playable(segment):
                if segment == updated.players[playerIndex].currentTarget {
                    updated.players[playerIndex].progressIndex += 1
                }
                // Capture one prisoner on the segment if any exist.
                if let idx = updated.prisoners.firstIndex(where: { $0.segment == segment }) {
                    updated.prisoners.remove(at: idx)
                    updated.players[playerIndex].pool += 1
                    prisonersCaptured.append(segment)
                }
            case let .innerSingle(segment):
                let owner = updated.players[playerIndex].playerId
                updated.prisoners.append(PrisonerOnBoard(segment: segment, ownerPlayerId: owner))
                updated.players[playerIndex].pool -= 1
                prisonersCreated.append(segment)
            case .bull:
                // Per spec: bull captures bull prisoners. If a bull prisoner
                // exists, capture it; otherwise the dart becomes a new bull
                // prisoner.
                let bullSegment = MatchConfigPrisoner.bullSegment
                if let idx = updated.prisoners.firstIndex(where: { $0.segment == bullSegment }) {
                    updated.prisoners.remove(at: idx)
                    updated.players[playerIndex].pool += 1
                    prisonersCaptured.append(bullSegment)
                } else {
                    let owner = updated.players[playerIndex].playerId
                    updated.prisoners.append(PrisonerOnBoard(segment: bullSegment, ownerPlayerId: owner))
                    updated.players[playerIndex].pool -= 1
                    prisonersCreated.append(bullSegment)
                }
            case .outsideDouble:
                dartsLost += 1
            }
        }

        // Previous-visit stuck darts are recovered; new losses become next
        // visit's stuck pool. Pool itself is unchanged by stuck mechanics.
        updated.players[playerIndex].stuckOnBoard = dartsLost

        let progressAfter = updated.players[playerIndex].progressIndex
        let poolAfter = updated.players[playerIndex].pool

        updated.turnIndex += 1

        let matchCompleted = updated.players[playerIndex].hasFinished
        if matchCompleted {
            updated.isComplete = true
            updated.winnerPlayerId = playerId
        } else {
            updated.currentPlayerIndex = (playerIndex + 1) % updated.players.count
        }

        let event = PrisonerVisitEvent(
            playerId: playerId,
            turnIndex: state.turnIndex,
            progressIndexBefore: progressBefore,
            progressIndexAfter: progressAfter,
            prisonersCreated: prisonersCreated,
            prisonersCaptured: prisonersCaptured,
            dartsLost: dartsLost,
            poolAfter: poolAfter,
            hits: hits,
            matchCompleted: matchCompleted,
            timestamp: timestamp
        )
        return PrisonerVisitOutcome(updatedState: updated, event: event)
    }

    public static func replay(
        config: MatchConfigPrisoner,
        playerIds: [UUID],
        events: [PrisonerVisitEvent]
    ) throws -> PrisonerState {
        var state = try makeInitialState(config: config, playerIds: playerIds)
        for event in events {
            state = try submitVisit(state: state, hits: event.hits, timestamp: event.timestamp).updatedState
        }
        return state
    }

    // MARK: - Helpers

    /// Convenience wrapper for callers working with `DartInput` only.
    public static func submitVisit(
        state: PrisonerState,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> PrisonerVisitOutcome {
        let hits = darts.map(PrisonerDartHit.from)
        return try submitVisit(state: state, hits: hits, timestamp: timestamp)
    }
}
