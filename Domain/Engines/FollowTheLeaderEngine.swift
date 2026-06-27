import Foundation

public enum FollowTheLeaderRing: String, Codable, CaseIterable, Sendable {
    case single
    case double
    case triple
    case outerBull
    case innerBull

    public var localizationKey: String {
        switch self {
        case .single: "play.followTheLeader.targetArea.single"
        case .double: "play.followTheLeader.targetArea.double"
        case .triple: "play.followTheLeader.targetArea.triple"
        case .outerBull: "play.followTheLeader.targetArea.outerBull"
        case .innerBull: "play.followTheLeader.targetArea.innerBull"
        }
    }
}

public struct FollowTheLeaderTargetArea: Codable, Equatable, Sendable {
    /// Segment 1…20, or 25 for bull.
    public let segment: Int
    public let ringRaw: String

    public var ring: FollowTheLeaderRing {
        FollowTheLeaderRing(rawValue: ringRaw) ?? .single
    }

    public init(segment: Int, ring: FollowTheLeaderRing) {
        self.segment = segment
        self.ringRaw = ring.rawValue
    }

    public var displayLabel: String {
        switch ring {
        case .outerBull, .innerBull:
            return L10n.string(ring.localizationKey)
        default:
            return L10n.format("play.followTheLeader.currentTargetFormat", segment, L10n.string(ring.localizationKey))
        }
    }
}

public struct MatchConfigFollowTheLeader: Codable, Equatable, Sendable {
    public static let currentPayloadVersion = 1

    public let payloadVersion: Int
    public let startingLives: Int

    public init(payloadVersion: Int = currentPayloadVersion, startingLives: Int = 3) {
        self.payloadVersion = payloadVersion
        self.startingLives = min(5, max(1, startingLives))
    }
}

public struct FollowTheLeaderDartResolution: Codable, Equatable, Sendable {
    public let segmentRaw: String
    public let multiplierRaw: String
    public let wasMiss: Bool
    public let matchedTarget: Bool

    public init(segmentRaw: String, multiplierRaw: String, wasMiss: Bool, matchedTarget: Bool = false) {
        self.segmentRaw = segmentRaw
        self.multiplierRaw = multiplierRaw
        self.wasMiss = wasMiss
        self.matchedTarget = matchedTarget
    }
}

public struct FollowTheLeaderVisitEvent: Codable, Equatable, Identifiable, Sendable {
    public let payloadVersion: Int
    public let id: UUID
    public let playerId: UUID
    public let turnIndex: Int
    public let targetBefore: FollowTheLeaderTargetArea?
    public let targetAfter: FollowTheLeaderTargetArea?
    public let darts: [FollowTheLeaderDartResolution]
    public let matched: Bool
    public let lifeLost: Bool
    public let passed: Bool
    public let setOpeningTarget: Bool
    public let matchCompleted: Bool
    public let timestamp: Date

    public init(
        payloadVersion: Int = 1,
        id: UUID = UUID(),
        playerId: UUID,
        turnIndex: Int,
        targetBefore: FollowTheLeaderTargetArea?,
        targetAfter: FollowTheLeaderTargetArea?,
        darts: [FollowTheLeaderDartResolution],
        matched: Bool,
        lifeLost: Bool,
        passed: Bool = false,
        setOpeningTarget: Bool = false,
        matchCompleted: Bool,
        timestamp: Date
    ) {
        self.payloadVersion = payloadVersion
        self.id = id
        self.playerId = playerId
        self.turnIndex = turnIndex
        self.targetBefore = targetBefore
        self.targetAfter = targetAfter
        self.darts = darts
        self.matched = matched
        self.lifeLost = lifeLost
        self.passed = passed
        self.setOpeningTarget = setOpeningTarget
        self.matchCompleted = matchCompleted
        self.timestamp = timestamp
    }
}

public struct FollowTheLeaderPlayerState: Codable, Equatable, Sendable {
    public let playerId: UUID
    public var lives: Int
    public var isEliminated: Bool

