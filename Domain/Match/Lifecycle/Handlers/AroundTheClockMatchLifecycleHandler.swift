import Foundation

enum AroundTheClockMatchLifecycleHandler {
    static func submitTurn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var state = session.runtime.aroundTheClockState else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .error,
                isRecoverable: true,
                userMessageKey: "error.match.mode.aroundTheClockUnavailable"
            )
        }
        let outcome = try AroundTheClockEngine.submitTurn(state: state, darts: darts, timestamp: timestamp)
        state = outcome.updatedState
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .aroundTheClockTurn(outcome.event),
            timestamp: timestamp
        )
        return try MatchLifecycleCoordinator.appendAndProject(
            session: session,
            newEvent: envelope,
            timestamp: timestamp
        ) { runtime in
            runtime.aroundTheClockState = state
        }
    }

    static func replayTurn(
        _ turn: AroundTheClockTurnEvent,
        session: MatchLifecycleSession,
        timestamp: Date
    ) throws -> MatchLifecycleSession {
        try submitTurn(session: session, darts: replayDarts(for: turn), timestamp: timestamp)
    }

    static func replayDarts(for turn: AroundTheClockTurnEvent) -> [DartInput] {
        if turn.targetAfter > turn.targetBefore {
            let segment: DartSegment
            if turn.targetBefore < 20 {
                segment = .oneToTwenty(turn.targetBefore + 1)
            } else {
                segment = .outerBull
            }
            return [DartInput(multiplier: .single, segment: segment, isMiss: false)]
        }
        return Array(
            repeating: DartInput(multiplier: .single, segment: .miss, isMiss: true),
            count: max(1, turn.dartsThrown)
        )
    }
}
