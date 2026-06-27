import Foundation

extension DartBotEngine {
    /// Generates three darts for a 51 By 5's bot turn.
    ///
    /// All tiers aim at the same scoring segment so difficulty shows up in multiplier
    /// choice and hit resolution rather than different target numbers.
    public static func generateFiftyOneByFivesTurn(
        state: FiftyOneByFivesState,
        playerIndex: Int,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> [DartInput] {
        _ = state
        _ = playerIndex
        let tier = profile.x01.scoringBehaviorTier
        let targetSegment = 20

        var darts: [DartInput] = []
        while darts.count < 3 {
            let intended: DartInput
            if tier == .veryEasy || tier == .easy {
                intended = DartInput(multiplier: .single, segment: .oneToTwenty(targetSegment))
            } else if Double.random(in: 0 ... 1, using: &rng) < profile.cricket.tripleOnOpenChance {
                intended = DartInput(multiplier: .triple, segment: .oneToTwenty(targetSegment))
            } else if Double.random(in: 0 ... 1, using: &rng) < profile.cricket.doubleOnOpenChance {
                intended = DartInput(multiplier: .double, segment: .oneToTwenty(targetSegment))
            } else {
                intended = DartInput(multiplier: .single, segment: .oneToTwenty(targetSegment))
            }

            let resolved = resolveFiftyOneByFivesDart(
                intended: intended,
                profile: profile,
                rng: &rng
            )
            darts.append(resolved)
        }
        return darts
    }

    // MARK: - Private helpers

    private static func resolveFiftyOneByFivesDart(
        intended: DartInput,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        guard !intended.isMiss else { return intended }

        let roll = Double.random(in: 0 ... 1, using: &rng)
        let hitChance = fiftyOneByFiveHitChance(intended: intended, profile: profile)
        if roll < hitChance {
            return intended
        }

        let missRoll = Double.random(in: 0 ... 1, using: &rng)
        if missRoll < profile.cricket.offBoardMissChance {
            return DartInput(multiplier: .single, segment: .miss, isMiss: true)
        }
        if case let .oneToTwenty(value) = intended.segment {
            return DartInput(
                multiplier: .single,
                segment: .oneToTwenty(adjacentClockSegment(to: value, rng: &rng))
            )
        }
        return DartInput(multiplier: .single, segment: .miss, isMiss: true)
    }

    private static func fiftyOneByFiveHitChance(
        intended: DartInput,
        profile: BotSkillProfile
    ) -> Double {
        let base: Double
        switch intended.multiplier {
        case .single:
            base = profile.x01.hitChances.single
        case .double:
            base = profile.x01.hitChances.double
        case .triple:
            base = profile.x01.hitChances.triple
        default:
            base = profile.cricket.hitChances.single
        }
        return boostedCricketHitChance(base: base, profile: profile)
    }
}
