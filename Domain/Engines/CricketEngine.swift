import Foundation

public enum CricketTarget: String, CaseIterable, Codable, Sendable {
    case t20 = "20"
    case t19 = "19"
    case t18 = "18"
    case t17 = "17"
    case t16 = "16"
    case t15 = "15"
    case bull

    public var points: Int {
        switch self {
        case .bull:
            return 25
        case let target:
            return Int(target.rawValue) ?? 0
        }
    }
}

public struct CricketDartTouch: Codable, Equatable, Sendable {
    public let dartOrder: Int
    public let targetRaw: String
    public let multiplierRaw: String
    public let marksAdded: Int
    public let overflowMarks: Int
    public let pointsAdded: Int
    public let wasMiss: Bool
    /// The precise dart segment (e.g. "innerBull"/"outerBull"/"20"/"miss").
    /// `targetRaw` collapses both bulls to "bull", which is lossy for replay;
    /// this preserves the distinction so resume/undo are deterministic.
    /// Optional so historical events that predate the field still decode.
    public let segmentRaw: String?

    public init(
        dartOrder: Int,
        targetRaw: String,
        multiplierRaw: String,
        marksAdded: Int,
        overflowMarks: Int,
        pointsAdded: Int,
        wasMiss: Bool,
        segmentRaw: String? = nil
    ) {
        self.dartOrder = dartOrder
        self.targetRaw = targetRaw
        self.multiplierRaw = multiplierRaw
        self.marksAdded = marksAdded
        self.overflowMarks = overflowMarks
        self.pointsAdded = pointsAdded
        self.wasMiss = wasMiss
        self.segmentRaw = segmentRaw
    }
}

public struct CricketTurnEvent: Codable, Equatable, Identifiable, Sendable {
    public let payloadVersion: Int
    public let id: UUID
    public let playerId: UUID
    public let turnIndex: Int
    public let roundIndex: Int
    public let legIndex: Int?
    public let setIndex: Int?
    public let totalPointsAdded: Int
    public let targetsTouched: [CricketDartTouch]
    public let timestamp: Date

    public var effectiveLegIndex: Int { legIndex ?? 0 }
    public var effectiveSetIndex: Int { setIndex ?? 0 }
}

public struct CricketPlayerState: Codable, Equatable, Sendable {
    public let playerId: UUID
    public var score: Int
    public var marks: [String: Int]
    public var legsWon: Int
    public var setsWon: Int

    public init(
        playerId: UUID,
        score: Int,
        marks: [String: Int],
        legsWon: Int = 0,
        setsWon: Int = 0
    ) {
        self.playerId = playerId
        self.score = score
        self.marks = marks
        self.legsWon = legsWon
        self.setsWon = setsWon
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        playerId = try container.decode(UUID.self, forKey: .playerId)
        score = try container.decode(Int.self, forKey: .score)
        marks = try container.decode([String: Int].self, forKey: .marks)
        legsWon = try container.decodeIfPresent(Int.self, forKey: .legsWon) ?? 0
        setsWon = try container.decodeIfPresent(Int.self, forKey: .setsWon) ?? 0
    }

    private enum CodingKeys: String, CodingKey {
        case playerId
        case score
        case marks
        case legsWon
        case setsWon
    }
}

public struct CricketState: Codable, Equatable, Sendable {
    public let config: MatchConfigCricket
    public var players: [CricketPlayerState]
    public var currentPlayerIndex: Int
    public var roundIndex: Int
    public var turnIndex: Int
    public var legIndex: Int
    public var setIndex: Int
    public var winnerPlayerId: UUID?
    public var isComplete: Bool

