import Foundation

public protocol PlayerRepository: Sendable {
    func fetchPlayers(includeArchived: Bool) async throws -> [PlayerSummary]
    func createPlayer(name: String) async throws -> PlayerSummary
    func createBot(difficulty: BotDifficulty) async throws -> PlayerSummary
    func createCustomBot(name: String, metrics: CustomBotMetrics) async throws -> PlayerSummary
    func createCustomBot(name: String, configuration: CustomBotConfiguration) async throws -> PlayerSummary
    func updateCustomBotMetrics(playerId: UUID, metrics: CustomBotMetrics) async throws -> PlayerSummary
    func updateCustomBotConfiguration(playerId: UUID, configuration: CustomBotConfiguration) async throws -> PlayerSummary
    func decodeCustomBotConfiguration(player: PlayerSummary) -> CustomBotConfiguration?
    func updatePlayerName(playerId: UUID, name: String) async throws -> PlayerSummary
    func updatePlayerProfile(
        playerId: UUID,
        name: String,
        avatarStyle: PlayerAvatarStyle,
        colorToken: PlayerColorToken,
        notes: String
    ) async throws -> PlayerSummary
    func archivePlayer(playerId: UUID) async throws
    func unarchivePlayer(playerId: UUID) async throws
    func deletePlayer(playerId: UUID) async throws
    func fetchTrainingBot(linkedTo playerId: UUID) async throws -> PlayerSummary?
    func createTrainingBot(for playerId: UUID) async throws -> PlayerSummary
    func resolveTrainingBotSkill(for botId: UUID, mode: MatchType) async throws -> BotSkillProfile
}

public extension PlayerRepository {
    func createCustomBot(name _: String, metrics _: CustomBotMetrics) async throws -> PlayerSummary {
        throw AppError(
            code: .unsupportedOperation,
            layer: .data,
            severity: .warning,
            isRecoverable: true,
            userMessageKey: "error.repository.notImplemented",
            debugContext: ["repository": "PlayerRepository", "method": "createCustomBot"]
        )
    }

    func createCustomBot(name _: String, configuration _: CustomBotConfiguration) async throws -> PlayerSummary {
        throw AppError(
            code: .unsupportedOperation,
            layer: .data,
            severity: .warning,
            isRecoverable: true,
            userMessageKey: "error.repository.notImplemented",
            debugContext: ["repository": "PlayerRepository", "method": "createCustomBot(configuration:)"]
        )
    }

    func updateCustomBotMetrics(playerId _: UUID, metrics _: CustomBotMetrics) async throws -> PlayerSummary {
        throw AppError(
            code: .unsupportedOperation,
            layer: .data,
            severity: .warning,
            isRecoverable: true,
            userMessageKey: "error.repository.notImplemented",
            debugContext: ["repository": "PlayerRepository", "method": "updateCustomBotMetrics"]
        )
    }

    func updateCustomBotConfiguration(playerId _: UUID, configuration _: CustomBotConfiguration) async throws -> PlayerSummary {
        throw AppError(
            code: .unsupportedOperation,
            layer: .data,
            severity: .warning,
            isRecoverable: true,
            userMessageKey: "error.repository.notImplemented",
            debugContext: ["repository": "PlayerRepository", "method": "updateCustomBotConfiguration"]
        )
    }

    func decodeCustomBotConfiguration(player: PlayerSummary) -> CustomBotConfiguration? {
        player.customBotConfiguration
    }

    func fetchTrainingBot(linkedTo _: UUID) async throws -> PlayerSummary? { nil }

    func createTrainingBot(for _: UUID) async throws -> PlayerSummary {
        throw AppError(
            code: .unsupportedOperation,
            layer: .data,
            severity: .warning,
            isRecoverable: true,
            userMessageKey: "error.repository.notImplemented",
            debugContext: ["repository": "PlayerRepository", "method": "createTrainingBot"]
        )
    }

    func resolveTrainingBotSkill(for _: UUID, mode _: MatchType) async throws -> BotSkillProfile {
        throw AppError(
            code: .unsupportedOperation,
            layer: .data,
            severity: .warning,
            isRecoverable: true,
            userMessageKey: "error.repository.notImplemented",
            debugContext: ["repository": "PlayerRepository", "method": "resolveTrainingBotSkill"]
        )
    }
}

public protocol MatchRepository: Sendable {
    func createMatch(type: MatchType, configPayload: Data, participants: [MatchParticipantSummary]) async throws -> MatchSummary
    func fetchActiveMatch() async throws -> MatchSummary?
    func fetchHistory(page: Int, pageSize: Int) async throws -> [MatchSummary]
    func fetchHistoryWithParticipants(page: Int, pageSize: Int, filter: MatchHistoryFilter) async throws -> [MatchHistoryRecord]
    func updateMatch(_ match: MatchSummary) async throws
    func completeMatch(matchId: UUID, endedAt: Date, winnerPlayerId: UUID?) async throws -> MatchSummary
    func appendEvent(matchId: UUID, eventTypeRaw: String, eventPayload: Data) async throws -> MatchEventSummary
    func saveSnapshot(matchId: UUID, snapshotVersion: Int, snapshotPayload: Data) async throws -> MatchSnapshotSummary
    func fetchLatestSnapshot(matchId: UUID) async throws -> MatchSnapshotSummary?
    func fetchMatch(matchId: UUID) async throws -> MatchSummary?
    func fetchParticipants(matchId: UUID) async throws -> [MatchParticipantSummary]
    func fetchConfigPayload(matchId: UUID) async throws -> Data?
    func deleteMatch(matchId: UUID) async throws
}

public extension MatchRepository {
    func fetchConfigPayload(matchId _: UUID) async throws -> Data? { nil }
}

public protocol StatsRepository: Sendable {
    func fetchEvents(matchId: UUID) async throws -> [MatchEventSummary]
    func fetchEvents(matchIds: [UUID]) async throws -> [MatchEventSummary]
}

public protocol SettingsRepository: Sendable {
    func fetchSettings() async throws -> SettingsSummary
    func seedDefaultsIfNeeded() async throws -> SettingsSummary
    func updateSettings(_ settings: SettingsSummary) async throws -> SettingsSummary
    func resetPreferencesToDefaults() async throws
    func resetAllLocalData() async throws
}

public struct MatchHistoryRecord: Equatable, Sendable {
    public let summary: MatchSummary
    public let participants: [MatchParticipantSummary]
    public let historyCardPayload: Data?

    public init(
        summary: MatchSummary,
        participants: [MatchParticipantSummary],
        historyCardPayload: Data? = nil
    ) {
        self.summary = summary
        self.participants = participants
        self.historyCardPayload = historyCardPayload
    }
}
