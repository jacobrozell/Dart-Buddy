import Foundation
import Testing
@testable import DartBuddy

@Suite("Bot skill profile interpolator", .tags(.unit, .regression))
struct BotSkillProfileInterpolatorTests {
    @Test
    func x01ProfileAtTierAnchorsMatchesDifficultyProfiles() {
        for difficulty in BotDifficulty.allCases {
            let anchor = difficulty.skillProfile
            let interpolated = BotSkillProfileInterpolator.profile(forX01Average: x01Anchor(for: difficulty))
            #expect(interpolated.x01.scoringVisitMax == anchor.x01.scoringVisitMax)
            #expect(
                approxEqual(interpolated.x01.hitChances.triple, anchor.x01.hitChances.triple)
            )
        }
    }

    @Test
    func cricketProfileAtTierAnchorsMatchesDifficultyProfiles() {
        for difficulty in BotDifficulty.allCases {
            let anchor = difficulty.skillProfile
            let interpolated = BotSkillProfileInterpolator.profile(forCricketMPR: cricketAnchor(for: difficulty))
            #expect(
                approxEqual(interpolated.cricket.hitChances.triple, anchor.cricket.hitChances.triple)
            )
            #expect(
                approxEqual(interpolated.cricket.tripleOnOpenChance, anchor.cricket.tripleOnOpenChance)
            )
        }
    }

    @Test
    func x01InterpolationBetweenTiersIsMonotonic() {
        let low = BotSkillProfileInterpolator.profile(forX01Average: 29)
        let mid = BotSkillProfileInterpolator.profile(forX01Average: 45)
        let high = BotSkillProfileInterpolator.profile(forX01Average: 75)
        #expect(mid.x01.hitChances.triple > low.x01.hitChances.triple)
        #expect(high.x01.hitChances.triple > mid.x01.hitChances.triple)
        #expect(mid.x01.checkoutAttemptChance > low.x01.checkoutAttemptChance)
    }

    @Test
    func cricketInterpolationBetweenTiersIsMonotonic() {
        let low = BotSkillProfileInterpolator.profile(forCricketMPR: 1.25)
        let mid = BotSkillProfileInterpolator.profile(forCricketMPR: 1.55)
        let high = BotSkillProfileInterpolator.profile(forCricketMPR: 2.45)
        #expect(mid.cricket.hitChances.triple > low.cricket.hitChances.triple)
        #expect(high.cricket.hitChances.triple > mid.cricket.hitChances.triple)
    }

    @Test
    func x01ExtrapolationBelowVeryEasyWhenUnclamped() {
        let clamped = BotSkillProfileInterpolator.profile(forX01Average: 5, clampToTierRange: true)
        let extrapolated = BotSkillProfileInterpolator.profile(forX01Average: 5, clampToTierRange: false)
        #expect(extrapolated.x01.scoringVisitMax <= clamped.x01.scoringVisitMax)
    }

    @Test
    func x01ExtrapolationAboveProWhenUnclamped() {
        let pro = BotSkillProfileInterpolator.profile(forX01Average: 88, clampToTierRange: true)
        let beyond = BotSkillProfileInterpolator.profile(forX01Average: 100, clampToTierRange: false)
        #expect(beyond.x01.hitChances.triple >= pro.x01.hitChances.triple)
    }

    @Test
    func cricketExtrapolationBelowVeryEasyWhenUnclamped() {
        let clamped = BotSkillProfileInterpolator.profile(forCricketMPR: 0.2, clampToTierRange: true)
        let extrapolated = BotSkillProfileInterpolator.profile(forCricketMPR: 0.2, clampToTierRange: false)
        #expect(extrapolated.cricket.hitChances.triple <= clamped.cricket.hitChances.triple)
    }

    @Test
    func interpolatedProfilePreservesScoringBehaviorTier() {
        let lowerTier = BotSkillProfileInterpolator.profile(forX01Average: 30)
        let upperTier = BotSkillProfileInterpolator.profile(forX01Average: 70)
        #expect(!lowerTier.x01.scoringBehaviorTierRaw.isEmpty)
        #expect(!upperTier.x01.scoringBehaviorTierRaw.isEmpty)
    }

    @Test
    func x01ProfilesAcrossRangeStayWithinSensibleBounds() {
        for average in stride(from: 20.0, through: 88.0, by: 4.0) {
            let profile = BotSkillProfileInterpolator.profile(forX01Average: average)
            #expect(profile.x01.hitChances.single >= 0)
            #expect(profile.x01.hitChances.single <= 1)
            #expect(profile.x01.hitChances.triple >= 0)
            #expect(profile.x01.hitChances.triple <= 1)
            #expect(profile.x01.scoringVisitMin <= profile.x01.scoringVisitMax)
        }
    }

    @Test
    func cricketProfilesAcrossRangeStayWithinSensibleBounds() {
        for mpr in stride(from: 0.85, through: 3.05, by: 0.2) {
            let profile = BotSkillProfileInterpolator.profile(forCricketMPR: mpr)
            #expect(profile.cricket.hitChances.single >= 0)
            #expect(profile.cricket.hitChances.single <= 1)
            #expect(profile.cricket.wrongBedChance >= 0)
            #expect(profile.cricket.wrongBedChance <= 1)
        }
    }

    @Test
    func midpointInterpolationUsesRoundedIntegers() {
        let low = BotDifficulty.easy.skillProfile
        let high = BotDifficulty.medium.skillProfile
        let mid = BotSkillProfileInterpolator.profile(forX01Average: 45)
        let expectedMin = min(low.x01.scoringVisitMin, high.x01.scoringVisitMin)
        let expectedMax = max(low.x01.scoringVisitMax, high.x01.scoringVisitMax)
        #expect(mid.x01.scoringVisitMin >= expectedMin)
        #expect(mid.x01.scoringVisitMax <= expectedMax)
    }

    private func approxEqual(_ lhs: Double, _ rhs: Double, tolerance: Double = 0.000_001) -> Bool {
        abs(lhs - rhs) <= tolerance
    }

    private func x01Anchor(for difficulty: BotDifficulty) -> Double {
        switch difficulty {
        case .veryEasy: 20
        case .easy: 29
        case .medium: 61
        case .hard: 75
        case .pro: 88
        }
    }

    private func cricketAnchor(for difficulty: BotDifficulty) -> Double {
        switch difficulty {
        case .veryEasy: 0.85
        case .easy: 1.25
        case .medium: 1.85
        case .hard: 2.45
        case .pro: 3.05
        }
    }
}
