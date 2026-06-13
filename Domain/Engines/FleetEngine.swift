import Foundation

// MARK: - Config

public enum FleetShipCount: Int, Codable, CaseIterable, Sendable {
    case quick = 3
    case standard = 5
    case siege = 7

    public var count: Int { rawValue }
}

public enum FleetShipHealth: Int, Codable, CaseIterable, Sendable {
    case fragile = 1
    case armored = 3
}

public enum FleetCallMode: String, Codable, CaseIterable, Sendable {
    case strict
    case callOnly
}

public struct MatchConfigFleet: Codable, Equatable, Sendable {
    public static let currentPayloadVersion = 1

    public let payloadVersion: Int
    public let shipCountRaw: Int
    public let shipHealthRaw: Int
    public let bullAllowed: Bool
    public let callModeRaw: String
    public let sonarEnabled: Bool
    public let sonarUsesPerPlayer: Int
    public let handoffEachTurn: Bool

    public var shipCount: FleetShipCount {
        FleetShipCount(rawValue: shipCountRaw) ?? .standard
    }

    public var shipHealth: FleetShipHealth {
        FleetShipHealth(rawValue: shipHealthRaw) ?? .armored
    }

    public var callMode: FleetCallMode {
        FleetCallMode(rawValue: callModeRaw) ?? .strict
    }

    public init(
        payloadVersion: Int = currentPayloadVersion,
        shipCount: FleetShipCount = .standard,
        shipHealth: FleetShipHealth = .armored,
        bullAllowed: Bool = false,
        callMode: FleetCallMode = .strict,
        sonarEnabled: Bool = true,
        sonarUsesPerPlayer: Int = 1,
        handoffEachTurn: Bool = false
    ) {
        self.payloadVersion = payloadVersion
        self.shipCountRaw = shipCount.rawValue
        self.shipHealthRaw = shipHealth.rawValue
        self.bullAllowed = bullAllowed
        self.callModeRaw = callMode.rawValue
        self.sonarEnabled = sonarEnabled
        self.sonarUsesPerPlayer = sonarEnabled ? sonarUsesPerPlayer : 0
        self.handoffEachTurn = handoffEachTurn
    }

    public static func presetQuick() -> MatchConfigFleet {
        MatchConfigFleet(shipCount: .quick, shipHealth: .fragile)
    }

    public static func presetStandard() -> MatchConfigFleet {
        MatchConfigFleet()
    }

    public static func presetSiege() -> MatchConfigFleet {
        MatchConfigFleet(shipCount: .siege, shipHealth: .armored)
    }

    public static func presetBullseye() -> MatchConfigFleet {
        MatchConfigFleet(bullAllowed: true)
    }
}

// MARK: - Board model

public enum FleetBoardCell: Codable, Hashable, Sendable {
    case segment(Int)
    case bull

    public var segmentValue: Int? {
        if case let .segment(value) = self { return value }
        return nil
    }

    public var displayLabel: String {
        switch self {
        case let .segment(value): return "\(value)"
        case .bull: return "Bull"
        }
    }
}

public enum FleetProbeResult: String, Codable, Sendable {
    case miss
    case hit
    case sunk
}

public enum FleetPhase: String, Codable, Sendable {
    case placement
    case hunt
}

public enum FleetPlacementUIStep: Codable, Equatable, Sendable {
    case handoff(playerId: UUID)
    case placing(playerId: UUID)
    case passDevice(to: UUID)
    case placementComplete

    private enum CodingKeys: String, CodingKey {
        case kind, playerId
    }

