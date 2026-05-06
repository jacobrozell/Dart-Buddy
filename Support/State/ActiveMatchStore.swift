import Foundation

@MainActor
final class ActiveMatchStore: ObservableObject {
    @Published private(set) var sessions: [UUID: MatchLifecycleSession] = [:]

    func session(for matchId: UUID) -> MatchLifecycleSession? {
        sessions[matchId]
    }

    func save(_ session: MatchLifecycleSession) {
        sessions[session.runtime.matchId] = session
    }

    func remove(matchId: UUID) {
        sessions.removeValue(forKey: matchId)
    }

    func clearAll() {
        sessions.removeAll()
    }

    func activeMatchSummary() -> MatchSummary? {
        guard let session = sessions.values.first(where: { $0.runtime.status == .inProgress }) else { return nil }
        return MatchSummary(
            id: session.runtime.matchId,
            type: session.runtime.type,
            status: .inProgress,
            startedAt: session.runtime.startedAt,
            endedAt: session.runtime.endedAt,
            winnerPlayerId: session.runtime.winnerPlayerId,
            currentTurnPlayerId: session.runtime.currentTurnPlayerId,
            currentLegIndex: session.runtime.currentLegIndex,
            currentSetIndex: session.runtime.currentSetIndex,
            eventCount: session.runtime.eventCount,
            createdAt: session.runtime.startedAt,
            updatedAt: Date()
        )
    }

    func completedSessions() -> [MatchLifecycleSession] {
        sessions.values
            .filter { $0.runtime.status == .completed }
            .sorted { ($0.runtime.endedAt ?? .distantPast) > ($1.runtime.endedAt ?? .distantPast) }
    }
}
