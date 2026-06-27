import Foundation

struct BotPlayContext: Sendable, Equatable {
    let matchType: MatchType
    let uiTemplate: GameplayUITemplate

    init(matchType: MatchType, uiTemplate: GameplayUITemplate) {
        self.matchType = matchType
        self.uiTemplate = uiTemplate
    }

    static func forMatchType(_ matchType: MatchType) -> BotPlayContext? {
        guard let entry = GameModeCatalog.entry(for: matchType) else { return nil }
        return BotPlayContext(matchType: matchType, uiTemplate: entry.uiTemplate)
    }
}

enum CustomBotSimpleMetric: String, Sendable {
    case x01Average
    case cricketMPR
    case both
}

/// Template-based custom bot skill resolution.
enum BotSkillProfileResolver {
    static func profile(
        configuration: CustomBotConfiguration,
        context: BotPlayContext
    ) -> BotSkillProfile {
        if configuration.isAdvanced {
            return configuration.resolvedCanonicalProfile()
        }
        return templateWeightedProfile(configuration: configuration, template: context.uiTemplate)
    }

    static func primarySimpleMetric(for template: GameplayUITemplate) -> CustomBotSimpleMetric {
        switch template {
        case .checkoutScore, .soloChallenge:
            return .x01Average
        case .markBoard:
            return .cricketMPR
        default:
            return .both
        }
    }

    static func allShippedTemplates() -> [GameplayUITemplate] {
        GameModeCatalog.available.compactMap(\.matchType).compactMap { matchType in
            GameModeCatalog.entry(for: matchType)?.uiTemplate
        }
    }

    static func compatibleTemplates() -> [GameplayUITemplate] {
        Array(Set(allShippedTemplates())).sorted { $0.rawValue < $1.rawValue }
    }

    private static func templateWeightedProfile(
        configuration: CustomBotConfiguration,
        template: GameplayUITemplate
    ) -> BotSkillProfile {
        let x01Slice = BotSkillProfileInterpolator.profile(
            forX01Average: configuration.x01Average,
            clampToTierRange: false
        )
        let cricketSlice = BotSkillProfileInterpolator.profile(
            forCricketMPR: configuration.cricketMPR,
            clampToTierRange: false
        )

        let behaviorTier: BotDifficulty
        switch template {
        case .markBoard:
            behaviorTier = configuration.scoringBehaviorTier ?? cricketSlice.x01.scoringBehaviorTier
        case .checkoutScore, .soloChallenge:
            behaviorTier = configuration.scoringBehaviorTier ?? x01Slice.x01.scoringBehaviorTier
        default:
            behaviorTier = configuration.scoringBehaviorTier ?? x01Slice.x01.scoringBehaviorTier
        }

        return mergeDerivedProfile(
            x01: x01Slice.x01,
            cricket: cricketSlice.cricket,
            scoringBehaviorTier: behaviorTier
        )
    }

    static func mergeDerivedProfile(
        x01: BotSkillProfile.X01,
        cricket: BotSkillProfile.Cricket,
        scoringBehaviorTier: BotDifficulty
    ) -> BotSkillProfile {
        BotSkillProfile(
            x01: .init(
                scoringVisitMin: x01.scoringVisitMin,
                scoringVisitMax: x01.scoringVisitMax,
                hitChances: x01.hitChances,
                checkoutAttemptChance: x01.checkoutAttemptChance,
                offBoardMissChance: x01.offBoardMissChance,
                riskyBustChance: x01.riskyBustChance,
                triplePreference: x01.triplePreference,
                checkInHitBoost: x01.checkInHitBoost,
                innerBullAimChance: x01.innerBullAimChance,
                masterInTripleOpenerChance: x01.masterInTripleOpenerChance,
                safeRemainingSingleOut: x01.safeRemainingSingleOut,
                safeRemainingDoubleOut: x01.safeRemainingDoubleOut,
                safeRemainingMasterOut: x01.safeRemainingMasterOut,
                scoringBehaviorTierRaw: scoringBehaviorTier.rawValue
            ),
            cricket: cricket
        )
    }
}

extension GameplayUITemplate {
    var displayTitleKey: String { "gameplayTemplate.\(rawValue).title" }

    var customBotPrimaryMetricKey: String {
        switch BotSkillProfileResolver.primarySimpleMetric(for: self) {
        case .x01Average:
            return "customBot.compatible.x01Primary"
        case .cricketMPR:
            return "customBot.compatible.mprPrimary"
        case .both:
            return "customBot.compatible.bothPrimary"
        }
    }
}
