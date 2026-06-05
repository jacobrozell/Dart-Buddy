import Foundation

public enum KillerPhase: String, Codable, Sendable {
    case numberPick
    case playing
    case completed
}

public struct MatchConfigKiller: Codable, Equatable, Sendable {
    public static let currentPayloadVersion = 1

    public let payloadVersion: Int
    public let startingLives: Int
    public let bullAllowedOnPick: Bool

    public init(
        payloadVersion: Int = currentPayloadVersion,
        startingLives: Int = 3,
        bullAllowedOnPick: Bool = false
    ) {
        self.payloadVersion = payloadVersion
        self.startingLives = min(5, max(3, startingLives))
        self.bullAllowedOnPick = bullAllowedOnPick
    }
}

public struct KillerDartResolution: Codable, Equatable, Sendable {
    public let segmentRaw: String
    public let multiplierRaw: String
    public let wasMiss: Bool
    public let becameKiller: Bool
    public let lifeDeltas: [UUID: Int]

    public init(
        segmentRaw: String,
        multiplierRaw: String,
        wasMiss: Bool,
        becameKiller: Bool = false,
        lifeDeltas: [UUID: Int] = [:]
    ) {
        self.segmentRaw = segmentRaw
        self.multiplierRaw = multiplierRaw
        self.wasMiss = wasMiss
        self.becameKiller = becameKiller
        self.lifeDeltas = lifeDeltas
    }
}

public struct KillerPickEvent: Codable, Equatable, Identifiable, Sendable {
    public let payloadVersion: Int
    public let id: UUID
    public let playerId: UUID
    public let eventIndex: Int
    public let assignedNumber: Int?
    public let wasRetake: Bool
    public let segmentRaw: String
    public let multiplierRaw: String
    public let wasMiss: Bool
    public let timestamp: Date

    public init(
        payloadVersion: Int = 1,
        id: UUID = UUID(),
        playerId: UUID,
        eventIndex: Int,
        assignedNumber: Int?,
        wasRetake: Bool,
        segmentRaw: String,
        multiplierRaw: String,
        wasMiss: Bool,
        timestamp: Date
    ) {
        self.payloadVersion = payloadVersion
        self.id = id
        self.playerId = playerId
        self.eventIndex = eventIndex
        self.assignedNumber = assignedNumber
        self.wasRetake = wasRetake
        self.segmentRaw = segmentRaw
        self.multiplierRaw = multiplierRaw
        self.wasMiss = wasMiss
        self.timestamp = timestamp
    }
}

public struct KillerTurnEvent: Codable, Equatable, Identifiable, Sendable {
    public let payloadVersion: Int
    public let id: UUID
    public let playerId: UUID
    public let turnIndex: Int
    public let phaseRaw: String
    public let darts: [KillerDartResolution]
    public let timestamp: Date

    public var phase: KillerPhase {
        KillerPhase(rawValue: phaseRaw) ?? .playing
    }

    public init(
        payloadVersion: Int = 1,
        id: UUID = UUID(),
        playerId: UUID,
        turnIndex: Int,
        phaseRaw: String = KillerPhase.playing.rawValue,
        darts: [KillerDartResolution],
        timestamp: Date
    ) {
        self.payloadVersion = payloadVersion
        self.id = id
        self.playerId = playerId
        self.turnIndex = turnIndex
        self.phaseRaw = phaseRaw
        self.darts = darts
        self.timestamp = timestamp
    }
}

public struct KillerPlayerState: Codable, Equatable, Sendable {
    public let playerId: UUID
    public var assignedNumber: Int?
    public var lives: Int
    public var isKiller: Bool
    public var isEliminated: Bool

    public init(
        playerId: UUID,
        assignedNumber: Int? = nil,
        lives: Int,
        isKiller: Bool = false,
        isEliminated: Bool = false
    ) {
        self.playerId = playerId
        self.assignedNumber = assignedNumber
        self.lives = lives
        self.isKiller = isKiller
        self.isEliminated = isEliminated
    }
}

public struct KillerState: Codable, Equatable, Sendable {
    public let config: MatchConfigKiller
    public var players: [KillerPlayerState]
    public var phase: KillerPhase
    public var currentPlayerIndex: Int
    public var turnIndex: Int
    public var pickQueue: [UUID]
    public var winnerPlayerId: UUID?
    public var isComplete: Bool

    public init(
        config: MatchConfigKiller,
        players: [KillerPlayerState],
        phase: KillerPhase = .numberPick,
        currentPlayerIndex: Int = 0,
        turnIndex: Int = 0,
        pickQueue: [UUID] = [],
        winnerPlayerId: UUID? = nil,
        isComplete: Bool = false
    ) {
        self.config = config
        self.players = players
        self.phase = phase
        self.currentPlayerIndex = currentPlayerIndex
        self.turnIndex = turnIndex
        self.pickQueue = pickQueue
        self.winnerPlayerId = winnerPlayerId
        self.isComplete = isComplete
    }
}

public struct KillerPickOutcome: Sendable {
    public let updatedState: KillerState
    public let event: KillerPickEvent
}

