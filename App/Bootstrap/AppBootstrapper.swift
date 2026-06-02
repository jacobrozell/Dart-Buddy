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

        do {
            let container = try await Task.detached(priority: .userInitiated) {
                let container = try ModelContainerFactory.makeContainer(mode: .appDefault)
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

            let dependencies = AppDependencies(
                modelContainer: container,
                logger: logger,
                playerRepository: SwiftDataPlayerRepository(container: container),
                matchRepository: SwiftDataMatchRepository(container: container),
                statsRepository: SwiftDataStatsRepository(container: container),
                settingsRepository: settingsRepository,
                hapticsService: GatedHapticsService(underlying: baseHaptics, preferences: feedbackPreferences),
                audioFeedbackService: GatedAudioFeedbackService(underlying: baseAudio, preferences: feedbackPreferences),
                userPreferencesStore: userPreferencesStore,
                activeMatchStore: activeMatchStore,
                pendingMatchPlayerSelections: pendingMatchPlayerSelections
            )
            await DemoSeeder.seedIfRequested(dependencies)
            logger.info(.appLifecycle, eventName: "app_bootstrap_ready", message: "App bootstrap completed.")
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
        let matches = try context.fetch(FetchDescriptor<SchemaV1.MatchRecord>())
        for match in matches {
            try validateContiguousEventIndexes(for: match.id, in: context)
        }
    }

    private static func validateContiguousEventIndexes(for matchId: UUID, in context: ModelContext) throws {
        var expectedIndex = 0
        var fetchOffset = 0
        let pageSize = 500

        while true {
            var descriptor = FetchDescriptor<SchemaV1.MatchEventRecord>(
                predicate: #Predicate<SchemaV1.MatchEventRecord> { $0.matchId == matchId },
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
