import Foundation

extension DartBotEngine {
    /// Generates three darts for a Nine Lives bot turn.
    ///
    /// The bot aims at the player's current target (1–20). After the first hit the
    /// player advances for the visit, so remaining darts are thrown as misses to avoid
    /// double-advancing (the engine only counts the first hit per visit).
    public static func generateNineLivesTurn(
        targetIndex: Int,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> [DartInput] {
        var darts: [DartInput] = []
        var hasHit = false

        while darts.count < 3 {
            guard !hasHit else {
                darts.append(DartInput(multiplier: .single, segment: .miss, isMiss: true))
                continue
            }

            guard targetIndex < 20 else {
                // Sequence already complete — fill remaining darts with misses.
                darts.append(DartInput(multiplier: .single, segment: .miss, isMiss: true))
                continue
            }

            let segmentValue = targetIndex + 1
            let dart = resolveNineLivesDart(segmentValue: segmentValue, profile: profile, rng: &rng)
            if case let .oneToTwenty(v) = dart.segment, v == segmentValue, !dart.isMiss {
                hasHit = true
            }
            darts.append(dart)
        }

        return darts
    }

    // MARK: - Private helpers

    private static func resolveNineLivesDart(
        segmentValue: Int,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        let hitChance = profile.cricket.hitChances.single
        if Double.random(in: 0 ... 1, using: &rng) < hitChance {
            return DartInput(multiplier: .single, segment: .oneToTwenty(segmentValue))
        }
        let offBoardChance = profile.cricket.offBoardMissChance
        if Double.random(in: 0 ... 1, using: &rng) < offBoardChance {
            return DartInput(multiplier: .single, segment: .miss, isMiss: true)
        }
        let adjacent = Bool.random(using: &rng)
            ? max(1, segmentValue - 1)
            : min(20, segmentValue + 1)
        return DartInput(multiplier: .single, segment: .oneToTwenty(adjacent))
    }
}