    private enum Kind: String, Codable {
        case handoff, placing, passDevice, placementComplete
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        switch kind {
        case .handoff:
            self = .handoff(playerId: try container.decode(UUID.self, forKey: .playerId))
        case .placing:
            self = .placing(playerId: try container.decode(UUID.self, forKey: .playerId))
        case .passDevice:
            self = .passDevice(to: try container.decode(UUID.self, forKey: .playerId))
        case .placementComplete:
            self = .placementComplete
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case let .handoff(playerId):
            try container.encode(Kind.handoff, forKey: .kind)
            try container.encode(playerId, forKey: .playerId)
        case let .placing(playerId):
            try container.encode(Kind.placing, forKey: .kind)
            try container.encode(playerId, forKey: .playerId)
        case let .passDevice(to):
            try container.encode(Kind.passDevice, forKey: .kind)
            try container.encode(to, forKey: .playerId)
        case .placementComplete:
            try container.encode(Kind.placementComplete, forKey: .kind)
        }
    }
}

public struct FleetPlayerFleet: Codable, Equatable, Sendable {
    public var ships: Set<FleetBoardCell>
    public var damage: [FleetBoardCell: Int]
    public var sunk: Set<FleetBoardCell>
    public var sonarRemaining: Int

    public init(ships: Set<FleetBoardCell> = [], damage: [FleetBoardCell: Int] = [:], sunk: Set<FleetBoardCell> = [], sonarRemaining: Int = 0) {
        self.ships = ships
        self.damage = damage
        self.sunk = sunk
        self.sonarRemaining = sonarRemaining
    }

    public func unsunkShips() -> Set<FleetBoardCell> {
        ships.subtracting(sunk)
    }
}

public struct FleetState: Codable, Equatable, Sendable {
    public let config: MatchConfigFleet
    public let playerIds: [UUID]
    public var phase: FleetPhase
    public var currentPlayerIndex: Int
    public var fleets: [UUID: FleetPlayerFleet]
    public var probeMaps: [UUID: [FleetBoardCell: FleetProbeResult]]
    public var placementSelections: [UUID: Set<FleetBoardCell>]
    public var placementLocks: [UUID: Bool]
    public var placementUIStep: FleetPlacementUIStep
    public var placementAudience: UUID?
    public var visitDartIndex: Int
    public var pendingCall: FleetBoardCell?
    public var pendingSonarUsedThisDart: Bool
    public var turnIndex: Int
    public var winnerPlayerId: UUID?
    public var isComplete: Bool

    public var currentPlayerId: UUID { playerIds[currentPlayerIndex] }

    public func opponentId(for playerId: UUID) -> UUID? {
        playerIds.first { $0 != playerId }
    }

    public init(
        config: MatchConfigFleet,
        playerIds: [UUID],
        phase: FleetPhase = .placement,
        currentPlayerIndex: Int = 0,
        fleets: [UUID: FleetPlayerFleet] = [:],
        probeMaps: [UUID: [FleetBoardCell: FleetProbeResult]] = [:],
        placementSelections: [UUID: Set<FleetBoardCell>] = [:],
        placementLocks: [UUID: Bool] = [:],
        placementUIStep: FleetPlacementUIStep,
        placementAudience: UUID? = nil,
        visitDartIndex: Int = 0,
        pendingCall: FleetBoardCell? = nil,
        pendingSonarUsedThisDart: Bool = false,
        turnIndex: Int = 0,
        winnerPlayerId: UUID? = nil,
        isComplete: Bool = false
    ) {
        self.config = config
        self.playerIds = playerIds
        self.phase = phase
        self.currentPlayerIndex = currentPlayerIndex
        self.fleets = fleets
        self.probeMaps = probeMaps
        self.placementSelections = placementSelections
        self.placementLocks = placementLocks
        self.placementUIStep = placementUIStep
        self.placementAudience = placementAudience
        self.visitDartIndex = visitDartIndex
        self.pendingCall = pendingCall
        self.pendingSonarUsedThisDart = pendingSonarUsedThisDart
        self.turnIndex = turnIndex
        self.winnerPlayerId = winnerPlayerId
        self.isComplete = isComplete
    }
}

// MARK: - Events

