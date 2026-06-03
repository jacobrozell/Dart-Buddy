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
                isBot: false,
                createdAt: now,
                updatedAt: now
            )
            record.avatarStyleRaw = PlayerAvatarStyle.defaultForPlayer(id: record.id, isBot: false).rawValue
            record.preferredColorToken = PlayerColorToken.defaultForPlayer(id: record.id).rawValue
            context.insert(record)
            try context.save()
            return mapPlayer(record)
        }
    }

    public func createBot(difficulty: BotDifficulty) async throws -> PlayerSummary {
        try dataCall {
            let context = ModelContext(container)
            let existing = try context.fetch(FetchDescriptor<SchemaV1.PlayerRecord>())
            let name = BotNaming.nextDefaultName(difficulty: difficulty, existingNames: existing.map(\.name))
            let now = Date()
            let record = SchemaV1.PlayerRecord(
                name: name,
                isArchived: false,
                isBot: true,
                botDifficultyRaw: difficulty.rawValue,
                createdAt: now,
                updatedAt: now
            )
            record.avatarStyleRaw = PlayerAvatarStyle.defaultForPlayer(id: record.id, isBot: true).rawValue
            record.preferredColorToken = PlayerColorToken.defaultForPlayer(id: record.id).rawValue
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

    public func updatePlayerProfile(
        playerId: UUID,
        name: String,
        avatarStyle: PlayerAvatarStyle,
        colorToken: PlayerColorToken,
        notes: String
    ) async throws -> PlayerSummary {
        try dataCall {
            let context = ModelContext(container)
            let player = try fetchPlayerRecord(id: playerId, in: context)
            let trimmed = normalizeNameForSave(name)
            try validateName(trimmed, in: context, excludingPlayerId: playerId)
            player.name = trimmed
            player.avatarStyleRaw = avatarStyle.rawValue
            player.preferredColorToken = colorToken.rawValue
            let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            player.notes = trimmedNotes.isEmpty ? nil : String(trimmedNotes.prefix(200))
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
