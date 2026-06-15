import Foundation
@testable import DartBuddy

// MARK: - Player

actor FakePlayerRepository: PlayerRepository {
    private var players: [PlayerSummary]
    private let fetchError: AppError?
    private let humanCreationEnabled: Bool
    private let customBotCreationEnabled: Bool
    private let skillByBotId: [UUID: BotSkillProfile]
    private let throwOnMutations: Bool
    private let appendBotsOnCreate: Bool
    private let stubCreatePlayerWithFirst: Bool

    init(
        players: [PlayerSummary] = [],
        fetchError: AppError? = nil,
        humanCreationEnabled: Bool = false,
        customBotCreationEnabled: Bool = false,
        skillByBotId: [UUID: BotSkillProfile] = [:],
        throwOnMutations: Bool = false,
        appendBotsOnCreate: Bool = false,
        stubCreatePlayerWithFirst: Bool = false
    ) {
        self.players = players
        self.fetchError = fetchError
        self.humanCreationEnabled = humanCreationEnabled
        self.customBotCreationEnabled = customBotCreationEnabled
        self.skillByBotId = skillByBotId
        self.throwOnMutations = throwOnMutations
        self.appendBotsOnCreate = appendBotsOnCreate
        self.stubCreatePlayerWithFirst = stubCreatePlayerWithFirst
    }

    func fetchPlayers(includeArchived _: Bool) async throws -> [PlayerSummary] {
        if let fetchError { throw fetchError }
        return players
    }

    func createPlayer(name: String) async throws -> PlayerSummary {
        if throwOnMutations {
            throw unsupportedMutationError()
        }
        if stubCreatePlayerWithFirst {
            return try requireFirstPlayer()
        }
        if humanCreationEnabled {
            let created = PlayerSummary(
                id: UUID(),
                name: name,
                isArchived: false,
                createdAt: Date(),
                updatedAt: Date()
            )
            players.append(created)
            return created
        }
        return try requireFirstPlayer()
    }

    func createBot(difficulty: BotDifficulty) async throws -> PlayerSummary {
        if throwOnMutations {
            throw unsupportedMutationError()
        }
        if customBotCreationEnabled {
            let created = PlayerSummary(
                id: UUID(),
                name: "Bot",
                isArchived: false,
                isBot: true,
                botDifficultyRaw: difficulty.rawValue,
                botKindRaw: BotKind.preset.rawValue,
                createdAt: Date(),
                updatedAt: Date()
            )
            if appendBotsOnCreate {
                players.append(created)
            }
            return created
        }
        let created = PlayerSummary(
            id: UUID(),
            name: BotNaming.nextDefaultName(difficulty: difficulty, existingNames: players.map(\.name)),
            isArchived: false,
            isBot: true,
            botDifficultyRaw: difficulty.rawValue,
            createdAt: Date(),
            updatedAt: Date()
        )
        if appendBotsOnCreate {
            players.append(created)
        }
        return created
    }

    func createCustomBot(name: String, metrics: CustomBotMetrics) async throws -> PlayerSummary {
        if throwOnMutations {
            throw unsupportedMutationError()
        }
        guard customBotCreationEnabled else {
            throw AppError(
                code: .unsupportedOperation,
                layer: .data,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.repository.notImplemented",
                debugContext: ["repository": "PlayerRepository", "method": "createCustomBot"]
            )
        }
        let created = PlayerSummary(
            id: UUID(),
            name: name,
            isArchived: false,
            isBot: true,
            botDifficultyRaw: metrics.encode(),
            botKindRaw: BotKind.custom.rawValue,
            createdAt: Date(),
            updatedAt: Date()
        )
        players.append(created)
        return created
    }

    func updatePlayerName(playerId: UUID, name: String) async throws -> PlayerSummary {
        if throwOnMutations {
            throw unsupportedMutationError()
        }
        if humanCreationEnabled {
            return try await updatePlayerProfile(
                playerId: playerId,
                name: name,
                avatarStyle: .dart,
                colorToken: .blue,
                notes: ""
            )
        }
        return try requireFirstPlayer()
    }

    func updatePlayerProfile(
        playerId: UUID,
        name: String,
        avatarStyle: PlayerAvatarStyle,
        colorToken: PlayerColorToken,
        notes: String
    ) async throws -> PlayerSummary {
        if throwOnMutations {
            throw unsupportedMutationError()
        }
        if humanCreationEnabled {
            guard let index = players.firstIndex(where: { $0.id == playerId }) else {
                throw AppError(
                    code: .notFound,
                    layer: .data,
                    severity: .warning,
                    isRecoverable: true,
                    userMessageKey: "error.player.notFound"
                )
            }
            let existing = players[index]
            let updated = PlayerSummary(
                id: existing.id,
                name: name,
                isArchived: existing.isArchived,
                avatarStyleRaw: avatarStyle.rawValue,
                preferredColorToken: colorToken.rawValue,
                notes: notes.isEmpty ? nil : notes,
                createdAt: existing.createdAt,
                updatedAt: Date()
            )
            players[index] = updated
            return updated
        }
        return try requireFirstPlayer()
    }

    func archivePlayer(playerId _: UUID) async throws {}
    func unarchivePlayer(playerId _: UUID) async throws {}
    func deletePlayer(playerId _: UUID) async throws {}

    func resolveTrainingBotSkill(for botId: UUID, mode _: MatchType) async throws -> BotSkillProfile {
        guard let profile = skillByBotId[botId] else {
            throw AppError(
                code: .notFound,
                layer: .data,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "trainingBot.error.notTrainingBot"
            )
        }
        return profile
    }

    private func requireFirstPlayer() throws -> PlayerSummary {
        guard let first = players.first else {
            throw AppError(
                code: .notFound,
                layer: .data,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.player.notFound"
            )
        }
        return first
    }

    private func unsupportedMutationError() -> AppError {
        AppError(
            code: .unsupportedOperation,
            layer: .data,
            severity: .warning,
            isRecoverable: true,
            userMessageKey: "error"
        )
    }
}

