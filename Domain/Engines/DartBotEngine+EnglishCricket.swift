import Foundation

extension DartBotEngine {
    // MARK: - English Cricket

    /// Generates a three-dart batter visit for an English Cricket bot.
    ///
    /// The batter can throw at any segment; the bot picks high-value scoring darts
    /// proportional to its difficulty profile so expected runs exceed the 40-point
    /// threshold consistently at higher tiers.
    ///
    /// - Parameters:
    ///   - role: Whether this bot is batting or bowling this turn.
    ///   - profile: The bot's skill profile.
    ///   - rng: Random number source.
    /// - Returns: Exactly 3 dart inputs appropriate for the given role.
    public static func generateEnglishCricketTurn(
        role: EnglishCricketRole,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> [DartInput] {
        switch role {
        case .batter:
            return generateEnglishCricketBatterTurn(profile: profile, rng: &rng)
        case .bowler:
            return generateEnglishCricketBowlerTurn(profile: profile, rng: &rng)
        }
    }

    // MARK: - Batter

    /// The batter aims for high-value segments to maximise runs above the 40-point threshold.
    private static func generateEnglishCricketBatterTurn(
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> [DartInput] {
        var darts: [DartInput] = []
        while darts.count < 3 {
            let intended = englishCricketBatterDart(profile: profile, rng: &rng)
            let resolved = resolveEnglishCricketBatterDart(intended: intended, profile: profile, rng: &rng)
            darts.append(resolved)
        }
        return darts
    }

    /// Selects the intended scoring dart for a batter visit.
    private static func englishCricketBatterDart(
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        // Aim for T20 with tier-appropriate probability, then D20, then S20.
        if Double.random(in: 0 ... 1, using: &rng) < profile.x01.triplePreference {
            return DartInput(multiplier: .triple, segment: .oneToTwenty(20))
        }
        if Double.random(in: 0 ... 1, using: &rng) < profile.x01.triplePreference {
            return DartInput(multiplier: .double, segment: .oneToTwenty(20))
        }
        // Lower tiers aim S20; better tiers include T19 / T18 as fallbacks.
        let tier = profile.x01.scoringBehaviorTier
        switch tier {
        case .veryEasy, .easy:
            return DartInput(multiplier: .single, segment: .oneToTwenty(20))
        case .medium:
            let segment = [20, 19, 18].randomElement(using: &rng) ?? 20
            return DartInput(multiplier: .single, segment: .oneToTwenty(segment))
        case .hard, .pro:
            // Aim triple on a secondary segment with residual probability.
            if Double.random(in: 0 ... 1, using: &rng) < 0.40 {
                let segment = [19, 18, 17].randomElement(using: &rng) ?? 19
                return DartInput(multiplier: .triple, segment: .oneToTwenty(segment))
            }
            let segment = [20, 19].randomElement(using: &rng) ?? 20
            return DartInput(multiplier: .single, segment: .oneToTwenty(segment))
        }
    }

    /// Resolves a batter dart using X01 hit probabilities.
    private static func resolveEnglishCricketBatterDart(
        intended: DartInput,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        guard !intended.isMiss else { return intended }

        let roll = Double.random(in: 0 ... 1, using: &rng)
        let hitChance = min(0.90, profile.x01HitChance(intendedMultiplier: intended.multiplier))
        if roll < hitChance {
            return intended
        }

        if Double.random(in: 0 ... 1, using: &rng) < profile.cricket.offBoardMissChance {
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

    // MARK: - Bowler

    /// The bowler aims at the bull (outer or inner) to take wickets.
    /// Uses cricket hit-chance parameters since bull aiming is a cricket-style skill.
    private static func generateEnglishCricketBowlerTurn(
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> [DartInput] {
        var darts: [DartInput] = []
        while darts.count < 3 {
            let intended = englishCricketBowlerDart(profile: profile, rng: &rng)
            let resolved = resolveCricketBullDart(intended: intended, profile: profile, rng: &rng)
            darts.append(resolved)
        }
        return darts
    }

    /// Chooses inner vs outer bull based on the bot's aim preference.
    private static func englishCricketBowlerDart(
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        if Double.random(in: 0 ... 1, using: &rng) < profile.cricket.innerBullAimChance {
            return DartInput(multiplier: .single, segment: .innerBull)
        }
        return DartInput(multiplier: .single, segment: .outerBull)
    }

    /// Resolves a bull-aimed dart using cricket hit probabilities.
    /// On a miss the dart lands on a random number segment (not a bull).
    private static func resolveCricketBullDart(
        intended: DartInput,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        guard !intended.isMiss else { return intended }

        let roll = Double.random(in: 0 ... 1, using: &rng)
        let hitChance = min(0.90, profile.cricketHitChance(intendedMultiplier: .single))
        if roll < hitChance {
            return intended
        }

        if Double.random(in: 0 ... 1, using: &rng) < profile.cricket.offBoardMissChance {
            return DartInput(multiplier: .single, segment: .miss, isMiss: true)
        }

        // Missed the bull — land on a random number segment.
        let face = Int.random(in: 1 ... 20, using: &rng)
        return DartInput(multiplier: .single, segment: .oneToTwenty(face))
    }
}
