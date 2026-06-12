import Foundation
import SwiftData

public actor SwiftDataPlayerRepository: PlayerRepository {
    private let container: ModelContainer
    private let matchRepository: any MatchRepository
    private let statsRepository: any StatsRepository

    public init(
        container: ModelContainer,
        matchRepository: any MatchRepository,
        statsRepository: any StatsRepository
    ) {
        self.container = container
        self.matchRepository = matchRepository
        self.statsRepository = statsRepository
    }

    public func fetchPlayers(includeArchived: Bool) async throws -> [PlayerSummary] {
        try dataCall {
            let context = ModelContext(container)
            var descriptor = FetchDescriptor<SchemaV3.PlayerRecord>(
                sortBy: [SortDescriptor(\.name, order: .forward)]
            )
            if !includeArchived {
                descriptor.predicate = #Predicate<SchemaV3.PlayerRecord> { !$0.isArchived }
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
            let record = SchemaV3.PlayerRecord(
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
            let existing = try context.fetch(FetchDescriptor<SchemaV3.PlayerRecord>())
            let name = BotNaming.nextDefaultName(difficulty: difficulty, existingNames: existing.map(\.name))
            let now = Date()
            let record = SchemaV3.PlayerRecord(
                name: name,
                isArchived: false,
                isBot: true,
                botDifficultyRaw: difficulty.rawValue,
                botKindRaw: BotKind.preset.rawValue,
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

    public func createCustomBot(name: String, metrics: CustomBotMetrics) async throws -> PlayerSummary {
        try await createCustomBot(name: name, configuration: .from(metrics: metrics))
    }

    public func createCustomBot(name: String, configuration: CustomBotConfiguration) async throws -> PlayerSummary {
        try dataCall {
            let context = ModelContext(container)
            let existing = try context.fetch(FetchDescriptor<SchemaV3.PlayerRecord>())
            let trimmed = normalizeNameForSave(name)
            let resolvedName = trimmed.isEmpty
                ? BotNaming.nextCustomBotName(existingNames: existing.map(\.name))
                : trimmed
            try validateName(resolvedName, in: context, excludingPlayerId: nil)
            let now = Date()
            let record = SchemaV3.PlayerRecord(
                name: resolvedName,
                isArchived: false,
                isBot: true,
                botDifficultyRaw: CustomBotConfigurationCodec.encode(configuration),
                botKindRaw: BotKind.custom.rawValue,
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

    public func updateCustomBotMetrics(playerId: UUID, metrics: CustomBotMetrics) async throws -> PlayerSummary {
        let existing = try await fetchPlayers(includeArchived: true)
        guard let player = existing.first(where: { $0.id == playerId }) else {
            throw customBotError("customBot.error.notCustomBot")
        }
        var configuration = decodeCustomBotConfiguration(player: player) ?? .from(metrics: metrics)
        configuration.x01Average = metrics.x01Average
        configuration.cricketMPR = metrics.cricketMPR
        return try await updateCustomBotConfiguration(playerId: playerId, configuration: configuration)
    }

    public func updateCustomBotConfiguration(
        playerId: UUID,
        configuration: CustomBotConfiguration
    ) async throws -> PlayerSummary {
        try dataCall {
            let context = ModelContext(container)
            let player = try fetchPlayerRecord(id: playerId, in: context)
            guard player.isBot == true, player.botKindRaw == BotKind.custom.rawValue else {
                throw customBotError("customBot.error.notCustomBot")
            }
            player.botDifficultyRaw = CustomBotConfigurationCodec.encode(configuration)
            player.updatedAt = Date()
            try context.save()
            return mapPlayer(player)
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
            if player.isBot != true {
                try archiveLinkedTrainingBot(for: playerId, in: context)
            }
            try context.save()
        }
    }

    public func fetchTrainingBot(linkedTo playerId: UUID) async throws -> PlayerSummary? {
        try dataCall {
            let context = ModelContext(container)
            let trainingRaw = BotKind.training.rawValue
            let descriptor = FetchDescriptor<SchemaV3.PlayerRecord>(
                predicate: #Predicate<SchemaV3.PlayerRecord> {
                    $0.linkedPlayerId == playerId && $0.botKindRaw == trainingRaw
                }
            )
            return try context.fetch(descriptor).first.map(mapPlayer)
        }
    }

    public func createTrainingBot(for playerId: UUID) async throws -> PlayerSummary {
        try dataCall {
            let context = ModelContext(container)
            let human = try fetchPlayerRecord(id: playerId, in: context)
            guard human.isBot != true, human.isArchived == false else {
                throw trainingBotError("trainingBot.error.invalidPlayer")
            }
            if try fetchTrainingBotRecord(linkedTo: playerId, in: context) != nil {
                throw trainingBotError("trainingBot.error.duplicate")
            }
            let name = TrainingBotNaming.defaultName(linkedPlayerName: human.name)
            try validateName(name, in: context, excludingPlayerId: nil)
            let now = Date()
            let record = SchemaV3.PlayerRecord(
                name: name,
                isArchived: false,
                isBot: true,
                botKindRaw: BotKind.training.rawValue,
                linkedPlayerId: playerId,
                createdAt: now,
                updatedAt: now
            )
            record.avatarStyleRaw = human.avatarStyleRaw ?? PlayerAvatarStyle.defaultForPlayer(id: record.id, isBot: true).rawValue
            record.preferredColorToken = human.preferredColorToken ?? PlayerColorToken.defaultForPlayer(id: record.id).rawValue
            context.insert(record)
            try context.save()
            return mapPlayer(record)
        }
    }

    public func resolveTrainingBotSkill(for botId: UUID, mode: MatchType) async throws -> BotSkillProfile {
        let bot = try await fetchPlayer(botId: botId)
        guard bot.isTrainingBot, let linkedId = bot.linkedPlayerId else {
            throw trainingBotError("trainingBot.error.notTrainingBot")
        }
        let loaded = try await MatchStatsLoader.load(
            matchRepository: matchRepository,
            statsRepository: statsRepository,
            request: MatchStatsLoadRequest(matchType: mode, participantPlayerId: linkedId)
        )
        let breakdown = StatsService.breakdowns(from: loaded.inputs, nameById: loaded.namesById)
            .first { $0.playerId == linkedId }
        guard let breakdown else {
            throw trainingBotError("trainingBot.error.ineligible")
        }
        let eligibility = TrainingBotEligibilityService.eligibility(breakdown: breakdown, mode: mode)
        guard eligibility.isEligible else {
            throw trainingBotError("trainingBot.error.ineligible")
        }
        return TrainingBotSkillResolver.resolve(breakdown: breakdown, mode: mode)
    }

    private func fetchPlayer(botId: UUID) async throws -> PlayerSummary {
        try dataCall {
            let context = ModelContext(container)
            return mapPlayer(try fetchPlayerRecord(id: botId, in: context))
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

    public func fetchPrimaryPlayer() async throws -> PlayerSummary? {
        try dataCall {
            let context = ModelContext(container)
            let primaryRaw = PlayerRole.primary.rawValue
            let descriptor = FetchDescriptor<SchemaV3.PlayerRecord>(
                predicate: #Predicate<SchemaV3.PlayerRecord> {
                    $0.playerRoleRaw == primaryRaw && $0.isBot != true
                }
            )
            return try context.fetch(descriptor).first.map(mapPlayer)
        }
    }

    public func designatePrimaryPlayer(playerId: UUID) async throws -> PlayerSummary {
        try dataCall {
            let context = ModelContext(container)
            let player = try fetchPlayerRecord(id: playerId, in: context)
            guard player.isBot != true else {
                throw AppError(
                    code: .validationFailed,
                    layer: .data,
                    severity: .warning,
                    isRecoverable: true,
                    userMessageKey: "players.primary.botNotAllowed",
                    debugContext: ["playerId": playerId.uuidString]
                )
            }
            let primaryRaw = PlayerRole.primary.rawValue
            let guestRaw = PlayerRole.guest.rawValue
            let humans = try context.fetch(
                FetchDescriptor<SchemaV3.PlayerRecord>(
                    predicate: #Predicate<SchemaV3.PlayerRecord> { $0.isBot != true }
                )
            )
            for human in humans {
                if human.playerRoleRaw == primaryRaw {
                    human.playerRoleRaw = guestRaw
                }
            }
            player.playerRoleRaw = primaryRaw
            player.updatedAt = Date()
            try context.save()
            return mapPlayer(player)
        }
    }

    public func relinquishPrimaryPlayer(playerId: UUID) async throws -> PlayerSummary {
        try dataCall {
            let context = ModelContext(container)
            let player = try fetchPlayerRecord(id: playerId, in: context)
            guard player.playerRoleRaw == PlayerRole.primary.rawValue else {
                return mapPlayer(player)
            }
            player.playerRoleRaw = PlayerRole.guest.rawValue
            player.updatedAt = Date()
            try context.save()
            return mapPlayer(player)
        }
    }

    public func deletePlayer(playerId: UUID) async throws {
        try dataCall {
            let context = ModelContext(container)
            let player = try fetchPlayerRecord(id: playerId, in: context)
            let refs = try context.fetch(
                FetchDescriptor<SchemaV3.MatchParticipantRecord>(
                    predicate: #Predicate<SchemaV3.MatchParticipantRecord> { $0.playerId == playerId }
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

    private func fetchPlayerRecord(id: UUID, in context: ModelContext) throws -> SchemaV3.PlayerRecord {
        let descriptor = FetchDescriptor<SchemaV3.PlayerRecord>(
            predicate: #Predicate<SchemaV3.PlayerRecord> { $0.id == id }
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
        let players = try context.fetch(FetchDescriptor<SchemaV3.PlayerRecord>())
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

    private func fetchTrainingBotRecord(linkedTo playerId: UUID, in context: ModelContext) throws -> SchemaV3.PlayerRecord? {
        let trainingRaw = BotKind.training.rawValue
        let descriptor = FetchDescriptor<SchemaV3.PlayerRecord>(
            predicate: #Predicate<SchemaV3.PlayerRecord> {
                $0.linkedPlayerId == playerId && $0.botKindRaw == trainingRaw
            }
        )
        return try context.fetch(descriptor).first
    }

    private func archiveLinkedTrainingBot(for playerId: UUID, in context: ModelContext) throws {
        guard let bot = try fetchTrainingBotRecord(linkedTo: playerId, in: context) else { return }
        bot.isArchived = true
        bot.updatedAt = Date()
    }

    private func trainingBotError(_ key: String) -> AppError {
        AppError(
            code: .validationFailed,
            layer: .data,
            severity: .warning,
            isRecoverable: true,
            userMessageKey: key
        )
    }

    private func customBotError(_ key: String) -> AppError {
        AppError(
            code: .validationFailed,
            layer: .data,
            severity: .warning,
            isRecoverable: true,
            userMessageKey: key
        )
    }
}
