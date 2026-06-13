import Foundation

extension DartBotEngine {
    /// Generates three darts aimed at the current Mulligan target.
    ///
    /// For number targets the bot uses cricket-style mark resolution.
    /// For bull the bot aims with the same inner-bull probability as cricket.
    public static func generateMulliganTurn(
        activeTarget: MulliganSegment,
        marksAlreadyOnTarget: Int,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> [DartInput] {
        var darts: [DartInput] = []
        var remainingMarks = max(0, MulliganEngine.marksToClose - marksAlreadyOnTarget)

        while darts.count < 3 {
            let intended = intendedMulliganDart(
                target: activeTarget,
                remainingMarks: remainingMarks,
                profile: profile,
                rng: &rng
            )
            let resolved = resolveMulliganDart(intended: intended, profile: profile, rng: &rng)
            darts.append(resolved)

            // Track marks to avoid over-aiming once the target is simulated-closed
            let marks = mulliganMarks(for: resolved, target: activeTarget)
            remainingMarks = max(0, remainingMarks - marks)
        }

        return darts
    }

    // MARK: - Private

    private static func intendedMulliganDart(
        target: MulliganSegment,
        remainingMarks: Int,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        switch target {
        case .bull:
            if Double.random(in: 0 ... 1, using: &rng) < profile.cricket.innerBullAimChance {
                return DartInput(multiplier: .single, segment: .innerBull)
            }
            return DartInput(multiplier: .single, segment: .outerBull)

        case let .number(n):
            let tier = profile.x01.scoringBehaviorTier
            if tier == .veryEasy || tier == .easy {
                return DartInput(multiplier: .single, segment: .oneToTwenty(n))
            }
            // Aim for triple while more than one mark is needed; else aim single
            if remainingMarks >= 3,
               Double.random(in: 0 ... 1, using: &rng) < profile.cricket.tripleOnOpenChance {
                return DartInput(multiplier: .triple, segment: .oneToTwenty(n))
            }
            if remainingMarks >= 2,
               Double.random(in: 0 ... 1, using: &rng) < profile.cricket.doubleOnOpenChance {
                return DartInput(multiplier: .double, segment: .oneToTwenty(n))
            }
            return DartInput(multiplier: .single, segment: .oneToTwenty(n))
        }
    }

    /// Resolves an intended Mulligan dart using cricket accuracy curves (same
    /// off-board miss and wrong-bed chances as cricket aiming).
    private static func resolveMulliganDart(
        intended: DartInput,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        guard !intended.isMiss else { return intended }

        let hitChance = min(0.90, profile.cricketHitChance(intendedMultiplier: intended.multiplier))
        if Double.random(in: 0 ... 1, using: &rng) < hitChance {
            return intended
        }

        let missRoll = Double.random(in: 0 ... 1, using: &rng)
        if missRoll < profile.cricket.offBoardMissChance + profile.cricket.wrongBedChance {
            return DartInput(multiplier: .single, segment: .miss, isMiss: true)
        }
        // Partial miss: downgrade multiplier or keep as single miss
        return DartInput(multiplier: .single, segment: .miss, isMiss: true)
    }

    private static func mulliganMarks(for dart: DartInput, target: MulliganSegment) -> Int {
        guard !dart.isMiss else { return 0 }
        switch target {
        case let .number(n):
            guard case let .oneToTwenty(v) = dart.segment, v == n else { return 0 }
            return dart.multiplier.markValue
        case .bull:
            switch dart.segment {
            case .innerBull: return 2
            case .outerBull: return 1
            default: return 0
            }
        }
    }
}

