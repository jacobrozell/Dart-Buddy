import Foundation

extension DartBotEngine {
    /// Generates a simulated 3-dart Knockout visit for a bot player.
    ///
    /// The bot aims to score as high as possible. Harder bots more consistently
    /// aim for treble-20; easier bots spray more. The target segment is T20/D20
    /// depending on skill, mirroring the way humans chase a high visit total.
    ///
    /// - Parameters:
    ///   - currentHigh: The current-round benchmark the bot must exceed to avoid a strike.
    ///   - profile: The bot's continuous skill profile.
    ///   - rng: Random number generator (injectable for deterministic tests).
    /// - Returns: Up to 3 `DartInput` values representing the visit.
    public static func generateKnockoutTurn(
        currentHigh: Int,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> [DartInput] {
        var darts: [DartInput] = []

        // Bots always aim for maximum scoring (treble-20 preference mirrors
        // how real players attack Knockout). Harder bots prefer T20; easier
        // bots are more likely to settle for singles or other segments.
        while darts.count < 3 {
            let intended = knockoutIntendedDart(profile: profile, rng: &rng)
            let resolved = resolveDart(intended: intended, profile: profile, rng: &rng)
            darts.append(resolved)
        }

        return darts
    }

    // MARK: - Private helpers

    private static func knockoutIntendedDart(
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        let roll = Double.random(in: 0 ... 1, using: &rng)
        if roll < profile.x01.triplePreference {
            return DartInput(multiplier: .triple, segment: .oneToTwenty(20))
        }
        let doubleRoll = Double.random(in: 0 ... 1, using: &rng)
        if doubleRoll < 0.25 {
            return DartInput(multiplier: .double, segment: .oneToTwenty(20))
        }
        // Fallback to single-20 for lower-tier bots.
        return DartInput(multiplier: .single, segment: .oneToTwenty(20))
    }

    /// Wraps the internal `resolveDart` for use in the Knockout extension.
    /// Since `resolveDart` is `private` on `DartBotEngine`, we replicate the
    /// same resolution logic used for X01 scoring visits here.
    private static func resolveDart(
        intended: DartInput,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        guard !intended.isMiss else { return intended }

        let hitChance = min(0.95, profile.x01HitChance(intendedMultiplier: intended.multiplier))
        let roll = Double.random(in: 0 ... 1, using: &rng)

        if roll < hitChance {
            return intended
        }

        let downgradeBand = 0.28
        if roll < hitChance + downgradeBand {
            return knockoutDowngrade(intended: intended, rng: &rng)
        }

        if roll < hitChance + downgradeBand + profile.x01.offBoardMissChance {
            return DartInput(multiplier: .single, segment: .miss, isMiss: true)
        }

        // Board glance — land on a nearby segment.
        if case let .oneToTwenty(value) = intended.segment {
            return DartInput(
                multiplier: .single,
                segment: .oneToTwenty(adjacentClockSegment(to: value, rng: &rng))
            )
        }
        return DartInput(multiplier: .single, segment: .oneToTwenty(Int.random(in: 1 ... 20, using: &rng)))
    }

    private static func knockoutDowngrade(
        intended: DartInput,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        switch intended.segment {
        case let .oneToTwenty(value):
            switch intended.multiplier {
            case .triple:
                if Double.random(in: 0 ... 1, using: &rng) < 0.55 {
                    return DartInput(multiplier: .single, segment: .oneToTwenty(value))
                }
                return DartInput(multiplier: .double, segment: .oneToTwenty(value))
            case .double:
                return DartInput(multiplier: .single, segment: .oneToTwenty(value))
            case .single:
                return DartInput(
                    multiplier: .single,
                    segment: .oneToTwenty(adjacentClockSegment(to: value, rng: &rng))
                )
            }
        default:
            return DartInput(multiplier: .single, segment: .oneToTwenty(Int.random(in: 1 ... 20, using: &rng)))
        }
    }
}
