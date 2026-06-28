import Foundation

/// Maps target X01 3-dart average or Cricket MPR to a continuous `BotSkillProfile`.
public enum BotSkillProfileInterpolator {
    static let x01TierAverages: [(BotDifficulty, Double)] = [
        (.veryEasy, 20),
        (.easy, 29),
        (.medium, 61),
        (.hard, 75),
        (.pro, 88)
    ]

    static let cricketTierMPR: [(BotDifficulty, Double)] = [
        (.veryEasy, 0.85),
        (.easy, 1.25),
        (.medium, 1.85),
        (.hard, 2.45),
        (.pro, 3.05)
    ]

    /// Player-facing X01 3-dart average anchor for a preset tier (custom-bot slider scale).
    public static func referenceX01Average(for difficulty: BotDifficulty) -> Double {
        x01TierAverages.first { $0.0 == difficulty }?.1 ?? x01TierAverages[0].1
    }

    /// Player-facing Cricket MPR anchor for a preset tier (custom-bot slider scale).
    public static func referenceCricketMPR(for difficulty: BotDifficulty) -> Double {
        cricketTierMPR.first { $0.0 == difficulty }?.1 ?? cricketTierMPR[0].1
    }

    public static func profile(forX01Average target: Double, clampToTierRange: Bool = true) -> BotSkillProfile {
        profile(for: target, anchors: x01TierAverages, clampToTierRange: clampToTierRange)
    }

    public static func profile(forCricketMPR target: Double, clampToTierRange: Bool = true) -> BotSkillProfile {
        profile(for: target, anchors: cricketTierMPR, clampToTierRange: clampToTierRange)
    }

    private static func profile(
        for target: Double,
        anchors: [(BotDifficulty, Double)],
        clampToTierRange: Bool
    ) -> BotSkillProfile {
        let value: Double
        if clampToTierRange, let lowest = anchors.first?.1, let highest = anchors.last?.1 {
            value = min(max(target, lowest), highest)
        } else {
            value = target
        }
        let (lower, upper, t) = bracket(for: value, anchors: anchors, extrapolate: !clampToTierRange)
        return interpolate(
            from: lower.skillProfile,
            to: upper.skillProfile,
            fraction: t,
            scoringBehaviorTier: t < 0.5 ? lower : upper
        )
    }

    private static func bracket(
        for value: Double,
        anchors: [(BotDifficulty, Double)],
        extrapolate: Bool = false
    ) -> (BotDifficulty, BotDifficulty, Double) {
        guard anchors.count >= 2 else {
            return (anchors[0].0, anchors[0].0, 0)
        }
        if value <= anchors[0].1 {
            if extrapolate, value < anchors[0].1 {
                let low = anchors[0]
                let high = anchors[1]
                let span = high.1 - low.1
                let t = span > 0 ? (value - low.1) / span : 0
                return (low.0, high.0, t)
            }
            return (anchors[0].0, anchors[1].0, 0)
        }
        for index in 0 ..< anchors.count - 1 {
            let low = anchors[index]
            let high = anchors[index + 1]
            if value <= high.1 {
                let span = high.1 - low.1
                let t = span > 0 ? (value - low.1) / span : 0
                return (low.0, high.0, extrapolate ? t : min(1, max(0, t)))
            }
        }
        let last = anchors[anchors.count - 2]
        let top = anchors[anchors.count - 1]
        if extrapolate, value > top.1 {
            let span = top.1 - last.1
            let t = span > 0 ? (value - last.1) / span : 1
            return (last.0, top.0, t)
        }
        return (last.0, top.0, 1)
    }

