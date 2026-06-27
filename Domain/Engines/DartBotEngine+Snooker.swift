import Foundation

extension DartBotEngine {
    /// Colour to nominate after potting a red. Harder tiers chase black; easier tiers
    /// sometimes take a lower colour.
    public static func generateSnookerNomination(
        state: SnookerState,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> SnookerColour {
        if state.availableReds.isEmpty {
            return .black
        }
        let tier = profile.x01.scoringBehaviorTier
        if tier == .veryEasy,
           Double.random(in: 0 ... 1, using: &rng) < 0.35 {
            return [.yellow, .green, .brown].randomElement(using: &rng) ?? .yellow
        }
        if tier == .easy,
           Double.random(in: 0 ... 1, using: &rng) < 0.15 {
            return .pink
        }
        return .black
    }

    /// Generates one snooker dart for the current break phase.
    public static func generateSnookerDart(
        state: SnookerState,
        profile: BotSkillProfile,
        nominatedColour: SnookerColour?,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        switch state.phase {
        case .awaitingRed:
            guard let target = preferredSnookerRed(in: state.availableReds) else {
                return DartInput(multiplier: .single, segment: .miss, isMiss: true)
            }
            let intended = DartInput(multiplier: .single, segment: .oneToTwenty(target))
            return resolveSnookerRedDart(
                intended: intended,
                targetSegment: target,
                profile: profile,
                rng: &rng
            )
        case .awaitingNomination:
            let colour = nominatedColour ?? generateSnookerNomination(
                state: state,
                profile: profile,
                rng: &rng
            )
            return resolveSnookerColourDart(colour: colour, profile: profile, rng: &rng)
        case .awaitingColour(let colour):
            return resolveSnookerColourDart(colour: colour, profile: profile, rng: &rng)
        }
    }

    // MARK: - Private helpers

    private static func preferredSnookerRed(in available: Set<Int>) -> Int? {
        available.max()
    }

    private static func resolveSnookerRedDart(
        intended: DartInput,
        targetSegment: Int,
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
        if Double.random(in: 0 ... 1, using: &rng) < profile.cricket.hitChances.double {
            return DartInput(multiplier: .double, segment: .oneToTwenty(targetSegment))
        }
        if Double.random(in: 0 ... 1, using: &rng) < profile.cricket.hitChances.triple {
            return DartInput(multiplier: .triple, segment: .oneToTwenty(targetSegment))
        }
        let adjacent = adjacentClockSegment(to: targetSegment, rng: &rng)
        return DartInput(multiplier: .single, segment: .oneToTwenty(adjacent))
    }

    private static func resolveSnookerColourDart(
        colour: SnookerColour,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        if colour == .black {
            let intended: DartInput
            if Double.random(in: 0 ... 1, using: &rng) < profile.cricket.innerBullAimChance {
                intended = DartInput(multiplier: .single, segment: .innerBull)
            } else {
                intended = DartInput(multiplier: .single, segment: .outerBull)
            }
            return resolveSnookerBullDart(intended: intended, profile: profile, rng: &rng)
        }
        guard let segment = colour.targetSegment else {
            return DartInput(multiplier: .single, segment: .miss, isMiss: true)
        }
        let intended = DartInput(multiplier: .single, segment: .oneToTwenty(segment))
        return resolveSnookerRedDart(
            intended: intended,
            targetSegment: segment,
            profile: profile,
            rng: &rng
        )
    }

    private static func resolveSnookerBullDart(
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
}
