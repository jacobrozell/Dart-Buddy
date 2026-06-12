import Foundation

extension MatchPlaySessionHost {
    func abandonMatch() async {
        await loadSessionIfNeeded()
        guard let current = session, current.runtime.status == .inProgress else { return }
        do {
            let abandoned = try MatchLifecycleService.abandon(session: current)
            try await hostMatchRepository.updateMatch(MatchTurnSupport.matchSummary(from: abandoned.runtime))
            _ = try await hostMatchRepository.saveSnapshot(
                matchId: matchId,
                snapshotVersion: abandoned.latestSnapshot.payloadVersion,
                snapshotPayload: abandoned.latestSnapshot.payload
            )
            hostMatchStore.remove(matchId: matchId)
            session = abandoned
            hostMatchLogger.matchInfo(
                matchId: matchId,
                matchType: hostMatchType,
                category: .appLifecycle,
                eventName: "match_abandoned",
                message: "Match abandoned by user.",
                metadata: ["eventCount": String(abandoned.runtime.eventCount)]
            )
        } catch {
            hostMatchLogger.matchError(
                matchId: matchId,
                matchType: hostMatchType,
                category: .appLifecycle,
                eventName: "match_abandon_failed",
                message: "Abandon failed.",
                metadata: MatchTurnSupport.appErrorMetadata(for: error)
            )
        }
    }
}
