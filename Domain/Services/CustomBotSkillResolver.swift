import Foundation

public enum CustomBotSkillResolver {
    public static func profile(for mode: MatchType, metrics: CustomBotMetrics) -> BotSkillProfile {
        switch mode {
        case .x01:
            return BotSkillProfileInterpolator.profile(forX01Average: metrics.x01Average, clampToTierRange: false)
        case .cricket:
            return BotSkillProfileInterpolator.profile(forCricketMPR: metrics.cricketMPR, clampToTierRange: false)
        case .baseball, .killer, .shanghai:
            return BotSkillProfileInterpolator.profile(forX01Average: metrics.x01Average, clampToTierRange: false)
        }
    }

    public static func combinedDisplayProfile(metrics: CustomBotMetrics) -> BotDifficultyDisplayProfile {
        let x01 = profile(for: .x01, metrics: metrics)
        let cricket = profile(for: .cricket, metrics: metrics)
        return BotDifficultyDisplayProfile(
            x01: x01.displayProfile.x01,
            cricket: cricket.displayProfile.cricket
        )
    }
}
