import Foundation
import SwiftData

public enum AppBootstrapResult {
    case ready(AppDependencies)
}

public enum AppBootstrapper {
    public static func bootstrap() async -> AppBootstrapResult {
        let logger = DefaultAppLogger.makeForCurrentBuild()
        logger.info(.appLifecycle, eventName: "app_bootstrap_start", message: "Bootstrapping app dependencies.")

        AppStoreReset.applyLaunchArgumentOverrides()

        let mode = ModelContainerFactory.storageModeForCurrentProcess()
        let container = await Task.detached(priority: .userInitiated) {
            BootstrapStoreRecovery.openContainerOrRecreate(mode: mode, logger: logger)
        }.value

        let (activeMatchStore, pendingMatchPlayerSelections, userPreferencesStore) = await MainActor.run {
            (ActiveMatchStore(), PendingMatchPlayerSelections(), UserPreferencesStore())
        }

        let settingsRepository = SwiftDataSettingsRepository(container: container)
        if let initialSettings = try? await settingsRepository.seedDefaultsIfNeeded() {
            await userPreferencesStore.apply(initialSettings)
        }

        let feedbackPreferences = userPreferencesStore.feedback
        let baseHaptics = SystemHapticsService()
        let baseAudio = BundledAudioFeedbackService()
        let baseTurnTotalCaller = SpeechTurnTotalCallerService()

        let matchRepository = SwiftDataMatchRepository(container: container)
        let statsRepository = SwiftDataStatsRepository(container: container)
        let dependencies = AppDependencies(
            modelContainer: container,
            logger: logger,
            playerRepository: SwiftDataPlayerRepository(
                container: container,
                matchRepository: matchRepository,
                statsRepository: statsRepository
            ),
            matchRepository: matchRepository,
            statsRepository: statsRepository,
            settingsRepository: settingsRepository,
            hapticsService: GatedHapticsService(underlying: baseHaptics, preferences: feedbackPreferences),
            audioFeedbackService: GatedAudioFeedbackService(underlying: baseAudio, preferences: feedbackPreferences),
            turnTotalCallerService: GatedTurnTotalCallerService(underlying: baseTurnTotalCaller, preferences: feedbackPreferences),
            userPreferencesStore: userPreferencesStore,
            activeMatchStore: activeMatchStore,
            pendingMatchPlayerSelections: pendingMatchPlayerSelections
        )
        await DemoSeeder.seedIfRequested(dependencies)
        await PrimaryPlayerBootstrap.promoteOldestHumanIfNeeded(using: dependencies.playerRepository)
        logger.info(
            .appLifecycle,
            eventName: "app_bootstrap_ready",
            message: "App bootstrap completed.",
            metadata: ClientEnvironment.snapshot.analyticsMetadata
        )
        return .ready(dependencies)
    }
}
