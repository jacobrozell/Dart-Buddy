import Foundation

enum X01MatchLifecycleHandler {
    static func submitTurn(
        session: MatchLifecycleSession,
        enteredTotal: Int?,
        darts: [DartInput]?,
        timestamp: Date = Date()
    ) throws -> MatchLifecycleSession {
        guard var state = session.runtime.x01State else {
            throw AppError(
                code: .invalidGameState,
                layer: .domain,
                severity: .error,
                isRecoverable: true,
                userMessageKey: "error.match.mode.x01Unavailable"
            )
        }
        let outcome = try X01Engine.submitTurn(
            state: state,
            enteredTotal: enteredTotal,
            darts: darts,
            timestamp: timestamp
        )
        state = outcome.updatedState
        let envelope = MatchEventEnvelope(
            eventIndex: session.runtime.eventCount,
            payload: .x01Turn(outcome.event),
            timestamp: timestamp
        )
        return try MatchLifecycleCoordinator.appendAndProject(
            session: session,
            newEvent: envelope,
            timestamp: timestamp
        ) { runtime in
            runtime.x01State = state
        }
    }

    static func replayTurn(
        _ turn: X01TurnEvent,
        session: MatchLifecycleSession,
        timestamp: Date
    ) throws -> MatchLifecycleSession {
        let darts = turn.darts.map {
            DartInput(
                multiplier: DartMultiplier(rawValue: $0.multiplierRaw) ?? .single,
                segment: mapSegmentRaw($0.segmentRaw),
                isMiss: $0.wasMiss
            )
        }
        return try submitTurn(
            session: session,
            enteredTotal: turn.enteredTotal,
            darts: darts,
            timestamp: timestamp
        )
    }

    static func mapSegmentRaw(_ raw: String) -> DartSegment {
        if let value = Int(raw), (1 ... 20).contains(value) {
            return .oneToTwenty(value)
        }
        switch raw {
        case "outerBull": return .outerBull
        case "innerBull": return .innerBull
        default: return .miss
        }
    }
}
