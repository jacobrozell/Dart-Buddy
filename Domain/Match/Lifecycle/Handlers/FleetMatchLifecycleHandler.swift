import Foundation

enum FleetMatchLifecycleHandler {
    static func confirmHandoff(
        session: MatchLifecycleSession,
        playerId: UUID,
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var state = session.runtime.fleetState else {
            throw fleetUnavailable()
        }
        let (updatedState, uiEvent) = try FleetEngine.confirmHandoff(state: state, playerId: playerId, timestamp: timestamp)
        state = updatedState
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .fleetPlacementUI(uiEvent),
            timestamp: timestamp
        )
        return try MatchLifecycleCoordinator.appendAndProject(
            session: session,
            newEvent: envelope,
            timestamp: timestamp
        ) { runtime in
            runtime.fleetState = state
        }
    }

    static func confirmPassDevice(
        session: MatchLifecycleSession,
        playerId: UUID,
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var state = session.runtime.fleetState else {
            throw fleetUnavailable()
        }
        let (updatedState, uiEvent) = try FleetEngine.confirmPassDevice(state: state, playerId: playerId, timestamp: timestamp)
        state = updatedState
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .fleetPlacementUI(uiEvent),
            timestamp: timestamp
        )
        return try MatchLifecycleCoordinator.appendAndProject(
            session: session,
            newEvent: envelope,
            timestamp: timestamp
        ) { runtime in
            runtime.fleetState = state
        }
    }

    static func togglePlacementCell(
        session: MatchLifecycleSession,
        playerId: UUID,
        cell: FleetBoardCell
    ) throws -> MatchLifecycleSession {
        guard var state = session.runtime.fleetState else {
            throw fleetUnavailable()
        }
        state = try FleetEngine.togglePlacementCell(state: state, playerId: playerId, cell: cell)
        var updated = session
        updated.runtime.fleetState = state
        return updated
    }

    static func clearPlacement(
        session: MatchLifecycleSession,
        playerId: UUID
    ) throws -> MatchLifecycleSession {
        guard var state = session.runtime.fleetState else {
            throw fleetUnavailable()
        }
        state = try FleetEngine.clearPlacement(state: state, playerId: playerId)
        var updated = session
        updated.runtime.fleetState = state
        return updated
    }

    static func submitPlacementLock(
        session: MatchLifecycleSession,
        playerId: UUID,
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var state = session.runtime.fleetState else {
            throw fleetUnavailable()
        }
        let outcome = try FleetEngine.lockPlacement(state: state, playerId: playerId, timestamp: timestamp)
        state = outcome.updatedState
        let placementEnvelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .fleetPlacement(outcome.event),
            timestamp: timestamp
        )
        var updated = try MatchLifecycleCoordinator.appendAndProject(
            session: session,
            newEvent: placementEnvelope,
            timestamp: timestamp
        ) { runtime in
            runtime.fleetState = state
        }
        if let uiEvent = outcome.uiEvent {
            let uiEnvelope = MatchEventEnvelope(
                eventIndex: updated.runtime.eventCount,
                payload: .fleetPlacementUI(uiEvent),
                timestamp: timestamp
            )
            updated = try MatchLifecycleCoordinator.appendAndProject(
                session: updated,
                newEvent: uiEnvelope,
                timestamp: timestamp
            ) { runtime in
                runtime.fleetState = state
            }
        }
        return updated
    }

    static func submitSonar(
        session: MatchLifecycleSession,
        playerId: UUID,
        cell: FleetBoardCell,
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var state = session.runtime.fleetState else {
            throw fleetUnavailable()
        }
        let outcome = try FleetEngine.useSonar(state: state, playerId: playerId, cell: cell, timestamp: timestamp)
        state = outcome.updatedState
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .fleetSonar(outcome.event),
            timestamp: timestamp
        )
        return try MatchLifecycleCoordinator.appendAndProject(
            session: session,
            newEvent: envelope,
            timestamp: timestamp
        ) { runtime in
            runtime.fleetState = state
        }
    }

    static func submitDart(
        session: MatchLifecycleSession,
        playerId: UUID,
        callCell: FleetBoardCell,
        dart: DartInput,
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var state = session.runtime.fleetState else {
            throw fleetUnavailable()
        }
        state = try FleetEngine.setCall(state: state, playerId: playerId, cell: callCell)
        let outcome = try FleetEngine.submitDart(state: state, playerId: playerId, dart: dart, timestamp: timestamp)
        state = outcome.updatedState
        let dartEnvelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .fleetDart(outcome.event),
            timestamp: timestamp
        )
        return try MatchLifecycleCoordinator.appendAndProject(
            session: session,
            newEvent: dartEnvelope,
            timestamp: timestamp
        ) { runtime in
            runtime.fleetState = state
        }
    }

    static func replayPlacement(
        _ placement: FleetPlacementEvent,
        session: MatchLifecycleSession
    ) throws -> MatchLifecycleSession {
        var updated = session
        for cell in placement.ships {
            updated = try togglePlacementCell(session: updated, playerId: placement.playerId, cell: cell)
        }
        return try submitPlacementLock(
            session: updated,
            playerId: placement.playerId,
            timestamp: placement.lockedAt
        )
    }

    static func replayPlacementUI(
        _ ui: FleetPlacementUIEvent,
        session: MatchLifecycleSession
    ) throws -> MatchLifecycleSession {
        switch ui.step {
        case let .placing(playerId):
            return try confirmHandoff(session: session, playerId: playerId, timestamp: ui.timestamp)
        case let .handoff(playerId):
            return try confirmPassDevice(session: session, playerId: playerId, timestamp: ui.timestamp)
        case .passDevice, .placementComplete:
            return try projectUIStep(session: session, ui: ui)
        }
    }

    static func replaySonar(
        _ sonar: FleetSonarEvent,
        session: MatchLifecycleSession
    ) throws -> MatchLifecycleSession {
        try submitSonar(
            session: session,
            playerId: sonar.playerId,
            cell: sonar.cell,
            timestamp: sonar.timestamp
        )
    }

    static func replayDart(
        _ dart: FleetDartEvent,
        session: MatchLifecycleSession
    ) throws -> MatchLifecycleSession {
        try submitDart(
            session: session,
            playerId: dart.playerId,
            callCell: dart.callCell,
            dart: FleetEngine.dartInput(from: dart),
            timestamp: dart.timestamp
        )
    }

    private static func projectUIStep(
        session: MatchLifecycleSession,
        ui: FleetPlacementUIEvent
    ) throws -> MatchLifecycleSession {
        guard var state = session.runtime.fleetState else { throw fleetUnavailable() }
        state.placementUIStep = ui.step
        state.placementAudience = nil
        if case let .placing(playerId) = ui.step {
            state.placementAudience = playerId
        }
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .fleetPlacementUI(ui),
            timestamp: ui.timestamp
        )
        return try MatchLifecycleCoordinator.appendAndProject(
            session: session,
            newEvent: envelope,
            timestamp: ui.timestamp
        ) { runtime in
            runtime.fleetState = state
        }
    }

    private static func fleetUnavailable() -> AppError {
        AppError(
            code: .invalidGameState,
            layer: .domain,
            severity: .error,
            isRecoverable: true,
            userMessageKey: "error.match.mode.fleetUnavailable"
        )
    }
}
