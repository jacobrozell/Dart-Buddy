import Foundation

enum GrandNationalMatchLifecycleHandler {
    static func submitTurn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var state = session.runtime.grandNationalState else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .error,
                isRecoverable: true,
                userMessageKey: "error.match.mode.grandNationalUnavailable"
            )
        }
        let outcome = try GrandNationalEngine.submitTurn(state: state, darts: darts, timestamp: timestamp)
        state = outcome.updatedState
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .grandNationalTurn(outcome.event),
            timestamp: timestamp
        )
        return try MatchLifecycleCoordinator.appendAndProject(
            session: session,
            newEvent: envelope,
            timestamp: timestamp
        ) { runtime in
            runtime.grandNationalState = state
        }
    }

    static func replayTurn(
        _ turn: GrandNationalTurnEvent,
        session: MatchLifecycleSession,
        timestamp: Date
    ) throws -> MatchLifecycleSession {
        try submitTurn(session: session, darts: replayDarts(for: turn), timestamp: timestamp)
    }

    static func replayDarts(for turn: GrandNationalTurnEvent) -> [DartInput] {
        if turn.segmentIndexAfter > turn.segmentIndexBefore {
            let segment = grandNationalCourseOrder[turn.segmentIndexBefore]
            return [DartInput(multiplier: .single, segment: .oneToTwenty(segment), isMiss: false)]
        }
        return [DartInput(multiplier: .single, segment: .miss, isMiss: true)]
    }
}
