import Foundation

enum Bobs27MatchLifecycleHandler {
    static func submitTurn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var state = session.runtime.bobs27State else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .error,
                isRecoverable: true,
                userMessageKey: "error.match.mode.bobs27Unavailable"
            )
        }
        let outcome = try Bobs27Engine.submitTurn(state: state, darts: darts, timestamp: timestamp)
        state = outcome.updatedState
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .bobs27Round(outcome.event),
            timestamp: timestamp
        )
        return try MatchLifecycleCoordinator.appendAndProject(
            session: session,
            newEvent: envelope,
            timestamp: timestamp
        ) { runtime in
            runtime.bobs27State = state
        }
    }

    static func replayTurn(
        _ turn: Bobs27RoundEvent,
        session: MatchLifecycleSession,
        timestamp: Date
    ) throws -> MatchLifecycleSession {
        // Events do not store per-dart inputs; reconstruct a minimal visit that
        // reproduces hitCount / miss outcome for the recorded target.
        let darts = reconstructedDarts(for: turn)
        return try submitTurn(session: session, darts: darts, timestamp: timestamp)
    }

    static func reconstructedDarts(for turn: Bobs27RoundEvent) -> [DartInput] {
        if turn.hitCount > 0 {
            let hit: DartInput
            if turn.targetRoundNumber == 25 {
                hit = DartInput(multiplier: .single, segment: .innerBull)
            } else {
                hit = DartInput(
                    multiplier: .double,
                    segment: .oneToTwenty(turn.targetRoundNumber)
                )
            }
            return Array(repeating: hit, count: turn.hitCount)
        }
        return [
            DartInput(multiplier: .single, segment: .miss, isMiss: true),
            DartInput(multiplier: .single, segment: .miss, isMiss: true),
            DartInput(multiplier: .single, segment: .miss, isMiss: true)
        ]
    }
}
