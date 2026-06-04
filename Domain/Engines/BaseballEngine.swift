import Foundation

public enum BaseballTieBreaker: String, Codable, CaseIterable, Sendable {
    case extraInnings
    case bullPlayoff

    public var displayName: String {
        switch self {
        case .extraInnings: L10n.string("play.baseball.tieBreaker.extraInnings")
        case .bullPlayoff: L10n.string("play.baseball.tieBreaker.bullPlayoff")
        }
    }
}

public enum BaseballPhase: String, Codable, Sendable {
    case innings
    case bullPlayoff
    case completed
}

public struct MatchConfigBaseball: Codable, Equatable, Sendable {
    public static let currentPayloadVersion = 1

    public let payloadVersion: Int
    public let inningCount: Int
    public let tieBreakerRaw: String
    public let seventhInningStretch: Bool

    public var tieBreaker: BaseballTieBreaker {
        BaseballTieBreaker(rawValue: tieBreakerRaw) ?? .extraInnings
    }

    public init(
        payloadVersion: Int = currentPayloadVersion,
        inningCount: Int = 9,
        tieBreaker: BaseballTieBreaker = .extraInnings,
        seventhInningStretch: Bool = false
    ) {
        self.payloadVersion = payloadVersion
        self.inningCount = max(1, inningCount)
        self.tieBreakerRaw = tieBreaker.rawValue
        self.seventhInningStretch = seventhInningStretch
    }
}

public struct BaseballDartEvent: Codable, Equatable, Sendable {
    public let dartOrder: Int
    public let segmentRaw: String
    public let multiplierRaw: String
    public let runsAwarded: Int
    public let wasMiss: Bool
    public let openedStretchGate: Bool

    public init(
        dartOrder: Int,
        segmentRaw: String,
        multiplierRaw: String,
        runsAwarded: Int,
        wasMiss: Bool,
        openedStretchGate: Bool = false
    ) {
        self.dartOrder = dartOrder
        self.segmentRaw = segmentRaw
        self.multiplierRaw = multiplierRaw
        self.runsAwarded = runsAwarded
        self.wasMiss = wasMiss
        self.openedStretchGate = openedStretchGate
    }
}

public struct BaseballTurnEvent: Codable, Equatable, Identifiable, Sendable {
    public let payloadVersion: Int
    public let id: UUID
    public let playerId: UUID
    public let turnIndex: Int
    public let inning: Int
    public let phaseRaw: String
    public let legIndex: Int?
    public let runsThisVisit: Int
    public let cumulativeRunsAfterTurn: Int
    public let darts: [BaseballDartEvent]
    public let timestamp: Date

    public var phase: BaseballPhase {
        BaseballPhase(rawValue: phaseRaw) ?? .innings
    }

    public var effectiveLegIndex: Int { legIndex ?? 0 }
}

public struct BaseballPlayerState: Codable, Equatable, Sendable {
    public let playerId: UUID
    public var cumulativeRuns: Int
    public var runsThisInning: Int
    public var stretchGateOpen: Bool
    public var playoffRunsThisRound: Int

    public init(
        playerId: UUID,
        cumulativeRuns: Int = 0,
        runsThisInning: Int = 0,
        stretchGateOpen: Bool = false,
        playoffRunsThisRound: Int = 0
    ) {
        self.playerId = playerId
        self.cumulativeRuns = cumulativeRuns
        self.runsThisInning = runsThisInning
        self.stretchGateOpen = stretchGateOpen
        self.playoffRunsThisRound = playoffRunsThisRound
    }
}

public struct BaseballState: Codable, Equatable, Sendable {
    public let config: MatchConfigBaseball
    public var players: [BaseballPlayerState]
    public var currentPlayerIndex: Int
    public var turnIndex: Int
    public var currentInning: Int
    public var phase: BaseballPhase
    public var isExtraInning: Bool
    public var playoffRound: Int
    /// Player indices (into `players`) participating in the current bull playoff round.
    public var playoffPlayerIndices: [Int]
    public var winnerPlayerId: UUID?
    public var isComplete: Bool

    public init(
        config: MatchConfigBaseball,
        players: [BaseballPlayerState],
        currentPlayerIndex: Int,
        turnIndex: Int,
        currentInning: Int,
        phase: BaseballPhase = .innings,
        isExtraInning: Bool = false,
        playoffRound: Int = 0,
        playoffPlayerIndices: [Int] = [],
        winnerPlayerId: UUID? = nil,
        isComplete: Bool = false
    ) {
        self.config = config
        self.players = players
        self.currentPlayerIndex = currentPlayerIndex
        self.turnIndex = turnIndex
        self.currentInning = currentInning
        self.phase = phase
        self.isExtraInning = isExtraInning
        self.playoffRound = playoffRound
        self.playoffPlayerIndices = playoffPlayerIndices
        self.winnerPlayerId = winnerPlayerId
        self.isComplete = isComplete
    }
}

public struct BaseballTurnOutcome: Sendable {
    public let updatedState: BaseballState
    public let event: BaseballTurnEvent
}

