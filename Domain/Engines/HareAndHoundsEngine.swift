import Foundation

// MARK: - Enums

/// The two roles in a Hare and Hounds match.
public enum HareAndHoundsRole: String, Codable, CaseIterable, Sendable {
    case hare
    case hound
}

/// The starting position for the Hound (setup option).
public enum HoundStartPosition: String, Codable, CaseIterable, Sendable {
    case segment5
    case segment12

    public var displayName: String {
        switch self {
        case .segment5: L10n.string("play.hareAndHounds.setup.houndStart.segment5")
        case .segment12: L10n.string("play.hareAndHounds.setup.houndStart.segment12")
        }
    }
}

// MARK: - Config

/// Serialisable configuration for a Hare and Hounds match.
public struct MatchConfigHareAndHounds: Codable, Equatable, Sendable {
    public static let currentPayloadVersion = 1

    /// The clockwise dartboard order starting from 20.
    /// 20→1→18→4→13→6→10→15→2→17→3→19→7→16→8→11→14→9→12→5 (then back to 20).
    public static let clockwiseCourse: [Int] = [20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5]

    public let payloadVersion: Int
    public let houndStartRaw: String

    public var houndStart: HoundStartPosition {
        HoundStartPosition(rawValue: houndStartRaw) ?? .segment5
    }

    public init(
        payloadVersion: Int = currentPayloadVersion,
        houndStart: HoundStartPosition = .segment5
    ) {
        self.payloadVersion = payloadVersion
        self.houndStartRaw = houndStart.rawValue
    }
}

// MARK: - Events

/// Immutable record of a single visit in a Hare and Hounds match.
public struct HareAndHoundsTurnEvent: Codable, Equatable, Identifiable, Sendable {
    public let payloadVersion: Int
    public let id: UUID
    public let playerId: UUID
    public let turnIndex: Int
    public let role: HareAndHoundsRole
    public let positionBefore: Int
    public let positionAfter: Int
    /// Set when this turn results in a win; describes the win reason.
    public let winReason: HareAndHoundsWinReason?
    public let timestamp: Date

    public init(
        payloadVersion: Int = 1,
        id: UUID,
        playerId: UUID,
        turnIndex: Int,
        role: HareAndHoundsRole,
        positionBefore: Int,
        positionAfter: Int,
        winReason: HareAndHoundsWinReason?,
        timestamp: Date
    ) {
        self.payloadVersion = payloadVersion
        self.id = id
        self.playerId = playerId
        self.turnIndex = turnIndex
        self.role = role
        self.positionBefore = positionBefore
        self.positionAfter = positionAfter
        self.winReason = winReason
        self.timestamp = timestamp
    }
}

/// Reason a player won the match.
public enum HareAndHoundsWinReason: String, Codable, Sendable {
    /// Hare completed the full clockwise circuit back to index 0 (segment 20).
    case hareLapComplete
    /// Hound reached or passed the Hare's position index.
    case houndOvertook
}

// MARK: - State

/// Per-player mutable state for Hare and Hounds.
public struct HareAndHoundsPlayerState: Codable, Equatable, Sendable {
    public let playerId: UUID
    public let role: HareAndHoundsRole
    /// Index into `MatchConfigHareAndHounds.clockwiseCourse` (0 = segment 20).
    public var positionIndex: Int

    /// The current target segment value.
    public var currentSegment: Int {
        MatchConfigHareAndHounds.clockwiseCourse[positionIndex]
    }

    public init(playerId: UUID, role: HareAndHoundsRole, positionIndex: Int) {
        self.playerId = playerId
        self.role = role
        self.positionIndex = positionIndex
    }
}

/// Complete mutable game state for a Hare and Hounds match.
public struct HareAndHoundsState: Codable, Equatable, Sendable {
    public let config: MatchConfigHareAndHounds
    public var players: [HareAndHoundsPlayerState]
    public var currentPlayerIndex: Int
    public var turnIndex: Int
    public var winnerPlayerId: UUID?
    public var winReason: HareAndHoundsWinReason?
    public var isComplete: Bool

    /// Total segments in the course.
    public static let courseLength = MatchConfigHareAndHounds.clockwiseCourse.count

    public init(
        config: MatchConfigHareAndHounds,
        players: [HareAndHoundsPlayerState],
        currentPlayerIndex: Int = 0,
        turnIndex: Int = 0,
        winnerPlayerId: UUID? = nil,
        winReason: HareAndHoundsWinReason? = nil,
        isComplete: Bool = false
    ) {
        self.config = config
        self.players = players
        self.currentPlayerIndex = currentPlayerIndex
        self.turnIndex = turnIndex
        self.winnerPlayerId = winnerPlayerId
        self.winReason = winReason
        self.isComplete = isComplete
    }

    /// The Hare's player state.
    public var harePlayer: HareAndHoundsPlayerState? {
        players.first { $0.role == .hare }
    }

    /// The Hound's player state.
    public var houndPlayer: HareAndHoundsPlayerState? {
        players.first { $0.role == .hound }
    }
}

// MARK: - Outcome

/// Result of a submitted visit.
public struct HareAndHoundsTurnOutcome: Sendable {
    public let updatedState: HareAndHoundsState
    public let event: HareAndHoundsTurnEvent
}

// MARK: - Engine

/// Pure engine for Hare and Hounds. All state transitions are side-effect free.
///
/// **Course order (clockwise from 20):**
/// 20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5
///
/// **Role assignment (v1):** The first roster player (index 0) is the Hare;
/// the second player (index 1) is the Hound.
///
/// **Win conditions:**
/// - Hare wins by completing a full lap (advancing past index 19 back to 0, after at least
///   one full circuit). In engine terms: after advancing, positionIndex reaches courseLength
///   (20), which is normalised to 0 — a `hareLapComplete` win is triggered.
/// - Hound wins by reaching or passing the Hare's position index on the course.
public enum HareAndHoundsEngine {

