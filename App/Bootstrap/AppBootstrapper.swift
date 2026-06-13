import Foundation
import SwiftData

public enum AppBootstrapResult {
    case ready(AppDependencies)
    case migrationRecovery(MigrationRecoveryContext)
}

public enum AppBootstrapper {
    public static func bootstrap() async -> AppBootstrapResult {
        let logger = DefaultAppLogger.makeForCurrentBuild()
        logger.info(.appLifecycle, eventName: "app_bootstrap_start", message: "Bootstrapping app dependencies.")

        AppStoreReset.applyLaunchArgumentOverrides()

        do {
            let container = try await Task.detached(priority: .userInitiated) {
                let container = try ModelContainerFactory.makeContainer(
                    mode: ModelContainerFactory.storageModeForCurrentProcess()
                )
                try validateSchemaInvariants(in: container)
                return container
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
            let featureFlags = LocalFeatureFlagsProvider()
            let achievementService = DefaultAchievementService(
                achievementRepository: SwiftDataAchievementRepository(container: container),
                matchRepository: matchRepository,
                statsRepository: statsRepository,
                featureFlags: featureFlags
            )
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
                pendingMatchPlayerSelections: pendingMatchPlayerSelections,
                featureFlags: featureFlags
            )
            await MainActor.run {
                AchievementHooks.register(service: achievementService)
            }
            await DemoSeeder.seedIfRequested(dependencies)
            await PrimaryPlayerBootstrap.promoteOldestHumanIfNeeded(using: dependencies.playerRepository)
            logger.info(
                .appLifecycle,
                eventName: "app_bootstrap_ready",
                message: "App bootstrap completed.",
                metadata: ClientEnvironment.snapshot.analyticsMetadata
            )
            return .ready(dependencies)
        } catch {
            let appError = AppError.migrationFailure(error)
            logger.fault(
                .migration,
                eventName: "app_bootstrap_migration_failure",
                message: "Failed to bootstrap model container.",
                metadata: [
                    "errorCode": appError.code.rawValue,
                    "layer": appError.layer.rawValue
                ]
            )
            return .migrationRecovery(MigrationRecoveryContext(error: appError))
        }
    }

    private static func validateSchemaInvariants(in container: ModelContainer) throws {
        let context = ModelContext(container)
        let matches = try context.fetch(FetchDescriptor<SchemaV3.MatchRecord>())
        for match in matches {
            try validateContiguousEventIndexes(for: match.id, in: context)
        }
    }

    private static func validateContiguousEventIndexes(for matchId: UUID, in context: ModelContext) throws {
        var expectedIndex = 0
        var fetchOffset = 0
        let pageSize = 500

        while true {
            var descriptor = FetchDescriptor<SchemaV3.MatchEventRecord>(
                predicate: #Predicate<SchemaV3.MatchEventRecord> { $0.matchId == matchId },
                sortBy: [SortDescriptor(\.eventIndex, order: .forward)]
            )
            descriptor.fetchLimit = pageSize
            descriptor.fetchOffset = fetchOffset

            let page = try context.fetch(descriptor)
            if page.isEmpty {
                break
            }

            for event in page {
                guard event.eventIndex == expectedIndex else {
                    throw AppError(
                        code: .migrationFailed,
                        layer: .data,
                        severity: .fault,
                        isRecoverable: true,
                        userMessageKey: "error.migration.invariant",
                        debugContext: ["matchId": matchId.uuidString]
                    )
                }
                expectedIndex += 1
            }

            fetchOffset += page.count
        }
    }
}
