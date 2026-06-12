import Foundation

extension DartBotEngine {
    /// Generates three darts for an Around the Clock bot turn, aiming at the player's
    /// current target.  Stops placing darts after the first hit (the sequence advances
    /// on the first hit, so remaining darts are all misses in practice — but we still
    /// fill all three slots to keep the submission consistent).
    public static func generateAroundTheClockTurn(
        targetIndex: Int,
        includeBullFinish: Bool,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> [DartInput] {
        var darts: [DartInput] = []
        var hasHit = false

        while darts.count < 3 {
            // After the first hit the player would have advanced, so subsequent darts
            // miss deliberately (bot does not throw at the new target mid-visit).
            guard !hasHit else {
                darts.append(DartInput(multiplier: .single, segment: .miss, isMiss: true))
                continue
            }

            let dart: DartInput
            if targetIndex < 20 {
                let segmentValue = targetIndex + 1
                dart = resolveAroundTheClockDart(
                    segmentValue: segmentValue,
                    profile: profile,
                    rng: &rng
                )
                if case let .oneToTwenty(v) = dart.segment, v == segmentValue, !dart.isMiss {
                    hasHit = true
                }
            } else if includeBullFinish {
                // Bull finish: aim outer bull (single in this context).
                let hitChance = profile.cricket.hitChances.single
                if Double.random(in: 0 ... 1, using: &rng) < hitChance {
                    dart = DartInput(multiplier: .single, segment: .outerBull)
                    hasHit = true
                } else {
                    dart = DartInput(multiplier: .single, segment: .miss, isMiss: true)
                }
            } else {
                dart = DartInput(multiplier: .single, segment: .miss, isMiss: true)
            }
            darts.append(dart)
        }

        return darts
    }

    // MARK: - Private helpers

    private static func resolveAroundTheClockDart(
        segmentValue: Int,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        let hitChance = profile.cricket.hitChances.single
        if Double.random(in: 0 ... 1, using: &rng) < hitChance {
            return DartInput(multiplier: .single, segment: .oneToTwenty(segmentValue))
        }
        // Miss — land on a neighbouring segment or board miss.
        let offBoardChance = profile.cricket.offBoardMissChance
        if Double.random(in: 0 ... 1, using: &rng) < offBoardChance {
            return DartInput(multiplier: .single, segment: .miss, isMiss: true)
        }
        // Wrong bed: adjacent segment (±1, clamped to 1…20).
        let adjacent = Bool.random(using: &rng)
            ? max(1, segmentValue - 1)
            : min(20, segmentValue + 1)
        return DartInput(multiplier: .single, segment: .oneToTwenty(adjacent))
    }
}
