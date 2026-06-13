import Foundation

extension DartBotEngine {
    /// Generates three darts for an Around the Clock bot turn, aiming at successive targets
    /// within the visit when hits land.
    public static func generateAroundTheClockTurn(
        targetIndex: Int,
        includeBullFinish: Bool,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> [DartInput] {
        var darts: [DartInput] = []
        var currentIndex = targetIndex

        while darts.count < 3 {
            guard currentIndex < 20 else {
                if includeBullFinish, currentIndex == 20 {
                    let hitChance = profile.cricket.hitChances.single
                    if Double.random(in: 0 ... 1, using: &rng) < hitChance {
                        darts.append(DartInput(multiplier: .single, segment: .outerBull))
                        currentIndex += 1
                    } else {
                        darts.append(DartInput(multiplier: .single, segment: .miss, isMiss: true))
                    }
                } else {
                    darts.append(DartInput(multiplier: .single, segment: .miss, isMiss: true))
                }
                continue
            }

            let segmentValue = currentIndex + 1
            let dart = resolveAroundTheClockDart(
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

    private static func resolveAroundTheClockDart(
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