public struct FleetPlacementEvent: Codable, Equatable, Identifiable, Sendable {
    public let payloadVersion: Int
    public let id: UUID
    public let playerId: UUID
    public let ships: [FleetBoardCell]
    public let lockedAt: Date

    public init(payloadVersion: Int = 1, id: UUID = UUID(), playerId: UUID, ships: [FleetBoardCell], lockedAt: Date) {
        self.payloadVersion = payloadVersion
        self.id = id
        self.playerId = playerId
        self.ships = ships
        self.lockedAt = lockedAt
    }
}

public struct FleetPlacementUIEvent: Codable, Equatable, Identifiable, Sendable {
    public let payloadVersion: Int
    public let id: UUID
    public let step: FleetPlacementUIStep
    public let timestamp: Date

    public init(payloadVersion: Int = 1, id: UUID = UUID(), step: FleetPlacementUIStep, timestamp: Date) {
        self.payloadVersion = payloadVersion
        self.id = id
        self.step = step
        self.timestamp = timestamp
    }
}

public struct FleetSonarEvent: Codable, Equatable, Identifiable, Sendable {
    public let payloadVersion: Int
    public let id: UUID
    public let playerId: UUID
    public let cell: FleetBoardCell
    public let inFleet: Bool
    public let timestamp: Date

    public init(payloadVersion: Int = 1, id: UUID = UUID(), playerId: UUID, cell: FleetBoardCell, inFleet: Bool, timestamp: Date) {
        self.payloadVersion = payloadVersion
        self.id = id
        self.playerId = playerId
        self.cell = cell
        self.inFleet = inFleet
        self.timestamp = timestamp
    }
}

public enum FleetDartOutcome: String, Codable, Sendable {
    case wildMiss
    case clear
    case hit
    case sink
}

public enum FleetSinkCause: String, Codable, Sendable {
    case damage
    case triple
}

public struct FleetDartEvent: Codable, Equatable, Identifiable, Sendable {
    public let payloadVersion: Int
    public let id: UUID
    public let playerId: UUID
    public let callCell: FleetBoardCell
    public let actualCell: FleetBoardCell?
    public let multiplierRaw: String
    public let damageDealt: Int
    public let outcome: FleetDartOutcome
    public let sinkCause: FleetSinkCause?
    public let visitDartIndex: Int
    public let visitEnded: Bool
    public let sonarUsedBeforeDart: Bool
    public let matchCompleted: Bool
    public let timestamp: Date

    public init(
        payloadVersion: Int = 1,
        id: UUID = UUID(),
        playerId: UUID,
        callCell: FleetBoardCell,
        actualCell: FleetBoardCell?,
        multiplier: DartMultiplier,
        damageDealt: Int,
        outcome: FleetDartOutcome,
        sinkCause: FleetSinkCause? = nil,
        visitDartIndex: Int,
        visitEnded: Bool,
        sonarUsedBeforeDart: Bool,
        matchCompleted: Bool,
        timestamp: Date
    ) {
        self.payloadVersion = payloadVersion
        self.id = id
        self.playerId = playerId
        self.callCell = callCell
        self.actualCell = actualCell
        self.multiplierRaw = multiplier.rawValue
        self.damageDealt = damageDealt
        self.outcome = outcome
        self.sinkCause = sinkCause
        self.visitDartIndex = visitDartIndex
        self.visitEnded = visitEnded
        self.sonarUsedBeforeDart = sonarUsedBeforeDart
        self.matchCompleted = matchCompleted
        self.timestamp = timestamp
    }
}

// MARK: - Outcomes

public struct FleetPlacementOutcome: Sendable {
    public let updatedState: FleetState
    public let event: FleetPlacementEvent
    public let uiEvent: FleetPlacementUIEvent?
}

public struct FleetSonarOutcome: Sendable {
    public let updatedState: FleetState
    public let event: FleetSonarEvent
}

public struct FleetDartOutcomeBundle: Sendable {
    public let updatedState: FleetState
    public let event: FleetDartEvent
}