    // MARK: - Public API

    public static func makeInitialState(
        config: MatchConfigHareAndHounds,
        playerIds: [UUID]
    ) throws -> HareAndHoundsState {
        guard playerIds.count == 2 else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "setup.validation.hareAndHoundsExactTwoPlayers"
            )
        }

        let hareStartIndex = 0 // segment 20
        let houndStartIndex: Int
        switch config.houndStart {
        case .segment5:
            houndStartIndex = MatchConfigHareAndHounds.clockwiseCourse.firstIndex(of: 5) ?? 19
        case .segment12:
            houndStartIndex = MatchConfigHareAndHounds.clockwiseCourse.firstIndex(of: 12) ?? 18
        }

        // v1: first player is always Hare, second is Hound.
        let players: [HareAndHoundsPlayerState] = [
            HareAndHoundsPlayerState(playerId: playerIds[0], role: .hare, positionIndex: hareStartIndex),
            HareAndHoundsPlayerState(playerId: playerIds[1], role: .hound, positionIndex: houndStartIndex),
        ]

        return HareAndHoundsState(config: config, players: players)
    }

    public static func submitTurn(
        state: HareAndHoundsState,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> HareAndHoundsTurnOutcome {
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
        let player = updated.players[playerIndex]
        let positionBefore = player.positionIndex
        let targetSegment = player.currentSegment

        // First hit on current segment advances one position clockwise.
        let didHit = darts.contains { dartHitsSegment($0, segment: targetSegment) }

        var positionAfter = positionBefore
        var winReason: HareAndHoundsWinReason? = nil

        if didHit {
            let newIndex = positionBefore + 1
            if newIndex >= HareAndHoundsState.courseLength {
                // Hare completed the circuit.
                if player.role == .hare {
                    positionAfter = HareAndHoundsState.courseLength // sentinel; normalised to 0 on store
                    updated.players[playerIndex].positionIndex = 0
                    winReason = .hareLapComplete
                    completeMatch(&updated, winnerId: player.playerId, reason: .hareLapComplete)
                } else {
                    // Hound completed the course (wraps — unusual but safe).
                    updated.players[playerIndex].positionIndex = 0
                    positionAfter = 0
                }
            } else {
                updated.players[playerIndex].positionIndex = newIndex
                positionAfter = newIndex
            }

            // Check Hound-overtake win (only if not already completed by Hare lap).
            if !updated.isComplete {
                winReason = checkOvertake(&updated)
            }
        }

        let event = HareAndHoundsTurnEvent(
            id: UUID(),
            playerId: player.playerId,
            turnIndex: state.turnIndex,
            role: player.role,
            positionBefore: positionBefore,
            positionAfter: positionAfter == HareAndHoundsState.courseLength ? 0 : positionAfter,
            winReason: winReason ?? updated.winReason,
            timestamp: timestamp
        )

        if !updated.isComplete {
            advanceTurn(&updated)
        }

        return HareAndHoundsTurnOutcome(updatedState: updated, event: event)
    }

    public static func replay(
        config: MatchConfigHareAndHounds,
        playerIds: [UUID],
        events: [HareAndHoundsTurnEvent]
    ) throws -> HareAndHoundsState {
        var state = try makeInitialState(config: config, playerIds: playerIds)
        for event in events {
            guard let playerIndex = state.players.firstIndex(where: { $0.playerId == event.playerId })
            else { continue }
            state.players[playerIndex].positionIndex = event.positionAfter
            state.turnIndex += 1
            if let reason = event.winReason {
                let winnerId = event.playerId
                completeMatch(&state, winnerId: winnerId, reason: reason)
            } else {
                let playerCount = state.players.count
                state.currentPlayerIndex = (playerIndex + 1) % playerCount
            }
        }
        return state
    }

    // MARK: - Helpers

    /// Returns `true` if the dart hits the given segment value.
    static func dartHitsSegment(_ dart: DartInput, segment: Int) -> Bool {
        guard !dart.isMiss else { return false }
        guard case let .oneToTwenty(value) = dart.segment else { return false }
        return value == segment
    }

    /// Checks whether the Hound has reached or passed the Hare after a position update.
    /// Mutates state and returns the win reason if a win occurred.
    @discardableResult
    private static func checkOvertake(_ updated: inout HareAndHoundsState) -> HareAndHoundsWinReason? {
        guard let hareIndex = updated.harePlayer?.positionIndex,
              let hound = updated.houndPlayer else { return nil }
        let houndIndex = hound.positionIndex
        let courseLength = HareAndHoundsState.courseLength
        let chaseDistance = (hareIndex - houndIndex + courseLength) % courseLength
        guard chaseDistance == 0 else { return nil }
        completeMatch(&updated, winnerId: hound.playerId, reason: .houndOvertook)
        return .houndOvertook
    }

    private static func advanceTurn(_ state: inout HareAndHoundsState) {
        state.turnIndex += 1
        let playerCount = state.players.count
        state.currentPlayerIndex = (state.currentPlayerIndex + 1) % playerCount
    }

    private static func completeMatch(
        _ state: inout HareAndHoundsState,
        winnerId: UUID,
        reason: HareAndHoundsWinReason
    ) {
        state.winnerPlayerId = winnerId
        state.winReason = reason
        state.isComplete = true
        state.currentPlayerIndex = 0
        state.turnIndex += 1
    }
}
