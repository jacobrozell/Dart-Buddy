import Foundation
import Testing
@testable import DartBuddy

@Suite struct BotDifficultyReferenceMetricsTests {
    @Test func presetReferenceMetricsMatchInterpolatorAnchors() {
        #expect(BotDifficulty.veryEasy.referenceMetrics.x01Average == 20)
        #expect(BotDifficulty.veryEasy.referenceMetrics.cricketMPR == 0.85)
        #expect(BotDifficulty.easy.referenceMetrics.x01Average == 29)
        #expect(BotDifficulty.easy.referenceMetrics.cricketMPR == 1.25)
        #expect(BotDifficulty.medium.referenceMetrics.x01Average == 61)
        #expect(BotDifficulty.medium.referenceMetrics.cricketMPR == 1.85)
        #expect(BotDifficulty.hard.referenceMetrics.x01Average == 75)
        #expect(BotDifficulty.hard.referenceMetrics.cricketMPR == 2.45)
        #expect(BotDifficulty.pro.referenceMetrics.x01Average == 88)
        #expect(BotDifficulty.pro.referenceMetrics.cricketMPR == 3.05)
    }

    @Test func displayProfileIncludesSummaryForPresetTiers() {
        let profile = BotDifficulty.medium.displayProfile
        #expect(profile.summary == BotModeSummaryMetrics.preset(.medium))
    }

    @Test func customBotConfigurationFromPresetUsesReferenceMetrics() {
        let configuration = CustomBotConfiguration.fromPreset(.hard)
        #expect(configuration.x01Average == 75)
        #expect(configuration.cricketMPR == 2.45)
        #expect(configuration.scoringBehaviorTier == .hard)
        #expect(configuration.explicitProfile == BotDifficulty.hard.skillProfile)
    }

    @Test func customMetricsRoundTripThroughSummary() {
        let metrics = CustomBotMetrics(x01Average: 42, cricketMPR: 1.75)
        let summary = BotModeSummaryMetrics.custom(metrics)
        #expect(summary.customBotMetrics == metrics)
    }
}
