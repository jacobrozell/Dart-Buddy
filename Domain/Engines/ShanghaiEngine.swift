import Foundation

public enum ShanghaiBonusRule: String, Codable, CaseIterable, Sendable {
    case bonus150
    case instantWin

    public var displayName: String {
        switch self {
        case .bonus150: L10n.string("play.shanghai.bonusRule.bonus150")
        case .instantWin: L10n.string("play.shanghai.bonusRule.instantWin")
        }
    }
}

public enum ShanghaiTieBreaker: String, Codable, CaseIterable, Sendable {
    case extraRounds

    public var displayName: String {
        L10n.string("play.shanghai.tieBreaker.extraRounds")
    }
}

public struct MatchConfigShanghai: Codable, Equatable, Sendable {
    public static let currentPayloadVersion = 1

    public let payloadVersion: Int
    public let roundCount: Int
    public let bonusRuleRaw: String
    public let tieBreakerRaw: String

    public var bonusRule: ShanghaiBonusRule {
        ShanghaiBonusRule(rawValue: bonusRuleRaw) ?? .bonus150
    }

    public var tieBreaker: ShanghaiTieBreaker {
        ShanghaiTieBreaker(rawValue: tieBreakerRaw) ?? .extraRounds
    }

    public init(
        payloadVersion: Int = currentPayloadVersion,
        roundCount: Int = 20,
        bonusRule: ShanghaiBonusRule = .bonus150,
        tieBreaker: ShanghaiTieBreaker = .extraRounds
    ) {
        self.payloadVersion = payloadVersion
        self.roundCount = max(1, min(20, roundCount))
        self.bonusRuleRaw = bonusRule.rawValue
        self.tieBreakerRaw = tieBreaker.rawValue
    }
}

public struct ShanghaiDartEvent: Codable, Equatable, Sendable {
    public let dartOrder: Int
    public let segmentRaw: String
    public let multiplierRaw: String
    public let pointsAwarded: Int
    public let wasMiss: Bool
    public let hitTarget: Bool

    public init(
        dartOrder: Int,
        segmentRaw: String,
        multiplierRaw: String,
        pointsAwarded: Int,
        wasMiss: Bool,
        hitTarget: Bool
    ) {
        self.dartOrder = dartOrder
        self.segmentRaw = segmentRaw
        self.multiplierRaw = multiplierRaw
        self.pointsAwarded = pointsAwarded
        self.wasMiss = wasMiss
        self.hitTarget = hitTarget
    }
}

public struct ShanghaiTurnEvent: Codable, Equatable, Identifiable, Sendable {
    public let payloadVersion: Int
    public let id: UUID
    public let playerId: UUID
    public let turnIndex: Int
    public let round: Int
    public let legIndex: Int?
    public let pointsThisVisit: Int
    public let cumulativePointsAfterTurn: Int
    public let achievedShanghai: Bool
    public let darts: [ShanghaiDartEvent]
    public let timestamp: Date

    public var effectiveLegIndex: Int { legIndex ?? 0 }
}

public struct ShanghaiPlayerState: Codable, Equatable, Sendable {
    public let playerId: UUID
    public var cumulativePoints: Int
    public var pointsThisRound: Int

    public init(playerId: UUID, cumulativePoints: Int = 0, pointsThisRound: Int = 0) {
        self.playerId = playerId
        self.cumulativePoints = cumulativePoints
        self.pointsThisRound = pointsThisRound
    }
}

public struct ShanghaiState: Codable, Equatable, Sendable {
    public let config: MatchConfigShanghai
    public var players: [ShanghaiPlayerState]
    public var currentPlayerIndex: Int
    public var turnIndex: Int
    public var currentRound: Int
    public var isExtraRound: Bool
    public var winnerPlayerId: UUID?
    public var isComplete: Bool

    public init(
        config: MatchConfigShanghai,
        players: [ShanghaiPlayerState],
        currentPlayerIndex: Int,
        turnIndex: Int,
        currentRound: Int,
        isExtraRound: Bool = false,
        winnerPlayerId: UUID? = nil,
        isComplete: Bool = false
    ) {
        self.config = config
        self.players = players
        self.currentPlayerIndex = currentPlayerIndex
        self.turnIndex = turnIndex
        self.currentRound = currentRound
        self.isExtraRound = isExtraRound
        self.winnerPlayerId = winnerPlayerId
        self.isComplete = isComplete
    }
}

public struct ShanghaiTurnOutcome: Sendable {
    public let updatedState: ShanghaiState
    public let event: ShanghaiTurnEvent
}

public enum ShanghaiEngine {
    public static let shanghaiBonusPoints = 150

