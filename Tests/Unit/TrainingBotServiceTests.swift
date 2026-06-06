import Foundation
import Testing
@testable import DartBuddy

@Test(.tags(.unit, .regression))
func trainingBotEligibilityReportsProgressMetadata() {
    var breakdown = PlayerStatBreakdown(playerId: UUID(), name: "Test")
    breakdown.games = 3
    let eligibility = TrainingBotEligibilityService.eligibility(breakdown: breakdown, mode: .x01)
    #expect(eligibility.gamesPlayed == 3)
    #expect(eligibility.requiredGames == TrainingBotEligibilityService.requiredGames)
    #expect(eligibility.mode == .x01)
}

@Test(.tags(.unit, .regression))
func trainingBotEligibilityRequiresFiveGames() {
    var breakdown = PlayerStatBreakdown(playerId: UUID(), name: "Test")
    breakdown.games = 4
    #expect(TrainingBotEligibilityService.eligibility(breakdown: breakdown, mode: .x01).isEligible == false)

    breakdown.games = 5
    #expect(TrainingBotEligibilityService.eligibility(breakdown: breakdown, mode: .x01).isEligible == true)
}

@Test(.tags(.unit, .regression))
func trainingBotSkillResolverBumpsX01Average() {
    var breakdown = PlayerStatBreakdown(playerId: UUID(), name: "Test")
    breakdown.games = 5
    breakdown.darts = 300
    breakdown.points = 4500
    #expect(breakdown.average3Dart > 40)
    let profile = TrainingBotSkillResolver.resolve(breakdown: breakdown, mode: .x01)
    let veryEasy = BotDifficulty.veryEasy.skillProfile
    #expect(profile.x01.checkoutAttemptChance > veryEasy.x01.checkoutAttemptChance)
}

@Test(.tags(.unit, .regression))
func botSkillProfileInterpolatorIsMonotonicBetweenTiers() {
    let low = BotSkillProfileInterpolator.profile(forX01Average: 25)
    let high = BotSkillProfileInterpolator.profile(forX01Average: 75)
    #expect(high.x01.hitChances.triple > low.x01.hitChances.triple)
}

@Test(.tags(.unit, .regression))
func trainingBotSkillResolverClampsCricketMPR() {
    var breakdown = PlayerStatBreakdown(playerId: UUID(), name: "Test")
    breakdown.games = 10
    breakdown.cricketMarks = 200
    breakdown.cricketRounds = 40
    let profile = TrainingBotSkillResolver.resolve(breakdown: breakdown, mode: .cricket)
    #expect(profile.cricket.hitChances.triple <= 0.95)
}

@Test(.tags(.unit, .regression))
func trainingBotEligibilityIsPerMode() {
    var breakdown = PlayerStatBreakdown(playerId: UUID(), name: "Test")
    breakdown.games = 5
    #expect(TrainingBotEligibilityService.eligibility(breakdown: breakdown, mode: .x01).isEligible)
    breakdown.games = 2
    #expect(!TrainingBotEligibilityService.eligibility(breakdown: breakdown, mode: .cricket).isEligible)
}