public enum BaseballEngine {
    public static func makeInitialState(config: MatchConfigBaseball, playerIds: [UUID]) throws -> BaseballState {
        guard config.inningCount > 0 else {
            throw AppError(code: .validationFailed, layer: .domain, severity: .warning, isRecoverable: true, userMessageKey: "error.match.baseball.invalidInningCount")
        }
        guard playerIds.count >= 2 else {
            throw AppError(code: .validationFailed, layer: .domain, severity: .warning, isRecoverable: true, userMessageKey: "error.match.players.minimum")
        }
        let players = playerIds.map { BaseballPlayerState(playerId: $0) }
        return BaseballState(
            config: config,
            players: players,
            currentPlayerIndex: 0,
            turnIndex: 0,
            currentInning: 1,
            phase: .innings
        )
    }

    public static func submitTurn(
        state: BaseballState,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> BaseballTurnOutcome {
        guard !state.isComplete else {
            throw AppError(code: .invalidGameState, layer: .domain, severity: .warning, isRecoverable: true, userMessageKey: "error.match.completed")
        }
        guard darts.count <= 3 else {
            throw AppError(code: .validationFailed, layer: .domain, severity: .warning, isRecoverable: true, userMessageKey: "error.turn.maxDarts")
        }

        var updated = state
        let playerIndex = updated.currentPlayerIndex
        let playerId = updated.players[playerIndex].playerId
        var dartEvents: [BaseballDartEvent] = []
        var visitRuns = 0

        for (offset, dart) in darts.enumerated() {
            let resolution = resolveDart(dart, state: updated, playerIndex: playerIndex)
            if resolution.openedStretchGate {
                updated.players[playerIndex].stretchGateOpen = true
            }
            visitRuns += resolution.runs
            dartEvents.append(
                BaseballDartEvent(
                    dartOrder: offset + 1,
                    segmentRaw: segmentRaw(for: dart.segment),
                    multiplierRaw: dart.multiplier.rawValue,
                    runsAwarded: resolution.runs,
                    wasMiss: dart.isMiss,
                    openedStretchGate: resolution.openedStretchGate
                )
            )
        }

        switch updated.phase {
        case .innings:
            updated.players[playerIndex].runsThisInning += visitRuns
            updated.players[playerIndex].cumulativeRuns += visitRuns
        case .bullPlayoff:
            updated.players[playerIndex].playoffRunsThisRound += visitRuns
        case .completed:
            break
        }

        advanceTurn(&updated)

        let cumulativeAfter = updated.players[playerIndex].cumulativeRuns
        let event = BaseballTurnEvent(
            payloadVersion: 1,
            id: UUID(),
            playerId: playerId,
            turnIndex: state.turnIndex,
            inning: state.currentInning,
            phaseRaw: state.phase.rawValue,
            legIndex: state.currentInning - 1,
            runsThisVisit: visitRuns,
            cumulativeRunsAfterTurn: cumulativeAfter,
            darts: dartEvents,
            timestamp: timestamp
        )
        return BaseballTurnOutcome(updatedState: updated, event: event)
    }

    public static func replay(
        config: MatchConfigBaseball,
        playerIds: [UUID],
        events: [BaseballTurnEvent]
    ) throws -> BaseballState {
        var state = try makeInitialState(config: config, playerIds: playerIds)
        for event in events {
            let darts = event.darts.map(dartInput(from:))
            state = try submitTurn(state: state, darts: darts, timestamp: event.timestamp).updatedState
        }
        return state
    }

    public static func dartInput(from event: BaseballDartEvent) -> DartInput {
        DartInput(
            multiplier: DartMultiplier(rawValue: event.multiplierRaw) ?? .single,
            segment: segment(fromRaw: event.segmentRaw),
            isMiss: event.wasMiss
        )
    }

    // MARK: - Resolution

    private struct DartResolution {
        let runs: Int
        let openedStretchGate: Bool
    }

    private static func resolveDart(_ dart: DartInput, state: BaseballState, playerIndex: Int) -> DartResolution {
        if dart.isMiss {
            return DartResolution(runs: 0, openedStretchGate: false)
        }

        switch state.phase {
        case .bullPlayoff:
            return DartResolution(runs: bullPlayoffRuns(for: dart), openedStretchGate: false)
        case .innings:
            return resolveInningsDart(dart, state: state, playerIndex: playerIndex)
        case .completed:
            return DartResolution(runs: 0, openedStretchGate: false)
        }
    }

    private static func resolveInningsDart(_ dart: DartInput, state: BaseballState, playerIndex: Int) -> DartResolution {
        let target = state.currentInning
        let stretchActive = state.config.seventhInningStretch && target == 7
        let gateOpen = state.players[playerIndex].stretchGateOpen

        if stretchActive, !gateOpen {
            if isBull(dart.segment) {
                return DartResolution(runs: 0, openedStretchGate: true)
            }
            if segmentValue(dart.segment) == target {
                return DartResolution(runs: 0, openedStretchGate: false)
            }
            return DartResolution(runs: 0, openedStretchGate: false)
        }

        guard segmentValue(dart.segment) == target else {
            return DartResolution(runs: 0, openedStretchGate: false)
        }

        return DartResolution(runs: multiplierRuns(dart.multiplier), openedStretchGate: false)
    }

    private static func bullPlayoffRuns(for dart: DartInput) -> Int {
        switch dart.segment {
        case .outerBull: return 1
        case .innerBull: return 2
        default: return 0
        }
    }

    private static func multiplierRuns(_ multiplier: DartMultiplier) -> Int {
        switch multiplier {
        case .single: return 1
        case .double: return 2
        case .triple: return 3
        }
    }

    private static func isBull(_ segment: DartSegment) -> Bool {
        switch segment {
        case .outerBull, .innerBull: return true
        default: return false
        }
    }

    private static func segmentValue(_ segment: DartSegment) -> Int? {
        switch segment {
        case let .oneToTwenty(value): return value
        default: return nil
        }
    }

    // MARK: - Progression

    private static func advanceTurn(_ state: inout BaseballState) {
        state.turnIndex += 1
        guard !state.isComplete else { return }

        switch state.phase {
        case .innings:
            advanceInningsTurn(&state)
        case .bullPlayoff:
            advancePlayoffTurn(&state)
        case .completed:
            break
        }
    }

    private static func advanceInningsTurn(_ state: inout BaseballState) {
        let playerCount = state.players.count
        let wasLastPlayerInInning = state.currentPlayerIndex == playerCount - 1
        state.currentPlayerIndex = (state.currentPlayerIndex + 1) % playerCount

        guard wasLastPlayerInInning else { return }

        let completedInning = state.currentInning
        resetInningScratch(&state)

        if completedInning >= state.config.inningCount {
            if let winnerId = singleLeader(in: state.players) {
                completeMatch(&state, winnerId: winnerId)
                return
            }
            switch state.config.tieBreaker {
            case .extraInnings:
                state.isExtraInning = true
                state.currentInning = completedInning + 1
                prepareInningStart(&state)
            case .bullPlayoff:
                enterBullPlayoff(&state)
            }
        } else {
            state.currentInning = completedInning + 1
            prepareInningStart(&state)
        }
    }

    private static func advancePlayoffTurn(_ state: inout BaseballState) {
        guard !state.playoffPlayerIndices.isEmpty else { return }
        guard let position = state.playoffPlayerIndices.firstIndex(of: state.currentPlayerIndex) else { return }
        let nextPosition = (position + 1) % state.playoffPlayerIndices.count
        let completedRound = nextPosition == 0

        if completedRound {
            if let winnerIndex = playoffRoundWinner(in: state) {
                completeMatch(&state, winnerId: state.players[winnerIndex].playerId)
                return
            }
            state.playoffRound += 1
            for index in state.playoffPlayerIndices {
                state.players[index].playoffRunsThisRound = 0
            }
        }

        state.currentPlayerIndex = state.playoffPlayerIndices[nextPosition]
    }

    private static func resetInningScratch(_ state: inout BaseballState) {
        for index in state.players.indices {
            state.players[index].runsThisInning = 0
        }
    }

    private static func prepareInningStart(_ state: inout BaseballState) {
        guard state.config.seventhInningStretch, state.currentInning == 7 else { return }
        for index in state.players.indices {
            state.players[index].stretchGateOpen = false
        }
    }

    private static func enterBullPlayoff(_ state: inout BaseballState) {
        let tiedIndices = tiedLeaderIndices(in: state.players)
        guard !tiedIndices.isEmpty else { return }
        state.phase = .bullPlayoff
        state.playoffRound = 1
        state.playoffPlayerIndices = tiedIndices
        for index in tiedIndices {
            state.players[index].playoffRunsThisRound = 0
        }
        state.currentPlayerIndex = tiedIndices[0]
    }

    private static func completeMatch(_ state: inout BaseballState, winnerId: UUID) {
        state.winnerPlayerId = winnerId
        state.isComplete = true
        state.phase = .completed
        state.currentPlayerIndex = 0
    }

    private static func singleLeader(in players: [BaseballPlayerState]) -> UUID? {
        guard let maxRuns = players.map(\.cumulativeRuns).max() else { return nil }
        let leaders = players.filter { $0.cumulativeRuns == maxRuns }
        guard leaders.count == 1 else { return nil }
        return leaders[0].playerId
    }

    private static func tiedLeaderIndices(in players: [BaseballPlayerState]) -> [Int] {
        guard let maxRuns = players.map(\.cumulativeRuns).max() else { return [] }
        return players.indices.filter { players[$0].cumulativeRuns == maxRuns }
    }

    private static func playoffRoundWinner(in state: BaseballState) -> Int? {
        let indices = state.playoffPlayerIndices
        guard !indices.isEmpty else { return nil }
        let scores = indices.map { state.players[$0].playoffRunsThisRound }
        guard let maxScore = scores.max() else { return nil }
        let leaders = indices.filter { state.players[$0].playoffRunsThisRound == maxScore }
        guard leaders.count == 1 else { return nil }
        return leaders[0]
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