    public static func makeInitialState(config: MatchConfigShanghai, playerIds: [UUID]) throws -> ShanghaiState {
        guard config.roundCount > 0 else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.shanghai.invalidRoundCount"
            )
        }
        guard playerIds.count >= 2 else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.players.minimum"
            )
        }
        let players = playerIds.map { ShanghaiPlayerState(playerId: $0) }
        return ShanghaiState(
            config: config,
            players: players,
            currentPlayerIndex: 0,
            turnIndex: 0,
            currentRound: 1
        )
    }

    public static func submitTurn(
        state: ShanghaiState,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> ShanghaiTurnOutcome {
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
        let target = updated.currentRound
        var dartEvents: [ShanghaiDartEvent] = []
        var visitPoints = 0
        var hitMultipliers = Set<DartMultiplier>()

        for (offset, dart) in darts.enumerated() {
            let resolution = resolveDart(dart, target: target)
            visitPoints += resolution.points
            if resolution.hitTarget, !dart.isMiss {
                hitMultipliers.insert(dart.multiplier)
            }
            dartEvents.append(
                ShanghaiDartEvent(
                    dartOrder: offset + 1,
                    segmentRaw: segmentRaw(for: dart.segment),
                    multiplierRaw: dart.multiplier.rawValue,
                    pointsAwarded: resolution.points,
                    wasMiss: dart.isMiss,
                    hitTarget: resolution.hitTarget
                )
            )
        }

        let achievedShanghai = hitMultipliers.contains(.single)
            && hitMultipliers.contains(.double)
            && hitMultipliers.contains(.triple)

        if achievedShanghai {
            switch updated.config.bonusRule {
            case .bonus150:
                visitPoints += shanghaiBonusPoints
            case .instantWin:
                updated.players[playerIndex].pointsThisRound += visitPoints
                updated.players[playerIndex].cumulativePoints += visitPoints
                completeMatch(&updated, winnerId: playerId)
                let event = makeTurnEvent(
                    state: state,
                    playerId: playerId,
                    visitPoints: visitPoints,
                    cumulativeAfter: updated.players[playerIndex].cumulativePoints,
                    achievedShanghai: true,
                    darts: dartEvents,
                    timestamp: timestamp
                )
                return ShanghaiTurnOutcome(updatedState: updated, event: event)
            }
        }

        updated.players[playerIndex].pointsThisRound += visitPoints
        updated.players[playerIndex].cumulativePoints += visitPoints
        advanceTurn(&updated)

        let cumulativeAfter = updated.players[playerIndex].cumulativePoints
        let event = makeTurnEvent(
            state: state,
            playerId: playerId,
            visitPoints: visitPoints,
            cumulativeAfter: cumulativeAfter,
            achievedShanghai: achievedShanghai,
            darts: dartEvents,
            timestamp: timestamp
        )
        return ShanghaiTurnOutcome(updatedState: updated, event: event)
    }

    public static func replay(
        config: MatchConfigShanghai,
        playerIds: [UUID],
        events: [ShanghaiTurnEvent]
    ) throws -> ShanghaiState {
        var state = try makeInitialState(config: config, playerIds: playerIds)
        for event in events {
            let darts = event.darts.map(dartInput(from:))
            state = try submitTurn(state: state, darts: darts, timestamp: event.timestamp).updatedState
        }
        return state
    }

    public static func dartInput(from event: ShanghaiDartEvent) -> DartInput {
        DartInput(
            multiplier: DartMultiplier(rawValue: event.multiplierRaw) ?? .single,
            segment: segment(fromRaw: event.segmentRaw),
            isMiss: event.wasMiss
        )
    }

    // MARK: - Resolution

    private struct DartResolution {
        let points: Int
        let hitTarget: Bool
    }

    private static func resolveDart(_ dart: DartInput, target: Int) -> DartResolution {
        if dart.isMiss {
            return DartResolution(points: 0, hitTarget: false)
        }
        guard segmentValue(dart.segment) == target else {
            return DartResolution(points: 0, hitTarget: false)
        }
        return DartResolution(points: faceValuePoints(for: dart, target: target), hitTarget: true)
    }

    private static func faceValuePoints(for dart: DartInput, target: Int) -> Int {
        switch dart.multiplier {
        case .single: return target
        case .double: return target * 2
        case .triple: return target * 3
        }
    }

    private static func segmentValue(_ segment: DartSegment) -> Int? {
        switch segment {
        case let .oneToTwenty(value): return value
        default: return nil
        }
    }

    // MARK: - Progression

    private static func advanceTurn(_ state: inout ShanghaiState) {
        state.turnIndex += 1
        guard !state.isComplete else { return }

        let playerCount = state.players.count
        let wasLastPlayerInRound = state.currentPlayerIndex == playerCount - 1
        state.currentPlayerIndex = (state.currentPlayerIndex + 1) % playerCount

        guard wasLastPlayerInRound else { return }

        let completedRound = state.currentRound
        resetRoundScratch(&state)

        if completedRound >= state.config.roundCount {
            if let winnerId = singleLeader(in: state.players) {
                completeMatch(&state, winnerId: winnerId)
                return
            }
            switch state.config.tieBreaker {
            case .extraRounds:
                state.isExtraRound = true
                state.currentRound = completedRound + 1
            }
        } else {
            state.currentRound = completedRound + 1
        }
    }

    private static func resetRoundScratch(_ state: inout ShanghaiState) {
        for index in state.players.indices {
            state.players[index].pointsThisRound = 0
        }
    }

    private static func completeMatch(_ state: inout ShanghaiState, winnerId: UUID) {
        state.winnerPlayerId = winnerId
        state.isComplete = true
        state.currentPlayerIndex = 0
    }

    private static func singleLeader(in players: [ShanghaiPlayerState]) -> UUID? {
        guard let maxPoints = players.map(\.cumulativePoints).max() else { return nil }
        let leaders = players.filter { $0.cumulativePoints == maxPoints }
        guard leaders.count == 1 else { return nil }
        return leaders[0].playerId
    }

    private static func makeTurnEvent(
        state: ShanghaiState,
        playerId: UUID,
        visitPoints: Int,
        cumulativeAfter: Int,
        achievedShanghai: Bool,
        darts: [ShanghaiDartEvent],
        timestamp: Date
    ) -> ShanghaiTurnEvent {
        ShanghaiTurnEvent(
            payloadVersion: 1,
            id: UUID(),
            playerId: playerId,
            turnIndex: state.turnIndex,
            round: state.currentRound,
            legIndex: state.currentRound - 1,
            pointsThisVisit: visitPoints,
            cumulativePointsAfterTurn: cumulativeAfter,
            achievedShanghai: achievedShanghai,
            darts: darts,
            timestamp: timestamp
        )
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
