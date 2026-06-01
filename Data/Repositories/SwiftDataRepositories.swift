import Foundation
import SwiftData

public actor SwiftDataPlayerRepository: PlayerRepository {
    private let container: ModelContainer

    public init(container: ModelContainer) {
        self.container = container
    }

    public func fetchPlayers(includeArchived: Bool) async throws -> [PlayerSummary] {
        try dataCall {
            let context = ModelContext(container)
            var descriptor = FetchDescriptor<SchemaV1.PlayerRecord>(
                sortBy: [SortDescriptor(\.name, order: .forward)]
            )
            if !includeArchived {
                descriptor.predicate = #Predicate<SchemaV1.PlayerRecord> { !$0.isArchived }
            }
            return try context.fetch(descriptor).map(mapPlayer)
        }
    }

    public func createPlayer(name: String) async throws -> PlayerSummary {
        try dataCall {
            let context = ModelContext(container)
            let trimmed = normalizeNameForSave(name)
            try validateName(trimmed, in: context, excludingPlayerId: nil)
            let now = Date()
            let record = SchemaV1.PlayerRecord(
                name: trimmed,
                isArchived: false,
                createdAt: now,
                updatedAt: now
            )
            context.insert(record)
            try context.save()
            return mapPlayer(record)
        }
    }

    public func updatePlayerName(playerId: UUID, name: String) async throws -> PlayerSummary {
        try dataCall {
            let context = ModelContext(container)
            let player = try fetchPlayerRecord(id: playerId, in: context)
            let trimmed = normalizeNameForSave(name)
            try validateName(trimmed, in: context, excludingPlayerId: playerId)
            player.name = trimmed
            player.updatedAt = Date()
            try context.save()
            return mapPlayer(player)
        }
    }

    public func archivePlayer(playerId: UUID) async throws {
        try dataCall {
            let context = ModelContext(container)
            let player = try fetchPlayerRecord(id: playerId, in: context)
            player.isArchived = true
            player.updatedAt = Date()
            try context.save()
        }
    }

    public func unarchivePlayer(playerId: UUID) async throws {
        try dataCall {
            let context = ModelContext(container)
            let player = try fetchPlayerRecord(id: playerId, in: context)
            player.isArchived = false
            player.updatedAt = Date()
            try context.save()
        }
    }

    public func deletePlayer(playerId: UUID) async throws {
        try dataCall {
            let context = ModelContext(container)
            let player = try fetchPlayerRecord(id: playerId, in: context)
            let refs = try context.fetch(
                FetchDescriptor<SchemaV1.MatchParticipantRecord>(
                    predicate: #Predicate<SchemaV1.MatchParticipantRecord> { $0.playerId == playerId }
                )
            )
            guard refs.isEmpty else {
                throw AppError(
                    code: .conflict,
                    layer: .data,
                    severity: .warning,
                    isRecoverable: true,
                    userMessageKey: "players.delete.blocked.message",
                    debugContext: ["playerId": playerId.uuidString]
                )
            }
            context.delete(player)
            try context.save()
        }
    }

    private func fetchPlayerRecord(id: UUID, in context: ModelContext) throws -> SchemaV1.PlayerRecord {
        let descriptor = FetchDescriptor<SchemaV1.PlayerRecord>(
            predicate: #Predicate<SchemaV1.PlayerRecord> { $0.id == id }
        )
        guard let player = try context.fetch(descriptor).first else {
            throw AppError(
                code: .notFound,
                layer: .data,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "error.player.notFound",
                debugContext: ["playerId": id.uuidString]
            )
        }
        return player
    }

    private func validateName(_ name: String, in context: ModelContext, excludingPlayerId: UUID?) throws {
        guard !name.isEmpty, name.count <= 32 else {
            throw AppError(
                code: .validationFailed,
                layer: .data,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "player.validation.nameRequired"
            )
        }
        let players = try context.fetch(FetchDescriptor<SchemaV1.PlayerRecord>())
        let normalized = normalizeForComparison(name)
        let duplicate = players.contains {
            if let excludingPlayerId, $0.id == excludingPlayerId {
                return false
            }
            return normalizeForComparison($0.name) == normalized
        }
        if duplicate {
            throw AppError(
                code: .conflict,
                layer: .data,
                severity: .warning,
                isRecoverable: true,
                userMessageKey: "player.validation.duplicateName"
            )
        }
    }

    private func normalizeNameForSave(_ value: String) -> String {
        value
            .split(whereSeparator: \.isWhitespace)
            .joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func normalizeForComparison(_ value: String) -> String {
        normalizeNameForSave(value).lowercased()
    }
}

public actor SwiftDataMatchRepository: MatchRepository {
    private let container: ModelContainer

    public init(container: ModelContainer) {
        self.container = container
    }

    public func createMatch(type: MatchType, configPayload: Data, participants: [MatchParticipantSummary]) async throws -> MatchSummary {
        try dataCall {
            let context = ModelContext(container)
            let inProgressRaw = MatchStatus.inProgress.rawValue
            let activeDescriptor = FetchDescriptor<SchemaV1.MatchRecord>(
                predicate: #Predicate<SchemaV1.MatchRecord> { $0.statusRaw == inProgressRaw }
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
            let record = SchemaV1.MatchRecord(
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
                    SchemaV1.MatchParticipantRecord(
                        id: participant.id,
                        matchId: matchId,
                        playerId: participant.playerId,
                        turnOrder: participant.turnOrder,
                        displayNameAtMatchStart: participant.displayNameAtMatchStart,
                        avatarStyleAtMatchStart: participant.avatarStyleAtMatchStart
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
            let descriptor = FetchDescriptor<SchemaV1.MatchRecord>(
                predicate: #Predicate<SchemaV1.MatchRecord> { $0.statusRaw == inProgressRaw },
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
            var descriptor = FetchDescriptor<SchemaV1.MatchRecord>(
                predicate: #Predicate<SchemaV1.MatchRecord> { $0.statusRaw == completedRaw },
                sortBy: [SortDescriptor(\.endedAt, order: .reverse), SortDescriptor(\.startedAt, order: .reverse)]
            )
            descriptor.fetchOffset = safePage * safeSize
            descriptor.fetchLimit = safeSize
            return try context.fetch(descriptor).map(mapMatch)
        }
    }

    public func fetchHistoryWithParticipants(page: Int, pageSize: Int) async throws -> [MatchHistoryRecord] {
        try dataCall {
            let context = ModelContext(container)
            let safePage = max(0, page)
            let safeSize = max(1, pageSize)
            let completedRaw = MatchStatus.completed.rawValue
            var descriptor = FetchDescriptor<SchemaV1.MatchRecord>(
                predicate: #Predicate<SchemaV1.MatchRecord> { $0.statusRaw == completedRaw },
                sortBy: [SortDescriptor(\.endedAt, order: .reverse), SortDescriptor(\.startedAt, order: .reverse)]
            )
            descriptor.fetchOffset = safePage * safeSize
            descriptor.fetchLimit = safeSize
            let pageMatches = try context.fetch(descriptor)
            guard !pageMatches.isEmpty else { return [] }
            let pageMatchIds = pageMatches.map(\.id)

            let participantDescriptor = FetchDescriptor<SchemaV1.MatchParticipantRecord>(
                predicate: #Predicate<SchemaV1.MatchParticipantRecord> { pageMatchIds.contains($0.matchId) },
                sortBy: [SortDescriptor(\.turnOrder, order: .forward)]
            )
            let participants = try context.fetch(participantDescriptor).map(mapParticipant)
            let participantsByMatchId = Dictionary(grouping: participants, by: \.matchId)
            return pageMatches.map {
                MatchHistoryRecord(
                    summary: mapMatch($0),
                    participants: participantsByMatchId[$0.id] ?? []
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
            record.updatedAt = Date()
            if match.eventCount < previousEventCount {
                let matchId = match.id
                let eventCount = match.eventCount
                let staleEvents = try context.fetch(
                    FetchDescriptor<SchemaV1.MatchEventRecord>(
                        predicate: #Predicate<SchemaV1.MatchEventRecord> {
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
            record.updatedAt = Date()
            try context.save()
            return mapMatch(record)
        }
    }

    public func appendEvent(matchId: UUID, eventTypeRaw: String, eventPayload: Data) async throws -> MatchEventSummary {
        try dataCall {
            let context = ModelContext(container)
            let match = try fetchMatchRecord(id: matchId, in: context)
            let existing = try context.fetch(
                FetchDescriptor<SchemaV1.MatchEventRecord>(
                    predicate: #Predicate<SchemaV1.MatchEventRecord> { $0.matchId == matchId },
                    sortBy: [SortDescriptor(\.eventIndex, order: .reverse)]
                )
            )
            let nextIndex = (existing.first?.eventIndex ?? -1) + 1
            let now = Date()
            let event = SchemaV1.MatchEventRecord(
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
                FetchDescriptor<SchemaV1.MatchSnapshotRecord>(
                    predicate: #Predicate<SchemaV1.MatchSnapshotRecord> { $0.matchId == matchId },
                    sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
                )
            ).first
            let now = Date()
            let record: SchemaV1.MatchSnapshotRecord
            if let existing {
                existing.snapshotVersion = snapshotVersion
                existing.snapshotPayload = snapshotPayload
                existing.updatedAt = now
                record = existing
            } else {
                let created = SchemaV1.MatchSnapshotRecord(
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
            let descriptor = FetchDescriptor<SchemaV1.MatchSnapshotRecord>(
                predicate: #Predicate<SchemaV1.MatchSnapshotRecord> { $0.matchId == matchId },
                sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
            )
            return try context.fetch(descriptor).first.map(mapSnapshot)
        }
    }

    public func fetchMatch(matchId: UUID) async throws -> MatchSummary? {
        try dataCall {
            let context = ModelContext(container)
            let descriptor = FetchDescriptor<SchemaV1.MatchRecord>(
                predicate: #Predicate<SchemaV1.MatchRecord> { $0.id == matchId }
            )
            return try context.fetch(descriptor).first.map(mapMatch)
        }
    }

    public func fetchParticipants(matchId: UUID) async throws -> [MatchParticipantSummary] {
        try dataCall {
            let context = ModelContext(container)
            let descriptor = FetchDescriptor<SchemaV1.MatchParticipantRecord>(
                predicate: #Predicate<SchemaV1.MatchParticipantRecord> { $0.matchId == matchId },
                sortBy: [SortDescriptor(\.turnOrder, order: .forward)]
            )
            return try context.fetch(descriptor).map(mapParticipant)
        }
    }

    public func deleteMatch(matchId: UUID) async throws {
        try dataCall {
            let context = ModelContext(container)
            let match = try fetchMatchRecord(id: matchId, in: context)
            let participants = try context.fetch(
                FetchDescriptor<SchemaV1.MatchParticipantRecord>(
                    predicate: #Predicate<SchemaV1.MatchParticipantRecord> { $0.matchId == matchId }
                )
            )
            let snapshots = try context.fetch(
                FetchDescriptor<SchemaV1.MatchSnapshotRecord>(
                    predicate: #Predicate<SchemaV1.MatchSnapshotRecord> { $0.matchId == matchId }
                )
            )
            let events = try context.fetch(
                FetchDescriptor<SchemaV1.MatchEventRecord>(
                    predicate: #Predicate<SchemaV1.MatchEventRecord> { $0.matchId == matchId }
                )
            )
            participants.forEach(context.delete)
            snapshots.forEach(context.delete)
            events.forEach(context.delete)
            context.delete(match)
            try context.save()
        }
    }

    private func fetchMatchRecord(id: UUID, in context: ModelContext) throws -> SchemaV1.MatchRecord {
        let descriptor = FetchDescriptor<SchemaV1.MatchRecord>(
            predicate: #Predicate<SchemaV1.MatchRecord> { $0.id == id }
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

public actor SwiftDataStatsRepository: StatsRepository {
    private let container: ModelContainer

    public init(container: ModelContainer) {
        self.container = container
    }

    public func fetchEvents(matchId: UUID) async throws -> [MatchEventSummary] {
        try dataCall {
            let context = ModelContext(container)
            let descriptor = FetchDescriptor<SchemaV1.MatchEventRecord>(
                predicate: #Predicate<SchemaV1.MatchEventRecord> { $0.matchId == matchId },
                sortBy: [SortDescriptor(\.eventIndex, order: .forward)]
            )
            return try context.fetch(descriptor).map(mapEvent)
        }
    }
}

public actor SwiftDataSettingsRepository: SettingsRepository {
    private let container: ModelContainer

    public init(container: ModelContainer) {
        self.container = container
    }

    public func fetchSettings() async throws -> SettingsSummary {
        try dataCall {
            let context = ModelContext(container)
            if let record = try context.fetch(FetchDescriptor<SchemaV1.SettingsRecord>()).first {
                return mapSettings(record)
            }
            let created = SchemaV1.SettingsRecord()
            context.insert(created)
            try context.save()
            return mapSettings(created)
        }
    }

    public func seedDefaultsIfNeeded() async throws -> SettingsSummary {
        try await fetchSettings()
    }

    public func updateSettings(_ settings: SettingsSummary) async throws -> SettingsSummary {
        try dataCall {
            let context = ModelContext(container)
            let settingsId = settings.id
            let descriptor = FetchDescriptor<SchemaV1.SettingsRecord>(
                predicate: #Predicate<SchemaV1.SettingsRecord> { $0.id == settingsId }
            )
            let record: SchemaV1.SettingsRecord
            if let existing = try context.fetch(descriptor).first {
                record = existing
            } else {
                let created = SchemaV1.SettingsRecord(id: settings.id)
                context.insert(created)
                record = created
            }
            if record.modelContext == nil {
                context.insert(record)
            }
            record.appearanceModeRaw = settings.appearanceModeRaw
            record.hapticsEnabled = settings.hapticsEnabled
            record.soundEnabled = settings.soundEnabled
            record.defaultMatchTypeRaw = settings.defaultMatchTypeRaw
            record.defaultX01StartScore = settings.defaultX01StartScore
            record.defaultCheckoutModeRaw = settings.defaultCheckoutModeRaw
            record.defaultLegsToWin = settings.defaultLegsToWin
            record.defaultSetsEnabled = settings.defaultSetsEnabled
            record.updatedAt = settings.updatedAt
            try context.save()
            return mapSettings(record)
        }
    }

    public func resetPreferencesToDefaults() async throws {
        try dataCall {
            let context = ModelContext(container)
            let record: SchemaV1.SettingsRecord
            if let existing = try context.fetch(FetchDescriptor<SchemaV1.SettingsRecord>()).first {
                record = existing
            } else {
                let created = SchemaV1.SettingsRecord()
                context.insert(created)
                record = created
            }
            record.appearanceModeRaw = "system"
            record.hapticsEnabled = true
            record.soundEnabled = true
            record.defaultMatchTypeRaw = "x01"
            record.defaultX01StartScore = 501
            record.defaultCheckoutModeRaw = "doubleOut"
            record.defaultLegsToWin = 3
            record.defaultSetsEnabled = false
            record.updatedAt = Date()
            try context.save()
        }
    }

    public func resetAllLocalData() async throws {
        try dataCall {
            let context = ModelContext(container)
            for player in try context.fetch(FetchDescriptor<SchemaV1.PlayerRecord>()) {
                context.delete(player)
            }
            for match in try context.fetch(FetchDescriptor<SchemaV1.MatchRecord>()) {
                context.delete(match)
            }
            for participant in try context.fetch(FetchDescriptor<SchemaV1.MatchParticipantRecord>()) {
                context.delete(participant)
            }
            for snapshot in try context.fetch(FetchDescriptor<SchemaV1.MatchSnapshotRecord>()) {
                context.delete(snapshot)
            }
            for event in try context.fetch(FetchDescriptor<SchemaV1.MatchEventRecord>()) {
                context.delete(event)
            }
            for setting in try context.fetch(FetchDescriptor<SchemaV1.SettingsRecord>()) {
                context.delete(setting)
            }
            context.insert(SchemaV1.SettingsRecord())
            try context.save()
        }
    }
}

private func mapPlayer(_ record: SchemaV1.PlayerRecord) -> PlayerSummary {
    PlayerSummary(
        id: record.id,
        name: record.name,
        isArchived: record.isArchived,
        createdAt: record.createdAt,
        updatedAt: record.updatedAt
    )
}

private func mapMatch(_ record: SchemaV1.MatchRecord) -> MatchSummary {
    MatchSummary(
        id: record.id,
        type: MatchType(rawValue: record.typeRaw) ?? .x01,
        status: MatchStatus(rawValue: record.statusRaw) ?? .notStarted,
        startedAt: record.startedAt,
        endedAt: record.endedAt,
        winnerPlayerId: record.winnerPlayerId,
        currentTurnPlayerId: record.currentTurnPlayerId,
        currentLegIndex: record.currentLegIndex,
        currentSetIndex: record.currentSetIndex,
        eventCount: record.eventCount,
        createdAt: record.createdAt,
        updatedAt: record.updatedAt
    )
}

private func mapEvent(_ record: SchemaV1.MatchEventRecord) -> MatchEventSummary {
    MatchEventSummary(
        id: record.id,
        matchId: record.matchId,
        eventIndex: record.eventIndex,
        eventTypeRaw: record.eventTypeRaw,
        eventPayload: record.eventPayload,
        createdAt: record.createdAt
    )
}

private func mapSnapshot(_ record: SchemaV1.MatchSnapshotRecord) -> MatchSnapshotSummary {
    MatchSnapshotSummary(
        id: record.id,
        matchId: record.matchId,
        snapshotVersion: record.snapshotVersion,
        snapshotPayload: record.snapshotPayload,
        updatedAt: record.updatedAt
    )
}

private func mapSettings(_ record: SchemaV1.SettingsRecord) -> SettingsSummary {
    SettingsSummary(
        id: record.id,
        appearanceModeRaw: record.appearanceModeRaw,
        hapticsEnabled: record.hapticsEnabled,
        soundEnabled: record.soundEnabled,
        defaultMatchTypeRaw: record.defaultMatchTypeRaw,
        defaultX01StartScore: record.defaultX01StartScore,
        defaultCheckoutModeRaw: record.defaultCheckoutModeRaw,
        defaultLegsToWin: record.defaultLegsToWin,
        defaultSetsEnabled: record.defaultSetsEnabled,
        updatedAt: record.updatedAt
    )
}

private func mapParticipant(_ record: SchemaV1.MatchParticipantRecord) -> MatchParticipantSummary {
    MatchParticipantSummary(
        id: record.id,
        matchId: record.matchId,
        playerId: record.playerId,
        turnOrder: record.turnOrder,
        displayNameAtMatchStart: record.displayNameAtMatchStart,
        avatarStyleAtMatchStart: record.avatarStyleAtMatchStart
    )
}

private func dataCall<T>(_ block: () throws -> T) throws -> T {
    do {
        return try block()
    } catch let error as AppError {
        throw error
    } catch {
        throw AppError(
            code: .storageUnavailable,
            layer: .data,
            severity: .error,
            isRecoverable: true,
            userMessageKey: "error.repository.storage",
            underlyingError: error
        )
    }
}
