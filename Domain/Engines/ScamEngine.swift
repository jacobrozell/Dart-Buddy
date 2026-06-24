import Foundation

// MARK: - Roles and config

public enum ScamRole: String, Codable, CaseIterable, Sendable {
    case stopper
    case scorer
}

public struct MatchConfigScam: Codable, Equatable, Sendable {
    public static let currentPayloadVersion = 1

    public let payloadVersion: Int

    public init(payloadVersion: Int = currentPayloadVersion) {
        self.payloadVersion = payloadVersion
    }
}

// MARK: - State

/// One half = stopper closes segments while scorer collects points.
public struct ScamHalfState: Codable, Equatable, Sendable {
    public var closedSegments: Set<Int>
    public var stopperPlayerId: UUID
    public var scorerPlayerId: UUID

    public init(stopperPlayerId: UUID, scorerPlayerId: UUID) {
        self.closedSegments = []
        self.stopperPlayerId = stopperPlayerId
        self.scorerPlayerId = scorerPlayerId
    }

    public var isClosed: Bool { closedSegments.count >= 20 }
    public var highestOpenSegment: Int? {
        (1 ... 20).reversed().first { !closedSegments.contains($0) }
    }
}

public struct ScamPlayerState: Codable, Equatable, Sendable {
    public let playerId: UUID
    public var totalScore: Int

    public init(playerId: UUID, totalScore: Int = 0) {
        self.playerId = playerId
        self.totalScore = totalScore
    }
}

public struct ScamVisitEvent: Codable, Equatable, Identifiable, Sendable {
    public let payloadVersion: Int
    public let id: UUID
    public let playerId: UUID
    public let halfIndex: Int
    public let roleRaw: String
    public let segmentsClosedThisVisit: [Int]
    public let highestOpenSegmentAtVisitStart: Int?
    public let pointsAdded: Int
    public let scoreAfter: Int
    public let halfCompleted: Bool
    public let matchCompleted: Bool
    public let timestamp: Date

    public var role: ScamRole { ScamRole(rawValue: roleRaw) ?? .stopper }

    public init(
        payloadVersion: Int = 1,
        id: UUID = UUID(),
        playerId: UUID,
        halfIndex: Int,
        role: ScamRole,
        segmentsClosedThisVisit: [Int],
        highestOpenSegmentAtVisitStart: Int?,
        pointsAdded: Int,
        scoreAfter: Int,
        halfCompleted: Bool,
        matchCompleted: Bool,
        timestamp: Date
    ) {
        self.payloadVersion = payloadVersion
        self.id = id
        self.playerId = playerId
        self.halfIndex = halfIndex
        self.roleRaw = role.rawValue
        self.segmentsClosedThisVisit = segmentsClosedThisVisit
        self.highestOpenSegmentAtVisitStart = highestOpenSegmentAtVisitStart
        self.pointsAdded = pointsAdded
        self.scoreAfter = scoreAfter
        self.halfCompleted = halfCompleted
        self.matchCompleted = matchCompleted
        self.timestamp = timestamp
    }
}

public struct ScamState: Codable, Equatable, Sendable {
    public let config: MatchConfigScam
    public var players: [ScamPlayerState]
    public var halves: [ScamHalfState]
    public var halfIndex: Int
    public var currentRole: ScamRole
    public var winnerPlayerId: UUID?
    public var isComplete: Bool

    public var currentHalf: ScamHalfState { halves[halfIndex] }
    public var currentPlayerId: UUID {
        currentRole == .stopper ? currentHalf.stopperPlayerId : currentHalf.scorerPlayerId
    }

    public init(
        config: MatchConfigScam,
        players: [ScamPlayerState],
        halves: [ScamHalfState],
        halfIndex: Int = 0,
        currentRole: ScamRole = .stopper,
        winnerPlayerId: UUID? = nil,
        isComplete: Bool = false
    ) {
        self.config = config
        self.players = players
        self.halves = halves
        self.halfIndex = halfIndex
        self.currentRole = currentRole
        self.winnerPlayerId = winnerPlayerId
        self.isComplete = isComplete
    }
}

public struct ScamVisitOutcome: Sendable {
    public let updatedState: ScamState
    public let event: ScamVisitEvent
}

// MARK: - Engine

public enum ScamEngine {

