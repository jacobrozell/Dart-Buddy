import Foundation
import SwiftData

public actor SwiftDataAchievementRepository: AchievementRepository {
    private let container: ModelContainer

    public init(container: ModelContainer) {
        self.container = container
    }

    public func fetchProgress(playerId: UUID) async throws -> [PlayerAchievementProgress] {
        let map = try await fetchProgress(playerIds: [playerId])
        return Array(map[playerId]?.values ?? [:].values)
    }

    public func fetchProgress(playerIds: [UUID]) async throws -> [UUID: [String: PlayerAchievementProgress]] {
        guard !playerIds.isEmpty else { return [:] }
        return try dataCall {
            let context = ModelContext(container)
            let descriptor = FetchDescriptor<SchemaV4.PlayerAchievementRecord>(
                predicate: #Predicate<SchemaV4.PlayerAchievementRecord> { playerIds.contains($0.playerId) }
            )
            let records = try context.fetch(descriptor)
            var result: [UUID: [String: PlayerAchievementProgress]] = [:]
            for record in records {
                let progress = PlayerAchievementProgress(
                    achievementId: record.achievementId,
                    unlockedAt: record.unlockedAt,
                    progressPercent: record.progressPercent,
                    sourceMatchId: record.sourceMatchId
                )
                result[record.playerId, default: [:]][record.achievementId] = progress
            }
            return result
        }
    }

    public func apply(deltas: [AchievementDelta], matchId: UUID) async throws -> [AchievementUnlockPresentation] {
        guard !deltas.isEmpty else { return [] }
        return try dataCall {
            let context = ModelContext(container)
            var presentations: [AchievementUnlockPresentation] = []

            for delta in deltas {
                switch delta.kind {
                case .revoke:
                    let playerId = delta.playerId
                    let achievementId = delta.achievementId
                    let descriptor = FetchDescriptor<SchemaV4.PlayerAchievementRecord>(
                        predicate: #Predicate<SchemaV4.PlayerAchievementRecord> {
                            $0.playerId == playerId && $0.achievementId == achievementId
                        }
                    )
                    for record in try context.fetch(descriptor) {
                        context.delete(record)
                    }
                case .unlock, .progressUpdate:
                    let record = try fetchOrCreateRecord(
                        playerId: delta.playerId,
                        achievementId: delta.achievementId,
                        in: context
                    )
                    let wasUnlocked = record.unlockedAt != nil
                    if delta.kind == .unlock {
                        record.unlockedAt = delta.unlockedAt ?? Date()
                        record.progressPercent = delta.progressPercent ?? 100
                        record.sourceMatchId = matchId
                        if !wasUnlocked {
                            presentations.append(
                                AchievementUnlockPresentation(
                                    playerId: delta.playerId,
                                    achievementId: delta.achievementId,
                                    progressPercent: record.progressPercent,
                                    isNewUnlock: true
                                )
                            )
                        }
                    } else if let percent = delta.progressPercent, percent > record.progressPercent {
                        record.progressPercent = percent
                        record.sourceMatchId = matchId
                        if AchievementCatalog.definition(for: delta.achievementId)?.isIncremental == true,
                           percent >= 100,
                           record.unlockedAt == nil {
                            record.unlockedAt = Date()
                            presentations.append(
                                AchievementUnlockPresentation(
                                    playerId: delta.playerId,
                                    achievementId: delta.achievementId,
                                    progressPercent: percent,
                                    isNewUnlock: true
                                )
                            )
                        } else if shouldPresentProgressMilestone(achievementId: delta.achievementId, percent: percent) {
                            presentations.append(
                                AchievementUnlockPresentation(
                                    playerId: delta.playerId,
                                    achievementId: delta.achievementId,
                                    progressPercent: percent,
                                    isNewUnlock: false
                                )
                            )
                        }
                    }
                    record.updatedAt = Date()
                }
            }

            try context.save()
            return presentations
        }
    }

    public func deleteAllProgress() async throws {
        try dataCall {
            let context = ModelContext(container)
            try SwiftDataStoreReset.deleteAll(SchemaV4.PlayerAchievementRecord.self, in: context)
            try context.save()
        }
    }

    private func fetchOrCreateRecord(
        playerId: UUID,
        achievementId: String,
        in context: ModelContext
    ) throws -> SchemaV4.PlayerAchievementRecord {
        let descriptor = FetchDescriptor<SchemaV4.PlayerAchievementRecord>(
            predicate: #Predicate<SchemaV4.PlayerAchievementRecord> {
                $0.playerId == playerId && $0.achievementId == achievementId
            }
        )
        if let existing = try context.fetch(descriptor).first {
            return existing
        }
        let created = SchemaV4.PlayerAchievementRecord(playerId: playerId, achievementId: achievementId)
        context.insert(created)
        return created
    }

    private func shouldPresentProgressMilestone(achievementId: String, percent: Int) -> Bool {
        guard let threshold = AchievementCatalog.definition(for: achievementId)?.threshold else { return false }
        let milestonePercents = Set([10, 50, 100, 250, 500, 20, 30, 100].compactMap { value -> Int? in
            guard threshold > 0 else { return nil }
            return min(100, (value * 100) / threshold)
        })
        return milestonePercents.contains(percent) && percent < 100
    }
}