// MARK: - Match

struct HistoryMatchRecord: Sendable {
    let matchId: UUID
    let summary: MatchSummary
    let participants: [MatchParticipantSummary]
    let snapshot: MatchSnapshotSummary?

    init(
        matchId: UUID,
        summary: MatchSummary,
        participants: [MatchParticipantSummary],
        snapshot: MatchSnapshotSummary?
    ) {
        self.matchId = matchId
        self.summary = summary
        self.participants = participants
        self.snapshot = snapshot
    }
}

struct FakeMatchRepositoryConfiguration: Sendable {
    enum Behavior: Sendable {
        case setupDefault
        case readOnlyActive
        case matchViewModel
        case setupWithPersistence
    }

    var behavior: Behavior = .setupDefault
    var activeMatch: MatchSummary?
    var pinnedActiveMatch: MatchSummary?
    var storedSnapshot: MatchSnapshotSummary?
    var fetchActiveError: AppError?
    var failAppend = false
    var captureParticipants = false
    var captureTurnOrder = false
    var trackAbandonOnUpdate = false
    var trackDeletes = false
    var trackSnapshotSaves = false
    var clearActiveOnAbandon = false
    var clearActiveOnDelete = false
    var dynamicActiveConflict = false
    var completedMatchType: MatchType = .x01
    var unsupportedOperationKey = "error.repository.notImplemented"
    var tracksForfeit = false
    var captureUpdatedSummaries = false
    var historyCompleted: [HistoryMatchRecord] = []
    var historyActive: HistoryMatchRecord?
    var historyMutationsReturnStoredSummary = false
    var historyForfeitReturnsStoredSummary = false
    var historyRequiresFirstPage = false
    var trackDeletedMatchIds = false
    var blockCompleteAndForfeit = false
}

