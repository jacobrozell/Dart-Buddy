import Foundation

public enum CustomBotSkillResolver {
    /// Legacy match-type resolution kept for backward-compatible call sites and tests.
    public static func profile(for mode: MatchType, metrics: CustomBotMetrics) -> BotSkillProfile {
        guard let context = BotPlayContext.forMatchType(mode) else {
            return BotSkillProfileInterpolator.profile(
                forX01Average: metrics.x01Average,
                clampToTierRange: false
            )
        }
        return BotSkillProfileResolver.profile(
            configuration: .from(metrics: metrics),
            context: context
        )
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
