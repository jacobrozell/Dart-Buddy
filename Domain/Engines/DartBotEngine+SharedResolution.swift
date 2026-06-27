import Foundation

extension DartBotEngine {
    static func tierAccuracyMultiplier(for tier: BotDifficulty) -> Double {
        switch tier {
        case .veryEasy: 0.80
        case .easy: 0.88
        case .medium: 0.96
        case .hard: 1.04
        case .pro: 1.12
        }
    }

    static func boostedCricketHitChance(
        base: Double,
        profile: BotSkillProfile
    ) -> Double {
        min(0.95, base * tierAccuracyMultiplier(for: profile.x01.scoringBehaviorTier))
    }

    /// Resolves a single on `segment` with off-board and clock-adjacent misses.
    static func resolveSingleOnSegment(
        segment: Int,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        let intended = DartInput(multiplier: .single, segment: .oneToTwenty(segment))
        guard !intended.isMiss else { return intended }

        if Double.random(in: 0 ... 1, using: &rng) < boostedCricketHitChance(base: profile.cricket.hitChances.single, profile: profile) {
            return intended
        }
        if Double.random(in: 0 ... 1, using: &rng) < profile.cricket.offBoardMissChance {
            return DartInput(multiplier: .single, segment: .miss, isMiss: true)
        }
        let adjacent = adjacentClockSegment(to: segment, rng: &rng)
        return DartInput(multiplier: .single, segment: .oneToTwenty(adjacent))
    }

    /// Resolves an intended multiplier dart on a segment using baseball-style partial hits.
    static func resolveMultiplierOnSegment(
        intended: DartInput,
        targetSegment: Int,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        guard intended.isMiss == false else { return intended }

        let roll = Double.random(in: 0 ... 1, using: &rng)
        let hitChance = min(0.95, boostedCricketHitChance(
            base: profile.cricketHitChance(intendedMultiplier: intended.multiplier),
            profile: profile
        ))
        if roll < hitChance {
            return intended
        }
        if Double.random(in: 0 ... 1, using: &rng) < profile.cricket.offBoardMissChance {
            return DartInput(multiplier: .single, segment: .miss, isMiss: true)
        }
        if case let .oneToTwenty(value) = intended.segment, value == targetSegment,
           let partial = baseballPartialHitOnTarget(intended: intended, profile: profile, rng: &rng) {
            return partial
        }
        let adjacent = adjacentClockSegment(to: targetSegment, rng: &rng)
        return DartInput(multiplier: .single, segment: .oneToTwenty(adjacent))
    }

    static func followTheLeaderDartInput(for target: FollowTheLeaderTargetArea) -> DartInput {
        switch target.ring {
        case .single:
            return DartInput(multiplier: .single, segment: .oneToTwenty(target.segment))
        case .double:
            return DartInput(multiplier: .double, segment: .oneToTwenty(target.segment))
        case .triple:
            return DartInput(multiplier: .triple, segment: .oneToTwenty(target.segment))
        case .outerBull:
            return DartInput(multiplier: .single, segment: .outerBull)
        case .innerBull:
            return DartInput(multiplier: .single, segment: .innerBull)
        }
    }

    static func resolveFollowTheLeaderDart(
        intended: DartInput,
        target: FollowTheLeaderTargetArea,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        switch target.ring {
        case .single:
            return resolveSingleOnSegment(segment: target.segment, profile: profile, rng: &rng)
        case .double, .triple:
            return resolveMultiplierOnSegment(
                intended: intended,
                targetSegment: target.segment,
                profile: profile,
                rng: &rng
            )
        case .outerBull, .innerBull:
            return resolveBullTargetDart(intended: intended, profile: profile, rng: &rng)
        }
    }

    static func resolveBullTargetDart(
        intended: DartInput,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        guard intended.isMiss == false else { return intended }

        if Double.random(in: 0 ... 1, using: &rng) < profile.cricket.hitChances.single {
            return intended
        }
        if Double.random(in: 0 ... 1, using: &rng) < profile.cricket.offBoardMissChance {
            return DartInput(multiplier: .single, segment: .miss, isMiss: true)
        }
        if intended.segment == .innerBull {
            return DartInput(multiplier: .single, segment: .outerBull)
        }
        let face = [16, 17, 18, 19, 20].randomElement(using: &rng) ?? 20
        return DartInput(multiplier: .single, segment: .oneToTwenty(face))
    }

    static func preferredOpeningLeaderTarget(
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> FollowTheLeaderTargetArea {
        switch profile.x01.scoringBehaviorTier {
        case .veryEasy:
            return FollowTheLeaderTargetArea(segment: 20, ring: .single)
        case .easy:
            return FollowTheLeaderTargetArea(segment: Int.random(in: 16 ... 20, using: &rng), ring: .single)
        case .medium:
            return FollowTheLeaderTargetArea(segment: 20, ring: .double)
        case .hard:
            if Double.random(in: 0 ... 1, using: &rng) < 0.35 {
                return FollowTheLeaderTargetArea(segment: 25, ring: .outerBull)
            }
            return FollowTheLeaderTargetArea(segment: 20, ring: .double)
        case .pro:
            if Double.random(in: 0 ... 1, using: &rng) < profile.cricket.innerBullAimChance {
                return FollowTheLeaderTargetArea(segment: 25, ring: .innerBull)
            }
            return FollowTheLeaderTargetArea(segment: 20, ring: .triple)
        }
    }

    static func preferredSpareLeaderTarget(
        after current: FollowTheLeaderTargetArea,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> FollowTheLeaderTargetArea {
        let segment = [18, 19, 20, 16, 17].randomElement(using: &rng) ?? 20
        switch profile.x01.scoringBehaviorTier {
        case .veryEasy, .easy:
            return FollowTheLeaderTargetArea(segment: segment, ring: .single)
        case .medium:
            return FollowTheLeaderTargetArea(segment: segment, ring: .double)
        case .hard, .pro:
            return FollowTheLeaderTargetArea(segment: segment, ring: .triple)
        }
    }
}
