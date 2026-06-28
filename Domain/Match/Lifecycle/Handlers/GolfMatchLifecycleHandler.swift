import Foundation

enum GolfMatchLifecycleHandler {
    static func submitTurn(
        session: MatchLifecycleSession,
        input: GolfTurnInput,
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var state = session.runtime.golfState else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .error,
                isRecoverable: true,
                userMessageKey: "error.match.mode.golfUnavailable"
            )
        }
        let outcome = try GolfEngine.submitTurn(state: state, input: input, timestamp: timestamp)
        state = outcome.updatedState
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .golfTurn(outcome.event),
            timestamp: timestamp
        )
        return try MatchLifecycleCoordinator.appendAndProject(
            session: session,
            newEvent: envelope,
            timestamp: timestamp
        ) { runtime in
            runtime.golfState = state
        }
    }

    static func replayTurn(
        _ turn: GolfTurnEvent,
        session: MatchLifecycleSession,
        timestamp: Date
    ) throws -> MatchLifecycleSession {
        let darts = turn.darts.map(GolfEngine.dartInput(from:))
        let input = GolfTurnInput(darts: darts, endedEarly: turn.endedEarly)
        return try submitTurn(session: session, input: input, timestamp: timestamp)
    }
}
