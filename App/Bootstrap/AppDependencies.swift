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
    public let activeMatchStore: ActiveMatchStore

    public init(
        modelContainer: ModelContainer,
        logger: any AppLogger,
        playerRepository: any PlayerRepository,
        matchRepository: any MatchRepository,
        statsRepository: any StatsRepository,
        settingsRepository: any SettingsRepository,
        hapticsService: any HapticsService,
        audioFeedbackService: any AudioFeedbackService,
        activeMatchStore: ActiveMatchStore
    ) {
        self.modelContainer = modelContainer
        self.logger = logger
        self.playerRepository = playerRepository
        self.matchRepository = matchRepository
        self.statsRepository = statsRepository
        self.settingsRepository = settingsRepository
        self.hapticsService = hapticsService
        self.audioFeedbackService = audioFeedbackService
        self.activeMatchStore = activeMatchStore
    }
}
