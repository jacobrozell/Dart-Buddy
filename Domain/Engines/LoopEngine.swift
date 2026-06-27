import Foundation

public enum LoopWireTargetKind: String, Codable, CaseIterable, Sendable {
    case standard
    case lowerLoop
    case upperLoop
    case split

    public var localizationKey: String {
        switch self {
        case .standard: "play.loop.wireTarget.standard"
        case .lowerLoop: "play.loop.wireTarget.lowerLoop"
        case .upperLoop: "play.loop.wireTarget.upperLoop"
        case .split: "play.loop.wireTarget.split"
        }
    }
}

public struct LoopWireTargetArea: Codable, Equatable, Sendable, Hashable {
    /// Segment 1…20, 25 for bull, 11 for split.
    public let segment: Int
    public let kindRaw: String
    /// Only used when `kind == .standard` — mirrors Follow the Leader rings.
    public let ringRaw: String?

    public var kind: LoopWireTargetKind {
        LoopWireTargetKind(rawValue: kindRaw) ?? .standard
    }

    public var ring: FollowTheLeaderRing? {
        guard kind == .standard, let ringRaw else { return nil }
        return FollowTheLeaderRing(rawValue: ringRaw)
    }

    public init(segment: Int, kind: LoopWireTargetKind, ring: FollowTheLeaderRing? = nil) {
        self.segment = segment
        self.kindRaw = kind.rawValue
        self.ringRaw = ring?.rawValue
    }

    public var displayLabel: String {
        switch kind {
        case .lowerLoop:
            return L10n.format("play.loop.wireTarget.loopFormat", segment, L10n.string("play.loop.wireTarget.lowerLoop"))
        case .upperLoop:
            return L10n.format("play.loop.wireTarget.loopFormat", segment, L10n.string("play.loop.wireTarget.upperLoop"))
        case .split:
            return L10n.format("play.loop.wireTarget.splitFormat", segment)
        case .standard:
            guard let ring else { return L10n.format("play.loop.currentTargetFormat", segment, "") }
            switch ring {
            case .outerBull, .innerBull:
                return L10n.string(ring.localizationKey)
            default:
                return L10n.format("play.loop.currentTargetFormat", segment, L10n.string(ring.localizationKey))
            }
        }
    }

    public static let loopSegments: Set<Int> = [4, 6, 8, 10, 14, 16, 18, 20]
    public static let splitSegment = 11

    public static func candidates(for dart: DartInput) -> [LoopWireTargetArea] {
        guard !dart.isMiss else { return [] }
        switch dart.segment {
        case let .oneToTwenty(value):
            var options: [LoopWireTargetArea] = []
            switch dart.multiplier {
            case .single:
                options.append(LoopWireTargetArea(segment: value, kind: .standard, ring: .single))
            case .double:
                options.append(LoopWireTargetArea(segment: value, kind: .standard, ring: .double))
            case .triple:
                options.append(LoopWireTargetArea(segment: value, kind: .standard, ring: .triple))
            }
            if loopSegments.contains(value) {
                options.append(LoopWireTargetArea(segment: value, kind: .lowerLoop))
                options.append(LoopWireTargetArea(segment: value, kind: .upperLoop))
            }
            if value == splitSegment {
                options.append(LoopWireTargetArea(segment: value, kind: .split))
            }
            return options
        case .outerBull:
            return [LoopWireTargetArea(segment: 25, kind: .standard, ring: .outerBull)]
        case .innerBull:
            return [LoopWireTargetArea(segment: 25, kind: .standard, ring: .innerBull)]
        case .miss:
            return []
        }
    }
}

public struct MatchConfigLoop: Codable, Equatable, Sendable {
    public static let currentPayloadVersion = 1

    public let payloadVersion: Int
    public let startingLives: Int

    public init(payloadVersion: Int = currentPayloadVersion, startingLives: Int = 3) {
        self.payloadVersion = payloadVersion
        self.startingLives = min(5, max(1, startingLives))
    }
}

public struct LoopSubmittedDart: Codable, Equatable, Sendable {
    public let dart: DartInput
    public let wireTarget: LoopWireTargetArea

    public init(dart: DartInput, wireTarget: LoopWireTargetArea) {
        self.dart = dart
        self.wireTarget = wireTarget
    }
}

public struct LoopDartResolution: Codable, Equatable, Sendable {
    public let segmentRaw: String
    public let multiplierRaw: String
    public let wasMiss: Bool
    public let wireTarget: LoopWireTargetArea
    public let matchedTarget: Bool

    public init(
        segmentRaw: String,
        multiplierRaw: String,
        wasMiss: Bool,
        wireTarget: LoopWireTargetArea,
        matchedTarget: Bool = false
    ) {
        self.segmentRaw = segmentRaw
        self.multiplierRaw = multiplierRaw
        self.wasMiss = wasMiss
        self.wireTarget = wireTarget
        self.matchedTarget = matchedTarget
    }
}

