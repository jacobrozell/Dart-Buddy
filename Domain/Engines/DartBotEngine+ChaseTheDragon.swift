import Foundation

extension DartBotEngine {
    /// Generates a three-dart visit for the current Chase the Dragon step.
    ///
    /// The bot aims at the required target for the current `stepIndex` position in
    /// the dragon sequence. Because only the **first** qualifying hit advances the
    /// player, all three darts aim at the same step — matching how a human would
    /// throw. Hit resolution reuses the cricket-profile probability tables since
    /// the required shots (trebles, bull rings) map directly onto those hit-chance
    /// parameters.
    public static func generateChaseTheDragonTurn(
        stepIndex: Int,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> [DartInput] {
        guard stepIndex < ChaseTheDragonEngine.dragonSequence.count else {
            return [
                DartInput(multiplier: .single, segment: .miss, isMiss: true),
                DartInput(multiplier: .single, segment: .miss, isMiss: true),
                DartInput(multiplier: .single, segment: .miss, isMiss: true),
            ]
        }
        let step = ChaseTheDragonEngine.dragonSequence[stepIndex]
        var darts: [DartInput] = []
        while darts.count < 3 {
            let intended = intendedDart(for: step)
            let resolved = resolveDragonDart(intended: intended, step: step, profile: profile, rng: &rng)
            darts.append(resolved)
        }
        return darts
    }

    // MARK: - Private helpers

    private static func intendedDart(for step: ChaseTheDragonEngine.DragonStep) -> DartInput {
        switch step {
        case let .treble(number):
            return DartInput(multiplier: .triple, segment: .oneToTwenty(number))
        case .outerBull:
            return DartInput(multiplier: .single, segment: .outerBull)
        case .innerBull:
            return DartInput(multiplier: .single, segment: .innerBull)
        }
    }

    /// Resolves an intended dragon dart using the cricket hit-chance profile.
    private static func resolveDragonDart(
        intended: DartInput,
        step: ChaseTheDragonEngine.DragonStep,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        guard !intended.isMiss else { return intended }

        let roll = Double.random(in: 0 ... 1, using: &rng)
        let hitChance = min(0.90, profile.cricketHitChance(intendedMultiplier: intended.multiplier))
        if roll < hitChance {
            return intended
        }

        // Miss: check for off-board.
        if Double.random(in: 0 ... 1, using: &rng) < profile.cricket.offBoardMissChance {
            return DartInput(multiplier: .single, segment: .miss, isMiss: true)
        }

        // Otherwise land on a wrong segment.
        switch step {
        case let .treble(number):
            // Wrong multiplier on the same number, or completely wrong face.
            let wrongFace = Int.random(in: 1 ... 20, using: &rng)
            let face = wrongFace == number ? number % 20 + 1 : wrongFace
            return DartInput(multiplier: .single, segment: .oneToTwenty(face))
        case .outerBull, .innerBull:
            // Missed bull lands on a random number.
            let face = Int.random(in: 1 ... 20, using: &rng)
            return DartInput(multiplier: .single, segment: .oneToTwenty(face))
        }
    }
}
