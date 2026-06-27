import Foundation

extension DartBotEngine {
    public static func generateFleetHuntDart(
        callCell: FleetBoardCell,
        profile: BotSkillProfile,
        callMode: FleetCallMode,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        if callMode == .callOnly {
            return DartInput(multiplier: .single, segment: .miss, isMiss: true)
        }
        switch callCell {
        case let .segment(value):
            return resolveFleetSegmentDart(segmentValue: value, profile: profile, rng: &rng)
        case .bull:
            return resolveFleetBullDart(profile: profile, rng: &rng)
        }
    }

    private static func resolveFleetSegmentDart(
        segmentValue: Int,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        let tier = profile.x01.scoringBehaviorTier
        let intended: DartInput
        if tier == .veryEasy || tier == .easy {
            intended = DartInput(multiplier: .single, segment: .oneToTwenty(segmentValue))
            return resolveSingleOnSegment(segment: segmentValue, profile: profile, rng: &rng)
        }
        if Double.random(in: 0 ... 1, using: &rng) < profile.cricket.tripleOnOpenChance {
            intended = DartInput(multiplier: .triple, segment: .oneToTwenty(segmentValue))
        } else if Double.random(in: 0 ... 1, using: &rng) < profile.cricket.doubleOnOpenChance {
            intended = DartInput(multiplier: .double, segment: .oneToTwenty(segmentValue))
        } else {
            intended = DartInput(multiplier: .single, segment: .oneToTwenty(segmentValue))
        }
        return resolveMultiplierOnSegment(
            intended: intended,
            targetSegment: segmentValue,
            profile: profile,
            rng: &rng
        )
    }

    private static func resolveFleetBullDart(
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        if Double.random(in: 0 ... 1, using: &rng) < profile.cricket.innerBullAimChance {
            return DartInput(multiplier: .single, segment: .innerBull)
        }
        if Double.random(in: 0 ... 1, using: &rng) < profile.cricket.hitChances.single {
            return DartInput(multiplier: .single, segment: .outerBull)
        }
        if Double.random(in: 0 ... 1, using: &rng) < profile.cricket.offBoardMissChance {
            return DartInput(multiplier: .single, segment: .miss, isMiss: true)
        }
        return DartInput(multiplier: .single, segment: .outerBull)
    }
}