// MARK: - Engine

public enum FleetEngine {

    public static func placementPool(bullAllowed: Bool) -> [FleetBoardCell] {
        var cells = (1 ... 20).map { FleetBoardCell.segment($0) }
        if bullAllowed { cells.append(.bull) }
        return cells
    }

    public static func makeInitialState(
        config: MatchConfigFleet,
        playerIds: [UUID]
    ) throws -> FleetState {
        guard playerIds.count == 2 else {
            throw fleetError("setup.validation.fleetExactTwoPlayers")
        }
        let first = playerIds[0]
        var fleets: [UUID: FleetPlayerFleet] = [:]
        var probeMaps: [UUID: [FleetBoardCell: FleetProbeResult]] = [:]
        for id in playerIds {
            fleets[id] = FleetPlayerFleet(sonarRemaining: config.sonarUsesPerPlayer)
            probeMaps[id] = [:]
        }
        return FleetState(
            config: config,
            playerIds: playerIds,
            placementUIStep: .handoff(playerId: first),
            placementAudience: nil
        )
    }

    public static func confirmHandoff(
        state: FleetState,
        playerId: UUID,
        timestamp: Date = Date()
    ) throws -> (FleetState, FleetPlacementUIEvent) {
        guard state.phase == .placement else { throw fleetError("error.match.fleet.notPlacementPhase") }
        guard case let .handoff(expected) = state.placementUIStep, expected == playerId else {
            throw fleetError("error.match.fleet.invalidPlacementStep")
        }
        var updated = state
        updated.placementAudience = playerId
        updated.placementUIStep = .placing(playerId: playerId)
        let event = FleetPlacementUIEvent(step: updated.placementUIStep, timestamp: timestamp)
        return (updated, event)
    }

    public static func togglePlacementCell(
        state: FleetState,
        playerId: UUID,
        cell: FleetBoardCell
    ) throws -> FleetState {
        guard state.phase == .placement else { throw fleetError("error.match.fleet.notPlacementPhase") }
        guard state.placementLocks[playerId] != true else { throw fleetError("error.match.fleet.placementLocked") }
        try validateCellInPool(cell, bullAllowed: state.config.bullAllowed)
        var updated = state
        var selection = updated.placementSelections[playerId, default: []]
        if selection.contains(cell) {
            selection.remove(cell)
        } else if selection.count < state.config.shipCount.count {
            selection.insert(cell)
        } else {
            throw fleetError("error.match.fleet.invalidShipCount")
        }
        updated.placementSelections[playerId] = selection
        return updated
    }

    public static func clearPlacement(
        state: FleetState,
        playerId: UUID
    ) throws -> FleetState {
        guard state.phase == .placement else { throw fleetError("error.match.fleet.notPlacementPhase") }
        guard state.placementLocks[playerId] != true else { throw fleetError("error.match.fleet.placementLocked") }
        var updated = state
        updated.placementSelections[playerId] = []
        return updated
    }

    public static func lockPlacement(
        state: FleetState,
        playerId: UUID,
        timestamp: Date = Date()
    ) throws -> FleetPlacementOutcome {
        guard state.phase == .placement else { throw fleetError("error.match.fleet.notPlacementPhase") }
        guard state.placementLocks[playerId] != true else { throw fleetError("error.match.fleet.placementLocked") }
        let selection = state.placementSelections[playerId, default: []]
        guard selection.count == state.config.shipCount.count else {
            throw fleetError("error.match.fleet.invalidShipCount")
        }
        var updated = state
        updated.placementLocks[playerId] = true
        updated.fleets[playerId]?.ships = selection
        updated.placementSelections[playerId] = selection

        let placementEvent = FleetPlacementEvent(
            playerId: playerId,
            ships: Array(selection).sorted { lhs, rhs in cellSort(lhs, rhs) },
            lockedAt: timestamp
        )

        var uiEvent: FleetPlacementUIEvent?
        let otherLocked = updated.playerIds.allSatisfy { updated.placementLocks[$0] == true }
        if otherLocked {
            updated.phase = .hunt
            updated.placementUIStep = .placementComplete
            updated.placementAudience = nil
            updated.currentPlayerIndex = 0
            uiEvent = FleetPlacementUIEvent(step: .placementComplete, timestamp: timestamp)
        } else if let nextIndex = updated.playerIds.firstIndex(where: { updated.placementLocks[$0] != true }) {
            let nextId = updated.playerIds[nextIndex]
            updated.placementUIStep = .passDevice(to: nextId)
            updated.placementAudience = nil
            uiEvent = FleetPlacementUIEvent(step: updated.placementUIStep, timestamp: timestamp)
        }

        return FleetPlacementOutcome(updatedState: updated, event: placementEvent, uiEvent: uiEvent)
    }

