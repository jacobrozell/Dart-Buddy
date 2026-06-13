import Foundation

public enum CustomBotSkillResolver {
    /// Legacy match-type resolution kept for backward-compatible call sites and tests.
    public static func profile(for mode: MatchType, metrics: CustomBotMetrics) -> BotSkillProfile {
        switch mode {
        case .x01:
            return BotSkillProfileInterpolator.profile(forX01Average: metrics.x01Average, clampToTierRange: false)
        case .cricket:
            return BotSkillProfileInterpolator.profile(forCricketMPR: metrics.cricketMPR, clampToTierRange: false)
        case .baseball, .killer, .shanghai, .americanCricket, .mickeyMouse, .mulligan, .englishCricket,
             .knockout, .suddenDeath, .fiftyOneByFives, .golf, .football, .grandNational, .hareAndHounds,
             .aroundTheClock, .aroundTheClock180, .chaseTheDragon, .nineLives, .fleet, .raid:
            return BotSkillProfileInterpolator.profile(forX01Average: metrics.x01Average, clampToTierRange: false)
        case .blindKiller, .followTheLeader, .loop, .prisoner, .scam, .snooker, .ticTacToe, .bobs27, .halveIt:
            return BotSkillProfileInterpolator.profile(forX01Average: metrics.x01Average, clampToTierRange: false)
        }
    }

    static func profile(
        configuration: CustomBotConfiguration,
        context: BotPlayContext
    ) -> BotSkillProfile {
        BotSkillProfileResolver.profile(configuration: configuration, context: context)
    }

    public static func combinedDisplayProfile(metrics: CustomBotMetrics) -> BotDifficultyDisplayProfile {
        combinedDisplayProfile(configuration: .from(metrics: metrics))
    }

    public static func combinedDisplayProfile(configuration: CustomBotConfiguration) -> BotDifficultyDisplayProfile {
        configuration.resolvedCanonicalProfile().displayProfile
    }
}
