import Foundation

public enum AppBootstrapResult {
    case ready(AppDependencies)
    case migrationRecovery(MigrationRecoveryContext)
}

public enum AppBootstrapper {
    public static func bootstrap() -> AppBootstrapResult {
        let logger = DefaultAppLogger.makeForCurrentBuild()
        logger.info(.appLifecycle, eventName: "app_bootstrap_start", message: "Bootstrapping app dependencies.")

        do {
            let container = try ModelContainerFactory.makeContainer(mode: .appDefault)

            let dependencies = AppDependencies(
                modelContainer: container,
                logger: logger,
                playerRepository: SwiftDataPlayerRepository(container: container),
                matchRepository: SwiftDataMatchRepository(container: container),
                statsRepository: SwiftDataStatsRepository(container: container),
                settingsRepository: SwiftDataSettingsRepository(container: container),
                hapticsService: NoopHapticsService(),
                audioFeedbackService: NoopAudioFeedbackService(),
                activeMatchStore: ActiveMatchStore()
            )
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
}