    public static func confirmPassDevice(
        state: FleetState,
        playerId: UUID,
        timestamp: Date = Date()
    ) throws -> (FleetState, FleetPlacementUIEvent) {
        guard state.phase == .placement else { throw fleetError("error.match.fleet.notPlacementPhase") }
        guard case let .passDevice(to) = state.placementUIStep, to == playerId else {
            throw fleetError("error.match.fleet.invalidPlacementStep")
        }
        var updated = state
        updated.placementUIStep = .handoff(playerId: playerId)
        updated.placementAudience = nil
        let event = FleetPlacementUIEvent(step: updated.placementUIStep, timestamp: timestamp)
        return (updated, event)
    }

    public static func setCall(
        state: FleetState,
        playerId: UUID,
        cell: FleetBoardCell
    ) throws -> FleetState {
        guard state.phase == .hunt else { throw fleetError("error.match.fleet.notHuntPhase") }
        guard state.currentPlayerId == playerId else { throw fleetError("error.match.fleet.notYourTurn") }
        guard state.pendingCall == nil else { throw fleetError("error.match.fleet.callAlreadySet") }
        try validateCellInPool(cell, bullAllowed: state.config.bullAllowed)
        var updated = state
        updated.pendingCall = cell
        return updated
    }

    public static func useSonar(
        state: FleetState,
        playerId: UUID,
        cell: FleetBoardCell,
        timestamp: Date = Date()
    ) throws -> FleetSonarOutcome {
        guard state.phase == .hunt else { throw fleetError("error.match.fleet.notHuntPhase") }
        guard state.currentPlayerId == playerId else { throw fleetError("error.match.fleet.notYourTurn") }
        guard state.config.sonarEnabled else { throw fleetError("error.match.fleet.sonarDisabled") }
        guard (state.fleets[playerId]?.sonarRemaining ?? 0) > 0 else {
            throw fleetError("error.match.fleet.sonarDepleted")
        }
        guard state.pendingCall == nil else { throw fleetError("error.match.fleet.callAlreadySet") }
        try validateCellInPool(cell, bullAllowed: state.config.bullAllowed)

        guard let opponentId = state.opponentId(for: playerId) else {
            throw fleetError("error.match.fleet.invalidOpponent")
        }
        let opponentFleet = state.fleets[opponentId] ?? FleetPlayerFleet()
        let inFleet = opponentFleet.unsunkShips().contains(cell)

        var updated = state
        let sonarBefore = updated.fleets[playerId]?.sonarRemaining ?? 0
        updated.fleets[playerId]?.sonarRemaining = max(0, sonarBefore - 1)
        updated.pendingSonarUsedThisDart = true

        let event = FleetSonarEvent(playerId: playerId, cell: cell, inFleet: inFleet, timestamp: timestamp)
        return FleetSonarOutcome(updatedState: updated, event: event)
    }

