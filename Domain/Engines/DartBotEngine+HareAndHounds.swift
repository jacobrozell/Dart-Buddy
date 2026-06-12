import Foundation

extension DartBotEngine {
    /// Generates three darts for a Hare and Hounds bot turn.
    ///
    /// The bot aims at the active player's current segment. After the first hit the
    /// position would advance, so subsequent darts are deliberate misses (the engine
    /// only advances on the first hit per visit).
    public static func generateHareAndHoundsTurn(
        targetSegment: Int,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> [DartInput] {
        var darts: [DartInput] = []
        var hasHit = false

        while darts.count < 3 {
            // After the first hit the player would have advanced; remaining darts miss.
            guard !hasHit else {
                darts.append(DartInput(multiplier: .single, segment: .miss, isMiss: true))
                continue
            }

            let dart = resolveHareAndHoundsDart(
                segmentValue: targetSegment,
                profile: profile,
                rng: &rng
            )
            if case let .oneToTwenty(v) = dart.segment, v == targetSegment, !dart.isMiss {
                hasHit = true
            }
            darts.append(dart)
        }

        return darts
    }

    // MARK: - Private helpers

    private static func resolveHareAndHoundsDart(
        segmentValue: Int,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        let hitChance = profile.cricket.hitChances.single
        if Double.random(in: 0 ... 1, using: &rng) < hitChance {
            return DartInput(multiplier: .single, segment: .oneToTwenty(segmentValue))
        }
        // Miss — land on an off-board miss or adjacent segment.
        let offBoardChance = profile.cricket.offBoardMissChance
        if Double.random(in: 0 ... 1, using: &rng) < offBoardChance {
            return DartInput(multiplier: .single, segment: .miss, isMiss: true)
        }
        // Wrong bed: adjacent segment in board order (±1 on the numeric value, clamped 1…20).
        let adjacent = Bool.random(using: &rng)
            ? max(1, segmentValue - 1)
            : min(20, segmentValue + 1)
        return DartInput(multiplier: .single, segment: .oneToTwenty(adjacent))
    }
}
