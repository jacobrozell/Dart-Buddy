import Foundation

extension DartBotEngine {
    /// Generates up to three darts for an American Cricket bot turn.
    ///
    /// The bot aims at the active target, applying its Cricket hit-chance profile.
    /// Mark totals are tracked per-dart so scoring logic (overflow after close) is
    /// captured faithfully in the submitted inputs.
    public static func generateAmericanCricketTurn(
        state: AmericanCricketState,
        playerIndex: Int,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> [DartInput] {
        var darts: [DartInput] = []
        let activeTarget = state.activeTarget
        var marksOnTarget = state.players[playerIndex].marks[activeTarget.rawValue] ?? 0

        while darts.count < 3 {
            let dart = resolveAmericanCricketDart(
                target: activeTarget,
                currentMarks: marksOnTarget,
                profile: profile,
                rng: &rng
            )
            darts.append(dart)
            if !dart.isMiss {
                let added: Int
                switch dart.segment {
                case .innerBull: added = 2
                case .outerBull: added = 1
                case .oneToTwenty: added = dart.multiplier.markValue
                case .miss: added = 0
                }
                marksOnTarget = min(3 + added, marksOnTarget + added) // allow overflow accumulation
            }
        }

        return darts
    }

    // MARK: - Private helpers

    private static func resolveAmericanCricketDart(
        target: CricketTarget,
        currentMarks: Int,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        switch target {
        case .bull:
            return resolveBullDart(profile: profile, rng: &rng)
        default:
            guard let value = Int(target.rawValue) else {
                return DartInput(multiplier: .single, segment: .miss, isMiss: true)
            }
            return resolveNumberedTargetDart(
                segmentValue: value,
                currentMarks: currentMarks,
                profile: profile,
                rng: &rng
            )
        }
    }

    private static func resolveNumberedTargetDart(
        segmentValue: Int,
        currentMarks: Int,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        let hitChances = profile.cricket.hitChances
        let roll = Double.random(in: 0 ... 1, using: &rng)

        // After close, prefer triples to maximise scoring; before close prefer triples to close fast.
        let tripleThreshold = hitChances.triple
        let doubleThreshold = tripleThreshold + hitChances.double
        let singleThreshold = doubleThreshold + hitChances.single

        if roll < tripleThreshold {
            return DartInput(multiplier: .triple, segment: .oneToTwenty(segmentValue))
        } else if roll < doubleThreshold {
            return DartInput(multiplier: .double, segment: .oneToTwenty(segmentValue))
        } else if roll < singleThreshold {
            return DartInput(multiplier: .single, segment: .oneToTwenty(segmentValue))
        } else {
            // Miss: nearby segment or board miss.
            let offBoard = Double.random(in: 0 ... 1, using: &rng) < profile.cricket.offBoardMissChance
            if offBoard {
                return DartInput(multiplier: .single, segment: .miss, isMiss: true)
            }
            let adjacent = Bool.random(using: &rng)
                ? max(1, segmentValue - 1)
                : min(20, segmentValue + 1)
            return DartInput(multiplier: .single, segment: .oneToTwenty(adjacent))
        }
    }

    private static func resolveBullDart(
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        let roll = Double.random(in: 0 ... 1, using: &rng)
        let innerChance = profile.cricket.hitChances.triple   // inner bull = bullseye precision
        let outerChance = innerChance + profile.cricket.hitChances.single

        if roll < innerChance {
            return DartInput(multiplier: .single, segment: .innerBull)
        } else if roll < outerChance {
            return DartInput(multiplier: .single, segment: .outerBull)
        } else {
            return DartInput(multiplier: .single, segment: .miss, isMiss: true)
        }
    }
}
