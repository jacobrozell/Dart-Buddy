import Foundation

public actor StubPlayerRepository: PlayerRepository {
    public init() {}

    public func fetchPlayers(includeArchived _: Bool) async throws -> [PlayerSummary] { [] }
    public func createPlayer(name: String) async throws -> PlayerSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented", debugContext: ["repository": "PlayerRepository"]) }
    public func createBot(difficulty _: BotDifficulty) async throws -> PlayerSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented", debugContext: ["repository": "PlayerRepository"]) }
    public func updatePlayerName(playerId _: UUID, name _: String) async throws -> PlayerSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented", debugContext: ["repository": "PlayerRepository"]) }
    public func updatePlayerProfile(playerId _: UUID, name _: String, avatarStyle _: PlayerAvatarStyle, colorToken _: PlayerColorToken, notes _: String) async throws -> PlayerSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented", debugContext: ["repository": "PlayerRepository"]) }
    public func archivePlayer(playerId _: UUID) async throws {}
    public func unarchivePlayer(playerId _: UUID) async throws {}
    public func deletePlayer(playerId _: UUID) async throws {}
}

public actor StubMatchRepository: MatchRepository {
    public init() {}

    public func createMatch(type _: MatchType, configPayload _: Data, participants _: [MatchParticipantSummary]) async throws -> MatchSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented", debugContext: ["repository": "MatchRepository"]) }
    public func fetchActiveMatch() async throws -> MatchSummary? { nil }
    public func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] { [] }
    public func fetchHistoryWithParticipants(page _: Int, pageSize _: Int, filter _: MatchHistoryFilter) async throws -> [MatchHistoryRecord] { [] }
    public func updateMatch(_: MatchSummary) async throws {}
    public func completeMatch(matchId _: UUID, endedAt _: Date, winnerPlayerId _: UUID?) async throws -> MatchSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented", debugContext: ["repository": "MatchRepository"]) }
    public func appendEvent(matchId _: UUID, eventTypeRaw _: String, eventPayload _: Data) async throws -> MatchEventSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented", debugContext: ["repository": "MatchRepository"]) }
    public func saveSnapshot(matchId _: UUID, snapshotVersion _: Int, snapshotPayload _: Data) async throws -> MatchSnapshotSummary { throw AppError(code: .unsupportedOperation, layer: .data, severity: .warning, isRecoverable: true, userMessageKey: "error.repository.notImplemented", debugContext: ["repository": "MatchRepository"]) }
    public func fetchLatestSnapshot(matchId _: UUID) async throws -> MatchSnapshotSummary? { nil }
    public func fetchMatch(matchId _: UUID) async throws -> MatchSummary? { nil }
    public func fetchParticipants(matchId _: UUID) async throws -> [MatchParticipantSummary] { [] }
    public func deleteMatch(matchId _: UUID) async throws {}
}

public actor StubStatsRepository: StatsRepository {
    public init() {}
    public func fetchEvents(matchId _: UUID) async throws -> [MatchEventSummary] { [] }
    public func fetchEvents(matchIds _: [UUID]) async throws -> [MatchEventSummary] { [] }
}

public actor StubSettingsRepository: SettingsRepository {
    private var settings = SettingsSummary(
        id: UUID(),
        appearanceModeRaw: "system",
        hapticsEnabled: true,
        soundEnabled: true,
        turnTotalCallerEnabled: false,
        defaultMatchTypeRaw: "x01",
        defaultX01StartScore: 501,
        defaultCheckoutModeRaw: "doubleOut",
        defaultCheckInModeRaw: "straightIn",
        defaultLegFormatRaw: "firstTo",
        defaultLegsToWin: 3,
        defaultSetsEnabled: false,
        updatedAt: Date()
    )

    public init() {}

    public func fetchSettings() async throws -> SettingsSummary {
        settings
    }

    public func seedDefaultsIfNeeded() async throws -> SettingsSummary {
        settings
    }

    public func updateSettings(_ settings: SettingsSummary) async throws -> SettingsSummary {
        self.settings = settings
        return settings
    }

    public func resetPreferencesToDefaults() async throws {
        settings = SettingsSummary(
            id: settings.id,
            appearanceModeRaw: "system",
            hapticsEnabled: true,
            soundEnabled: true,
            turnTotalCallerEnabled: false,
            defaultMatchTypeRaw: "x01",
            defaultX01StartScore: 501,
            defaultCheckoutModeRaw: "doubleOut",
            defaultCheckInModeRaw: "straightIn",
            defaultLegFormatRaw: "firstTo",
            defaultLegsToWin: 3,
            defaultSetsEnabled: false,
            updatedAt: Date()
        )
    }

    public func resetAllLocalData() async throws {
        try await resetPreferencesToDefaults()
    }
}
