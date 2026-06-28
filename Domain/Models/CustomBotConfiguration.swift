import Foundation

/// Versioned persistence model for user-defined custom bots.
public struct CustomBotConfiguration: Codable, Equatable, Sendable {
    public static let currentSchemaVersion = 2

    public var schemaVersion: Int
    public var x01Average: Double
    public var cricketMPR: Double
    /// When non-nil, used as the canonical profile base instead of interpolator merge.
    public var explicitProfile: BotSkillProfile?
    /// Optional facet overrides applied after merge (Advanced UI).
    public var facetOverrides: CustomBotFacetOverrides?
    /// Anchors discrete scoring heuristics in `DartBotEngine`.
    public var scoringBehaviorTier: BotDifficulty?

    public init(
        schemaVersion: Int = currentSchemaVersion,
        x01Average: Double,
        cricketMPR: Double,
        explicitProfile: BotSkillProfile? = nil,
        facetOverrides: CustomBotFacetOverrides? = nil,
        scoringBehaviorTier: BotDifficulty? = nil
    ) {
        self.schemaVersion = schemaVersion
        self.x01Average = CustomBotMetrics.clampX01(x01Average)
        self.cricketMPR = CustomBotMetrics.clampMPR(cricketMPR)
        self.explicitProfile = explicitProfile
        self.facetOverrides = facetOverrides
        self.scoringBehaviorTier = scoringBehaviorTier
    }

    public static func from(metrics: CustomBotMetrics) -> CustomBotConfiguration {
        CustomBotConfiguration(
            schemaVersion: 1,
            x01Average: metrics.x01Average,
            cricketMPR: metrics.cricketMPR
        )
    }

    public static func fromPreset(_ difficulty: BotDifficulty) -> CustomBotConfiguration {
        let metrics = BotModeSummaryMetrics.preset(difficulty)
        return CustomBotConfiguration(
            schemaVersion: currentSchemaVersion,
            x01Average: metrics.x01Average ?? CustomBotMetrics.defaultX01Average,
            cricketMPR: metrics.cricketMPR ?? CustomBotMetrics.defaultCricketMPR,
            explicitProfile: difficulty.skillProfile,
            scoringBehaviorTier: difficulty
        )
    }

    public var metrics: CustomBotMetrics {
        CustomBotMetrics(x01Average: x01Average, cricketMPR: cricketMPR)
    }

    public var usesLegacyV1Encoding: Bool {
        explicitProfile == nil && facetOverrides == nil && scoringBehaviorTier == nil
    }

    public var isAdvanced: Bool {
        !usesLegacyV1Encoding
    }

    /// Single engine profile: explicit base, or merged X01 + Cricket slices, then facet overrides.
    public func resolvedCanonicalProfile() -> BotSkillProfile {
        var profile: BotSkillProfile
        if let explicitProfile {
            profile = explicitProfile
        } else {
            profile = Self.mergedDerivedProfile(
                x01Average: x01Average,
                cricketMPR: cricketMPR,
                scoringBehaviorTier: scoringBehaviorTier
            )
        }
        if let scoringBehaviorTier {
            profile = profile.withScoringBehaviorTier(scoringBehaviorTier)
        }
        if var facets = facetOverrides {
            facets.apply(to: &profile)
        }
        return profile
    }

    public func resetToSimpleTargets() -> CustomBotConfiguration {
        CustomBotConfiguration(
            schemaVersion: Self.currentSchemaVersion,
            x01Average: x01Average,
            cricketMPR: cricketMPR
        )
    }

    public func resetToPreset(_ difficulty: BotDifficulty) -> CustomBotConfiguration {
        var config = CustomBotConfiguration(
            schemaVersion: Self.currentSchemaVersion,
            x01Average: x01Average,
            cricketMPR: cricketMPR,
            explicitProfile: difficulty.skillProfile,
            scoringBehaviorTier: difficulty
        )
        config.facetOverrides = CustomBotFacetOverrides.extract(from: difficulty.skillProfile)
        return config
    }

    /// Bakes facet overrides into `explicitProfile`. Does not call `resolvedCanonicalProfile()`
    /// to avoid re-applying facets on top of an already-synced profile.
    public mutating func syncExplicitProfileFromFacets() {
        var profile = Self.mergedDerivedProfile(
            x01Average: x01Average,
            cricketMPR: cricketMPR,
            scoringBehaviorTier: scoringBehaviorTier
        )
        if var facets = facetOverrides {
            facets.apply(to: &profile)
        } else {
            facetOverrides = CustomBotFacetOverrides.extract(from: profile)
        }
        explicitProfile = profile
        schemaVersion = Self.currentSchemaVersion
    }

    private static func mergedDerivedProfile(
        x01Average: Double,
        cricketMPR: Double,
        scoringBehaviorTier: BotDifficulty?
    ) -> BotSkillProfile {
        let x01Slice = BotSkillProfileInterpolator.profile(
            forX01Average: x01Average,
            clampToTierRange: false
        )
        let cricketSlice = BotSkillProfileInterpolator.profile(
            forCricketMPR: cricketMPR,
            clampToTierRange: false
        )
        let tier = scoringBehaviorTier ?? x01Slice.x01.scoringBehaviorTier
        let x01 = x01Slice.x01
        return BotSkillProfile(
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
                scoringBehaviorTierRaw: tier.rawValue
            ),
            cricket: cricketSlice.cricket
        )
    }
}

public enum CustomBotConfigurationCodec {
    private static let v1Prefix = "custom:"
    private static let v2Prefix = "customV2:"

    public static func decode(botDifficultyRaw: String?) -> CustomBotConfiguration? {
        guard let raw = botDifficultyRaw else { return nil }
        if raw.hasPrefix(v2Prefix) {
            let body = String(raw.dropFirst(v2Prefix.count))
            guard let data = body.data(using: .utf8) else { return nil }
            return try? JSONDecoder().decode(CustomBotConfiguration.self, from: data)
        }
        if let metrics = CustomBotMetrics.decode(botDifficultyRaw: raw) {
            return CustomBotConfiguration.from(metrics: metrics)
        }
        return nil
    }

    public static func encode(_ configuration: CustomBotConfiguration) -> String {
        if configuration.usesLegacyV1Encoding {
            return configuration.metrics.encode()
        }
        guard let data = try? JSONEncoder().encode(configuration),
              let json = String(data: data, encoding: .utf8) else {
            return configuration.metrics.encode()
        }
        return "\(v2Prefix)\(json)"
    }
}

extension BotSkillProfile {
    func withScoringBehaviorTier(_ tier: BotDifficulty) -> BotSkillProfile {
        let x01 = self.x01
        return BotSkillProfile(
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
                scoringBehaviorTierRaw: tier.rawValue
            ),
            cricket: cricket
        )
    }
}
