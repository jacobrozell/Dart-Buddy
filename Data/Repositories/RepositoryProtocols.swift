import Foundation

public protocol PlayerRepository: Sendable {
    func fetchPlayers(includeArchived: Bool) async throws -> [PlayerSummary]
    func createPlayer(name: String) async throws -> PlayerSummary
    func updatePlayerName(playerId: UUID, name: String) async throws -> PlayerSummary
    func archivePlayer(playerId: UUID) async throws
    func unarchivePlayer(playerId: UUID) async throws
    func deletePlayer(playerId: UUID) async throws
}

public protocol MatchRepository: Sendable {
    func createMatch(type: MatchType, configPayload: Data, participants: [MatchParticipantSummary]) async throws -> MatchSummary
    func fetchActiveMatch() async throws -> MatchSummary?
    func fetchHistory(page: Int, pageSize: Int) async throws -> [MatchSummary]
    func updateMatch(_ match: MatchSummary) async throws
    func completeMatch(matchId: UUID, endedAt: Date, winnerPlayerId: UUID?) async throws -> MatchSummary
    func appendEvent(matchId: UUID, eventTypeRaw: String, eventPayload: Data) async throws -> MatchEventSummary
    func saveSnapshot(matchId: UUID, snapshotVersion: Int, snapshotPayload: Data) async throws -> MatchSnapshotSummary
    func fetchLatestSnapshot(matchId: UUID) async throws -> MatchSnapshotSummary?
    func fetchMatch(matchId: UUID) async throws -> MatchSummary?
    func fetchParticipants(matchId: UUID) async throws -> [MatchParticipantSummary]
}

public protocol StatsRepository: Sendable {
    func fetchEvents(matchId: UUID) async throws -> [MatchEventSummary]
    func rebuildAggregateCache() async throws
}

public protocol SettingsRepository: Sendable {
    func fetchSettings() async throws -> SettingsSummary
    func seedDefaultsIfNeeded() async throws -> SettingsSummary
    func updateSettings(_ settings: SettingsSummary) async throws -> SettingsSummary
    func resetSettings() async throws
}

public extension MatchRepository {
    func fetchMatch(matchId _: UUID) async throws -> MatchSummary? {
        nil
    }

    func fetchParticipants(matchId _: UUID) async throws -> [MatchParticipantSummary] {
        []
    }
}
