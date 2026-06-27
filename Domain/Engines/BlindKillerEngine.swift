import Foundation

/// Serialisable configuration for a Blind Killer match.
public struct MatchConfigBlindKiller: Codable, Equatable, Sendable {
    public static let currentPayloadVersion = 1

    public let payloadVersion: Int
    public let hitsToEliminate: Int
    public let assignmentSeed: UInt64
    /// UUID string → secret segment 1…20; populated when the match starts.
    public let secretAssignmentsByPlayerId: [String: Int]

    public init(
        payloadVersion: Int = currentPayloadVersion,
        hitsToEliminate: Int = 3,
        assignmentSeed: UInt64,
        secretAssignmentsByPlayerId: [String: Int] = [:]
    ) {
        self.payloadVersion = payloadVersion
        self.hitsToEliminate = min(5, max(2, hitsToEliminate))
        self.assignmentSeed = assignmentSeed
        self.secretAssignmentsByPlayerId = secretAssignmentsByPlayerId
    }

    public func secretNumber(for playerId: UUID) -> Int? {
        secretAssignmentsByPlayerId[playerId.uuidString]
    }

    public func withAssignments(_ assignments: [UUID: Int]) -> MatchConfigBlindKiller {
        let encoded = Dictionary(uniqueKeysWithValues: assignments.map { ($0.key.uuidString, $0.value) })
        return MatchConfigBlindKiller(
            payloadVersion: payloadVersion,
            hitsToEliminate: hitsToEliminate,
            assignmentSeed: assignmentSeed,
            secretAssignmentsByPlayerId: encoded
        )
    }
}

public struct BlindKillerDartResolution: Codable, Equatable, Sendable {
    public let segmentRaw: String
    public let multiplierRaw: String
    public let wasMiss: Bool
    public let doubleHitSegment: Int?

    public init(
        segmentRaw: String,
        multiplierRaw: String,
        wasMiss: Bool,
        doubleHitSegment: Int? = nil
    ) {
        self.segmentRaw = segmentRaw
        self.multiplierRaw = multiplierRaw
        self.wasMiss = wasMiss
        self.doubleHitSegment = doubleHitSegment
    }
}

public struct BlindKillerTurnEvent: Codable, Equatable, Identifiable, Sendable {
    public let payloadVersion: Int
    public let id: UUID
    public let playerId: UUID
    public let turnIndex: Int
    public let darts: [BlindKillerDartResolution]
    public let eliminatedPlayerIds: [UUID]
    public let matchCompleted: Bool
    public let timestamp: Date

    public init(
        payloadVersion: Int = 1,
        id: UUID = UUID(),
        playerId: UUID,
        turnIndex: Int,
        darts: [BlindKillerDartResolution],
        eliminatedPlayerIds: [UUID],
        matchCompleted: Bool,
        timestamp: Date
    ) {
        self.payloadVersion = payloadVersion
        self.id = id
        self.playerId = playerId
        self.turnIndex = turnIndex
        self.darts = darts
        self.eliminatedPlayerIds = eliminatedPlayerIds
        self.matchCompleted = matchCompleted
        self.timestamp = timestamp
    }
}

public struct BlindKillerPlayerState: Codable, Equatable, Sendable {
    public let playerId: UUID
    public var isEliminated: Bool

    public init(playerId: UUID, isEliminated: Bool = false) {
        self.playerId = playerId
        self.isEliminated = isEliminated
    }
}

public struct BlindKillerState: Codable, Equatable, Sendable {
    public let config: MatchConfigBlindKiller
    public var players: [BlindKillerPlayerState]
    /// Double-hit tally per segment 1…20 (`index 0` unused).
    public var segmentHitCounts: [Int]
    public var currentPlayerIndex: Int
    public var turnIndex: Int
    public var winnerPlayerId: UUID?
    public var isComplete: Bool

    public init(
        config: MatchConfigBlindKiller,
        players: [BlindKillerPlayerState],
        segmentHitCounts: [Int] = Array(repeating: 0, count: 21),
        currentPlayerIndex: Int = 0,
        turnIndex: Int = 0,
        winnerPlayerId: UUID? = nil,
        isComplete: Bool = false
    ) {
        self.config = config
        self.players = players
        self.segmentHitCounts = segmentHitCounts
        self.currentPlayerIndex = currentPlayerIndex
        self.turnIndex = turnIndex
        self.winnerPlayerId = winnerPlayerId
        self.isComplete = isComplete
    }

    public func secretNumber(for playerId: UUID) -> Int? {
        config.secretNumber(for: playerId)
    }

    public var currentPlayerId: UUID? {
        guard !isComplete, players.indices.contains(currentPlayerIndex) else { return nil }
        return players[currentPlayerIndex].playerId
    }
}

public struct BlindKillerTurnOutcome: Sendable {
    public let updatedState: BlindKillerState
    public let event: BlindKillerTurnEvent
}

public enum BlindKillerEngine {

    // MARK: - Public API

