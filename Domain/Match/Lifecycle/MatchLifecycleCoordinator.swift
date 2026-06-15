import Foundation

/// Shared append/replay/snapshot kernel for match lifecycle. Mode-specific turn
/// submission lives in handlers; this type owns event projection and snapshots.
enum MatchLifecycleCoordinator {
    static let snapshotInterval = 3

    static func appendAndProject(
        session: MatchLifecycleSession,
        newEvent: MatchEventEnvelope,
        timestamp: Date,
        update: (inout MatchRuntimeState) -> Void
    ) throws -> MatchLifecycleSession {
        var runtime = session.runtime
        runtime.eventCount += 1
        update(&runtime)
        MatchRuntimeProjection.project(&runtime, timestamp: timestamp)

        var events = session.events
        events.append(newEvent)
        var snapshot = session.latestSnapshot
        if runtime.eventCount % snapshotInterval == 0 || runtime.status == .completed {
            snapshot = try makeSnapshot(from: runtime, eventCount: runtime.eventCount, timestamp: timestamp)
        }
        return MatchLifecycleSession(runtime: runtime, events: events, latestSnapshot: snapshot)
    }

    static func makeSnapshot(
        from runtime: MatchRuntimeState,
        eventCount: Int,
        timestamp: Date
    ) throws -> MatchSnapshot {
        MatchSnapshot(
            payloadVersion: 1,
            eventCount: eventCount,
            createdAt: timestamp,
            payload: try CodablePayloadCoder.encode(runtime)
        )
    }
}
