import Foundation

extension DartBotEngine {
    /// Generates three darts for a Nine Lives bot turn, aiming at successive targets within the visit.
    public static func generateNineLivesTurn(
        targetIndex: Int,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> [DartInput] {
        var darts: [DartInput] = []
        var currentIndex = targetIndex

        while darts.count < 3 {
            guard currentIndex < 20 else {
                darts.append(DartInput(multiplier: .single, segment: .miss, isMiss: true))
                continue
            }

            let segmentValue = currentIndex + 1
            let dart = resolveNineLivesDart(segmentValue: segmentValue, profile: profile, rng: &rng)
            darts.append(dart)
            if case let .oneToTwenty(v) = dart.segment, v == segmentValue, !dart.isMiss {
                currentIndex += 1
            }
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
        let adjacent = adjacentClockSegment(to: segmentValue, rng: &rng)
        return DartInput(multiplier: .single, segment: .oneToTwenty(adjacent))
    }
}
