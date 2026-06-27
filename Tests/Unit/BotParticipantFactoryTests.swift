import Foundation
import Testing
@testable import DartBuddy

@Test(.tags(.unit, .regression))
func botParticipantFactoryBuildsCustomBotSnapshot() async throws {
    let configuration = CustomBotConfiguration(x01Average: 42, cricketMPR: 1.6)
    let playerId = UUID()
    let participant = try await BotParticipantFactory.makeParticipant(
        input: BotParticipantBuildInput(
            playerId: playerId,
            displayName: "Custom Ace",
            turnOrder: 0,
            botDifficulty: nil,
            isTrainingBot: false,
            isCustomBot: true,
            customConfiguration: configuration,
            linkedPlayerId: nil,
            colorTokenRaw: PlayerColorToken.green.rawValue,
            matchType: .x01,
            uiTemplate: .checkoutScore
        ),
        resolveTrainingSkill: { _, _ in BotDifficulty.medium.skillProfile }
    )
    #expect(participant.botKindRaw == BotKind.custom.rawValue)
    #expect(participant.botDifficultyRaw == nil)
    let payload = try #require(participant.botSkillProfilePayload)
    let snapshot = try CustomBotSkillSnapshot.decode(from: payload)
    #expect(snapshot.x01Average == 42)
    #expect(snapshot.cricketMPR == 1.6)
    let expectedProfile = BotSkillProfileResolver.profile(
        configuration: configuration,
        context: BotPlayContext(matchType: .x01, uiTemplate: .checkoutScore)
    )
    #expect(snapshot.profile == expectedProfile)
}

@Test(.tags(.unit, .regression))
func botParticipantFactoryBuildsPresetBotWithoutPayload() async throws {
    let participant = try await BotParticipantFactory.makeParticipant(
        input: BotParticipantBuildInput(
            playerId: UUID(),
            displayName: "Easy Bot",
            turnOrder: 1,
            botDifficulty: .easy,
            isTrainingBot: false,
            isCustomBot: false,
            customConfiguration: nil,
            linkedPlayerId: nil,
            colorTokenRaw: PlayerColorToken.blue.rawValue,
            matchType: .cricket,
            uiTemplate: .markBoard
        ),
        resolveTrainingSkill: { _, _ in BotDifficulty.medium.skillProfile }
    )
    #expect(participant.botKindRaw == BotKind.preset.rawValue)
    #expect(participant.botDifficultyRaw == BotDifficulty.easy.rawValue)
    #expect(participant.botSkillProfilePayload == nil)
}

@Test(.tags(.unit, .regression))
func botParticipantFactoryBuildsCustomBotSnapshotForKiller() async throws {
    let configuration = CustomBotConfiguration(x01Average: 40, cricketMPR: 1.5)
    let participant = try await BotParticipantFactory.makeParticipant(
        input: BotParticipantBuildInput(
            playerId: UUID(),
            displayName: "Custom",
            turnOrder: 0,
            botDifficulty: nil,
            isTrainingBot: false,
            isCustomBot: true,
            customConfiguration: configuration,
            linkedPlayerId: nil,
            colorTokenRaw: PlayerColorToken.green.rawValue,
            matchType: .killer,
            uiTemplate: .livesElimination
        ),
        resolveTrainingSkill: { _, _ in BotDifficulty.medium.skillProfile }
    )
    #expect(participant.botKindRaw == BotKind.custom.rawValue)
    #expect(participant.botSkillProfilePayload != nil)
}
