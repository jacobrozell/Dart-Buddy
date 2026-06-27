import Foundation

/// Maps bot participants to preset ladder tiers for achievement evaluation.
/// See `specs/AchievementCatalogPhase1.md` §12.2.
public enum BotAchievementTierResolver {
    public static func effectiveTier(for participant: MatchParticipant) -> BotDifficulty? {
        if let stored = participant.botEffectiveTierRaw.flatMap(BotDifficulty.init(rawValue:)) {
            return stored
        }
        return effectiveTier(
            botKindRaw: participant.botKindRaw,
            botDifficultyRaw: participant.botDifficultyRaw,
            customConfiguration: customConfiguration(from: participant),
            isTrainingBot: participant.botKind == .training
        )
    }

    public static func effectiveTier(
        botKindRaw: String?,
        botDifficultyRaw: String?,
        customConfiguration: CustomBotConfiguration?,
        isTrainingBot: Bool
    ) -> BotDifficulty? {
        if isTrainingBot || botKindRaw == BotKind.training.rawValue {
            return nil
        }

        let kind = botKindRaw.flatMap(BotKind.init(rawValue:))

        if kind == .custom || customConfiguration != nil {
            guard let configuration = customConfiguration else { return nil }
            return effectiveTier(forCustom: configuration)
        }

        if let preset = botDifficultyRaw.flatMap(BotDifficulty.init(rawValue:)) {
            return preset
        }

        if kind == .preset || botKindRaw == nil, botDifficultyRaw != nil {
            return botDifficultyRaw.flatMap(BotDifficulty.init(rawValue:))
        }

        return nil
    }

    public static func effectiveTier(forCustom configuration: CustomBotConfiguration) -> BotDifficulty {
        let tierX01 = BotSkillProfileInterpolator.achievementTierFloor(forX01Average: configuration.x01Average)
        let tierMPR = BotSkillProfileInterpolator.achievementTierFloor(forCricketMPR: configuration.cricketMPR)
        var effective = BotDifficulty.maxAchievementTier(tierX01, tierMPR)
        if let scoringBehaviorTier = configuration.scoringBehaviorTier {
            effective = BotDifficulty.maxAchievementTier(effective, scoringBehaviorTier)
        }
        return effective
    }

    public static func effectiveTierRaw(for participant: MatchParticipant) -> String? {
        effectiveTier(for: participant)?.rawValue
    }

    public static func effectiveTierRaw(
        botKindRaw: String?,
        botDifficultyRaw: String?,
        customConfiguration: CustomBotConfiguration?,
        isTrainingBot: Bool
    ) -> String? {
        effectiveTier(
            botKindRaw: botKindRaw,
            botDifficultyRaw: botDifficultyRaw,
            customConfiguration: customConfiguration,
            isTrainingBot: isTrainingBot
        )?.rawValue
    }

    private static func customConfiguration(from participant: MatchParticipant) -> CustomBotConfiguration? {
        guard participant.botKind == .custom,
              let payload = participant.botSkillProfilePayload,
              let snapshot = try? CustomBotSkillSnapshot.decode(from: payload) else {
            return nil
        }
        return CustomBotConfiguration(
            schemaVersion: snapshot.configurationSchemaVersion ?? CustomBotConfiguration.currentSchemaVersion,
            x01Average: snapshot.x01Average,
            cricketMPR: snapshot.cricketMPR,
            scoringBehaviorTier: snapshot.profile.x01.scoringBehaviorTier
        )
    }
}

extension BotDifficulty {
    var achievementRank: Int {
        switch self {
        case .veryEasy: 0
        case .easy: 1
        case .medium: 2
        case .hard: 3
        case .pro: 4
        }
    }

    public static func maxAchievementTier(_ tiers: BotDifficulty...) -> BotDifficulty {
        tiers.max(by: { $0.achievementRank < $1.achievementRank }) ?? .veryEasy
    }

    public func satisfiesAchievementLadder(threshold: BotDifficulty) -> Bool {
        achievementRank >= threshold.achievementRank
    }
}