    public init(playerId: UUID, lives: Int, isEliminated: Bool = false) {
        self.playerId = playerId
        self.lives = lives
        self.isEliminated = isEliminated
    }
}

public struct FollowTheLeaderState: Codable, Equatable, Sendable {
    public let config: MatchConfigFollowTheLeader
    public var players: [FollowTheLeaderPlayerState]
    public var target: FollowTheLeaderTargetArea?
    public var targetSetterId: UUID?
    public var currentPlayerIndex: Int
    public var turnIndex: Int
    public var needsOpeningTarget: Bool
    public var awaitingPassDecision: Bool
    /// Active players who missed on their visit since the current target was set.
    public var missedPlayerIdsSinceTargetSet: [UUID]
    public var winnerPlayerId: UUID?
    public var isComplete: Bool

    public var currentPlayerId: UUID? {
        guard !isComplete, players.indices.contains(currentPlayerIndex) else { return nil }
        return players[currentPlayerIndex].playerId
    }

    public init(
        config: MatchConfigFollowTheLeader,
        players: [FollowTheLeaderPlayerState],
        target: FollowTheLeaderTargetArea? = nil,
        targetSetterId: UUID? = nil,
        currentPlayerIndex: Int = 0,
        turnIndex: Int = 0,
        needsOpeningTarget: Bool = true,
        awaitingPassDecision: Bool = false,
        missedPlayerIdsSinceTargetSet: [UUID] = [],
        winnerPlayerId: UUID? = nil,
        isComplete: Bool = false
    ) {
        self.config = config
        self.players = players
        self.target = target
        self.targetSetterId = targetSetterId
        self.currentPlayerIndex = currentPlayerIndex
        self.turnIndex = turnIndex
        self.needsOpeningTarget = needsOpeningTarget
        self.awaitingPassDecision = awaitingPassDecision
        self.missedPlayerIdsSinceTargetSet = missedPlayerIdsSinceTargetSet
        self.winnerPlayerId = winnerPlayerId
        self.isComplete = isComplete
    }
}

public struct FollowTheLeaderVisitOutcome: Sendable {
    public let updatedState: FollowTheLeaderState
    public let event: FollowTheLeaderVisitEvent
}

public enum FollowTheLeaderEngine {