    public static func makeAssignments(playerIds: [UUID], seed: UInt64) -> [UUID: Int] {
        var rng = SeededRandomNumberGenerator(seed: seed)
        var numbers = Array(1 ... 20)
        numbers.shuffle(using: &rng)
        var result: [UUID: Int] = [:]
        for (index, playerId) in playerIds.enumerated() {
            result[playerId] = numbers[index]
        }
        return result
    }

    public static func resolvedConfig(
        _ config: MatchConfigBlindKiller,
        playerIds: [UUID]
    ) -> MatchConfigBlindKiller {
        guard config.secretAssignmentsByPlayerId.isEmpty else { return config }
        return config.withAssignments(makeAssignments(playerIds: playerIds, seed: config.assignmentSeed))
    }

    public static func makeInitialState(
        config: MatchConfigBlindKiller,
        playerIds: [UUID]
    ) throws -> BlindKillerState {
        guard playerIds.count >= 3 else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "setup.validation.blindKillerMinimumPlayers"
            )
        }
        let resolved = resolvedConfig(config, playerIds: playerIds)
        guard resolved.secretAssignmentsByPlayerId.count == playerIds.count else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .error,
                isRecoverable: false,
                userMessageKey: "error.match.blindKiller.assignmentsMissing"
            )
        }
        let players = playerIds.map { BlindKillerPlayerState(playerId: $0) }
        return BlindKillerState(config: resolved, players: players)
    }

    public static func submitTurn(
        state: BlindKillerState,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> BlindKillerTurnOutcome {
        guard !state.isComplete else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.completed"
            )
        }
        guard darts.count >= 1, darts.count <= 3 else {
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
        guard !updated.players[playerIndex].isEliminated else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.blindKiller.alreadyEliminated"
            )
        }

        var resolutions: [BlindKillerDartResolution] = []
        var eliminatedThisTurn: [UUID] = []

        for dart in darts {
            let segment = doubleHitSegment(from: dart)
            let resolution = BlindKillerDartResolution(
                segmentRaw: segmentRaw(for: dart.segment),
                multiplierRaw: dart.multiplier.rawValue,
                wasMiss: dart.isMiss || segment == nil,
                doubleHitSegment: segment
            )
            resolutions.append(resolution)

            if let segment {
                updated.segmentHitCounts[segment] += 1
                if updated.segmentHitCounts[segment] >= updated.config.hitsToEliminate,
                   let victimId = holderPlayerId(forSegment: segment, in: updated) {
                    eliminate(playerId: victimId, in: &updated)
                    if !eliminatedThisTurn.contains(victimId) {
                        eliminatedThisTurn.append(victimId)
                    }
                }
            }
        }

        updated.turnIndex += 1
        var matchCompleted = false
        checkLastStanding(&updated)
        if updated.isComplete {
            matchCompleted = true
        } else {
            advanceTurn(&updated)
        }

        let event = BlindKillerTurnEvent(
            playerId: playerId,
            turnIndex: state.turnIndex,
            darts: resolutions,
            eliminatedPlayerIds: eliminatedThisTurn,
            matchCompleted: matchCompleted,
            timestamp: timestamp
        )
        return BlindKillerTurnOutcome(updatedState: updated, event: event)
    }

    public static func dartInput(from resolution: BlindKillerDartResolution) -> DartInput {
        guard !resolution.wasMiss, let segment = resolution.doubleHitSegment else {
            return DartInput(multiplier: .single, segment: .miss, isMiss: true)
        }
        return DartInput(multiplier: .double, segment: .oneToTwenty(segment), isMiss: false)
    }

    // MARK: - Helpers

    static func doubleHitSegment(from dart: DartInput) -> Int? {
        guard !dart.isMiss, dart.multiplier == .double else { return nil }
        guard case let .oneToTwenty(value) = dart.segment, (1 ... 20).contains(value) else { return nil }
        return value
    }

    private static func holderPlayerId(forSegment segment: Int, in state: BlindKillerState) -> UUID? {
        state.players.first { player in
            !player.isEliminated && state.secretNumber(for: player.playerId) == segment
        }?.playerId
    }

    private static func eliminate(playerId: UUID, in state: inout BlindKillerState) {
        guard let index = state.players.firstIndex(where: { $0.playerId == playerId }) else { return }
        state.players[index].isEliminated = true
    }

    private static func advanceTurn(_ state: inout BlindKillerState) {
        guard !state.isComplete else { return }
        guard let nextIndex = nextActivePlayerIndex(after: state.currentPlayerIndex, in: state) else {
            checkLastStanding(&state)
            return
        }
        state.currentPlayerIndex = nextIndex
    }

    private static func nextActivePlayerIndex(after index: Int, in state: BlindKillerState) -> Int? {
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

    private static func checkLastStanding(_ state: inout BlindKillerState) {
        let active = state.players.filter { !$0.isEliminated }
        guard active.count <= 1 else { return }
        state.isComplete = true
        state.winnerPlayerId = active.first?.playerId
    }

    private static func segmentRaw(for segment: DartSegment) -> String {
        switch segment {
        case let .oneToTwenty(value): return String(value)
        case .outerBull: return "outerBull"
        case .innerBull: return "innerBull"
        case .miss: return "miss"
        }
    }
}
