import Foundation

enum SuddenDeathMatchLifecycleHandler {
    static func submitTurn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var state = session.runtime.suddenDeathState else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .error,
                isRecoverable: true,
                userMessageKey: "error.match.mode.suddenDeathUnavailable"
            )
        }
        let outcome = try SuddenDeathEngine.submitTurn(state: state, darts: darts, timestamp: timestamp)
        state = outcome.updatedState
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .suddenDeathTurn(outcome.event),
            timestamp: timestamp
        )
        return try MatchLifecycleCoordinator.appendAndProject(
            session: session,
            newEvent: envelope,
            timestamp: timestamp
        ) { runtime in
            runtime.suddenDeathState = state
        }
    }

    static func replayTurn(
        _ turn: SuddenDeathTurnEvent,
        session: MatchLifecycleSession,
        timestamp: Date
    ) throws -> MatchLifecycleSession {
        try submitTurn(session: session, darts: replayDarts(for: turn), timestamp: timestamp)
    }

    static func replayDarts(for turn: SuddenDeathTurnEvent) -> [DartInput] {
        guard turn.pointsThisVisit > 0 else { return [DartInput(multiplier: .single, segment: .miss, isMiss: true)] }
        let perDart = turn.pointsThisVisit / 3
        let remainder = turn.pointsThisVisit % 3
        return (0 ..< 3).map { index in
            let points = perDart + (index < remainder ? 1 : 0)
            guard points > 0 else {
                return DartInput(multiplier: .single, segment: .miss, isMiss: true)
            }
            return DartInput(multiplier: .single, segment: .oneToTwenty(min(20, max(1, points))), isMiss: false)
        }
    }
}
