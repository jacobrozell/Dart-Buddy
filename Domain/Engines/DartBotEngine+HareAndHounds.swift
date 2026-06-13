import Foundation

extension DartBotEngine {
    /// Generates three darts for a Hare and Hounds bot turn, aiming at successive course segments.
    public static func generateHareAndHoundsTurn(
        positionIndex: Int,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> [DartInput] {
        let course = MatchConfigHareAndHounds.clockwiseCourse
        var darts: [DartInput] = []
        var currentIndex = positionIndex

        while darts.count < 3 {
            guard currentIndex < HareAndHoundsState.courseLength else {
                darts.append(DartInput(multiplier: .single, segment: .miss, isMiss: true))
                continue
            }

            let segmentValue = course[currentIndex]
            let dart = resolveHareAndHoundsDart(
                segmentValue: segmentValue,
                profile: profile,
                rng: &rng
            )
            darts.append(dart)
            if case let .oneToTwenty(v) = dart.segment, v == segmentValue, !dart.isMiss {
                currentIndex += 1
            }
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
