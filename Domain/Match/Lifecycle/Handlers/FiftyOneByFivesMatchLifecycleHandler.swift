import Foundation

enum FiftyOneByFivesMatchLifecycleHandler {
    static func submitTurn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var state = session.runtime.fiftyOneByFivesState else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .error,
                isRecoverable: true,
                userMessageKey: "error.match.mode.fiftyOneByFivesUnavailable"
            )
        }
        let outcome = try FiftyOneByFivesEngine.submitTurn(state: state, darts: darts, timestamp: timestamp)
        state = outcome.updatedState
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .fiftyOneByFivesTurn(outcome.event),
            timestamp: timestamp
        )
        return try MatchLifecycleCoordinator.appendAndProject(
            session: session,
            newEvent: envelope,
            timestamp: timestamp
        ) { runtime in
            runtime.fiftyOneByFivesState = state
        }
    }

    static func replayTurn(
        _ turn: FiftyOneByFivesTurnEvent,
        session: MatchLifecycleSession,
        timestamp: Date
    ) throws -> MatchLifecycleSession {
        try submitTurn(session: session, darts: replayDarts(for: turn), timestamp: timestamp)
    }

    static func replayDarts(for turn: FiftyOneByFivesTurnEvent) -> [DartInput] {
        guard turn.rawTotal > 0 else {
            return [DartInput(multiplier: .single, segment: .miss, isMiss: true)]
        }
        return synthesizeReplayDarts(forRawTotal: turn.rawTotal)
    }

    private static func synthesizeReplayDarts(forRawTotal rawTotal: Int) -> [DartInput] {
        if rawTotal <= 20 {
            return [DartInput(multiplier: .single, segment: .oneToTwenty(rawTotal), isMiss: false)]
        }
        if rawTotal <= 40, rawTotal % 2 == 0 {
            let segment = rawTotal / 2
            return [DartInput(multiplier: .double, segment: .oneToTwenty(segment), isMiss: false)]
        }
        if rawTotal <= 60, rawTotal % 3 == 0 {
            let segment = rawTotal / 3
            return [DartInput(multiplier: .triple, segment: .oneToTwenty(segment), isMiss: false)]
        }
        return [DartInput(multiplier: .single, segment: .oneToTwenty(min(20, rawTotal)), isMiss: false)]
    }
}
