import Foundation

struct BotParticipantBuildInput: Sendable {
    let playerId: UUID
    let displayName: String
    let turnOrder: Int
    let botDifficulty: BotDifficulty?
    let isTrainingBot: Bool
    let isCustomBot: Bool
    let customConfiguration: CustomBotConfiguration?
    let linkedPlayerId: UUID?
    let colorTokenRaw: String
    let matchType: MatchType
    let uiTemplate: GameplayUITemplate

    init(
        playerId: UUID,
        displayName: String,
        turnOrder: Int,
        botDifficulty: BotDifficulty?,
        isTrainingBot: Bool,
        isCustomBot: Bool,
        customConfiguration: CustomBotConfiguration?,
        linkedPlayerId: UUID?,
        colorTokenRaw: String,
        matchType: MatchType,
        uiTemplate: GameplayUITemplate
    ) {
        self.playerId = playerId
        self.displayName = displayName
        self.turnOrder = turnOrder
        self.botDifficulty = botDifficulty
        self.isTrainingBot = isTrainingBot
        self.isCustomBot = isCustomBot
        self.customConfiguration = customConfiguration
        self.linkedPlayerId = linkedPlayerId
        self.colorTokenRaw = colorTokenRaw
        self.matchType = matchType
        self.uiTemplate = uiTemplate
    }
}

enum BotParticipantFactory {
    static func makeParticipant(
        input: BotParticipantBuildInput,
        resolveTrainingSkill: (UUID, MatchType) async throws -> BotSkillProfile
    ) async throws -> MatchParticipant {
        var botDifficultyRaw = input.botDifficulty?.rawValue
        var botKindRaw: String?
        var botSkillProfilePayload: Data?

        let context = BotPlayContext(matchType: input.matchType, uiTemplate: input.uiTemplate)

        if input.isTrainingBot {
            let profile = try await resolveTrainingSkill(input.playerId, input.matchType)
            let descriptor = TrainingBotDescriptor(linkedPlayerId: input.linkedPlayerId ?? input.playerId)
            botSkillProfilePayload = try descriptor.skillSnapshotPayload(profile: profile, context: context)
            botKindRaw = BotKind.training.rawValue
            botDifficultyRaw = nil
        } else if input.isCustomBot, let configuration = input.customConfiguration {
            let descriptor = CustomBotDescriptor(configuration: configuration)
            let profile = descriptor.skillProfile(context: context)
            botSkillProfilePayload = try descriptor.skillSnapshotPayload(profile: profile, context: context)
            botKindRaw = BotKind.custom.rawValue
            botDifficultyRaw = nil
        } else if input.botDifficulty != nil {
            botKindRaw = BotKind.preset.rawValue
        }

        return MatchParticipant(
            playerId: input.playerId,
            displayNameAtMatchStart: input.displayName,
            turnOrder: input.turnOrder,
            botDifficultyRaw: botDifficultyRaw,
            botKindRaw: botKindRaw,
            botSkillProfilePayload: botSkillProfilePayload,
            botEffectiveTierRaw: BotAchievementTierResolver.effectiveTierRaw(
                botKindRaw: botKindRaw,
                botDifficultyRaw: botDifficultyRaw,
                customConfiguration: input.customConfiguration,
                isTrainingBot: input.isTrainingBot
            ),
            preferredColorTokenAtMatchStart: input.colorTokenRaw
        )
    }
}
