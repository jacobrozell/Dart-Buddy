import Foundation
import Testing
@testable import DartBuddy

@Test(.tags(.unit, .regression))
func customBotConfigurationV1RoundTripDecodesLegacyString() {
    let raw = "custom:30.0:1.25"
    let configuration = CustomBotConfigurationCodec.decode(botDifficultyRaw: raw)
    #expect(configuration?.schemaVersion == 1)
    #expect(configuration?.x01Average == 30)
    #expect(configuration?.cricketMPR == 1.25)
    #expect(CustomBotConfigurationCodec.encode(configuration!) == raw)
}

@Test(.tags(.unit, .regression))
func customBotConfigurationV2RoundTripPreservesAdvancedFields() throws {
    var configuration = CustomBotConfiguration(
        schemaVersion: 2,
        x01Average: 55,
        cricketMPR: 2.2,
        scoringBehaviorTier: .hard
    )
    configuration.facetOverrides = CustomBotFacetOverrides(
        x01: X01SkillFacet(checkoutAttemptChance: 0.42)
    )
    let encoded = CustomBotConfigurationCodec.encode(configuration)
    #expect(encoded.hasPrefix("customV2:"))
    let decoded = CustomBotConfigurationCodec.decode(botDifficultyRaw: encoded)
    #expect(decoded == configuration)
}

@Test(.tags(.unit, .regression))
func customBotConfigurationResetToSimpleClearsAdvancedState() {
    var configuration = CustomBotConfiguration(
        x01Average: 50,
        cricketMPR: 2.0,
        explicitProfile: BotDifficulty.medium.skillProfile,
        scoringBehaviorTier: .medium
    )
    configuration.facetOverrides = CustomBotFacetOverrides(
        x01: X01SkillFacet(checkoutAttemptChance: 0.5)
    )
    let reset = configuration.resetToSimpleTargets()
    #expect(reset.explicitProfile == nil)
    #expect(reset.facetOverrides == nil)
    #expect(reset.scoringBehaviorTier == nil)
    #expect(reset.x01Average == 50)
    #expect(reset.cricketMPR == 2.0)
}

@Test(.tags(.unit, .regression))
func customBotConfigurationCanonicalProfileMergesSlices() {
    let configuration = CustomBotConfiguration(x01Average: 55, cricketMPR: 2.2)
    let profile = configuration.resolvedCanonicalProfile()
    let x01Slice = BotSkillProfileInterpolator.profile(forX01Average: 55, clampToTierRange: false)
    let cricketSlice = BotSkillProfileInterpolator.profile(forCricketMPR: 2.2, clampToTierRange: false)
    #expect(profile.x01.scoringVisitMax == x01Slice.x01.scoringVisitMax)
    #expect(profile.cricket.hitChances.triple == cricketSlice.cricket.hitChances.triple)
}

@Test(.tags(.unit, .regression))
func syncExplicitProfileFromFacetsIsIdempotent() {
    var configuration = CustomBotConfiguration(x01Average: 50, cricketMPR: 2.0)
    configuration.facetOverrides = CustomBotFacetOverrides(
        x01: X01SkillFacet(checkoutAttemptChance: 0.5)
    )
    configuration.syncExplicitProfileFromFacets()
    let first = configuration.explicitProfile
    configuration.syncExplicitProfileFromFacets()
    #expect(configuration.explicitProfile == first)
}

@Test(.tags(.unit, .regression))
func customBotFacetCheckoutOverrideAppliesToProfile() {
    var configuration = CustomBotConfiguration(x01Average: 40, cricketMPR: 1.5)
    configuration.facetOverrides = CustomBotFacetOverrides(
        x01: X01SkillFacet(checkoutAttemptChance: 0.88)
    )
    let profile = configuration.resolvedCanonicalProfile()
    #expect(profile.x01.checkoutAttemptChance == 0.88)
}
