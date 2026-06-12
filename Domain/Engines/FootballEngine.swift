import Foundation

/// Kickoff mode: how a player completes the kickoff phase.
public enum FootballKickoffMode: String, Codable, CaseIterable, Sendable {
    /// One hit on inner or outer bull completes kickoff (default).
    case singleBull
    /// Two outer-bull hits (or one inner bull) complete kickoff.
    case twoOuterBulls

    public var displayName: String {
        switch self {
        case .singleBull: L10n.string("play.football.setup.kickoffMode.singleBull")
        case .twoOuterBulls: L10n.string("play.football.setup.kickoffMode.twoOuterBulls")
        }
    }
}

/// Config payload for a Football match (v1).
public struct MatchConfigFootball: Codable, Equatable, Sendable {
    public static let currentPayloadVersion = 1

    public let payloadVersion: Int
    public let goalsToWin: Int
    public let kickoffModeRaw: String

    public var kickoffMode: FootballKickoffMode {
        FootballKickoffMode(rawValue: kickoffModeRaw) ?? .singleBull
    }

    public init(
        payloadVersion: Int = currentPayloadVersion,
        goalsToWin: Int = 10,
        kickoffMode: FootballKickoffMode = .singleBull
    ) {
        self.payloadVersion = payloadVersion
        self.goalsToWin = max(1, min(50, goalsToWin))
        self.kickoffModeRaw = kickoffMode.rawValue
    }
}

/// Recorded data for a single dart within a Football visit.
public struct FootballDartEvent: Codable, Equatable, Sendable {
    public let dartOrder: Int
    public let segmentRaw: String
    public let multiplierRaw: String
    /// True when this dart completed the kickoff phase for the player.
    public let completedKickoff: Bool
    /// Number of goals this dart contributed (0 or 1).
    public let goalsAdded: Int

    public init(
        dartOrder: Int,
        segmentRaw: String,
        multiplierRaw: String,
        completedKickoff: Bool,
        goalsAdded: Int
    ) {
        self.dartOrder = dartOrder
        self.segmentRaw = segmentRaw
        self.multiplierRaw = multiplierRaw
        self.completedKickoff = completedKickoff
        self.goalsAdded = goalsAdded
    }
}

/// Immutable event emitted once per submitted turn.
public struct FootballTurnEvent: Codable, Equatable, Identifiable, Sendable {
    public let payloadVersion: Int
    public let id: UUID
    public let playerId: UUID
    public let turnIndex: Int
    public let legIndex: Int?
    /// Phase at the start of this turn (before any dart processing).
    public let phaseRaw: String
    /// Whether kickoff was completed during this turn.
    public let kickoffAchieved: Bool
    /// Goals scored in this turn.
    public let goalsAdded: Int
    /// Cumulative goals after this turn.
    public let goalsAfterTurn: Int
    public let darts: [FootballDartEvent]
    public let timestamp: Date

    public var effectiveLegIndex: Int { legIndex ?? 0 }
}

/// Per-player mutable state.
public struct FootballPlayerState: Codable, Equatable, Sendable {
    public let playerId: UUID
    public var kickoffComplete: Bool
    /// Progress toward kickoff when twoOuterBulls mode: counts outer-bull hits (0, 1, or 2).
    public var kickoffProgress: Int
    public var goals: Int

    public init(
        playerId: UUID,
        kickoffComplete: Bool = false,
        kickoffProgress: Int = 0,
        goals: Int = 0
    ) {
        self.playerId = playerId
        self.kickoffComplete = kickoffComplete
        self.kickoffProgress = kickoffProgress
        self.goals = goals
    }
}

/// Match-level mutable state.
public struct FootballState: Codable, Equatable, Sendable {
    public let config: MatchConfigFootball
    public var players: [FootballPlayerState]
    public var currentPlayerIndex: Int
    public var turnIndex: Int
    public var winnerPlayerId: UUID?
    public var isComplete: Bool

    public init(
        config: MatchConfigFootball,
        players: [FootballPlayerState],
        currentPlayerIndex: Int,
        turnIndex: Int,
        winnerPlayerId: UUID? = nil,
        isComplete: Bool = false
    ) {
        self.config = config
        self.players = players
        self.currentPlayerIndex = currentPlayerIndex
        self.turnIndex = turnIndex
        self.winnerPlayerId = winnerPlayerId
        self.isComplete = isComplete
    }
}

/// Return value of `FootballEngine.submitTurn`.
public struct FootballTurnOutcome: Sendable {
    public let updatedState: FootballState
    public let event: FootballTurnEvent
}

// MARK: - Engine

/// Pure-functional rules engine for Football.
///
/// Phase 1 — Kickoff: hit inner or outer bull (two outer bulls when `kickoffMode == .twoOuterBulls`).
/// Phase 2 — Scoring: each double scores 1 goal; bull counts as a double and can score repeatedly.
/// First player to `goalsToWin` wins.
public enum FootballEngine {