    private static func interpolate(
        from lower: BotSkillProfile,
        to upper: BotSkillProfile,
        fraction t: Double,
        scoringBehaviorTier: BotDifficulty
    ) -> BotSkillProfile {
        BotSkillProfile(
            x01: .init(
                scoringVisitMin: lerpInt(lower.x01.scoringVisitMin, upper.x01.scoringVisitMin, t),
                scoringVisitMax: lerpInt(lower.x01.scoringVisitMax, upper.x01.scoringVisitMax, t),
                hitChances: lerpHits(lower.x01.hitChances, upper.x01.hitChances, t),
                checkoutAttemptChance: lerp(lower.x01.checkoutAttemptChance, upper.x01.checkoutAttemptChance, t),
                offBoardMissChance: lerp(lower.x01.offBoardMissChance, upper.x01.offBoardMissChance, t),
                riskyBustChance: lerp(lower.x01.riskyBustChance, upper.x01.riskyBustChance, t),
                triplePreference: lerp(lower.x01.triplePreference, upper.x01.triplePreference, t),
                checkInHitBoost: lerp(lower.x01.checkInHitBoost, upper.x01.checkInHitBoost, t),
                innerBullAimChance: lerp(lower.x01.innerBullAimChance, upper.x01.innerBullAimChance, t),
                masterInTripleOpenerChance: lerp(
                    lower.x01.masterInTripleOpenerChance,
                    upper.x01.masterInTripleOpenerChance,
                    t
                ),
                safeRemainingSingleOut: lerpInt(lower.x01.safeRemainingSingleOut, upper.x01.safeRemainingSingleOut, t),
                safeRemainingDoubleOut: lerpInt(lower.x01.safeRemainingDoubleOut, upper.x01.safeRemainingDoubleOut, t),
                safeRemainingMasterOut: lerpInt(lower.x01.safeRemainingMasterOut, upper.x01.safeRemainingMasterOut, t),
                scoringBehaviorTierRaw: scoringBehaviorTier.rawValue
            ),
            cricket: .init(
                hitChances: lerpHits(lower.cricket.hitChances, upper.cricket.hitChances, t),
                offBoardMissChance: lerp(lower.cricket.offBoardMissChance, upper.cricket.offBoardMissChance, t),
                wrongBedChance: lerp(lower.cricket.wrongBedChance, upper.cricket.wrongBedChance, t),
                innerBullAimChance: lerp(lower.cricket.innerBullAimChance, upper.cricket.innerBullAimChance, t),
                tripleOnOpenChance: lerp(lower.cricket.tripleOnOpenChance, upper.cricket.tripleOnOpenChance, t),
                doubleOnOpenChance: lerp(lower.cricket.doubleOnOpenChance, upper.cricket.doubleOnOpenChance, t)
            )
        )
    }

    private static func lerp(_ a: Double, _ b: Double, _ t: Double) -> Double {
        a + (b - a) * t
    }

    private static func lerpInt(_ a: Int, _ b: Int, _ t: Double) -> Int {
        Int((Double(a) + Double(b - a) * t).rounded())
    }

    private static func lerpHits(
        _ a: BotSkillProfile.HitChances,
        _ b: BotSkillProfile.HitChances,
        _ t: Double
    ) -> BotSkillProfile.HitChances {
        .init(
            single: lerp(a.single, b.single, t),
            double: lerp(a.double, b.double, t),
            triple: lerp(a.triple, b.triple, t)
        )
    }

    /// Highest preset tier whose anchor value is ≤ `metric` (achievement ladder floor).
    public static func achievementTierFloor(forX01Average average: Double) -> BotDifficulty {
        achievementTierFloor(metric: average, anchors: x01TierAverages)
    }

    /// Highest preset tier whose anchor value is ≤ `metric` (achievement ladder floor).
    public static func achievementTierFloor(forCricketMPR mpr: Double) -> BotDifficulty {
        achievementTierFloor(metric: mpr, anchors: cricketTierMPR)
    }

    private static func achievementTierFloor(
        metric: Double,
        anchors: [(BotDifficulty, Double)]
    ) -> BotDifficulty {
        guard let first = anchors.first else { return .veryEasy }
        var floor = first.0
        for (tier, anchorValue) in anchors where metric >= anchorValue {
            floor = tier
        }
        return floor
    }
}
