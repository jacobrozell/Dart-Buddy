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
func botSkillProfileInterpolatorClampsWhenRequested() {
    let below = BotSkillProfileInterpolator.profile(forX01Average: 5, clampToTierRange: true)
    let veryEasy = BotDifficulty.veryEasy.skillProfile
    #expect(below.x01.scoringVisitMax == veryEasy.x01.scoringVisitMax)

    let above = BotSkillProfileInterpolator.profile(forX01Average: 120, clampToTierRange: true)
    let pro = BotDifficulty.pro.skillProfile
    #expect(above.x01.hitChances.triple == pro.x01.hitChances.triple)
}

@Test(.tags(.unit, .regression))
func botSkillProfileInterpolatorExtrapolatesCricketMPRBeyondProWhenUnclamped() {
    let pro = BotSkillProfileInterpolator.profile(forCricketMPR: 3.05, clampToTierRange: true)
    let beyond = BotSkillProfileInterpolator.profile(forCricketMPR: 4.5, clampToTierRange: false)
    #expect(beyond.cricket.hitChances.triple > pro.cricket.hitChances.triple)
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

@Test(.tags(.unit, .regression))
func trainingBotSkillResolverUsesEasyFallbackWhenNoX01Average() {
    let breakdown = PlayerStatBreakdown(playerId: UUID(), name: "New")
    let profile = TrainingBotSkillResolver.resolve(breakdown: breakdown, mode: .x01)
    let easyFallback = BotSkillProfileInterpolator.profile(forX01Average: 24)
    #expect(profile.x01.scoringVisitMax == easyFallback.x01.scoringVisitMax)
}

@Test(.tags(.unit, .regression))
func trainingBotSkillResolverUsesEasyFallbackWhenNoCricketMPR() {
    let breakdown = PlayerStatBreakdown(playerId: UUID(), name: "New")
    let profile = TrainingBotSkillResolver.resolve(breakdown: breakdown, mode: .cricket)
    let easyFallback = BotSkillProfileInterpolator.profile(forCricketMPR: 1.35)
    #expect(profile.cricket.hitChances.triple == easyFallback.cricket.hitChances.triple)
}

@Test(.tags(.unit, .regression))
func trainingBotSkillResolverClampsHighX01Average() {
    var breakdown = PlayerStatBreakdown(playerId: UUID(), name: "Pro")
    breakdown.darts = 300
    breakdown.points = 27_000
    let profile = TrainingBotSkillResolver.resolve(breakdown: breakdown, mode: .x01)
    let capped = BotSkillProfileInterpolator.profile(forX01Average: TrainingBotSkillTuning.x01MaxAverage)
    #expect(profile.x01.hitChances.triple <= capped.x01.hitChances.triple)
}

@Test(.tags(.unit, .regression))
func trainingBotSkillResolverAppliesX01FormulaForPartyModes() {
    var breakdown = PlayerStatBreakdown(playerId: UUID(), name: "Test")
    breakdown.darts = 90
    breakdown.points = 3600
    let baseball = TrainingBotSkillResolver.resolve(breakdown: breakdown, mode: .baseball)
    let killer = TrainingBotSkillResolver.resolve(breakdown: breakdown, mode: .killer)
    let shanghai = TrainingBotSkillResolver.resolve(breakdown: breakdown, mode: .shanghai)
    #expect(baseball.x01.hitChances.triple == killer.x01.hitChances.triple)
    #expect(killer.x01.hitChances.triple == shanghai.x01.hitChances.triple)
}

@Test(.tags(.unit, .regression))
func trainingBotEligibilityStructStoresCustomRequiredGames() {
    let eligibility = TrainingBotEligibility(isEligible: true, gamesPlayed: 7, requiredGames: 7, mode: .cricket)
    #expect(eligibility.isEligible)
    #expect(eligibility.gamesPlayed == 7)
    #expect(eligibility.requiredGames == 7)
    #expect(eligibility.mode == .cricket)
}

@Test(.tags(.unit, .regression))
func trainingBotSkillResolverScalesMonotonicallyWithAverage() {
    var low = PlayerStatBreakdown(playerId: UUID(), name: "Low")
    low.darts = 300
    low.points = 1500
    var high = PlayerStatBreakdown(playerId: UUID(), name: "High")
    high.darts = 300
    high.points = 7500
    let lowProfile = TrainingBotSkillResolver.resolve(breakdown: low, mode: .x01)
    let highProfile = TrainingBotSkillResolver.resolve(breakdown: high, mode: .x01)
    #expect(highProfile.x01.hitChances.triple > lowProfile.x01.hitChances.triple)
}

@Test(.tags(.unit, .regression))
func trainingBotSkillResolverAppliesMinimumBumpForModerateAverages() {
    var breakdown = PlayerStatBreakdown(playerId: UUID(), name: "Mid")
    breakdown.darts = 300
    breakdown.points = 4500
    let playerAvg = breakdown.average3Dart
    let profile = TrainingBotSkillResolver.resolve(breakdown: breakdown, mode: .x01)
    let bumpedTarget = min(
        max(playerAvg * TrainingBotSkillTuning.x01AvgMultiplier + TrainingBotSkillTuning.x01AvgOffset, playerAvg + TrainingBotSkillTuning.x01MinBump),
        TrainingBotSkillTuning.x01MaxAverage
    )
    let expected = BotSkillProfileInterpolator.profile(forX01Average: bumpedTarget)
    #expect(profile.x01.scoringVisitMax == expected.x01.scoringVisitMax)
}
