import Foundation

enum HalveItMatchLifecycleHandler {
    static func submitTurn(
        session: MatchLifecycleSession,
        darts: [DartInput],
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var state = session.runtime.halveItState else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .error,
                isRecoverable: true,
                userMessageKey: "error.match.mode.halveItUnavailable"
            )
        }
        let outcome = try HalveItEngine.submitTurn(state: state, darts: darts, timestamp: timestamp)
        state = outcome.updatedState
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .halveItRound(outcome.event),
            timestamp: timestamp
        )
        return try MatchLifecycleCoordinator.appendAndProject(
            session: session,
            newEvent: envelope,
            timestamp: timestamp
        ) { runtime in
            runtime.halveItState = state
        }
    }

    static func replayTurn(
        _ turn: HalveItRoundEvent,
        session: MatchLifecycleSession,
        timestamp: Date
    ) throws -> MatchLifecycleSession {
        let darts = reconstructedDarts(for: turn)
        return try submitTurn(session: session, darts: darts, timestamp: timestamp)
    }

    /// Rebuild a visit that yields the recorded visitScore (or a full miss for halve).
    static func reconstructedDarts(for turn: HalveItRoundEvent) -> [DartInput] {
        if turn.halved || turn.visitScore == 0 {
            return [
                DartInput(multiplier: .single, segment: .miss, isMiss: true),
                DartInput(multiplier: .single, segment: .miss, isMiss: true),
                DartInput(multiplier: .single, segment: .miss, isMiss: true)
            ]
        }
        let target = turn.target
        var remaining = turn.visitScore
        var darts: [DartInput] = []
        // Greedy T → D → S so mixed visits (e.g. 100 = T20+D20) replay exactly.
        while remaining > 0, darts.count < 3 {
            if remaining >= target * 3 {
                darts.append(DartInput(multiplier: .triple, segment: .oneToTwenty(target)))
                remaining -= target * 3
            } else if remaining >= target * 2 {
                darts.append(DartInput(multiplier: .double, segment: .oneToTwenty(target)))
                remaining -= target * 2
            } else if remaining >= target {
                darts.append(DartInput(multiplier: .single, segment: .oneToTwenty(target)))
                remaining -= target
            } else {
                break
            }
        }
        return darts.isEmpty
            ? [DartInput(multiplier: .single, segment: .oneToTwenty(target))]
            : darts
    }
}
