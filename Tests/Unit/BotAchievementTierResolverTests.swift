import Foundation
import Testing
@testable import DartBuddy

@Test(.tags(.unit, .regression))
func botAchievementTierFloorMapsX01AverageToPresetTier() {
    #expect(BotSkillProfileInterpolator.achievementTierFloor(forX01Average: 5) == .veryEasy)
    #expect(BotSkillProfileInterpolator.achievementTierFloor(forX01Average: 29) == .easy)
    #expect(BotSkillProfileInterpolator.achievementTierFloor(forX01Average: 74) == .medium)
    #expect(BotSkillProfileInterpolator.achievementTierFloor(forX01Average: 75) == .hard)
    #expect(BotSkillProfileInterpolator.achievementTierFloor(forX01Average: 100) == .pro)
}

@Test(.tags(.unit, .regression))
func botAchievementTierResolverMapsCustomSlidersToHarderAxis() {
    let tier = BotAchievementTierResolver.effectiveTier(
        forCustom: CustomBotConfiguration(x01Average: 75, cricketMPR: 1.0)
    )
    #expect(tier == .hard)
}

@Test(.tags(.unit, .regression))
func botAchievementTierResolverExcludesTrainingBots() {
    let tier = BotAchievementTierResolver.effectiveTier(
        botKindRaw: BotKind.training.rawValue,
        botDifficultyRaw: nil,
        customConfiguration: nil,
        isTrainingBot: true
    )
    #expect(tier == nil)
}

@Test(.tags(.unit, .regression))
func botAchievementTierResolverUsesStoredParticipantTier() {
    let participant = MatchParticipant(
        playerId: UUID(),
        displayNameAtMatchStart: "Hard Bot",
        turnOrder: 0,
        botDifficultyRaw: BotDifficulty.easy.rawValue,
        botKindRaw: BotKind.preset.rawValue,
        botEffectiveTierRaw: BotDifficulty.hard.rawValue
    )
    #expect(BotAchievementTierResolver.effectiveTier(for: participant) == .hard)
}

@Test(.tags(.unit, .regression))
func botAchievementLadderHardSatisfiesEasyThreshold() {
    #expect(BotDifficulty.hard.satisfiesAchievementLadder(threshold: .easy))
    #expect(!BotDifficulty.easy.satisfiesAchievementLadder(threshold: .hard))
}

@Test(.tags(.unit, .regression))
func botParticipantFactoryStoresEffectiveTierForPresetBot() async throws {
    let participant = try await BotParticipantFactory.makeParticipant(
        input: BotParticipantBuildInput(
            playerId: UUID(),
            displayName: "Hard Bot",
            turnOrder: 0,
            botDifficulty: .hard,
            isTrainingBot: false,
            isCustomBot: false,
            customConfiguration: nil,
            linkedPlayerId: nil,
            colorTokenRaw: PlayerColorToken.blue.rawValue,
            matchType: .x01,
            uiTemplate: .checkoutScore,
            partyUsesPresetBotsOnly: false
        ),
        resolveTrainingSkill: { _, _ in BotDifficulty.medium.skillProfile }
    )
    #expect(participant.botEffectiveTierRaw == BotDifficulty.hard.rawValue)
}

@Test(.tags(.unit, .regression))
func botParticipantFactoryStoresEffectiveTierForCustomBot() async throws {
    let participant = try await BotParticipantFactory.makeParticipant(
        input: BotParticipantBuildInput(
            playerId: UUID(),
            displayName: "Custom",
            turnOrder: 0,
            botDifficulty: nil,
            isTrainingBot: false,
            isCustomBot: true,
            customConfiguration: CustomBotConfiguration(x01Average: 75, cricketMPR: 1.0),
            linkedPlayerId: nil,
            colorTokenRaw: PlayerColorToken.green.rawValue,
            matchType: .x01,
            uiTemplate: .checkoutScore,
            partyUsesPresetBotsOnly: false
        ),
        resolveTrainingSkill: { _, _ in BotDifficulty.medium.skillProfile }
    )
    #expect(participant.botEffectiveTierRaw == BotDifficulty.hard.rawValue)
}

@Test(.tags(.unit, .regression))
func botParticipantFactoryLeavesTrainingBotTierNil() async throws {
    let participant = try await BotParticipantFactory.makeParticipant(
        input: BotParticipantBuildInput(
            playerId: UUID(),
            displayName: "Training",
            turnOrder: 0,
            botDifficulty: .medium,
            isTrainingBot: true,
            isCustomBot: false,
            customConfiguration: nil,
            linkedPlayerId: UUID(),
            colorTokenRaw: PlayerColorToken.blue.rawValue,
            matchType: .x01,
            uiTemplate: .checkoutScore,
            partyUsesPresetBotsOnly: false
        ),
        resolveTrainingSkill: { _, _ in BotDifficulty.medium.skillProfile }
    )
    #expect(participant.botEffectiveTierRaw == nil)
}