    public static func makeInitialState(
        config: MatchConfigFollowTheLeader,
        playerIds: [UUID]
    ) throws -> FollowTheLeaderState {
        guard playerIds.count >= 2 else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "setup.validation.followTheLeaderMinimumPlayers"
            )
        }
        let players = playerIds.map {
            FollowTheLeaderPlayerState(playerId: $0, lives: config.startingLives)
        }
        return FollowTheLeaderState(config: config, players: players)
    }

    public static func submitPass(
        state: FollowTheLeaderState,
        timestamp: Date = Date()
    ) throws -> FollowTheLeaderVisitOutcome {
        guard !state.isComplete else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.completed"
            )
        }
        guard state.awaitingPassDecision else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.followTheLeader.passUnavailable"
            )
        }
        let playerIndex = state.currentPlayerIndex
        let playerId = state.players[playerIndex].playerId
        guard playerId == state.targetSetterId else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.followTheLeader.passUnavailable"
            )
        }

        var updated = state
        updated.awaitingPassDecision = false
        updated.missedPlayerIdsSinceTargetSet = []
        updated.turnIndex += 1
        advanceTurn(&updated)

        var matchCompleted = false
        checkLastStanding(&updated)
        if updated.isComplete { matchCompleted = true }

        let event = FollowTheLeaderVisitEvent(
            playerId: playerId,
            turnIndex: state.turnIndex,
            targetBefore: state.target,
            targetAfter: updated.target,
            darts: [],
            matched: false,
            lifeLost: false,
            passed: true,
            matchCompleted: matchCompleted,
            timestamp: timestamp
        )
        return FollowTheLeaderVisitOutcome(updatedState: updated, event: event)
    }

    public static func submitVisit(
        state: FollowTheLeaderState,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> FollowTheLeaderVisitOutcome {
        guard !state.isComplete else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.completed"
            )
        }
        guard !state.awaitingPassDecision else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.followTheLeader.usePassOrThrow"
            )
        }

        var updated = state
        let playerIndex = updated.currentPlayerIndex
        let playerId = updated.players[playerIndex].playerId
        guard !updated.players[playerIndex].isEliminated else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.followTheLeader.alreadyEliminated"
            )
        }

        let targetBefore = updated.target
        let maxDarts = updated.needsOpeningTarget ? 1 : 3
        guard !darts.isEmpty, darts.count <= maxDarts else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.turn.maxDarts"
            )
        }

        var matched = false
        var lifeLost = false
        var setOpeningTarget = false
        var resolutions: [FollowTheLeaderDartResolution] = []

        if updated.needsOpeningTarget {
            guard let dart = darts.first, let area = targetArea(from: dart) else {
                throw AppError(
                    code: .validationFailed,
                    layer: .domain,
                    severity: .warning,
                    isRecoverable: true,
                    userMessageKey: "error.match.followTheLeader.openingRequiresScoringDart"
                )
            }
            updated.target = area
            updated.targetSetterId = playerId
            updated.needsOpeningTarget = false
            updated.missedPlayerIdsSinceTargetSet = []
            setOpeningTarget = true
            matched = true
            resolutions.append(dartResolution(dart, matchedTarget: false))
        } else {
            guard let target = updated.target else {
                throw AppError(
                    code: .invalidGameState,
                    layer: .domain,
                    severity: .error,
                    isRecoverable: false,
                    userMessageKey: "error.match.followTheLeader.noTarget"
                )
            }

            var matchIndex: Int?
            for (index, dart) in darts.enumerated() {
                let didMatch = dartMatchesTarget(dart, target: target)
                resolutions.append(dartResolution(dart, matchedTarget: didMatch))
                if didMatch, matchIndex == nil {
                    matchIndex = index
                }
            }

            if let matchIndex {
                matched = true
                var newTarget = target
                for dart in darts[(matchIndex + 1)...] {
                    if let area = targetArea(from: dart) {
                        newTarget = area
                    }
                }
                if newTarget != target {
                    updated.target = newTarget
                    updated.targetSetterId = playerId
                }
                updated.missedPlayerIdsSinceTargetSet = []
            } else {
                updated.players[playerIndex].lives = max(0, updated.players[playerIndex].lives - 1)
                lifeLost = true
                if updated.players[playerIndex].lives == 0 {
                    updated.players[playerIndex].isEliminated = true
                }
                if !updated.missedPlayerIdsSinceTargetSet.contains(playerId) {
                    updated.missedPlayerIdsSinceTargetSet.append(playerId)
                }
            }
        }

        updated.turnIndex += 1
        var matchCompleted = false

        if !matched || setOpeningTarget {
            checkLastStanding(&updated)
            if updated.isComplete {
                matchCompleted = true
            } else if !setOpeningTarget {
                if shouldOfferPassDecision(updated) {
                    moveToTargetSetterForPass(&updated)
                } else {
                    advanceTurn(&updated)
                }
            } else {
                advanceTurn(&updated)
            }
        } else {
            checkLastStanding(&updated)
            if updated.isComplete {
                matchCompleted = true
            } else {
                advanceTurn(&updated)
            }
        }

        let event = FollowTheLeaderVisitEvent(
            playerId: playerId,
            turnIndex: state.turnIndex,
            targetBefore: targetBefore,
            targetAfter: updated.target,
            darts: resolutions,
            matched: matched,
            lifeLost: lifeLost,
            passed: false,
            setOpeningTarget: setOpeningTarget,
            matchCompleted: matchCompleted,
            timestamp: timestamp
        )
        return FollowTheLeaderVisitOutcome(updatedState: updated, event: event)
    }

    public static func dartInput(from resolution: FollowTheLeaderDartResolution) -> DartInput {
        guard !resolution.wasMiss else {
            return DartInput(multiplier: .single, segment: .miss, isMiss: true)
        }
        let multiplier = DartMultiplier(rawValue: resolution.multiplierRaw) ?? .single
        switch resolution.segmentRaw {
        case "outerBull":
            return DartInput(multiplier: multiplier, segment: .outerBull, isMiss: false)
        case "innerBull":
            return DartInput(multiplier: multiplier, segment: .innerBull, isMiss: false)
        case "miss":
            return DartInput(multiplier: .single, segment: .miss, isMiss: true)
        default:
            if let value = Int(resolution.segmentRaw), (1 ... 20).contains(value) {
                return DartInput(multiplier: multiplier, segment: .oneToTwenty(value), isMiss: false)
            }
            return DartInput(multiplier: .single, segment: .miss, isMiss: true)
        }
    }

    // MARK: - Helpers

    static func targetArea(from dart: DartInput) -> FollowTheLeaderTargetArea? {
        guard !dart.isMiss else { return nil }
        switch dart.segment {
        case let .oneToTwenty(value):
            switch dart.multiplier {
            case .single: return FollowTheLeaderTargetArea(segment: value, ring: .single)
            case .double: return FollowTheLeaderTargetArea(segment: value, ring: .double)
            case .triple: return FollowTheLeaderTargetArea(segment: value, ring: .triple)
            }
        case .outerBull:
            return FollowTheLeaderTargetArea(segment: 25, ring: .outerBull)
        case .innerBull:
            return FollowTheLeaderTargetArea(segment: 25, ring: .innerBull)
        case .miss:
            return nil
        }
    }

    static func dartMatchesTarget(_ dart: DartInput, target: FollowTheLeaderTargetArea) -> Bool {
        guard let area = targetArea(from: dart) else { return false }
        return area == target
    }

    private static func dartResolution(_ dart: DartInput, matchedTarget: Bool) -> FollowTheLeaderDartResolution {
        FollowTheLeaderDartResolution(
            segmentRaw: segmentRaw(for: dart.segment),
            multiplierRaw: dart.multiplier.rawValue,
            wasMiss: dart.isMiss,
            matchedTarget: matchedTarget
        )
    }

    private static func segmentRaw(for segment: DartSegment) -> String {
        switch segment {
        case let .oneToTwenty(value): return String(value)
        case .outerBull: return "outerBull"
        case .innerBull: return "innerBull"
        case .miss: return "miss"
        }
    }

    private static func activePlayers(in state: FollowTheLeaderState) -> [FollowTheLeaderPlayerState] {
        state.players.filter { !$0.isEliminated }
    }

    private static func shouldOfferPassDecision(_ state: FollowTheLeaderState) -> Bool {
        let active = activePlayers(in: state)
        guard active.count > 1, let setterId = state.targetSetterId else { return false }
        let activeIds = Set(active.map(\.playerId))
        let missed = Set(state.missedPlayerIdsSinceTargetSet)
        let others = activeIds.subtracting([setterId])
        return !others.isEmpty && others.isSubset(of: missed)
    }

    private static func moveToTargetSetterForPass(_ state: inout FollowTheLeaderState) {
        guard let setterId = state.targetSetterId,
              let index = state.players.firstIndex(where: { $0.playerId == setterId && !$0.isEliminated }) else {
            return
        }
        state.currentPlayerIndex = index
        state.awaitingPassDecision = true
    }

    private static func advanceTurn(_ state: inout FollowTheLeaderState) {
        guard !state.isComplete else { return }
        guard let nextIndex = nextActivePlayerIndex(after: state.currentPlayerIndex, in: state) else {
            checkLastStanding(&state)
            return
        }
        state.currentPlayerIndex = nextIndex
    }

    private static func nextActivePlayerIndex(after index: Int, in state: FollowTheLeaderState) -> Int? {
        let count = state.players.count
        guard count > 0 else { return nil }
        for offset in 1 ... count {
            let candidate = (index + offset) % count
            if !state.players[candidate].isEliminated {
                return candidate
            }
        }
        return nil
    }

    private static func checkLastStanding(_ state: inout FollowTheLeaderState) {
        let active = activePlayers(in: state)
        guard active.count <= 1 else { return }
        state.isComplete = true
        state.winnerPlayerId = active.first?.playerId
        state.awaitingPassDecision = false
    }
}
