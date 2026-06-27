import Foundation

extension DartBotEngine {
    public static func generateBlindKillerTurn(
        state: BlindKillerState,
        playerId: UUID,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> [DartInput] {
        var darts: [DartInput] = []
        while darts.count < 3 {
            let segment = preferredBlindKillerSegment(
                state: state,
                playerId: playerId,
                profile: profile,
                rng: &rng
            )
            let intended = DartInput(multiplier: .double, segment: .oneToTwenty(segment))
            darts.append(resolveBlindKillerDouble(intended: intended, profile: profile, rng: &rng))
        }
        return darts
    }

    static func preferredBlindKillerSegment(
        state: BlindKillerState,
        playerId: UUID,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> Int {
        let ownNumber = state.secretNumber(for: playerId)
        let hitsNeeded = state.config.hitsToEliminate

        func pool(excludingOwn: Bool) -> [Int] {
            (1 ... 20).filter { segment in
                !(excludingOwn && segment == ownNumber)
            }
        }

        let finishing = pool(excludingOwn: true).filter { state.segmentHitCounts[$0] == hitsNeeded - 1 }
        if let segment = finishing.randomElement(using: &rng) {
            return segment
        }

        let inProgress = pool(excludingOwn: true).filter { state.segmentHitCounts[$0] > 0 }
        if let segment = inProgress.randomElement(using: &rng) {
            return segment
        }

        switch profile.x01.scoringBehaviorTier {
        case .veryEasy, .easy:
            return pool(excludingOwn: true).randomElement(using: &rng) ?? 20
        case .medium:
            return [18, 19, 20, 16, 17].randomElement(using: &rng) ?? 20
        case .hard, .pro:
            return [16, 17, 18, 19, 20].randomElement(using: &rng) ?? 20
        }
    }

    static func resolveBlindKillerDouble(
        intended: DartInput,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        guard intended.isMiss == false else { return intended }

        let hitChance = min(0.90, profile.cricketHitChance(intendedMultiplier: .double))
        if Double.random(in: 0 ... 1, using: &rng) < hitChance {
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
            return DartInput(
                multiplier: .single,
                segment: .oneToTwenty(adjacentClockSegment(to: value, rng: &rng))
            )
        }
        return DartInput(multiplier: .single, segment: .miss, isMiss: true)
    }
}
