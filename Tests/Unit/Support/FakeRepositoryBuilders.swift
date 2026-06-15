import Foundation
@testable import DartBuddy

// MARK: - Match repository builders

enum FakeMatchRepositoryBuilder {
    static func standard() -> FakeMatchRepository {
        FakeMatchRepository()
    }

    static func withActiveMatch(_ activeMatch: MatchSummary?) -> FakeMatchRepository {
        var configuration = FakeMatchRepositoryConfiguration()
        configuration.behavior = .readOnlyActive
        configuration.activeMatch = activeMatch
        configuration.unsupportedOperationKey = "error"
        return FakeMatchRepository(configuration: configuration)
    }

    static func participantCapturing() -> FakeMatchRepository {
        var configuration = FakeMatchRepositoryConfiguration()
        configuration.captureParticipants = true
        return FakeMatchRepository(configuration: configuration)
    }

    static func turnOrderCapturing() -> FakeMatchRepository {
        var configuration = FakeMatchRepositoryConfiguration()
        configuration.captureTurnOrder = true
        return FakeMatchRepository(configuration: configuration)
    }

    static func throwingActiveLookup(
        error: AppError = AppError(
            code: .storageUnavailable,
            layer: .data,
            severity: .error,
            isRecoverable: true,
            userMessageKey: "setup.error.start"
        )
    ) -> FakeMatchRepository {
        var configuration = FakeMatchRepositoryConfiguration()
        configuration.fetchActiveError = error
        return FakeMatchRepository(configuration: configuration)
    }

    static func failingActiveLookup(
        userMessageKey: String
    ) -> FakeMatchRepository {
        var configuration = FakeMatchRepositoryConfiguration()
        configuration.fetchActiveError = AppError(
            code: .storageUnavailable,
            layer: .data,
            severity: .error,
            isRecoverable: true,
            userMessageKey: userMessageKey
        )
        return FakeMatchRepository(configuration: configuration)
    }

    static func throwingFetchActive() -> FakeMatchRepository {
        var configuration = FakeMatchRepositoryConfiguration()
        configuration.behavior = .readOnlyActive
        configuration.fetchActiveError = AppError(
            code: .unsupportedOperation,
            layer: .data,
            severity: .warning,
            isRecoverable: true,
            userMessageKey: "error"
        )
        configuration.unsupportedOperationKey = "error"
        return FakeMatchRepository(configuration: configuration)
    }

    static func activeConflict(hasActive: Bool) -> FakeMatchRepository {
        var configuration = FakeMatchRepositoryConfiguration()
        configuration.dynamicActiveConflict = hasActive
        configuration.trackAbandonOnUpdate = true
        configuration.trackDeletes = true
        configuration.clearActiveOnAbandon = true
        configuration.clearActiveOnDelete = true
        return FakeMatchRepository(configuration: configuration)
    }

    static func noSnapshotActiveConflict(active: MatchSummary) -> FakeMatchRepository {
        var configuration = FakeMatchRepositoryConfiguration()
        configuration.pinnedActiveMatch = active
        configuration.trackAbandonOnUpdate = true
        configuration.trackSnapshotSaves = true
        return FakeMatchRepository(configuration: configuration)
    }

    static func snapshotOnlyActiveConflict(
        active: MatchSummary,
        snapshot: MatchSnapshotSummary
    ) -> FakeMatchRepository {
        var configuration = FakeMatchRepositoryConfiguration()
        configuration.pinnedActiveMatch = active
        configuration.storedSnapshot = snapshot
        configuration.trackAbandonOnUpdate = true
        configuration.trackSnapshotSaves = true
        return FakeMatchRepository(configuration: configuration)
    }

    static func matchViewModel(completedType: MatchType) -> FakeMatchRepository {
        var configuration = FakeMatchRepositoryConfiguration()
        configuration.behavior = .matchViewModel
        configuration.completedMatchType = completedType
        return FakeMatchRepository(configuration: configuration)
    }

    static func rehydrating(
        snapshot: MatchSnapshotSummary,
        completedType: MatchType
    ) -> FakeMatchRepository {
        var configuration = FakeMatchRepositoryConfiguration()
        configuration.behavior = .matchViewModel
        configuration.storedSnapshot = snapshot
        configuration.completedMatchType = completedType
        return FakeMatchRepository(configuration: configuration)
    }

    static func matchViewModelFailingAppend(completedType: MatchType) -> FakeMatchRepository {
        var configuration = FakeMatchRepositoryConfiguration()
        configuration.behavior = .matchViewModel
        configuration.completedMatchType = completedType
        configuration.failAppend = true
        return FakeMatchRepository(configuration: configuration)
    }

    static func turnSubmitter(failAppend: Bool = false) -> FakeMatchRepository {
        var configuration = FakeMatchRepositoryConfiguration()
        configuration.behavior = .matchViewModel
        configuration.failAppend = failAppend
        return FakeMatchRepository(configuration: configuration)
    }

    static func abandonCapturing(completedType: MatchType) -> FakeMatchRepository {
        var configuration = FakeMatchRepositoryConfiguration()
        configuration.behavior = .matchViewModel
        configuration.completedMatchType = completedType
        configuration.trackSnapshotSaves = true
        return FakeMatchRepository(configuration: configuration)
    }

    static func forfeitCapturing(completedType: MatchType = .x01) -> FakeMatchRepository {
        var configuration = FakeMatchRepositoryConfiguration()
        configuration.tracksForfeit = true
        configuration.completedMatchType = completedType
        return FakeMatchRepository(configuration: configuration)
    }

    static func captureUpdatedSummaries() -> FakeMatchRepository {
        var configuration = FakeMatchRepositoryConfiguration()
        configuration.captureUpdatedSummaries = true
        return FakeMatchRepository(configuration: configuration)
    }

