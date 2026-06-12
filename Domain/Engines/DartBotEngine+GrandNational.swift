import Foundation

extension DartBotEngine {
    /// Generates three darts for a Grand National bot visit, aiming at the player's
    /// current hurdle segment.  Grand National only requires one hit per visit, so the
    /// bot stops trying after the first hit and fills remaining slots with misses.
    public static func generateGrandNationalTurn(
        currentHurdle: Int,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> [DartInput] {
        var darts: [DartInput] = []
        var hasHit = false

        while darts.count < 3 {
            // Once the hurdle is cleared the bot wastes remaining darts.
            guard !hasHit else {
                darts.append(DartInput(multiplier: .single, segment: .miss, isMiss: true))
                continue
            }

            let dart = resolveGrandNationalDart(
                hurdle: currentHurdle,
                profile: profile,
                rng: &rng
            )
            if case let .oneToTwenty(value) = dart.segment, value == currentHurdle, !dart.isMiss {
                hasHit = true
            }
            darts.append(dart)
        }

        return darts
    }

    // MARK: - Private resolution

    private static func resolveGrandNationalDart(
        hurdle: Int,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        let hitChance = profile.cricket.hitChances.single
        if Double.random(in: 0 ... 1, using: &rng) < hitChance {
            return DartInput(multiplier: .single, segment: .oneToTwenty(hurdle))
        }
        // Miss — off-board or adjacent segment.
        if Double.random(in: 0 ... 1, using: &rng) < profile.cricket.offBoardMissChance {
            return DartInput(multiplier: .single, segment: .miss, isMiss: true)
        }
        let adjacent = Bool.random(using: &rng)
            ? max(1, hurdle - 1)
            : min(20, hurdle + 1)
        return DartInput(multiplier: .single, segment: .oneToTwenty(adjacent))
    }
}