actor FakeMatchRepository: MatchRepository {
    private var configuration: FakeMatchRepositoryConfiguration
    private var hasActiveConflict: Bool

    private(set) var lastParticipants: [MatchParticipantSummary] = []
    private(set) var lastParticipantNames: [String] = []
    private(set) var abandonedCount = 0
    private(set) var deletedCount = 0
    private(set) var snapshotSaved = false
    private(set) var lastStatus: MatchStatus?
    private(set) var appendCount = 0
    private(set) var updateCount = 0
    private(set) var completeCount = 0
    private(set) var saveSnapshotCount = 0
    private(set) var forfeitCallCount = 0
    private(set) var updatedSummaries: [MatchSummary] = []
    private(set) var deletedMatchIds: [UUID] = []

    init(configuration: FakeMatchRepositoryConfiguration = FakeMatchRepositoryConfiguration()) {
        self.configuration = configuration
        hasActiveConflict = configuration.dynamicActiveConflict
            || configuration.pinnedActiveMatch != nil
            || configuration.activeMatch != nil
    }

    func createMatch(
        type: MatchType,
        configPayload _: Data,
        participants: [MatchParticipantSummary]
    ) async throws -> MatchSummary {
        if configuration.captureParticipants {
            lastParticipants = participants
        }
        if configuration.captureTurnOrder {
            lastParticipantNames = participants
                .sorted { $0.turnOrder < $1.turnOrder }
                .map(\.displayNameAtMatchStart)
        }
        if configuration.behavior == .readOnlyActive {
            throw unsupportedOperationError()
        }
        if configuration.historyMutationsReturnStoredSummary,
           let summary = primaryHistorySummary() {
            return summary
        }
        return makeSummary(type: type, status: .inProgress)
    }

    func fetchActiveMatch() async throws -> MatchSummary? {
        if let fetchActiveError = configuration.fetchActiveError {
            throw fetchActiveError
        }
        if configuration.dynamicActiveConflict {
            return hasActiveConflict ? dynamicConflictSummary() : nil
        }
        if let pinnedActiveMatch = configuration.pinnedActiveMatch {
            return pinnedActiveMatch
        }
        if let activeMatch = configuration.activeMatch {
            return activeMatch
        }
        return configuration.historyActive?.summary
    }

    func fetchHistory(page _: Int, pageSize _: Int) async throws -> [MatchSummary] {
        configuration.historyCompleted.map(\.summary)
    }

    func fetchHistoryWithParticipants(
        page: Int,
        pageSize: Int,
        filter: MatchHistoryFilter
    ) async throws -> [MatchHistoryRecord] {
        if configuration.historyRequiresFirstPage, page != 0 {
            return []
        }
        return filteredHistoryRecords(filter: filter)
            .prefix(pageSize)
            .map { MatchHistoryRecord(summary: $0.summary, participants: $0.participants) }
    }

    func updateMatch(_ match: MatchSummary) async throws {
        updateCount += 1
        lastStatus = match.status
        if configuration.captureUpdatedSummaries {
            updatedSummaries.append(match)
        }
        if configuration.trackAbandonOnUpdate, match.status == .abandoned {
            abandonedCount += 1
            if configuration.clearActiveOnAbandon {
                hasActiveConflict = false
                configuration.activeMatch = nil
            }
        }
    }

    func completeMatch(
        matchId _: UUID,
        endedAt _: Date,
        winnerPlayerId _: UUID?
    ) async throws -> MatchSummary {
        if configuration.historyMutationsReturnStoredSummary,
           let summary = primaryHistorySummary() {
            return summary
        }
        if configuration.blockCompleteAndForfeit {
            throw unsupportedOperationError()
        }
        switch configuration.behavior {
        case .matchViewModel, .setupWithPersistence:
            completeCount += 1
            return makeSummary(type: configuration.completedMatchType, status: .completed)
        case .setupDefault, .readOnlyActive:
            throw unsupportedOperationError()
        }
    }

    func forfeitMatch(
        matchId: UUID,
        endedAt: Date,
        winnerPlayerId: UUID?,
        forfeitedByPlayerId: UUID
    ) async throws -> MatchSummary {
        if configuration.historyForfeitReturnsStoredSummary,
           let summary = primaryHistorySummary() {
            return summary
        }
        if configuration.tracksForfeit {
            forfeitCallCount += 1
            return MatchSummary(
                id: matchId,
                type: configuration.completedMatchType,
                status: .forfeited,
                startedAt: Date(),
                endedAt: endedAt,
                winnerPlayerId: winnerPlayerId,
                forfeitedByPlayerId: forfeitedByPlayerId,
                currentTurnPlayerId: nil,
                currentLegIndex: 0,
                currentSetIndex: 0,
                eventCount: 1,
                createdAt: Date(),
                updatedAt: Date()
            )
        }
        throw AppError(
            code: .unsupportedOperation,
            layer: .data,
            severity: .warning,
            isRecoverable: true,
            userMessageKey: configuration.unsupportedOperationKey
        )
    }

    func appendEvent(
        matchId: UUID,
        eventTypeRaw: String,
        eventPayload: Data
    ) async throws -> MatchEventSummary {
        switch configuration.behavior {
        case .matchViewModel, .setupWithPersistence:
            appendCount += 1
            if configuration.failAppend {
                throw AppError(
                    code: .storageUnavailable,
                    layer: .data,
                    severity: .error,
                    isRecoverable: true,
                    userMessageKey: "error.repository.storage"
                )
            }
            return MatchEventSummary(
                id: UUID(),
                matchId: matchId,
                eventIndex: appendCount - 1,
                eventTypeRaw: eventTypeRaw,
                eventPayload: eventPayload,
                createdAt: Date()
            )
        case .setupDefault, .readOnlyActive:
            throw unsupportedOperationError()
        }
    }

    func saveSnapshot(
        matchId: UUID,
        snapshotVersion: Int,
        snapshotPayload: Data
    ) async throws -> MatchSnapshotSummary {
        if configuration.trackSnapshotSaves {
            snapshotSaved = true
        }
        switch configuration.behavior {
        case .setupDefault, .matchViewModel, .setupWithPersistence:
            saveSnapshotCount += 1
            return MatchSnapshotSummary(
                id: UUID(),
                matchId: matchId,
                snapshotVersion: snapshotVersion,
                snapshotPayload: snapshotPayload,
                updatedAt: Date()
            )
        case .readOnlyActive:
            throw unsupportedOperationError()
        }
    }

    func fetchLatestSnapshot(matchId: UUID) async throws -> MatchSnapshotSummary? {
        if let storedSnapshot = configuration.storedSnapshot,
           storedSnapshot.matchId == matchId {
            return storedSnapshot
        }
        if configuration.historyActive?.matchId == matchId {
            return configuration.historyActive?.snapshot
        }
        return configuration.historyCompleted.first { $0.matchId == matchId }?.snapshot
    }

    func fetchMatch(matchId: UUID) async throws -> MatchSummary? {
        if configuration.historyActive?.matchId == matchId {
            return configuration.historyActive?.summary
        }
        return configuration.historyCompleted.first { $0.matchId == matchId }?.summary
    }

    func fetchParticipants(matchId: UUID) async throws -> [MatchParticipantSummary] {
        if let active = configuration.historyActive, active.matchId == matchId {
            return active.participants
        }
        return configuration.historyCompleted.first { $0.matchId == matchId }?.participants ?? []
    }

    func deleteMatch(matchId: UUID) async throws {
        if configuration.trackDeletedMatchIds {
            deletedMatchIds.append(matchId)
        }
        if configuration.trackDeletes {
            deletedCount += 1
            if configuration.clearActiveOnDelete {
                hasActiveConflict = false
                configuration.activeMatch = nil
            }
        }
    }

    func wasMatchDeleted(_ id: UUID) -> Bool {
        deletedMatchIds.contains(id)
    }

    private func makeSummary(type: MatchType, status: MatchStatus) -> MatchSummary {
        MatchSummary(
            id: UUID(),
            type: type,
            status: status,
            startedAt: Date(),
            endedAt: status == .completed ? Date() : nil,
            winnerPlayerId: nil,
            currentTurnPlayerId: nil,
            currentLegIndex: 0,
            currentSetIndex: 0,
            eventCount: 0,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    private func dynamicConflictSummary() -> MatchSummary {
        MatchSummary(
            id: UUID(),
            type: .x01,
            status: .inProgress,
            startedAt: Date(),
            endedAt: nil,
            winnerPlayerId: nil,
            currentTurnPlayerId: nil,
            currentLegIndex: 0,
            currentSetIndex: 0,
            eventCount: 0,
            createdAt: Date(),
            updatedAt: Date()
        )
    }

    private func unsupportedOperationError() -> AppError {
        AppError(
            code: .unsupportedOperation,
            layer: .data,
            severity: .warning,
            isRecoverable: true,
            userMessageKey: configuration.unsupportedOperationKey
        )
    }

    private func primaryHistorySummary() -> MatchSummary? {
        configuration.historyActive?.summary
            ?? configuration.historyCompleted.first?.summary
    }

    private func filteredHistoryRecords(filter: MatchHistoryFilter) -> [HistoryMatchRecord] {
        configuration.historyCompleted.filter { record in
            if let type = filter.matchType, record.summary.type != type {
                return false
            }
            if let startedAfter = filter.startedAfter, record.summary.startedAt < startedAfter {
                return false
            }
            if let playerId = filter.participantPlayerId,
               !record.participants.contains(where: { $0.playerId == playerId }) {
                return false
            }
            return true
        }
    }
}

// MARK: - Settings

actor FakeSettingsRepository: SettingsRepository {
    var settings: SettingsSummary
    private let fetchError: AppError?
    private let updateError: AppError?
    private let resetError: AppError?
    private(set) var updateCallCount = 0
    private(set) var resetCallCount = 0

    init(
        settings: SettingsSummary? = nil,
        fetchError: AppError? = nil,
        updateError: AppError? = nil,
        resetError: AppError? = nil
    ) {
        self.settings = settings ?? Self.defaultSettings()
        self.fetchError = fetchError
        self.updateError = updateError
        self.resetError = resetError
    }

    func fetchSettings() async throws -> SettingsSummary {
        if let fetchError { throw fetchError }
        return settings
    }

    func seedDefaultsIfNeeded() async throws -> SettingsSummary {
        try await fetchSettings()
    }

    func replaceSettings(_ next: SettingsSummary) {
        settings = next
    }

    func updateSettings(_ settings: SettingsSummary) async throws -> SettingsSummary {
        updateCallCount += 1
        if let updateError { throw updateError }
        self.settings = settings
        return settings
    }

    func resetPreferencesToDefaults() async throws {
        settings = Self.defaultSettings(id: settings.id)
    }

    func resetAllLocalData() async throws {
        resetCallCount += 1
        if let resetError { throw resetError }
        settings = Self.defaultSettings(id: settings.id)
    }

    static func defaultSettings(id: UUID = UUID()) -> SettingsSummary {
        SettingsSummary(
            id: id,
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
            botStaggerEnabled: true,
            botDartHapticsEnabled: true,
            defaultDartEntryPresentationRaw: "numberPad",
            updatedAt: Date()
        )
    }
}

// MARK: - Stats

actor FakeStatsRepository: StatsRepository {
    private let events: [MatchEventSummary]
    private let filterByMatchId: Bool

    init(events: [MatchEventSummary] = [], filterByMatchId: Bool = false) {
        self.events = events
        self.filterByMatchId = filterByMatchId
    }

    func fetchEvents(matchId: UUID) async throws -> [MatchEventSummary] {
        guard filterByMatchId else { return events }
        return events.filter { $0.matchId == matchId }
    }

    func fetchEvents(matchIds: [UUID]) async throws -> [MatchEventSummary] {
        guard filterByMatchId else { return events }
        let idSet = Set(matchIds)
        return events.filter { idSet.contains($0.matchId) }
    }
}
