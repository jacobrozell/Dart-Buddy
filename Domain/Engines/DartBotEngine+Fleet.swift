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
        let roll = Double.random(in: 0 ... 1, using: &rng)
        let chances = profile.cricket.hitChances
        if roll < chances.triple * profile.cricket.tripleOnOpenChance {
            return DartInput(multiplier: .triple, segment: .oneToTwenty(segmentValue))
        }
        if roll < chances.triple * profile.cricket.tripleOnOpenChance + chances.double * profile.cricket.doubleOnOpenChance {
            return DartInput(multiplier: .double, segment: .oneToTwenty(segmentValue))
        }
        if roll < chances.single {
            return DartInput(multiplier: .single, segment: .oneToTwenty(segmentValue))
        }
        if Double.random(in: 0 ... 1, using: &rng) < profile.cricket.wrongBedChance {
            let wrong = ([15, 16, 17, 18, 19, 20].filter { $0 != segmentValue }.randomElement(using: &rng)) ?? 20
            return DartInput(multiplier: .single, segment: .oneToTwenty(wrong))
        }
        if Double.random(in: 0 ... 1, using: &rng) < profile.cricket.offBoardMissChance {
            return DartInput(multiplier: .single, segment: .miss, isMiss: true)
        }
        return DartInput(multiplier: .single, segment: .oneToTwenty(segmentValue))
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
