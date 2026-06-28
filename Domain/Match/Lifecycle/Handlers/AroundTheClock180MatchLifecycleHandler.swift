import Foundation

enum AroundTheClock180MatchLifecycleHandler {
    static func submitTurn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var state = session.runtime.aroundTheClock180State else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .error,
                isRecoverable: true,
                userMessageKey: "error.match.mode.aroundTheClock180Unavailable"
            )
        }
        let outcome = try AroundTheClock180Engine.submitTurn(state: state, darts: darts, timestamp: timestamp)
        state = outcome.updatedState
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .aroundTheClock180Turn(outcome.event),
            timestamp: timestamp
        )
        return try MatchLifecycleCoordinator.appendAndProject(
            session: session,
            newEvent: envelope,
            timestamp: timestamp
        ) { runtime in
            runtime.aroundTheClock180State = state
        }
    }

    static func replayTurn(
        _ turn: AroundTheClock180TurnEvent,
        session: MatchLifecycleSession,
        timestamp: Date
    ) throws -> MatchLifecycleSession {
        let darts = turn.darts.map(AroundTheClock180Engine.dartInput(from:))
        return try submitTurn(session: session, darts: darts, timestamp: timestamp)
    }
}
