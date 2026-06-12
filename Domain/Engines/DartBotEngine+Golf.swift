import Foundation

extension DartBotEngine {
    /// Generates a Golf hole turn for a bot player.
    ///
    /// Strategy (GLD last-dart rule — lower strokes win):
    /// - The bot always aims at the hole's target segment.
    /// - Harder bots aim for double (1 stroke) or triple (2 strokes); easier bots aim single.
    /// - After each dart, if the last resolved dart would already score ≤ 2 strokes
    ///   (double or triple), the bot stops early — no point risking a worse result.
    /// - Easier bots never stop early (they always throw all 3 and rely on luck).
    public static func generateGolfTurn(
        holeSegment: Int,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> GolfTurnInput {
        let tier = profile.x01.scoringBehaviorTier
        var darts: [DartInput] = []

        while darts.count < 3 {
            // Choose intended multiplier: harder bots aim for double/triple first
            let intended: DartInput
            if tier == .veryEasy || tier == .easy {
                intended = DartInput(multiplier: .single, segment: .oneToTwenty(holeSegment))
            } else if Double.random(in: 0 ... 1, using: &rng) < profile.cricket.tripleOnOpenChance {
                intended = DartInput(multiplier: .triple, segment: .oneToTwenty(holeSegment))
            } else if Double.random(in: 0 ... 1, using: &rng) < profile.cricket.doubleOnOpenChance {
                intended = DartInput(multiplier: .double, segment: .oneToTwenty(holeSegment))
            } else {
                intended = DartInput(multiplier: .single, segment: .oneToTwenty(holeSegment))
            }

            let resolved = resolveGolfDart(intended: intended, profile: profile, rng: &rng)
            darts.append(resolved)

            // Early stop: if sitting on double (1 stroke) or triple (2 strokes), stop
            // Medium+ bots will stop early on good results; easy/very-easy always throw all 3
            if tier != .veryEasy, tier != .easy {
                let strokes = GolfEngine.strokesForLastDart(resolved, holeSegment: holeSegment)
                if strokes <= 2 {
                    // Good enough — end turn early
                    let endedEarly = darts.count < 3
                    return GolfTurnInput(darts: darts, endedEarly: endedEarly)
                }
            }
        }

        return GolfTurnInput(darts: darts, endedEarly: false)
    }

    // MARK: - Private helpers

    private static func resolveGolfDart(
        intended: DartInput,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        guard !intended.isMiss else { return intended }

        let roll = Double.random(in: 0 ... 1, using: &rng)
        let hitChance = min(0.90, profile.cricketHitChance(intendedMultiplier: intended.multiplier))
        if roll < hitChance {
            return intended
        }

        // Miss: off-board or wrong-bed
        let missRoll = Double.random(in: 0 ... 1, using: &rng)
        if missRoll < profile.cricket.offBoardMissChance {
            return DartInput(multiplier: .single, segment: .miss, isMiss: true)
        }
        // Land on an adjacent segment (±1–3, clamped to 1…20)
        if case let .oneToTwenty(value) = intended.segment {
            let offset = Int.random(in: 1 ... 3, using: &rng) * (Bool.random(using: &rng) ? 1 : -1)
            let adjacent = max(1, min(20, value + offset))
            return DartInput(multiplier: .single, segment: .oneToTwenty(adjacent))
        }
        return DartInput(multiplier: .single, segment: .miss, isMiss: true)
    }
}