    static func summarySnapshotOnly(snapshot: MatchSnapshotSummary) -> FakeMatchRepository {
        var configuration = FakeMatchRepositoryConfiguration()
        configuration.behavior = .readOnlyActive
        configuration.storedSnapshot = snapshot
        return FakeMatchRepository(configuration: configuration)
    }

    static func statsVM(
        completed: HistoryMatchRecord? = nil,
        active: HistoryMatchRecord? = nil
    ) -> FakeMatchRepository {
        var configuration = FakeMatchRepositoryConfiguration()
        if let completed {
            configuration.historyCompleted = [completed]
        }
        configuration.historyActive = active
        return FakeMatchRepository(configuration: configuration)
    }

    static func multiStatsVM(records: [HistoryMatchRecord]) -> FakeMatchRepository {
        var configuration = FakeMatchRepositoryConfiguration()
        configuration.historyCompleted = records
        configuration.historyRequiresFirstPage = true
        return FakeMatchRepository(configuration: configuration)
    }

    static func historyDetail(record: HistoryMatchRecord) -> FakeMatchRepository {
        var configuration = FakeMatchRepositoryConfiguration()
        configuration.historyCompleted = [record]
        configuration.historyMutationsReturnStoredSummary = true
        configuration.historyForfeitReturnsStoredSummary = true
        return FakeMatchRepository(configuration: configuration)
    }

    static func statsFlow(record: HistoryMatchRecord, trackDeletes: Bool = true) -> FakeMatchRepository {
        var configuration = FakeMatchRepositoryConfiguration()
        configuration.historyCompleted = [record]
        configuration.historyMutationsReturnStoredSummary = true
        configuration.trackDeletedMatchIds = trackDeletes
        return FakeMatchRepository(configuration: configuration)
    }

    static func botIntegration() -> FakeMatchRepository {
        matchViewModel(completedType: .x01)
    }

    static func botSetupCapturing() -> FakeMatchRepository {
        var configuration = FakeMatchRepositoryConfiguration()
        configuration.behavior = .setupWithPersistence
        configuration.blockCompleteAndForfeit = true
        configuration.unsupportedOperationKey = "error.repository.notImplemented"
        return FakeMatchRepository(configuration: configuration)
    }
}

// MARK: - Player repository builders

enum FakePlayerRepositoryBuilder {
    static func standard(players: [PlayerSummary]) -> FakePlayerRepository {
        FakePlayerRepository(players: players)
    }

    static func humanCreating() -> FakePlayerRepository {
        FakePlayerRepository(players: [], humanCreationEnabled: true)
    }

    static func customBotCreating(existing: [PlayerSummary]) -> FakePlayerRepository {
        FakePlayerRepository(players: existing, customBotCreationEnabled: true)
    }

    static func trainingSkill(
        players: [PlayerSummary],
        skillByBotId: [UUID: BotSkillProfile]
    ) -> FakePlayerRepository {
        FakePlayerRepository(players: players, skillByBotId: skillByBotId)
    }

    static func emptyThrowing() -> FakePlayerRepository {
        FakePlayerRepository(throwOnMutations: true)
    }

    static func failingFetch(userMessageKey: String) -> FakePlayerRepository {
        FakePlayerRepository(
            fetchError: AppError(
                code: .storageUnavailable,
                layer: .data,
                severity: .error,
                isRecoverable: true,
                userMessageKey: userMessageKey
            )
        )
    }

    static func readOnly(players: [PlayerSummary] = []) -> FakePlayerRepository {
        FakePlayerRepository(players: players, throwOnMutations: true)
    }

    static func botIntegration(players: [PlayerSummary]) -> FakePlayerRepository {
        FakePlayerRepository(
            players: players,
            appendBotsOnCreate: true,
            stubCreatePlayerWithFirst: true
        )
    }
}

// MARK: - Stats repository builders

enum FakeStatsRepositoryBuilder {
    static func empty() -> FakeStatsRepository {
        FakeStatsRepository()
    }

    static func withEvents(_ events: [MatchEventSummary], filterByMatchId: Bool = false) -> FakeStatsRepository {
        FakeStatsRepository(events: events, filterByMatchId: filterByMatchId)
    }

    static func rehydrating(events: [MatchEventSummary]) -> FakeStatsRepository {
        FakeStatsRepository(events: events, filterByMatchId: true)
    }

    static func unfiltered(events: [MatchEventSummary]) -> FakeStatsRepository {
        FakeStatsRepository(events: events, filterByMatchId: false)
    }
}

extension FakeMatchRepository {
    static func activeConflict(hasActive: Bool) -> FakeMatchRepository {
        FakeMatchRepositoryBuilder.activeConflict(hasActive: hasActive)
    }

    static func participantCapturing() -> FakeMatchRepository {
        FakeMatchRepositoryBuilder.participantCapturing()
    }

    static func turnOrderCapturing() -> FakeMatchRepository {
        FakeMatchRepositoryBuilder.turnOrderCapturing()
    }
}

extension FakePlayerRepository {
    static func humanCreating() -> FakePlayerRepository {
        FakePlayerRepositoryBuilder.humanCreating()
    }

    static func customBotCreating(existing: [PlayerSummary]) -> FakePlayerRepository {
        FakePlayerRepositoryBuilder.customBotCreating(existing: existing)
    }

    static func trainingSkill(
        players: [PlayerSummary],
        skillByBotId: [UUID: BotSkillProfile]
    ) -> FakePlayerRepository {
        FakePlayerRepositoryBuilder.trainingSkill(players: players, skillByBotId: skillByBotId)
    }
}