    public init(
        config: MatchConfigCricket,
        players: [CricketPlayerState],
        currentPlayerIndex: Int,
        roundIndex: Int,
        turnIndex: Int,
        legIndex: Int = 0,
        setIndex: Int = 0,
        winnerPlayerId: UUID? = nil,
        isComplete: Bool = false
    ) {
        self.config = config
        self.players = players
        self.currentPlayerIndex = currentPlayerIndex
        self.roundIndex = roundIndex
        self.turnIndex = turnIndex
        self.legIndex = legIndex
        self.setIndex = setIndex
        self.winnerPlayerId = winnerPlayerId
        self.isComplete = isComplete
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        config = try container.decode(MatchConfigCricket.self, forKey: .config)
        players = try container.decode([CricketPlayerState].self, forKey: .players)
        currentPlayerIndex = try container.decode(Int.self, forKey: .currentPlayerIndex)
        roundIndex = try container.decode(Int.self, forKey: .roundIndex)
        turnIndex = try container.decode(Int.self, forKey: .turnIndex)
        legIndex = try container.decodeIfPresent(Int.self, forKey: .legIndex) ?? 0
        setIndex = try container.decodeIfPresent(Int.self, forKey: .setIndex) ?? 0
        winnerPlayerId = try container.decodeIfPresent(UUID.self, forKey: .winnerPlayerId)
        isComplete = try container.decode(Bool.self, forKey: .isComplete)
    }

    private enum CodingKeys: String, CodingKey {
        case config
        case players
        case currentPlayerIndex
        case roundIndex
        case turnIndex
        case legIndex
        case setIndex
        case winnerPlayerId
        case isComplete
    }
}

public struct CricketTurnOutcome: Sendable {
    public let updatedState: CricketState
    public let event: CricketTurnEvent
}

public enum CricketEngine {
    public static func makeInitialState(config: MatchConfigCricket, playerIds: [UUID]) throws -> CricketState {
        guard config.legsToWin > 0 else {
            throw AppError(code: .validationFailed, layer: .domain, severity: .warning, isRecoverable: true, userMessageKey: "error.match.x01.invalidLegCount")
        }
        if config.setsEnabled, (config.setsToWin ?? 0) <= 0 {
            throw AppError(code: .validationFailed, layer: .domain, severity: .warning, isRecoverable: true, userMessageKey: "error.match.x01.invalidSetCount")
        }
        guard playerIds.count >= 2 else {
            throw AppError(code: .validationFailed, layer: .domain, severity: .warning, isRecoverable: true, userMessageKey: "error.match.players.minimum")
        }
        let marksSeed = Dictionary(uniqueKeysWithValues: CricketTarget.allCases.map { ($0.rawValue, 0) })
        let players = playerIds.map {
            CricketPlayerState(playerId: $0, score: 0, marks: marksSeed, legsWon: 0, setsWon: 0)
        }
        return CricketState(
            config: config,
            players: players,
            currentPlayerIndex: 0,
            roundIndex: 0,
            turnIndex: 0,
            legIndex: 0,
            setIndex: 0,
            winnerPlayerId: nil,
            isComplete: false
        )
    }