public struct LoopVisitEvent: Codable, Equatable, Identifiable, Sendable {
    public let payloadVersion: Int
    public let id: UUID
    public let playerId: UUID
    public let turnIndex: Int
    public let targetBefore: LoopWireTargetArea?
    public let targetAfter: LoopWireTargetArea?
    public let darts: [LoopDartResolution]
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
        targetBefore: LoopWireTargetArea?,
        targetAfter: LoopWireTargetArea?,
        darts: [LoopDartResolution],
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

public struct LoopPlayerState: Codable, Equatable, Sendable {
    public let playerId: UUID
    public var lives: Int
    public var isEliminated: Bool

    public init(playerId: UUID, lives: Int, isEliminated: Bool = false) {
        self.playerId = playerId
        self.lives = lives
        self.isEliminated = isEliminated
    }
}

public struct LoopState: Codable, Equatable, Sendable {
    public let config: MatchConfigLoop
    public var players: [LoopPlayerState]
    public var target: LoopWireTargetArea?
    public var targetSetterId: UUID?
    public var currentPlayerIndex: Int
    public var turnIndex: Int
    public var needsOpeningTarget: Bool
    public var awaitingPassDecision: Bool
    public var missedPlayerIdsSinceTargetSet: [UUID]
    public var winnerPlayerId: UUID?
    public var isComplete: Bool

    public var currentPlayerId: UUID? {
        guard !isComplete, players.indices.contains(currentPlayerIndex) else { return nil }
        return players[currentPlayerIndex].playerId
    }

    public init(
        config: MatchConfigLoop,
        players: [LoopPlayerState],
        target: LoopWireTargetArea? = nil,
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

public struct LoopVisitOutcome: Sendable {
    public let updatedState: LoopState
    public let event: LoopVisitEvent
}

public enum LoopEngine {

    public static func makeInitialState(
        config: MatchConfigLoop,
        playerIds: [UUID]
    ) throws -> LoopState {
        guard playerIds.count >= 2 else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "setup.validation.loopMinimumPlayers"
            )
        }
        let players = playerIds.map {
            LoopPlayerState(playerId: $0, lives: config.startingLives)
        }
        return LoopState(config: config, players: players)
    }

