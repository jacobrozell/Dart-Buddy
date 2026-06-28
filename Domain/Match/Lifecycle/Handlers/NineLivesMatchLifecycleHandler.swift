import Foundation

enum NineLivesMatchLifecycleHandler {
    static func submitTurn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var state = session.runtime.nineLivesState else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .error,
                isRecoverable: true,
                userMessageKey: "error.match.mode.nineLivesUnavailable"
            )
        }
        let outcome = try NineLivesEngine.submitTurn(state: state, darts: darts, timestamp: timestamp)
        state = outcome.updatedState
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .nineLivesTurn(outcome.event),
            timestamp: timestamp
        )
        return try MatchLifecycleCoordinator.appendAndProject(
            session: session,
            newEvent: envelope,
            timestamp: timestamp
        ) { runtime in
            runtime.nineLivesState = state
        }
    }

    static func replayTurn(
        _ turn: NineLivesTurnEvent,
        session: MatchLifecycleSession,
        timestamp: Date
    ) throws -> MatchLifecycleSession {
        try submitTurn(session: session, darts: replayDarts(for: turn), timestamp: timestamp)
    }

    static func replayDarts(for turn: NineLivesTurnEvent) -> [DartInput] {
        if turn.advanced {
            let target = turn.targetIndexBefore + 1
            return [DartInput(multiplier: .single, segment: .oneToTwenty(min(20, max(1, target))), isMiss: false)]
        }
        return [DartInput(multiplier: .single, segment: .miss, isMiss: true)]
    }
}
