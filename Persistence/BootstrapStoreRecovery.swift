import Foundation
import SwiftData

/// Opens the SwiftData store at launch, repairing local inconsistencies or recreating
/// the on-disk store when migration/open fails. Callers should never surface a blocking
/// recovery screen — log faults and continue with a usable container.
enum BootstrapStoreRecovery {
    /// Returns a usable container, recreating the store when open or repair fails.
    static func openContainerOrRecreate(
        mode: ModelContainerFactory.StorageMode,
        logger: any AppLogger
    ) -> ModelContainer {
        do {
            return try openRecoveredContainer(mode: mode, logger: logger)
        } catch {
            logger.fault(
                .migration,
                eventName: "bootstrap_store_recovery_retry",
                message: "Store recovery failed; forcing recreation.",
                metadata: storageMetadata(mode: mode).merging(["underlyingError": String(describing: error)]) { current, _ in current }
            )
        }

        do {
            return try openRecoveredContainer(mode: mode, logger: logger, forceRecreate: true)
        } catch {
            logger.fault(
                .migration,
                eventName: "bootstrap_store_recovery_exhausted",
                message: "Forced store recreation failed; attempting bare container open.",
                metadata: storageMetadata(mode: mode).merging(["underlyingError": String(describing: error)]) { current, _ in current }
            )
        }

        if case .appDefault = mode {
            AppStoreReset.deleteSQLiteStore()
        }
        return (try? ModelContainerFactory.makeContainer(mode: mode))
            ?? ModelContainerFactory.makeInMemoryFallbackContainer()
    }

    static func openRecoveredContainer(
        mode: ModelContainerFactory.StorageMode,
        logger: any AppLogger,
        forceRecreate: Bool = false
    ) throws -> ModelContainer {
        if forceRecreate {
            backupAndDeleteStoreIfNeeded(mode: mode, logger: logger, reason: "forced_recreate")
            let container = try ModelContainerFactory.makeContainer(mode: mode)
            logger.info(
                .migration,
                eventName: "bootstrap_store_recreated",
                message: "Recreated local store after forced recovery.",
                metadata: storageMetadata(mode: mode)
            )
            return container
        }

        do {
            let container = try ModelContainerFactory.makeContainer(mode: mode)
            do {
                let repairedMatches = try repairAllMatchEventIndexes(in: container)
                if repairedMatches > 0 {
                    logger.warning(
                        .migration,
                        eventName: "bootstrap_invariants_repaired",
                        message: "Repaired non-contiguous match event indexes during bootstrap.",
                        metadata: storageMetadata(mode: mode).merging(["repairedMatchCount": String(repairedMatches)]) { current, _ in current }
                    )
                }
            } catch {
                logger.fault(
                    .migration,
                    eventName: "bootstrap_invariant_repair_failed",
                    message: "Invariant repair failed; recreating local store.",
                    metadata: storageMetadata(mode: mode).merging(["underlyingError": String(describing: error)]) { current, _ in current }
                )
                backupAndDeleteStoreIfNeeded(mode: mode, logger: logger, reason: "repair_failed")
                return try ModelContainerFactory.makeContainer(mode: mode)
            }
            return container
        } catch {
            logger.fault(
                .migration,
                eventName: "bootstrap_store_open_failed",
                message: "Failed to open local store; recreating from backup.",
                metadata: storageMetadata(mode: mode).merging(openFailureMetadata(error)) { current, _ in current }
            )
            backupAndDeleteStoreIfNeeded(mode: mode, logger: logger, reason: "open_failed")
            let container = try ModelContainerFactory.makeContainer(mode: mode)
            logger.fault(
                .migration,
                eventName: "bootstrap_store_recreated",
                message: "Recreated local store after open failure.",
                metadata: storageMetadata(mode: mode)
            )
            return container
        }
    }

    static func backupAndDeleteStoreIfNeeded(
        mode: ModelContainerFactory.StorageMode,
        logger: any AppLogger,
        reason: String
    ) {
        switch mode {
        case .appDefault:
            if let backupPath = AppStoreReset.backupSQLiteStore() {
                logger.fault(
                    .migration,
                    eventName: "bootstrap_store_backed_up",
                    message: "Backed up local store before recreation.",
                    metadata: ["reason": reason, "backupPath": backupPath]
                )
            }
            AppStoreReset.deleteSQLiteStore()
        case let .customURL(url):
            AppStoreReset.deleteSQLiteStore(at: url)
        case .inMemory:
            break
        }
    }

    static func repairAllMatchEventIndexes(in container: ModelContainer) throws -> Int {
        let context = ModelContext(container)
        let matches = try context.fetch(FetchDescriptor<SchemaV1.MatchRecord>())
        var repairedMatchCount = 0

        for match in matches {
            var matchRepaired = false
            if try repairEventIndexes(for: match.id, in: context) {
                matchRepaired = true
            }

            let eventCount = try eventCount(for: match.id, in: context)
            if match.eventCount != eventCount {
                match.eventCount = eventCount
                matchRepaired = true
            }

            if matchRepaired {
                repairedMatchCount += 1
            }
        }

        if repairedMatchCount > 0 {
            try context.save()
        }
        return repairedMatchCount
    }

    private static func repairEventIndexes(for matchId: UUID, in context: ModelContext) throws -> Bool {
        let descriptor = FetchDescriptor<SchemaV1.MatchEventRecord>(
            predicate: #Predicate<SchemaV1.MatchEventRecord> { $0.matchId == matchId },
            sortBy: [
                SortDescriptor(\.eventIndex, order: .forward),
                SortDescriptor(\.createdAt, order: .forward)
            ]
        )
        let events = try context.fetch(descriptor)
        guard !events.isEmpty else { return false }

        var repaired = false
        for (expectedIndex, event) in events.enumerated() where event.eventIndex != expectedIndex {
            event.eventIndex = expectedIndex
            repaired = true
        }
        return repaired
    }

    private static func eventCount(for matchId: UUID, in context: ModelContext) throws -> Int {
        let descriptor = FetchDescriptor<SchemaV1.MatchEventRecord>(
            predicate: #Predicate<SchemaV1.MatchEventRecord> { $0.matchId == matchId }
        )
        return try context.fetchCount(descriptor)
    }

    private static func storageMetadata(mode: ModelContainerFactory.StorageMode) -> [String: String] {
        switch mode {
        case .appDefault:
            return ["storageMode": "appDefault"]
        case .inMemory:
            return ["storageMode": "inMemory"]
        case let .customURL(url):
            return ["storageMode": "customURL", "storePath": url.path]
        }
    }

    private static func openFailureMetadata(_ error: Error) -> [String: String] {
        var metadata = ["underlyingError": String(describing: error)]
        let nsError = error as NSError
        metadata["errorDomain"] = nsError.domain
        metadata["errorCode"] = String(nsError.code)
        if nsError.code == 1_345_04 {
            metadata["failureKind"] = "unknownModelVersion"
        }
        return metadata
    }
}