public struct KillerTurnOutcome: Sendable {
    public let updatedState: KillerState
    public let event: KillerTurnEvent
}

public enum KillerEngine {
    public static func makeInitialState(config: MatchConfigKiller, playerIds: [UUID]) throws -> KillerState {
        guard playerIds.count >= 3 else {
            throw AppError(
                code: .validationFailed,
                layer: .domain,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.players.killerMinimum"
            )
        }
        let players = playerIds.map {
            KillerPlayerState(playerId: $0, lives: config.startingLives)
        }
        return KillerState(
            config: config,
            players: players,
            phase: .numberPick,
            pickQueue: playerIds
        )
    }

    public static func submitPick(
        state: KillerState,
        dart: DartInput,
        timestamp: Date = Date()
    ) throws -> KillerPickOutcome {
        guard state.phase == .numberPick else {
            throw AppError(code: .invalidGameState, layer: .domain, severity: .warning, isRecoverable: true, userMessageKey: "error.match.killer.notPickPhase")
        }
        guard !state.pickQueue.isEmpty else {
            throw AppError(code: .invalidGameState, layer: .domain, severity: .warning, isRecoverable: true, userMessageKey: "error.match.killer.pickComplete")
        }

        var updated = state
        let pickerId = updated.pickQueue[0]
        let segmentValue = segmentValue(from: dart)
        let isMiss = dart.isMiss || segmentValue == nil || isBull(dart.segment) && !updated.config.bullAllowedOnPick
        let takenNumbers = Set(updated.players.compactMap(\.assignedNumber))
        let numberTaken = segmentValue.map { takenNumbers.contains($0) } ?? false
        let assignedNumber = (!isMiss && !numberTaken) ? segmentValue : nil

        if let number = assignedNumber {
            guard let index = updated.players.firstIndex(where: { $0.playerId == pickerId }) else {
                throw AppError(code: .invalidGameState, layer: .domain, severity: .error, isRecoverable: false, userMessageKey: "error.match.killer.playerMissing")
            }
            updated.players[index].assignedNumber = number
            updated.pickQueue.removeFirst()
            if updated.pickQueue.isEmpty {
                updated.phase = .playing
                updated.currentPlayerIndex = firstActivePlayerIndex(in: updated) ?? 0
            }
        }

        let event = KillerPickEvent(
            playerId: pickerId,
            eventIndex: updated.turnIndex,
            assignedNumber: assignedNumber,
            wasRetake: isMiss || numberTaken,
            segmentRaw: segmentRaw(for: dart.segment),
            multiplierRaw: dart.multiplier.rawValue,
            wasMiss: isMiss || numberTaken,
            timestamp: timestamp
        )
        updated.turnIndex += 1
        return KillerPickOutcome(updatedState: updated, event: event)
    }

