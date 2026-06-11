import Foundation
import SwiftData

public actor SwiftDataMatchRepository: MatchRepository {
    private let container: ModelContainer

    public init(container: ModelContainer) {
        self.container = container
    }

    public func createMatch(type: MatchType, configPayload: Data, participants: [MatchParticipantSummary]) async throws -> MatchSummary {
        try dataCall {
            let context = ModelContext(container)
            let inProgressRaw = MatchStatus.inProgress.rawValue
            let activeDescriptor = FetchDescriptor<SchemaV2.MatchRecord>(
                predicate: #Predicate<SchemaV2.MatchRecord> { $0.statusRaw == inProgressRaw }
            )
            if try context.fetchCount(activeDescriptor) > 0 {
                throw AppError(
                    code: .conflict,
                    layer: .data,
                    severity: .warning,
                    isRecoverable: true,
                    userMessageKey: "error.match.activeExists"
                )
            }
            let now = Date()
            let matchId = UUID()
            let record = SchemaV2.MatchRecord(
                id: matchId,
                typeRaw: type.rawValue,
                statusRaw: inProgressRaw,
                startedAt: now,
                configPayload: configPayload,
                currentTurnPlayerId: participants.sorted(by: { $0.turnOrder < $1.turnOrder }).first?.playerId,
                eventCount: 0,
                createdAt: now,
                updatedAt: now
            )
            context.insert(record)
            for participant in participants {
                context.insert(
                    SchemaV2.MatchParticipantRecord(
                        id: participant.id,
                        matchId: matchId,
                        playerId: participant.playerId,
                        turnOrder: participant.turnOrder,
                        displayNameAtMatchStart: participant.displayNameAtMatchStart,
                        avatarStyleAtMatchStart: participant.avatarStyleAtMatchStart,
                        botDifficultyRaw: participant.botDifficultyRaw,
                        botKindRaw: participant.botKindRaw,
                        botSkillProfilePayload: participant.botSkillProfilePayload,
                        botEffectiveTierRaw: participant.botEffectiveTierRaw
                    )
                )
            }
            try context.save()
            return mapMatch(record)
        }
    }

    public func fetchActiveMatch() async throws -> MatchSummary? {
        try dataCall {
            let context = ModelContext(container)
            let inProgressRaw = MatchStatus.inProgress.rawValue
            let descriptor = FetchDescriptor<SchemaV2.MatchRecord>(
                predicate: #Predicate<SchemaV2.MatchRecord> { $0.statusRaw == inProgressRaw },
                sortBy: [SortDescriptor(\.startedAt, order: .reverse)]
            )
            return try context.fetch(descriptor).first.map(mapMatch)
        }
    }

    public func fetchHistory(page: Int, pageSize: Int) async throws -> [MatchSummary] {
        try dataCall {
            let context = ModelContext(container)
            let safePage = max(0, page)
            let safeSize = max(1, pageSize)
            let completedRaw = MatchStatus.completed.rawValue
            var descriptor = FetchDescriptor<SchemaV2.MatchRecord>(
                predicate: #Predicate<SchemaV2.MatchRecord> { $0.statusRaw == completedRaw },
                sortBy: [SortDescriptor(\.endedAt, order: .reverse), SortDescriptor(\.startedAt, order: .reverse)]
            )
            descriptor.fetchOffset = safePage * safeSize
            descriptor.fetchLimit = safeSize
            return try context.fetch(descriptor).map(mapMatch)
        }
    }

    public func fetchHistoryWithParticipants(page: Int, pageSize: Int, filter: MatchHistoryFilter) async throws -> [MatchHistoryRecord] {
        try dataCall {
            let context = ModelContext(container)
            let safePage = max(0, page)
            let safeSize = max(1, pageSize)
            let completedRaw = MatchStatus.completed.rawValue

            let restrictedMatchIds: [UUID]?
            if let playerId = filter.participantPlayerId {
                let participantDescriptor = FetchDescriptor<SchemaV2.MatchParticipantRecord>(
                    predicate: #Predicate<SchemaV2.MatchParticipantRecord> { $0.playerId == playerId }
                )
                let matchIds = Array(Set(try context.fetch(participantDescriptor).map(\.matchId)))
                guard !matchIds.isEmpty else { return [] }
                restrictedMatchIds = matchIds
            } else {
                restrictedMatchIds = nil
            }

            var descriptor = FetchDescriptor<SchemaV2.MatchRecord>(
                predicate: historyMatchPredicate(
                    filter: filter,
                    completedRaw: completedRaw,
                    restrictedToMatchIds: restrictedMatchIds
                ),
                sortBy: [SortDescriptor(\.endedAt, order: .reverse), SortDescriptor(\.startedAt, order: .reverse)]
            )
            descriptor.fetchOffset = safePage * safeSize
            descriptor.fetchLimit = safeSize
            let pageMatches = try context.fetch(descriptor)
            guard !pageMatches.isEmpty else { return [] }
            let pageMatchIds = pageMatches.map(\.id)

            let participantDescriptor = FetchDescriptor<SchemaV2.MatchParticipantRecord>(
                predicate: #Predicate<SchemaV2.MatchParticipantRecord> { pageMatchIds.contains($0.matchId) },
                sortBy: [SortDescriptor(\.turnOrder, order: .forward)]
            )
            let participants = try context.fetch(participantDescriptor).map(mapParticipant)
            let participantsByMatchId = Dictionary(grouping: participants, by: \.matchId)
            return pageMatches.map {
                MatchHistoryRecord(
                    summary: mapMatch($0),
                    participants: participantsByMatchId[$0.id] ?? [],
                    historyCardPayload: $0.historyCardPayload
                )
            }
        }
    }

    public func updateMatch(_ match: MatchSummary) async throws {
        try dataCall {
            let context = ModelContext(container)
            let record = try fetchMatchRecord(id: match.id, in: context)
            let previousEventCount = record.eventCount
            record.typeRaw = match.type.rawValue
            record.statusRaw = match.status.rawValue
            record.startedAt = match.startedAt
            record.endedAt = match.endedAt
            record.winnerPlayerId = match.winnerPlayerId
            record.currentTurnPlayerId = match.currentTurnPlayerId
            record.currentLegIndex = match.currentLegIndex
            record.currentSetIndex = match.currentSetIndex
            record.eventCount = match.eventCount
            if match.status == .completed {
                record.historyCardPayload = try buildHistoryCardPayload(matchId: match.id, in: context)
            } else {
                record.historyCardPayload = nil
            }
            record.isCampaignMatch = match.isCampaignMatch ? true : nil
            record.campaignStageId = match.campaignStageId
            record.updatedAt = Date()
            if match.eventCount < previousEventCount {
                let matchId = match.id
                let eventCount = match.eventCount
                let staleEvents = try context.fetch(
                    FetchDescriptor<SchemaV2.MatchEventRecord>(
                        predicate: #Predicate<SchemaV2.MatchEventRecord> {
                            $0.matchId == matchId && $0.eventIndex >= eventCount
                        }
                    )
                )
                for event in staleEvents {
                    context.delete(event)
                }
            }
            try context.save()
        }
    }

    public func completeMatch(matchId: UUID, endedAt: Date, winnerPlayerId: UUID?) async throws -> MatchSummary {
        try dataCall {
            let context = ModelContext(container)
            let record = try fetchMatchRecord(id: matchId, in: context)
            record.statusRaw = MatchStatus.completed.rawValue
            record.endedAt = endedAt
            record.winnerPlayerId = winnerPlayerId
            record.currentTurnPlayerId = nil
            record.historyCardPayload = try buildHistoryCardPayload(matchId: matchId, in: context)
            record.updatedAt = Date()
            try context.save()
            return mapMatch(record)
        }
    }

    public func appendEvent(matchId: UUID, eventTypeRaw: String, eventPayload: Data) async throws -> MatchEventSummary {
        try dataCall {
            let context = ModelContext(container)
            let match = try fetchMatchRecord(id: matchId, in: context)
            let nextIndex = match.eventCount
            let now = Date()
            let event = SchemaV2.MatchEventRecord(
                matchId: matchId,
                eventIndex: nextIndex,
                eventTypeRaw: eventTypeRaw,
                eventPayload: eventPayload,
                createdAt: now
            )
            context.insert(event)
            match.eventCount = max(match.eventCount, nextIndex + 1)
            match.updatedAt = now
            try context.save()
            return mapEvent(event)
        }
    }

    public func saveSnapshot(matchId: UUID, snapshotVersion: Int, snapshotPayload: Data) async throws -> MatchSnapshotSummary {
        try dataCall {
            let context = ModelContext(container)
            let existing = try context.fetch(
                FetchDescriptor<SchemaV2.MatchSnapshotRecord>(
                    predicate: #Predicate<SchemaV2.MatchSnapshotRecord> { $0.matchId == matchId },
                    sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
                )
            ).first
            let now = Date()
            let record: SchemaV2.MatchSnapshotRecord
            if let existing {
                existing.snapshotVersion = snapshotVersion
                existing.snapshotPayload = snapshotPayload
                existing.updatedAt = now
                record = existing
            } else {
                let created = SchemaV2.MatchSnapshotRecord(
                    matchId: matchId,
                    snapshotVersion: snapshotVersion,
                    snapshotPayload: snapshotPayload,
                    updatedAt: now
                )
                context.insert(created)
                record = created
            }
            try context.save()
            return mapSnapshot(record)
        }
    }

    public func fetchLatestSnapshot(matchId: UUID) async throws -> MatchSnapshotSummary? {
        try dataCall {
            let context = ModelContext(container)
            let descriptor = FetchDescriptor<SchemaV2.MatchSnapshotRecord>(
                predicate: #Predicate<SchemaV2.MatchSnapshotRecord> { $0.matchId == matchId },
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            )
            return try context.fetch(descriptor).first.map(mapSnapshot)
        }
    }

    public func fetchMatch(matchId: UUID) async throws -> MatchSummary? {
        try dataCall {
            let context = ModelContext(container)
            let descriptor = FetchDescriptor<SchemaV2.MatchRecord>(
                predicate: #Predicate<SchemaV2.MatchRecord> { $0.id == matchId }
            )
            return try context.fetch(descriptor).first.map(mapMatch)
        }
    }

    public func fetchParticipants(matchId: UUID) async throws -> [MatchParticipantSummary] {
        try dataCall {
            let context = ModelContext(container)
            let descriptor = FetchDescriptor<SchemaV2.MatchParticipantRecord>(
                predicate: #Predicate<SchemaV2.MatchParticipantRecord> { $0.matchId == matchId },
                sortBy: [SortDescriptor(\.turnOrder, order: .forward)]
            )
            return try context.fetch(descriptor).map(mapParticipant)
        }
    }

    public func fetchConfigPayload(matchId: UUID) async throws -> Data? {
        try dataCall {
            let context = ModelContext(container)
            let record = try fetchMatchRecord(id: matchId, in: context)
            return record.configPayload
        }
    }

    public func deleteMatch(matchId: UUID) async throws {
        try dataCall {
            let context = ModelContext(container)
            let match = try fetchMatchRecord(id: matchId, in: context)
            let participants = try context.fetch(
                FetchDescriptor<SchemaV2.MatchParticipantRecord>(
                    predicate: #Predicate<SchemaV2.MatchParticipantRecord> { $0.matchId == matchId }
                )
            )
            let snapshots = try context.fetch(
                FetchDescriptor<SchemaV2.MatchSnapshotRecord>(
                    predicate: #Predicate<SchemaV2.MatchSnapshotRecord> { $0.matchId == matchId }
                )
            )
            let events = try context.fetch(
                FetchDescriptor<SchemaV2.MatchEventRecord>(
                    predicate: #Predicate<SchemaV2.MatchEventRecord> { $0.matchId == matchId }
                )
            )
            participants.forEach(context.delete)
            snapshots.forEach(context.delete)
            events.forEach(context.delete)
            context.delete(match)
            try context.save()
        }
    }

    private func buildHistoryCardPayload(matchId: UUID, in context: ModelContext) throws -> Data? {
        let snapshotDescriptor = FetchDescriptor<SchemaV2.MatchSnapshotRecord>(
            predicate: #Predicate<SchemaV2.MatchSnapshotRecord> { $0.matchId == matchId },
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        guard let snapshot = try context.fetch(snapshotDescriptor).first,
              let runtime = try? CodablePayloadCoder.decode(MatchRuntimeState.self, from: snapshot.snapshotPayload) else {
            return nil
        }
        let participantDescriptor = FetchDescriptor<SchemaV2.MatchParticipantRecord>(
            predicate: #Predicate<SchemaV2.MatchParticipantRecord> { $0.matchId == matchId }
        )
        let participants = try context.fetch(participantDescriptor)
        let nameById = Dictionary(
            uniqueKeysWithValues: participants.map { ($0.playerId ?? $0.id, $0.displayNameAtMatchStart) }
        )
        let payload = MatchHistoryCardBuilder.build(from: runtime, nameById: nameById)
        return try CodablePayloadCoder.encode(payload)
    }

    private func fetchMatchRecord(id: UUID, in context: ModelContext) throws -> SchemaV2.MatchRecord {
        let descriptor = FetchDescriptor<SchemaV2.MatchRecord>(
            predicate: #Predicate<SchemaV2.MatchRecord> { $0.id == id }
        )
        guard let match = try context.fetch(descriptor).first else {
            throw AppError(
                code: .notFound,
                layer: .data,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.match.notFound",
                debugContext: ["matchId": id.uuidString]
            )
        }
        return match
    }
}
