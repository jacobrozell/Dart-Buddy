import Foundation

enum MickeyMouseMatchLifecycleHandler {
    static func submitTurn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var state = session.runtime.mickeyMouseState else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .error,
                isRecoverable: true,
                userMessageKey: "error.match.mode.mickeyMouseUnavailable"
            )
        }
        let outcome = try MickeyMouseEngine.submitTurn(state: state, darts: darts, timestamp: timestamp)
        state = outcome.updatedState
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .mickeyMouseTurn(outcome.event),
            timestamp: timestamp
        )
        return try MatchLifecycleCoordinator.appendAndProject(
            session: session,
            newEvent: envelope,
            timestamp: timestamp
        ) { runtime in
            runtime.mickeyMouseState = state
        }
    }

    static func replayTurn(
        _ turn: MickeyMouseTurnEvent,
        session: MatchLifecycleSession,
        timestamp: Date
    ) throws -> MatchLifecycleSession {
        let darts = turn.darts.map(MickeyMouseEngine.dartInput(from:))
        return try submitTurn(session: session, darts: darts, timestamp: timestamp)
    }
}