    public static func submitPass(
        state: LoopState,
        timestamp: Date = Date()
    ) throws -> LoopVisitOutcome {
        guard !state.isComplete else {
            throw completedError()
        }
        guard state.awaitingPassDecision else {
            throw passUnavailableError()
        }
        let playerIndex = state.currentPlayerIndex
        let playerId = state.players[playerIndex].playerId
        guard playerId == state.targetSetterId else {
            throw passUnavailableError()
        }

        var updated = state
        updated.awaitingPassDecision = false
        updated.missedPlayerIdsSinceTargetSet = []
        updated.turnIndex += 1
        advanceTurn(&updated)

        var matchCompleted = false
        checkLastStanding(&updated)
        if updated.isComplete { matchCompleted = true }

        let event = LoopVisitEvent(
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
        return LoopVisitOutcome(updatedState: updated, event: event)
    }

    public static func submitVisit(
        state: LoopState,
        darts: [LoopSubmittedDart],
        timestamp: Date = Date()
    ) throws -> LoopVisitOutcome {
        guard !state.isComplete else {
            throw completedError()
        }
        guard !state.awaitingPassDecision else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.loop.usePassOrThrow"
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
                userMessageKey: "error.match.loop.alreadyEliminated"
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
        var resolutions: [LoopDartResolution] = []

        if updated.needsOpeningTarget {
            guard let submitted = darts.first, !submitted.dart.isMiss else {
                throw AppError(
                    code: .validationFailed,
                    layer: .domain,
                    severity: .warning,
                    isRecoverable: true,
                    userMessageKey: "error.match.loop.openingRequiresScoringDart"
                )
            }
            try validateWireTarget(submitted)
            updated.target = submitted.wireTarget
            updated.targetSetterId = playerId
            updated.needsOpeningTarget = false
            updated.missedPlayerIdsSinceTargetSet = []
            setOpeningTarget = true
            matched = true
            resolutions.append(dartResolution(submitted, matchedTarget: false))
        } else {
            guard let target = updated.target else {
                throw AppError(
                    code: .invalidGameState,
                    layer: .domain,
                    severity: .error,
                    isRecoverable: false,
                    userMessageKey: "error.match.loop.noTarget"
                )
            }

            var matchIndex: Int?
            for (index, submitted) in darts.enumerated() {
                try validateWireTarget(submitted)
                let didMatch = submitted.wireTarget == target
                resolutions.append(dartResolution(submitted, matchedTarget: didMatch))
                if didMatch, matchIndex == nil {
                    matchIndex = index
                }
            }

            if let matchIndex {
                matched = true
                var newTarget = target
                for submitted in darts[(matchIndex + 1)...] {
                    try validateWireTarget(submitted)
                    if !submitted.dart.isMiss {
                        newTarget = submitted.wireTarget
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
                if shouldOfferPassDecision(&updated) {
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

        let event = LoopVisitEvent(
            playerId: playerId,
            turnIndex: state.turnIndex,
            targetBefore: targetBefore,
            targetAfter: updated.target,
            darts: resolutions,
            matched: matched,
            lifeLost: lifeLost,
            matchCompleted: matchCompleted,
            timestamp: timestamp
        )
        return LoopVisitOutcome(updatedState: updated, event: event)
    }

    public static func submittedDart(from resolution: LoopDartResolution) -> LoopSubmittedDart {
        LoopSubmittedDart(dart: dartInput(from: resolution), wireTarget: resolution.wireTarget)
    }

    public static func dartInput(from resolution: LoopDartResolution) -> DartInput {
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

    public static func defaultWireTarget(for dart: DartInput) -> LoopWireTargetArea? {
        let candidates = LoopWireTargetArea.candidates(for: dart)
        return candidates.first
    }

    // MARK: - Helpers

    private static func validateWireTarget(_ submitted: LoopSubmittedDart) throws {
        guard !submitted.dart.isMiss else { return }
        let candidates = LoopWireTargetArea.candidates(for: submitted.dart)
        guard candidates.contains(submitted.wireTarget) else {
            throw invalidWireTargetError()
        }
    }

    private static var missWireTarget: LoopWireTargetArea {
        LoopWireTargetArea(segment: 0, kind: .standard, ring: .single)
    }

    public static func missSubmittedDart(_ dart: DartInput) -> LoopSubmittedDart {
        LoopSubmittedDart(dart: dart, wireTarget: missWireTarget)
    }

    private static func dartResolution(_ submitted: LoopSubmittedDart, matchedTarget: Bool) -> LoopDartResolution {
        LoopDartResolution(
            segmentRaw: segmentRaw(for: submitted.dart.segment),
            multiplierRaw: submitted.dart.multiplier.rawValue,
            wasMiss: submitted.dart.isMiss,
            wireTarget: submitted.wireTarget,
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

    private static func activePlayers(in state: LoopState) -> [LoopPlayerState] {
        state.players.filter { !$0.isEliminated }
    }

    private static func shouldOfferPassDecision(_ state: inout LoopState) -> Bool {
        let active = activePlayers(in: state)
        guard active.count > 1, let setterId = state.targetSetterId else { return false }
        let activeIds = Set(active.map(\.playerId))
        let missed = Set(state.missedPlayerIdsSinceTargetSet)
        return activeIds.isSubset(of: missed) && missed.count >= activeIds.count
    }

    private static func moveToTargetSetterForPass(_ state: inout LoopState) {
        guard let setterId = state.targetSetterId,
              let index = state.players.firstIndex(where: { $0.playerId == setterId && !$0.isEliminated }) else {
            return
        }
        state.currentPlayerIndex = index
        state.awaitingPassDecision = true
    }

    private static func advanceTurn(_ state: inout LoopState) {
        guard !state.isComplete else { return }
        guard let nextIndex = nextActivePlayerIndex(after: state.currentPlayerIndex, in: state) else {
            checkLastStanding(&state)
            return
        }
        state.currentPlayerIndex = nextIndex
    }

    private static func nextActivePlayerIndex(after index: Int, in state: LoopState) -> Int? {
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

    private static func checkLastStanding(_ state: inout LoopState) {
        let active = activePlayers(in: state)
        guard active.count <= 1 else { return }
        state.isComplete = true
        state.winnerPlayerId = active.first?.playerId
        state.awaitingPassDecision = false
    }

    private static func completedError() -> AppError {
        AppError(
            code: .invalidGameState,
            layer: .domain,
            severity: .warning,
            isRecoverable: true,
            userMessageKey: "error.match.completed"
        )
    }

    private static func passUnavailableError() -> AppError {
        AppError(
            code: .invalidGameState,
            layer: .domain,
            severity: .warning,
            isRecoverable: true,
            userMessageKey: "error.match.loop.passUnavailable"
        )
    }

    private static func invalidWireTargetError() -> AppError {
        AppError(
            code: .validationFailed,
            layer: .domain,
            severity: .warning,
            isRecoverable: true,
            userMessageKey: "error.match.loop.invalidWireTarget"
        )
    }
}