    public static func makeInitialState(
        config: MatchConfigScam,
        playerIds: [UUID]
    ) throws -> ScamState {
        guard playerIds.count == 2 else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "setup.validation.scamExactTwoPlayers"
            )
        }
        let players = playerIds.map { ScamPlayerState(playerId: $0) }
        let halves = [
            ScamHalfState(stopperPlayerId: playerIds[0], scorerPlayerId: playerIds[1]),
            ScamHalfState(stopperPlayerId: playerIds[1], scorerPlayerId: playerIds[0]),
        ]
        return ScamState(config: config, players: players, halves: halves)
    }

    /// Submit a 3-dart visit for the current role.
    public static func submitVisit(
        state: ScamState,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> ScamVisitOutcome {
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
        let playerId = state.currentPlayerId
        let highestOpenAtStart = updated.currentHalf.highestOpenSegment

        var segmentsClosedThisVisit: [Int] = []
        var pointsAdded = 0
        switch state.currentRole {
        case .stopper:
            for dart in darts {
                guard let segment = stopperSegment(from: dart) else { continue }
                if !updated.halves[updated.halfIndex].closedSegments.contains(segment) {
                    updated.halves[updated.halfIndex].closedSegments.insert(segment)
                    segmentsClosedThisVisit.append(segment)
                }
            }
        case .scorer:
            guard let target = highestOpenAtStart else {
                // Defensive: scorer phase with all segments closed shouldn't be
                // possible because the half ends after the stopper visit, but
                // bail cleanly if it occurs.
                pointsAdded = 0
                break
            }
            for dart in darts {
                pointsAdded += scorerPoints(dart: dart, target: target)
            }
            if let idx = updated.players.firstIndex(where: { $0.playerId == playerId }) {
                updated.players[idx].totalScore += pointsAdded
            }
        }

        let scoreAfter = updated.players.first(where: { $0.playerId == playerId })?.totalScore ?? 0

        // Phase transitions.
        var halfCompleted = false
        var matchCompleted = false
        switch state.currentRole {
        case .stopper:
            // After stopper, hand off to scorer for this half.
            updated.currentRole = .scorer
            // Half can't end mid-round: only after the scorer's visit.
        case .scorer:
            // After scorer, check if half is now closed.
            if updated.halves[updated.halfIndex].isClosed {
                halfCompleted = true
                if updated.halfIndex == 0 {
                    updated.halfIndex = 1
                    updated.currentRole = .stopper
                } else {
                    matchCompleted = true
                    finalize(&updated)
                }
            } else {
                updated.currentRole = .stopper
            }
        }

        let event = ScamVisitEvent(
            playerId: playerId,
            halfIndex: state.halfIndex,
            role: state.currentRole,
            segmentsClosedThisVisit: segmentsClosedThisVisit,
            highestOpenSegmentAtVisitStart: highestOpenAtStart,
            pointsAdded: pointsAdded,
            scoreAfter: scoreAfter,
            halfCompleted: halfCompleted,
            matchCompleted: matchCompleted,
            timestamp: timestamp
        )
        return ScamVisitOutcome(updatedState: updated, event: event)
    }

    public static func replay(
        config: MatchConfigScam,
        playerIds: [UUID],
        events: [ScamVisitEvent]
    ) throws -> ScamState {
        var state = try makeInitialState(config: config, playerIds: playerIds)
        for event in events {
            switch event.role {
            case .stopper:
                for segment in event.segmentsClosedThisVisit {
                    state.halves[event.halfIndex].closedSegments.insert(segment)
                }
                state.currentRole = .scorer
            case .scorer:
                if let idx = state.players.firstIndex(where: { $0.playerId == event.playerId }) {
                    state.players[idx].totalScore = event.scoreAfter
                }
                if event.matchCompleted {
                    finalize(&state)
                } else if event.halfCompleted {
                    state.halfIndex = 1
                    state.currentRole = .stopper
                } else {
                    state.currentRole = .stopper
                }
            }
        }
        return state
    }

    // MARK: - Helpers

    /// Returns the segment (1…20) the dart closes for the stopper, or `nil` if
    /// the dart was a miss / outer / inner bull (bull is not used per spec).
    static func stopperSegment(from dart: DartInput) -> Int? {
        guard !dart.isMiss else { return nil }
        guard case let .oneToTwenty(value) = dart.segment else { return nil }
        return value
    }

    /// Points the dart contributes for the scorer, given the highest-open
    /// segment at the start of the visit. Multipliers count: a triple on the
    /// target adds 3 × segment value.
    static func scorerPoints(dart: DartInput, target: Int) -> Int {
        guard !dart.isMiss else { return 0 }
        guard case let .oneToTwenty(value) = dart.segment, value == target else { return 0 }
        return dart.points
    }

    private static func finalize(_ state: inout ScamState) {
        state.isComplete = true
        let sorted = state.players.sorted { $0.totalScore > $1.totalScore }
        if sorted.count >= 2, sorted[0].totalScore > sorted[1].totalScore {
            state.winnerPlayerId = sorted[0].playerId
        } else {
            state.winnerPlayerId = nil
        }
    }
}
