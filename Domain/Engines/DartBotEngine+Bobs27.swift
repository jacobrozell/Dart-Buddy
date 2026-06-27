import Foundation

extension DartBotEngine {
    /// Generates a Bob's 27 visit — doubles on the round segment, inner bull on the final round.
    public static func generateBobs27Turn(
        target: Bobs27Target,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> [DartInput] {
        var darts: [DartInput] = []
        while darts.count < 3 {
            let intended: DartInput
            switch target {
            case let .double(segment):
                intended = DartInput(multiplier: .double, segment: .oneToTwenty(segment))
            case .bull:
                intended = DartInput(multiplier: .single, segment: .innerBull)
            }
            darts.append(
                resolveBobs27Dart(
                    intended: intended,
                    target: target,
                    profile: profile,
                    rng: &rng
                )
            )
        }
        return darts
    }

    // MARK: - Private helpers

    private static func resolveBobs27Dart(
        intended: DartInput,
        target: Bobs27Target,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        guard intended.isMiss == false else { return intended }

        switch target {
        case .double:
            let roll = Double.random(in: 0 ... 1, using: &rng)
            let hitChance = min(0.90, profile.cricketHitChance(intendedMultiplier: .double))
            if roll < hitChance {
                return intended
            }
            if Double.random(in: 0 ... 1, using: &rng) < profile.cricket.offBoardMissChance {
                return DartInput(multiplier: .single, segment: .miss, isMiss: true)
            }
            if case let .oneToTwenty(value) = intended.segment,
               Double.random(in: 0 ... 1, using: &rng) < profile.cricket.hitChances.single {
                return DartInput(multiplier: .single, segment: .oneToTwenty(value))
            }
            if case let .oneToTwenty(value) = intended.segment {
                let adjacent = adjacentClockSegment(to: value, rng: &rng)
                return DartInput(multiplier: .single, segment: .oneToTwenty(adjacent))
            }
            return DartInput(multiplier: .single, segment: .miss, isMiss: true)
        case .bull:
            if Double.random(in: 0 ... 1, using: &rng) < profile.x01.innerBullAimChance {
                return DartInput(multiplier: .single, segment: .innerBull)
            }
            if Double.random(in: 0 ... 1, using: &rng) < profile.cricket.offBoardMissChance {
                return DartInput(multiplier: .single, segment: .miss, isMiss: true)
            }
            return DartInput(multiplier: .single, segment: .outerBull)
        }
    }
}
