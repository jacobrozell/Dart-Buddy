import Foundation

enum HareAndHoundsMatchLifecycleHandler {
    static func submitTurn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var state = session.runtime.hareAndHoundsState else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .error,
                isRecoverable: true,
                userMessageKey: "error.match.mode.hareAndHoundsUnavailable"
            )
        }
        let outcome = try HareAndHoundsEngine.submitTurn(state: state, darts: darts, timestamp: timestamp)
        state = outcome.updatedState
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .hareAndHoundsTurn(outcome.event),
            timestamp: timestamp
        )
        return try MatchLifecycleCoordinator.appendAndProject(
            session: session,
            newEvent: envelope,
            timestamp: timestamp
        ) { runtime in
            runtime.hareAndHoundsState = state
        }
    }

    static func replayTurn(
        _ turn: HareAndHoundsTurnEvent,
        session: MatchLifecycleSession,
        timestamp: Date
    ) throws -> MatchLifecycleSession {
        try submitTurn(session: session, darts: replayDarts(for: turn), timestamp: timestamp)
    }

    static func replayDarts(for turn: HareAndHoundsTurnEvent) -> [DartInput] {
        if turn.positionAfter > turn.positionBefore {
            let segment = MatchConfigHareAndHounds.clockwiseCourse[turn.positionBefore]
            return [DartInput(multiplier: .single, segment: .oneToTwenty(segment), isMiss: false)]
        }
        return [DartInput(multiplier: .single, segment: .miss, isMiss: true)]
    }
}