    public static func submitTurn(
        state: KillerState,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> KillerTurnOutcome {
        guard state.phase == .playing else {
            throw AppError(code: .invalidGameState, layer: .domain, severity: .warning, isRecoverable: true, userMessageKey: "error.match.killer.notPlayingPhase")
        }
        guard !state.isComplete else {
            throw AppError(code: .invalidGameState, layer: .domain, severity: .warning, isRecoverable: true, userMessageKey: "error.match.completed")
        }
        guard darts.count >= 1, darts.count <= 3 else {
            throw AppError(code: .validationFailed, layer: .domain, severity: .warning, isRecoverable: true, userMessageKey: "error.turn.maxDarts")
        }

        var updated = state
        let playerIndex = updated.currentPlayerIndex
        let playerId = updated.players[playerIndex].playerId
        var resolutions: [KillerDartResolution] = []
        var throwerIsKiller = updated.players[playerIndex].isKiller

        for dart in darts {
            let resolution = resolveDart(
                dart,
                throwerIndex: playerIndex,
                throwerIsKiller: throwerIsKiller,
                state: updated
            )
            applyLifeDeltas(resolution.lifeDeltas, to: &updated)
            if resolution.becameKiller {
                updated.players[playerIndex].isKiller = true
                throwerIsKiller = true
            }
            resolutions.append(resolution)
        }

        updated.turnIndex += 1
        advanceTurn(&updated)

        let event = KillerTurnEvent(
            playerId: playerId,
            turnIndex: state.turnIndex,
            darts: resolutions,
            timestamp: timestamp
        )
        return KillerTurnOutcome(updatedState: updated, event: event)
    }

    public static func replay(
        config: MatchConfigKiller,
        playerIds: [UUID],
        picks: [KillerPickEvent],
        turns: [KillerTurnEvent]
    ) throws -> KillerState {
        var state = try makeInitialState(config: config, playerIds: playerIds)
        for pick in picks {
            let dart = dartInput(from: pick)
            state = try submitPick(state: state, dart: dart, timestamp: pick.timestamp).updatedState
        }
        for turn in turns {
            let darts = turn.darts.map(dartInput(from:))
            state = try submitTurn(state: state, darts: darts, timestamp: turn.timestamp).updatedState
        }
        return state
    }

    public static func dartInput(from pick: KillerPickEvent) -> DartInput {
        DartInput(
            multiplier: DartMultiplier(rawValue: pick.multiplierRaw) ?? .single,
            segment: segment(fromRaw: pick.segmentRaw),
            isMiss: pick.wasMiss
        )
    }

    public static func dartInput(from resolution: KillerDartResolution) -> DartInput {
        DartInput(
            multiplier: DartMultiplier(rawValue: resolution.multiplierRaw) ?? .single,
            segment: segment(fromRaw: resolution.segmentRaw),
            isMiss: resolution.wasMiss
        )
    }

    // MARK: - Resolution

    private static func resolveDart(
        _ dart: DartInput,
        throwerIndex: Int,
        throwerIsKiller: Bool,
        state: KillerState
    ) -> KillerDartResolution {
        if dart.isMiss {
            return KillerDartResolution(
                segmentRaw: segmentRaw(for: dart.segment),
                multiplierRaw: dart.multiplier.rawValue,
                wasMiss: true
            )
        }

        let thrower = state.players[throwerIndex]
        guard let ownNumber = thrower.assignedNumber else {
            return KillerDartResolution(
                segmentRaw: segmentRaw(for: dart.segment),
                multiplierRaw: dart.multiplier.rawValue,
                wasMiss: true
            )
        }

        guard let hitNumber = segmentValue(from: dart) else {
            return KillerDartResolution(
                segmentRaw: segmentRaw(for: dart.segment),
                multiplierRaw: dart.multiplier.rawValue,
                wasMiss: true
            )
        }

        if !throwerIsKiller, hitNumber == ownNumber, dart.multiplier == .double {
            return KillerDartResolution(
                segmentRaw: segmentRaw(for: dart.segment),
                multiplierRaw: dart.multiplier.rawValue,
                wasMiss: false,
                becameKiller: true
            )
        }

        guard throwerIsKiller, dart.multiplier == .double else {
            return KillerDartResolution(
                segmentRaw: segmentRaw(for: dart.segment),
                multiplierRaw: dart.multiplier.rawValue,
                wasMiss: false
            )
        }

        if hitNumber == ownNumber {
            return KillerDartResolution(
                segmentRaw: segmentRaw(for: dart.segment),
                multiplierRaw: dart.multiplier.rawValue,
                wasMiss: false,
                lifeDeltas: [thrower.playerId: -1]
            )
        }

        if let targetIndex = state.players.firstIndex(where: {
            $0.assignedNumber == hitNumber && !$0.isEliminated
        }) {
            let targetId = state.players[targetIndex].playerId
            return KillerDartResolution(
                segmentRaw: segmentRaw(for: dart.segment),
                multiplierRaw: dart.multiplier.rawValue,
                wasMiss: false,
                lifeDeltas: [targetId: -1]
            )
        }

        return KillerDartResolution(
            segmentRaw: segmentRaw(for: dart.segment),
            multiplierRaw: dart.multiplier.rawValue,
            wasMiss: false
        )
    }

    private static func applyLifeDeltas(_ deltas: [UUID: Int], to state: inout KillerState) {
        for (playerId, delta) in deltas {
            guard let index = state.players.firstIndex(where: { $0.playerId == playerId }) else { continue }
            state.players[index].lives = max(0, state.players[index].lives + delta)
            if state.players[index].lives == 0 {
                state.players[index].isEliminated = true
            }
        }
    }

    private static func advanceTurn(_ state: inout KillerState) {
        guard !state.isComplete else { return }
        guard let nextIndex = nextActivePlayerIndex(after: state.currentPlayerIndex, in: state) else {
            completeIfSingleSurvivor(&state)
            return
        }
        state.currentPlayerIndex = nextIndex
        completeIfSingleSurvivor(&state)
    }

    private static func nextActivePlayerIndex(after index: Int, in state: KillerState) -> Int? {
        let count = state.players.count
        guard count > 0 else { return nil }
        var cursor = (index + 1) % count
        for _ in 0 ..< count {
            if !state.players[cursor].isEliminated {
                return cursor
            }
            cursor = (cursor + 1) % count
        }
        return nil
    }

    private static func firstActivePlayerIndex(in state: KillerState) -> Int? {
        state.players.firstIndex(where: { !$0.isEliminated })
    }

    private static func completeIfSingleSurvivor(_ state: inout KillerState) {
        let survivors = state.players.filter { !$0.isEliminated }
        guard survivors.count == 1 else { return }
        state.winnerPlayerId = survivors[0].playerId
        state.isComplete = true
        state.phase = .completed
        state.currentPlayerIndex = state.players.firstIndex(where: { $0.playerId == survivors[0].playerId }) ?? 0
    }

    private static func segmentValue(from dart: DartInput) -> Int? {
        guard !dart.isMiss else { return nil }
        switch dart.segment {
        case let .oneToTwenty(value) where (1 ... 20).contains(value):
            return value
        default:
            return nil
        }
    }

    private static func isBull(_ segment: DartSegment) -> Bool {
        switch segment {
        case .outerBull, .innerBull: return true
        default: return false
        }
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
