import Foundation

extension DartBotEngine {
    /// Generates a three-dart visit for the current Chase the Dragon step, advancing through
    /// successive dragon steps when qualifying hits land.
    public static func generateChaseTheDragonTurn(
        stepIndex: Int,
        lapsCompleted: Int,
        lapsNeeded: Int,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> [DartInput] {
        var darts: [DartInput] = []
        var currentStepIndex = stepIndex
        var currentLapsCompleted = lapsCompleted

        while darts.count < 3 {
            guard currentLapsCompleted < lapsNeeded,
                  currentStepIndex < ChaseTheDragonEngine.dragonSequence.count else {
                darts.append(DartInput(multiplier: .single, segment: .miss, isMiss: true))
                continue
            }

            let step = ChaseTheDragonEngine.dragonSequence[currentStepIndex]
            let intended = intendedDart(for: step)
            let resolved = resolveDragonDart(intended: intended, step: step, profile: profile, rng: &rng)
            darts.append(resolved)

            if step.isQualifyingHit(resolved) {
                currentStepIndex += 1
                if currentStepIndex == ChaseTheDragonEngine.stepsPerLap {
                    currentLapsCompleted += 1
                    if currentLapsCompleted >= lapsNeeded { continue }
                    currentStepIndex = 0
                }
            }
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

        if Double.random(in: 0 ... 1, using: &rng) < profile.cricket.offBoardMissChance {
            return DartInput(multiplier: .single, segment: .miss, isMiss: true)
        }

        switch step {
        case let .treble(number):
            return DartInput(
                multiplier: .single,
                segment: .oneToTwenty(adjacentClockSegment(to: number, rng: &rng))
            )
        case .outerBull, .innerBull:
            let face = [16, 17, 18, 19, 20].randomElement(using: &rng) ?? 20
            return DartInput(multiplier: .single, segment: .oneToTwenty(face))
        }
    }
}
