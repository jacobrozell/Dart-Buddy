import Foundation
import SwiftData

public struct AppDependencies {
    public let modelContainer: ModelContainer
    public let logger: any AppLogger
    public let playerRepository: any PlayerRepository
    public let matchRepository: any MatchRepository
    public let statsRepository: any StatsRepository
    public let settingsRepository: any SettingsRepository
    public let hapticsService: any HapticsService
    public let audioFeedbackService: any AudioFeedbackService
    public let turnTotalCallerService: any TurnTotalCallerService
    public let userPreferencesStore: UserPreferencesStore
    public let activeMatchStore: ActiveMatchStore
    public let pendingMatchPlayerSelections: PendingMatchPlayerSelections

    public init(
        modelContainer: ModelContainer,
        logger: any AppLogger,
        playerRepository: any PlayerRepository,
        matchRepository: any MatchRepository,
        statsRepository: any StatsRepository,
        settingsRepository: any SettingsRepository,
        hapticsService: any HapticsService,
        audioFeedbackService: any AudioFeedbackService,
        turnTotalCallerService: any TurnTotalCallerService,
        userPreferencesStore: UserPreferencesStore,
        activeMatchStore: ActiveMatchStore,
        pendingMatchPlayerSelections: PendingMatchPlayerSelections
    ) {
        self.modelContainer = modelContainer
        self.logger = logger
        self.playerRepository = playerRepository
        self.matchRepository = matchRepository
        self.statsRepository = statsRepository
        self.settingsRepository = settingsRepository
        self.hapticsService = hapticsService
        self.audioFeedbackService = audioFeedbackService
        self.turnTotalCallerService = turnTotalCallerService
        self.userPreferencesStore = userPreferencesStore
        self.activeMatchStore = activeMatchStore
        self.pendingMatchPlayerSelections = pendingMatchPlayerSelections
    }
}
