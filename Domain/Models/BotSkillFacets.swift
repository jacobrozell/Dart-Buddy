import Foundation

public struct CustomBotFacetOverrides: Codable, Equatable, Sendable {
    public var x01: X01SkillFacet?
    public var cricket: CricketSkillFacet?
    public var aim: AimSkillFacet?

    public init(x01: X01SkillFacet? = nil, cricket: CricketSkillFacet? = nil, aim: AimSkillFacet? = nil) {
        self.x01 = x01
        self.cricket = cricket
        self.aim = aim
    }

    public mutating func apply(to profile: inout BotSkillProfile) {
        x01?.apply(to: &profile)
        cricket?.apply(to: &profile)
        aim?.apply(to: &profile)
    }

    public static func extract(from profile: BotSkillProfile) -> CustomBotFacetOverrides {
        CustomBotFacetOverrides(
            x01: X01SkillFacet.extract(from: profile),
            cricket: CricketSkillFacet.extract(from: profile),
            aim: AimSkillFacet.extract(from: profile)
        )
    }
}

public struct X01SkillFacet: Codable, Equatable, Sendable {
    static let supportedTemplates: Set<GameplayUITemplate> = [
        .checkoutScore, .inningPoints, .livesElimination, .sequenceProgress,
        .soloChallenge, .phaseRace, .boardState, .roleSplit
    ]

    public var scoringVisitMin: Int?
    public var scoringVisitMax: Int?
    public var singleHitChance: Double?
    public var doubleHitChance: Double?
    public var tripleHitChance: Double?
    public var checkoutAttemptChance: Double?
    public var offBoardMissChance: Double?
    public var riskyBustChance: Double?
    public var triplePreference: Double?
    public var checkInHitBoost: Double?
    public var innerBullAimChance: Double?
    public var masterInTripleOpenerChance: Double?

    public mutating func apply(to profile: inout BotSkillProfile) {
        let x01 = profile.x01
        profile = BotSkillProfile(
            x01: .init(
                scoringVisitMin: scoringVisitMin ?? x01.scoringVisitMin,
                scoringVisitMax: scoringVisitMax ?? x01.scoringVisitMax,
                hitChances: .init(
                    single: singleHitChance ?? x01.hitChances.single,
                    double: doubleHitChance ?? x01.hitChances.double,
                    triple: tripleHitChance ?? x01.hitChances.triple
                ),
                checkoutAttemptChance: checkoutAttemptChance ?? x01.checkoutAttemptChance,
                offBoardMissChance: offBoardMissChance ?? x01.offBoardMissChance,
                riskyBustChance: riskyBustChance ?? x01.riskyBustChance,
                triplePreference: triplePreference ?? x01.triplePreference,
                checkInHitBoost: checkInHitBoost ?? x01.checkInHitBoost,
                innerBullAimChance: innerBullAimChance ?? x01.innerBullAimChance,
                masterInTripleOpenerChance: masterInTripleOpenerChance ?? x01.masterInTripleOpenerChance,
                safeRemainingSingleOut: x01.safeRemainingSingleOut,
                safeRemainingDoubleOut: x01.safeRemainingDoubleOut,
                safeRemainingMasterOut: x01.safeRemainingMasterOut,
                scoringBehaviorTierRaw: x01.scoringBehaviorTierRaw
            ),
            cricket: profile.cricket
        )
    }

    public static func extract(from profile: BotSkillProfile) -> X01SkillFacet {
        let x01 = profile.x01
        return X01SkillFacet(
            scoringVisitMin: x01.scoringVisitMin,
            scoringVisitMax: x01.scoringVisitMax,
            singleHitChance: x01.hitChances.single,
            doubleHitChance: x01.hitChances.double,
            tripleHitChance: x01.hitChances.triple,
            checkoutAttemptChance: x01.checkoutAttemptChance,
            offBoardMissChance: x01.offBoardMissChance,
            riskyBustChance: x01.riskyBustChance,
            triplePreference: x01.triplePreference,
            checkInHitBoost: x01.checkInHitBoost,
            innerBullAimChance: x01.innerBullAimChance,
            masterInTripleOpenerChance: x01.masterInTripleOpenerChance
        )
    }
}

public struct CricketSkillFacet: Codable, Equatable, Sendable {
    static let supportedTemplates: Set<GameplayUITemplate> = [
        .markBoard, .inningPoints, .livesElimination
    ]

    public var singleHitChance: Double?
    public var doubleHitChance: Double?
    public var tripleHitChance: Double?
    public var offBoardMissChance: Double?
    public var wrongBedChance: Double?

    public mutating func apply(to profile: inout BotSkillProfile) {
        let cricket = profile.cricket
        profile = BotSkillProfile(
            x01: profile.x01,
            cricket: .init(
                hitChances: .init(
                    single: singleHitChance ?? cricket.hitChances.single,
                    double: doubleHitChance ?? cricket.hitChances.double,
                    triple: tripleHitChance ?? cricket.hitChances.triple
                ),
                offBoardMissChance: offBoardMissChance ?? cricket.offBoardMissChance,
                wrongBedChance: wrongBedChance ?? cricket.wrongBedChance,
                innerBullAimChance: cricket.innerBullAimChance,
                tripleOnOpenChance: cricket.tripleOnOpenChance,
                doubleOnOpenChance: cricket.doubleOnOpenChance
            )
        )
    }

    public static func extract(from profile: BotSkillProfile) -> CricketSkillFacet {
        let cricket = profile.cricket
        return CricketSkillFacet(
            singleHitChance: cricket.hitChances.single,
            doubleHitChance: cricket.hitChances.double,
            tripleHitChance: cricket.hitChances.triple,
            offBoardMissChance: cricket.offBoardMissChance,
            wrongBedChance: cricket.wrongBedChance
        )
    }
}

public struct AimSkillFacet: Codable, Equatable, Sendable {
    static let supportedTemplates: Set<GameplayUITemplate> = [
        .inningPoints, .livesElimination, .sequenceProgress
    ]

    public var scoringBehaviorTier: BotDifficulty?
    public var tripleOnOpenChance: Double?
    public var doubleOnOpenChance: Double?

    public mutating func apply(to profile: inout BotSkillProfile) {
        var updated = profile
        if let scoringBehaviorTier {
            updated = updated.withScoringBehaviorTier(scoringBehaviorTier)
        }
        let cricket = updated.cricket
        updated = BotSkillProfile(
            x01: updated.x01,
            cricket: .init(
                hitChances: cricket.hitChances,
                offBoardMissChance: cricket.offBoardMissChance,
                wrongBedChance: cricket.wrongBedChance,
                innerBullAimChance: cricket.innerBullAimChance,
                tripleOnOpenChance: tripleOnOpenChance ?? cricket.tripleOnOpenChance,
                doubleOnOpenChance: doubleOnOpenChance ?? cricket.doubleOnOpenChance
            )
        )
        profile = updated
    }

    public static func extract(from profile: BotSkillProfile) -> AimSkillFacet {
        AimSkillFacet(
            scoringBehaviorTier: profile.x01.scoringBehaviorTier,
            tripleOnOpenChance: profile.cricket.tripleOnOpenChance,
            doubleOnOpenChance: profile.cricket.doubleOnOpenChance
        )
    }
}