    public static func makeInitialState(
        config: MatchConfigFootball,
        playerIds: [UUID]
    ) throws -> FootballState {
        guard config.goalsToWin > 0 else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.football.invalidGoalsToWin"
            )
        }
        guard playerIds.count == 2 else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "setup.validation.footballExactTwoPlayers"
            )
        }
        let players = playerIds.map { FootballPlayerState(playerId: $0) }
        return FootballState(
            config: config,
            players: players,
            currentPlayerIndex: 0,
            turnIndex: 0
        )
    }

    public static func submitTurn(
        state: FootballState,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> FootballTurnOutcome {
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

        let phaseRaw = updated.players[playerIndex].kickoffComplete ? "scoring" : "kickoff"
        var dartEvents: [FootballDartEvent] = []
        var kickoffAchieved = false
        var goalsThisTurn = 0

        for (offset, dart) in darts.enumerated() {
            var completedKickoffThisDart = false
            var goalsThisDart = 0

            if !updated.players[playerIndex].kickoffComplete {
                // Kickoff phase: only bull hits count.
                if isBull(dart) {
                    let progress = updated.players[playerIndex].kickoffProgress
                    switch updated.config.kickoffMode {
                    case .singleBull:
                        updated.players[playerIndex].kickoffComplete = true
                        completedKickoffThisDart = true
                        kickoffAchieved = true
                    case .twoOuterBulls:
                        // Inner bull counts as completing immediately; outer bull needs 2 hits.
                        if dart.segment == .innerBull {
                            updated.players[playerIndex].kickoffComplete = true
                            completedKickoffThisDart = true
                            kickoffAchieved = true
                        } else {
                            // outerBull
                            let newProgress = progress + 1
                            updated.players[playerIndex].kickoffProgress = newProgress
                            if newProgress >= 2 {
                                updated.players[playerIndex].kickoffComplete = true
                                completedKickoffThisDart = true
                                kickoffAchieved = true
                            }
                        }
                    }
                }
                // Non-bull darts during kickoff: no effect but still recorded.
            } else {
                // Scoring phase: doubles (and bull) score 1 goal each.
                if isGoal(dart) {
                    goalsThisDart = 1
                    goalsThisTurn += 1
                    updated.players[playerIndex].goals += 1
                }
            }

            dartEvents.append(
                FootballDartEvent(
                    dartOrder: offset + 1,
                    segmentRaw: segmentRaw(for: dart.segment),
                    multiplierRaw: dart.multiplier.rawValue,
                    completedKickoff: completedKickoffThisDart,
                    goalsAdded: goalsThisDart
                )
            )
        }

        let goalsAfter = updated.players[playerIndex].goals
        let winnerId = playerId

        if goalsAfter >= updated.config.goalsToWin {
            completeMatch(&updated, winnerId: winnerId)
        }

        if !updated.isComplete {
            advanceTurn(&updated)
        } else {
            updated.turnIndex += 1
        }

        let event = FootballTurnEvent(
            payloadVersion: 1,
            id: UUID(),
            playerId: playerId,
            turnIndex: state.turnIndex,
            legIndex: goalsAfter,
            phaseRaw: phaseRaw,
            kickoffAchieved: kickoffAchieved,
            goalsAdded: goalsThisTurn,
            goalsAfterTurn: goalsAfter,
            darts: dartEvents,
            timestamp: timestamp
        )
        return FootballTurnOutcome(updatedState: updated, event: event)
    }

    public static func replay(
        config: MatchConfigFootball,
        playerIds: [UUID],
        events: [FootballTurnEvent]
    ) throws -> FootballState {
        var state = try makeInitialState(config: config, playerIds: playerIds)
        for event in events {
            let darts = event.darts.map(dartInput(from:))
            state = try submitTurn(state: state, darts: darts, timestamp: event.timestamp).updatedState
        }
        return state
    }

    public static func dartInput(from event: FootballDartEvent) -> DartInput {
        DartInput(
            multiplier: DartMultiplier(rawValue: event.multiplierRaw) ?? .single,
            segment: segment(fromRaw: event.segmentRaw),
            isMiss: event.segmentRaw == "miss"
        )
    }

    // MARK: - Helpers

    /// Returns true when a dart is a bull hit (inner or outer, non-miss).
    static func isBull(_ dart: DartInput) -> Bool {
        guard !dart.isMiss else { return false }
        return dart.segment == .outerBull || dart.segment == .innerBull
    }

    /// Returns true when a dart scores a goal (double on 1–20, or any bull hit).
    static func isGoal(_ dart: DartInput) -> Bool {
        guard !dart.isMiss else { return false }
        switch dart.segment {
        case .innerBull, .outerBull:
            return true
        case .oneToTwenty:
            return dart.multiplier == .double
        case .miss:
            return false
        }
    }

    private static func advanceTurn(_ state: inout FootballState) {
        state.turnIndex += 1
        let playerCount = state.players.count
        state.currentPlayerIndex = (state.currentPlayerIndex + 1) % playerCount
    }

    private static func completeMatch(_ state: inout FootballState, winnerId: UUID) {
        state.winnerPlayerId = winnerId
        state.isComplete = true
        state.currentPlayerIndex = 0
    }

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
