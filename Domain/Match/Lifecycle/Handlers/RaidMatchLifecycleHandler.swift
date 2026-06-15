import Foundation

enum RaidMatchLifecycleHandler {
    static func submitVisit(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var state = session.runtime.raidState else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .error,
                isRecoverable: true,
                userMessageKey: "error.match.mode.raidUnavailable"
            )
        }
        let outcome = try RaidEngine.submitVisit(state: state, darts: darts, timestamp: timestamp)
        state = outcome.updatedState
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .raidVisit(outcome.event),
            timestamp: timestamp
        )
        return try MatchLifecycleCoordinator.appendAndProject(
            session: session,
            newEvent: envelope,
            timestamp: timestamp
        ) { runtime in
            runtime.raidState = state
        }
    }

    static func replayVisit(
        _ visit: RaidVisitEvent,
        session: MatchLifecycleSession,
        timestamp: Date
    ) throws -> MatchLifecycleSession {
        let darts = visit.darts.map(RaidEngine.dartInput(from:))
        return try submitVisit(session: session, darts: darts, timestamp: timestamp)
    }
}