    public static func submitDart(
        state: FleetState,
        playerId: UUID,
        dart: DartInput,
        timestamp: Date = Date()
    ) throws -> FleetDartOutcomeBundle {
        guard state.phase == .hunt else { throw fleetError("error.match.fleet.notHuntPhase") }
        guard state.currentPlayerId == playerId else { throw fleetError("error.match.fleet.notYourTurn") }
        guard let callCell = state.pendingCall else { throw fleetError("error.match.fleet.invalidCall") }

        guard let opponentId = state.opponentId(for: playerId) else {
            throw fleetError("error.match.fleet.invalidOpponent")
        }

        var updated = state
        let sonarUsed = updated.pendingSonarUsedThisDart
        updated.pendingSonarUsedThisDart = false
        updated.pendingCall = nil

        let actualCell = boardCell(for: dart, bullAllowed: updated.config.bullAllowed)
        let visitIndex = updated.visitDartIndex

        var outcome: FleetDartOutcome = .wildMiss
        var damageDealt = 0
        var sinkCause: FleetSinkCause?

        let strictMatch = updated.config.callMode == .strict
            && strictCallMatches(call: callCell, dart: dart, bullAllowed: updated.config.bullAllowed)
        let resolvesProbe = updated.config.callMode == .callOnly || strictMatch

        if resolvesProbe {
            var opponentFleet = updated.fleets[opponentId] ?? FleetPlayerFleet()
            if opponentFleet.unsunkShips().contains(callCell) {
                let damage = probeDamage(
                    dart: dart,
                    callMode: updated.config.callMode,
                    callCell: callCell,
                    bullAllowed: updated.config.bullAllowed
                )
                damageDealt = damage.amount
                if damage.autoSink {
                    opponentFleet.sunk.insert(callCell)
                    opponentFleet.damage[callCell] = updated.config.shipHealth.rawValue
                    outcome = .sink
                    sinkCause = .triple
                } else {
                    let prior = opponentFleet.damage[callCell, default: 0]
                    let next = prior + damage.amount
                    opponentFleet.damage[callCell] = next
                    if next >= updated.config.shipHealth.rawValue {
                        opponentFleet.sunk.insert(callCell)
                        outcome = .sink
                        sinkCause = .damage
                    } else {
                        outcome = .hit
                    }
                }
                updated.fleets[opponentId] = opponentFleet
                var probeMap = updated.probeMaps[playerId, default: [:]]
                probeMap[callCell] = outcome == .sink ? .sunk : .hit
                updated.probeMaps[playerId] = probeMap
            } else {
                outcome = .clear
                var probeMap = updated.probeMaps[playerId, default: [:]]
                probeMap[callCell] = .miss
                updated.probeMaps[playerId] = probeMap
            }
        } else {
            outcome = .wildMiss
        }

        updated.visitDartIndex += 1
        let visitEnded = updated.visitDartIndex >= 3

        var matchCompleted = false
        if updated.fleets[opponentId]?.sunk.count == updated.config.shipCount.count {
            updated.isComplete = true
            updated.winnerPlayerId = playerId
            matchCompleted = true
        } else if visitEnded {
            updated.visitDartIndex = 0
            updated.currentPlayerIndex = (updated.currentPlayerIndex + 1) % updated.playerIds.count
            updated.turnIndex += 1
        }

        let event = FleetDartEvent(
            playerId: playerId,
            callCell: callCell,
            actualCell: actualCell,
            multiplier: dart.isMiss ? .single : dart.multiplier,
            damageDealt: damageDealt,
            outcome: outcome,
            sinkCause: sinkCause,
            visitDartIndex: visitIndex,
            visitEnded: visitEnded,
            sonarUsedBeforeDart: sonarUsed,
            matchCompleted: matchCompleted,
            timestamp: timestamp
        )

        return FleetDartOutcomeBundle(updatedState: updated, event: event)
    }

