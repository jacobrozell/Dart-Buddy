import Foundation

extension DartBotEngine {
    /// Generates a bot turn for Mickey Mouse.
    ///
    /// The bot aims at the current active target using cricket-style hit chances.
    /// For numbered targets it uses the triple preference when available; for bull
    /// it favours the inner bull based on `profile.cricket.innerBullAimChance`.
    public static func generateMickeyMouseTurn(
        activeTarget: MickeyMouseTarget,
        marksAlreadyOnTarget: Int,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> [DartInput] {
        var darts: [DartInput] = []
        var simulatedMarks = marksAlreadyOnTarget

        while darts.count < 3 {
            let remaining = max(0, MickeyMouseEngine.marksToClose - simulatedMarks)
            let intended = intendedMickeyMouseDart(
                activeTarget: activeTarget,
                remainingMarks: remaining,
                profile: profile,
                rng: &rng
            )
            let resolved = resolveMickeyMouseDart(
                intended: intended,
                activeTarget: activeTarget,
                profile: profile,
                rng: &rng
            )
            darts.append(resolved)

            let gained = MickeyMouseEngine.marksForTarget(dart: resolved, activeTarget: activeTarget)
            simulatedMarks = min(MickeyMouseEngine.marksToClose, simulatedMarks + gained)
        }

        return darts
    }

    // MARK: - Private helpers

    private static func intendedMickeyMouseDart(
        activeTarget: MickeyMouseTarget,
        remainingMarks: Int,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        switch activeTarget {
        case let .number(value):
            // Choose multiplier to efficiently close the remaining marks.
            let multiplier: DartMultiplier
            if remainingMarks >= 3,
               Double.random(in: 0 ... 1, using: &rng) < profile.cricket.tripleOnOpenChance {
                multiplier = .triple
            } else if remainingMarks >= 2,
                      Double.random(in: 0 ... 1, using: &rng) < profile.cricket.doubleOnOpenChance {
                multiplier = .double
            } else {
                multiplier = .single
            }
            return DartInput(multiplier: multiplier, segment: .oneToTwenty(value))
        case .bull:
            // Prefer inner bull (2 marks) to close faster.
            let aimsInner = Double.random(in: 0 ... 1, using: &rng) < profile.cricket.innerBullAimChance
            return aimsInner
                ? DartInput(multiplier: .single, segment: .innerBull)
                : DartInput(multiplier: .single, segment: .outerBull)
        }
    }

    private static func resolveMickeyMouseDart(
        intended: DartInput,
        activeTarget: MickeyMouseTarget,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        guard !intended.isMiss else { return intended }

        let roll = Double.random(in: 0 ... 1, using: &rng)
        let hitChance = min(0.90, profile.cricketHitChance(intendedMultiplier: intended.multiplier))

        if roll < hitChance {
            return intended
        }

        // Miss: land off-board or on the wrong segment.
        let missRoll = Double.random(in: 0 ... 1, using: &rng)
        if missRoll < profile.cricket.offBoardMissChance {
            return DartInput(multiplier: .single, segment: .miss, isMiss: true)
        }
        if missRoll < profile.cricket.offBoardMissChance + profile.cricket.wrongBedChance {
            // Wrong bed within the cricket range.
            let wrongFace = Int.random(in: 1 ... 14, using: &rng)
            return DartInput(multiplier: .single, segment: .oneToTwenty(wrongFace))
        }
        // Partial miss — land on a neighbouring segment of the active target.
        let wrongFace = Int.random(in: 1 ... 14, using: &rng)
        return DartInput(multiplier: .single, segment: .oneToTwenty(wrongFace))
    }
}