    public static func submitTurn(
        state: CricketState,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> CricketTurnOutcome {
        guard !state.isComplete else {
            throw AppError(code: .invalidGameState, layer: .domain, severity: .warning, isRecoverable: true, userMessageKey: "error.match.completed")
        }
        guard darts.count <= 3 else {
            throw AppError(code: .validationFailed, layer: .domain, severity: .warning, isRecoverable: true, userMessageKey: "error.turn.maxDarts")
        }

        var updated = state
        let playerIndex = updated.currentPlayerIndex
        let playerId = updated.players[playerIndex].playerId
        var touches: [CricketDartTouch] = []
        var totalPointsAdded = 0

        for (offset, dart) in darts.enumerated() {
            let order = offset + 1
            guard let targetRaw = dart.segment.cricketTargetRaw, let target = cricketTarget(from: targetRaw) else {
                touches.append(
                    CricketDartTouch(
                        dartOrder: order,
                        targetRaw: "miss",
                        multiplierRaw: dart.multiplier.rawValue,
                        marksAdded: 0,
                        overflowMarks: 0,
                        pointsAdded: 0,
                        wasMiss: true,
                        segmentRaw: segmentRaw(for: dart.segment)
                    )
                )
                continue
            }

            let incomingMarks = marksForCricket(dart: dart)
            let beforeMarks = updated.players[playerIndex].marks[target.rawValue] ?? 0
            let neededToClose = max(0, 3 - beforeMarks)
            let marksAdded = min(neededToClose, incomingMarks)
            let overflow = max(0, incomingMarks - marksAdded)
            updated.players[playerIndex].marks[target.rawValue] = min(3, beforeMarks + incomingMarks)

            let scoring = applyOverflowScoring(
                target: target,
                overflowMarks: overflow,
                actingPlayerIndex: playerIndex,
                state: &updated
            )
            updated.players[playerIndex].score += scoring.throwerPoints
            totalPointsAdded += scoring.visitTotal

            touches.append(
                CricketDartTouch(
                    dartOrder: order,
                    targetRaw: target.rawValue,
                    multiplierRaw: dart.multiplier.rawValue,
                    marksAdded: marksAdded,
                    overflowMarks: overflow,
                    pointsAdded: scoring.visitTotal,
                    wasMiss: dart.isMiss,
                    segmentRaw: segmentRaw(for: dart.segment)
                )
            )
        }

        if let legWinnerIndex = legWinnerIndex(after: updated, actingPlayerIndex: playerIndex) {
            completeLeg(&updated, winnerIndex: legWinnerIndex)
        }

        if !updated.isComplete {
            updated.currentPlayerIndex = (playerIndex + 1) % updated.players.count
            if updated.currentPlayerIndex == 0 {
                updated.roundIndex += 1
            }
        }
        updated.turnIndex += 1

        let event = CricketTurnEvent(
            payloadVersion: 2,
            id: UUID(),
            playerId: playerId,
            turnIndex: state.turnIndex,
            roundIndex: state.roundIndex,
            legIndex: state.legIndex,
            setIndex: state.setIndex,
            totalPointsAdded: totalPointsAdded,
            targetsTouched: touches,
            timestamp: timestamp
        )
        return CricketTurnOutcome(updatedState: updated, event: event)
    }

    public static func replay(
        config: MatchConfigCricket,
        playerIds: [UUID],
        events: [CricketTurnEvent]
    ) throws -> CricketState {
        var state = try makeInitialState(config: config, playerIds: playerIds)
        for event in events {
            let darts = event.targetsTouched.map(dartInput(from:))
            state = try submitTurn(state: state, darts: darts, timestamp: event.timestamp).updatedState
        }
        return state
    }

    /// Reconstructs the original `DartInput` from a persisted touch.
    public static func dartInput(from touch: CricketDartTouch) -> DartInput {
        let multiplier = DartMultiplier(rawValue: touch.multiplierRaw) ?? .single
        let segment = touch.segmentRaw.map(segment(fromRaw:)) ?? parseTargetToSegment(touch.targetRaw)
        return DartInput(multiplier: multiplier, segment: segment, isMiss: touch.wasMiss)
    }

    private struct OverflowScoringResult {
        let throwerPoints: Int
        let visitTotal: Int
    }

    private static func applyOverflowScoring(
        target: CricketTarget,
        overflowMarks: Int,
        actingPlayerIndex: Int,
        state: inout CricketState
    ) -> OverflowScoringResult {
        guard overflowMarks > 0, state.config.pointsEnabled else {
            return OverflowScoringResult(throwerPoints: 0, visitTotal: 0)
        }
        let valuePerMark = target.points
        switch state.config.scoringMode {
        case .standard:
            let anyOpponentOpen = state.players.enumerated().contains { index, player in
                guard index != actingPlayerIndex else { return false }
                return (player.marks[target.rawValue] ?? 0) < 3
            }
            guard anyOpponentOpen else { return OverflowScoringResult(throwerPoints: 0, visitTotal: 0) }
            let points = overflowMarks * valuePerMark
            return OverflowScoringResult(throwerPoints: points, visitTotal: points)
        case .cutThroat:
            var inflicted = 0
            for index in state.players.indices where index != actingPlayerIndex {
                guard (state.players[index].marks[target.rawValue] ?? 0) < 3 else { continue }
                let credit = overflowMarks * valuePerMark
                state.players[index].score += credit
                inflicted += credit
            }
            return OverflowScoringResult(throwerPoints: 0, visitTotal: inflicted)
        }
    }

    private static func legWinnerIndex(after state: CricketState, actingPlayerIndex: Int) -> Int? {
        if state.config.pointsEnabled {
            guard allPlayersClosedAllTargets(state.players) else { return nil }
            return legWinnerIndex(in: state.players, config: state.config)
        }
        guard isPlayerClosedAllTargets(state.players[actingPlayerIndex]) else { return nil }
        return actingPlayerIndex
    }

    private static func completeLeg(_ state: inout CricketState, winnerIndex: Int) {
        state.players[winnerIndex].legsWon += 1
        state.legIndex += 1
        if state.players[winnerIndex].legsWon >= effectiveLegsToWin(state.config) {
            if state.config.setsEnabled {
                state.players[winnerIndex].setsWon += 1
                for index in state.players.indices {
                    state.players[index].legsWon = 0
                }
                state.setIndex += 1
                if state.players[winnerIndex].setsWon >= effectiveSetsToWin(state.config) {
                    state.winnerPlayerId = state.players[winnerIndex].playerId
                    state.isComplete = true
                }
            } else {
                state.winnerPlayerId = state.players[winnerIndex].playerId
                state.isComplete = true
            }
        }
        if !state.isComplete {
            resetLeg(&state)
        }
    }

    private static func resetLeg(_ state: inout CricketState) {
        let marksSeed = Dictionary(uniqueKeysWithValues: CricketTarget.allCases.map { ($0.rawValue, 0) })
        for index in state.players.indices {
            state.players[index].score = 0
            state.players[index].marks = marksSeed
        }
    }

    private static func effectiveLegsToWin(_ config: MatchConfigCricket) -> Int {
        switch config.legFormat {
        case .firstTo: return config.legsToWin
        case .bestOf: return config.legsToWin / 2 + 1
        }
    }

    private static func effectiveSetsToWin(_ config: MatchConfigCricket) -> Int {
        let target = config.setsToWin ?? 1
        switch config.legFormat {
        case .firstTo: return target
        case .bestOf: return target / 2 + 1
        }
    }

    public static func isTargetClosedByAllPlayers(_ players: [CricketPlayerState], target: CricketTarget) -> Bool {
        guard !players.isEmpty else { return false }
        return players.allSatisfy { ($0.marks[target.rawValue] ?? 0) >= 3 }
    }

    private static func isPlayerClosedAllTargets(_ player: CricketPlayerState) -> Bool {
        CricketTarget.allCases.allSatisfy { (player.marks[$0.rawValue] ?? 0) >= 3 }
    }

    private static func allPlayersClosedAllTargets(_ players: [CricketPlayerState]) -> Bool {
        players.allSatisfy(isPlayerClosedAllTargets)
    }

    private static func legWinnerIndex(in players: [CricketPlayerState], config: MatchConfigCricket) -> Int? {
        switch config.scoringMode {
        case .standard:
            guard let maxScore = players.map(\.score).max() else { return nil }
            return players.firstIndex { $0.score == maxScore }
        case .cutThroat:
            guard let minScore = players.map(\.score).min() else { return nil }
            return players.firstIndex { $0.score == minScore }
        }
    }

    private static func marksForCricket(dart: DartInput) -> Int {
        guard !dart.isMiss else { return 0 }
        switch dart.segment {
        case .innerBull:
            return 2
        case .outerBull:
            return 1
        case .oneToTwenty:
            return dart.multiplier.markValue
        case .miss:
            return 0
        }
    }

    private static func cricketTarget(from raw: String) -> CricketTarget? {
        CricketTarget(rawValue: raw)
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

    private static func parseTargetToSegment(_ raw: String) -> DartSegment {
        switch raw {
        case "bull":
            return .outerBull
        default:
            if let value = Int(raw), (15 ... 20).contains(value) {
                return .oneToTwenty(value)
            }
            return .miss
        }
    }
}