    public static func placeFleetForBot(
        state: FleetState,
        playerId: UUID,
        rng: inout some RandomNumberGenerator,
        timestamp: Date = Date()
    ) throws -> FleetPlacementOutcome {
        let pool = placementPool(bullAllowed: state.config.bullAllowed)
        var available = pool
        var selected: Set<FleetBoardCell> = []
        while selected.count < state.config.shipCount.count, !available.isEmpty {
            let index = Int.random(in: 0 ..< available.count, using: &rng)
            selected.insert(available.remove(at: index))
        }
        var updated = state
        updated.placementSelections[playerId] = selected
        return try lockPlacement(state: updated, playerId: playerId, timestamp: timestamp)
    }

    public static func replay(
        config: MatchConfigFleet,
        playerIds: [UUID],
        events: [MatchEventEnvelope]
    ) throws -> FleetState {
        var state = try makeInitialState(config: config, playerIds: playerIds)
        for envelope in events {
            switch envelope.payload {
            case let .fleetPlacementUI(event):
                state.placementUIStep = event.step
                switch event.step {
                case let .handoff(id), let .placing(id):
                    state.placementAudience = event.step == .placing(playerId: id) ? id : nil
                case .passDevice, .placementComplete:
                    state.placementAudience = nil
                }
            case let .fleetPlacement(event):
                state.placementLocks[event.playerId] = true
                state.fleets[event.playerId]?.ships = Set(event.ships)
                state.placementSelections[event.playerId] = Set(event.ships)
                if state.playerIds.allSatisfy({ state.placementLocks[$0] == true }) {
                    state.phase = .hunt
                    state.placementUIStep = .placementComplete
                    state.currentPlayerIndex = 0
                }
            case let .fleetSonar(event):
                let sonarBefore = state.fleets[event.playerId]?.sonarRemaining ?? 0
                state.fleets[event.playerId]?.sonarRemaining = max(0, sonarBefore - 1)
            case let .fleetDart(event):
                state = try applyDartEvent(state: state, event: event)
            default:
                continue
            }
        }
        return state
    }

    // MARK: - Display helpers (privacy-safe)

    public static func probeResult(
        state: FleetState,
        hunterId: UUID,
        cell: FleetBoardCell
    ) -> FleetProbeResult? {
        state.probeMaps[hunterId]?[cell]
    }

    public static func ownFleetDisplay(
        state: FleetState,
        playerId: UUID
    ) -> (ships: Set<FleetBoardCell>, damage: [FleetBoardCell: Int], sunk: Set<FleetBoardCell>) {
        let fleet = state.fleets[playerId] ?? FleetPlayerFleet()
        return (fleet.ships, fleet.damage, fleet.sunk)
    }

    public static func enemyFogCells(state: FleetState, hunterId: UUID) -> [FleetBoardCell: FleetProbeResult] {
        state.probeMaps[hunterId, default: [:]]
    }

    // MARK: - Dart geometry

    public static func dartInput(from event: FleetDartEvent) -> DartInput {
        if event.outcome == .wildMiss {
            return DartInput(multiplier: .single, segment: .miss, isMiss: true)
        }
        guard let actual = event.actualCell else {
            return DartInput(multiplier: .single, segment: .miss, isMiss: true)
        }
        let multiplier = DartMultiplier(rawValue: event.multiplierRaw) ?? .single
        let segment: DartSegment = switch actual {
        case let .segment(value): .oneToTwenty(value)
        case .bull: .innerBull
        }
        return DartInput(multiplier: multiplier, segment: segment, isMiss: false)
    }

    public static func boardCell(for dart: DartInput, bullAllowed: Bool) -> FleetBoardCell? {
        guard !dart.isMiss else { return nil }
        switch dart.segment {
        case let .oneToTwenty(value):
            return .segment(value)
        case .innerBull, .outerBull:
            return bullAllowed ? .bull : nil
        case .miss:
            return nil
        }
    }

