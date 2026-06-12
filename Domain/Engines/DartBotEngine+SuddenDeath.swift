import Foundation

extension DartBotEngine {
    /// Generates a 3-dart visit for a Sudden Death bot turn.
    ///
    /// The mode is score-only (no specific target segment), so the bot aims at
    /// high-value segments with a probability of hitting triples scaled by the
    /// skill profile.  This mirrors the general scoring strategy used in X01 bot
    /// turns, stripped of checkout logic.
    public static func generateSuddenDeathTurn(
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> [DartInput] {
        var darts: [DartInput] = []
        while darts.count < 3 {
            let dart = scoringDart(profile: profile, rng: &rng)
            darts.append(dart)
        }
        return darts
    }

    // MARK: - Private helpers

    private static func scoringDart(
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        // Pick target segment: prefer 20, occasionally 19 for realism.
        let segment = Double.random(in: 0 ... 1, using: &rng) < 0.75 ? 20 : 19
        let prefersTriple = Double.random(in: 0 ... 1, using: &rng) < profile.x01.triplePreference
        let intendedMultiplier: DartMultiplier = prefersTriple ? .triple : .single
        let hitChance: Double
        switch intendedMultiplier {
        case .single: hitChance = profile.x01.hitChances.single
        case .double: hitChance = profile.x01.hitChances.double
        case .triple: hitChance = profile.x01.hitChances.triple
        }

        if Double.random(in: 0 ... 1, using: &rng) < hitChance {
            return DartInput(multiplier: intendedMultiplier, segment: .oneToTwenty(segment))
        }
        // Miss: off-board or adjacent segment.
        if Double.random(in: 0 ... 1, using: &rng) < profile.x01.offBoardMissChance {
            return DartInput(multiplier: .single, segment: .miss, isMiss: true)
        }
        let adjacent = Bool.random(using: &rng)
            ? max(1, segment - 1)
            : min(20, segment + 1)
        return DartInput(multiplier: .single, segment: .oneToTwenty(adjacent))
    }
}
