import Foundation

extension DartBotEngine {
    /// Generates three darts for a 51 By 5's bot turn.
    ///
    /// Strategy: the bot aims to produce a 3-dart total that is divisible by 5.
    /// It targets segments whose face values sum cleanly to multiples of 5.
    /// Harder bots aim for higher-value multiples (e.g. triple-20 combos → 180 → 36 pts);
    /// easier bots aim for low reliable totals (e.g. 5 or 15).
    /// Actual dart placement is resolved through the standard X01 hit-chance model,
    /// so misses and wrong-bed results naturally arise from the skill profile.
    public static func generateFiftyOneByFivesTurn(
        state: FiftyOneByFivesState,
        playerIndex: Int,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> [DartInput] {
        // Choose an intended segment whose single value contributes to a divisible-by-5 total.
        // We aim for three darts at multiples-of-5 segments: 5, 10, 15, 20.
        // Higher tiers prefer 20 (triple-20 territory); lower tiers prefer 5.
        let tier = profile.x01.scoringBehaviorTier
        let targetSegment: Int
        switch tier {
        case .veryEasy: targetSegment = 5
        case .easy:     targetSegment = 10
        case .medium:   targetSegment = 15
        case .hard, .pro: targetSegment = 20
        }

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
        let hitChance = min(0.90, profile.cricketHitChance(intendedMultiplier: intended.multiplier))
        if roll < hitChance {
            return intended
        }

        // Miss: board-off or wrong-bed.
        let missRoll = Double.random(in: 0 ... 1, using: &rng)
        if missRoll < profile.cricket.offBoardMissChance {
            return DartInput(multiplier: .single, segment: .miss, isMiss: true)
        }
        // Land on an adjacent segment (±1–3, clamped to 1…20).
        if case let .oneToTwenty(value) = intended.segment {
            let offset = Int.random(in: 1 ... 3, using: &rng) * (Bool.random(using: &rng) ? 1 : -1)
            let adjacent = max(1, min(20, value + offset))
            return DartInput(multiplier: .single, segment: .oneToTwenty(adjacent))
        }
        return DartInput(multiplier: .single, segment: .miss, isMiss: true)
    }
}