    public static func strictCallMatches(
        call: FleetBoardCell,
        dart: DartInput,
        bullAllowed: Bool
    ) -> Bool {
        guard !dart.isMiss else { return false }
        switch (call, dart.segment) {
        case let (.segment(expected), .oneToTwenty(actual)):
            return expected == actual
        case (.bull, .innerBull), (.bull, .outerBull):
            return bullAllowed
        default:
            return false
        }
    }

    struct ProbeDamage {
        let amount: Int
        let autoSink: Bool
    }

    static func probeDamage(
        dart: DartInput,
        callMode: FleetCallMode,
        callCell: FleetBoardCell,
        bullAllowed: Bool
    ) -> ProbeDamage {
        if callMode == .callOnly {
            return ProbeDamage(amount: 1, autoSink: false)
        }
        if callCell == .bull, bullAllowed {
            switch dart.segment {
            case .innerBull:
                return ProbeDamage(amount: 0, autoSink: true)
            case .outerBull:
                return ProbeDamage(amount: 2, autoSink: false)
            default:
                return ProbeDamage(amount: 1, autoSink: false)
            }
        }
        switch dart.multiplier {
        case .triple:
            return ProbeDamage(amount: 0, autoSink: true)
        case .double:
            return ProbeDamage(amount: 2, autoSink: false)
        case .single:
            return ProbeDamage(amount: 1, autoSink: false)
        }
    }

    // MARK: - Private

    private static func applyDartEvent(state: FleetState, event: FleetDartEvent) throws -> FleetState {
        var updated = state
        updated.pendingCall = nil
        updated.pendingSonarUsedThisDart = false
        guard let opponentId = updated.opponentId(for: event.playerId) else { return updated }

        if event.outcome != .wildMiss {
            var opponentFleet = updated.fleets[opponentId] ?? FleetPlayerFleet()
            switch event.outcome {
            case .hit:
                let prior = opponentFleet.damage[event.callCell, default: 0]
                opponentFleet.damage[event.callCell] = prior + event.damageDealt
            case .sink:
                opponentFleet.sunk.insert(event.callCell)
                opponentFleet.damage[event.callCell] = updated.config.shipHealth.rawValue
            case .clear:
                break
            case .wildMiss:
                break
            }
            updated.fleets[opponentId] = opponentFleet
            var probeMap = updated.probeMaps[event.playerId, default: [:]]
            switch event.outcome {
            case .clear: probeMap[event.callCell] = .miss
            case .hit: probeMap[event.callCell] = .hit
            case .sink: probeMap[event.callCell] = .sunk
            case .wildMiss: break
            }
            updated.probeMaps[event.playerId] = probeMap
        }

        updated.visitDartIndex = event.visitEnded ? 0 : event.visitDartIndex + 1
        if event.visitEnded, !event.matchCompleted {
            if let idx = updated.playerIds.firstIndex(of: event.playerId) {
                updated.currentPlayerIndex = (idx + 1) % updated.playerIds.count
            }
            updated.turnIndex += 1
        }
        if event.matchCompleted {
            updated.isComplete = true
            updated.winnerPlayerId = event.playerId
        }
        return updated
    }

    private static func validateCellInPool(_ cell: FleetBoardCell, bullAllowed: Bool) throws {
        switch cell {
        case let .segment(value):
            guard (1 ... 20).contains(value) else { throw fleetError("error.match.fleet.invalidCall") }
        case .bull:
            guard bullAllowed else { throw fleetError("error.match.fleet.invalidCall") }
        }
    }

    private static func cellSort(_ lhs: FleetBoardCell, _ rhs: FleetBoardCell) -> Bool {
        switch (lhs, rhs) {
        case let (.segment(a), .segment(b)): return a < b
        case (.segment, .bull): return true
        case (.bull, .segment): return false
        case (.bull, .bull): return false
        }
    }

    private static func fleetError(_ key: String) -> AppError {
        AppError(code: .validationFailed, layer: .domain, severity: .warning, isRecoverable: true, userMessageKey: key)
    }
}
