import Foundation

extension DartBotEngine {
    /// Generates a Scam scorer visit — all three darts aim at the highest open
    /// segment at visit start. Multipliers count toward points.
    public static func generateScamScorerTurn(
        targetSegment: Int,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> [DartInput] {
        generateBaseballTurn(
            targetSegment: targetSegment,
            phase: .innings,
            stretchGateOpen: true,
            seventhInningStretch: false,
            profile: profile,
            rng: &rng
        )
    }

    /// Generates a Scam stopper visit — closes the highest still-open segments
    /// (20 downward). Any single on a segment closes it; re-targets within the
    /// visit when a segment is closed.
    public static func generateScamStopperTurn(
        closedSegments: Set<Int>,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> [DartInput] {
        var simulatedClosed = closedSegments
        var darts: [DartInput] = []
        while darts.count < 3 {
            guard let target = highestOpenScamSegment(excluding: simulatedClosed) else {
                darts.append(DartInput(multiplier: .single, segment: .miss, isMiss: true))
                continue
            }
            let intended = DartInput(multiplier: .single, segment: .oneToTwenty(target))
            let resolved = resolveScamStopperDart(
                intended: intended,
                targetSegment: target,
                profile: profile,
                rng: &rng
            )
            darts.append(resolved)
            if let closed = ScamEngine.stopperSegment(from: resolved) {
                simulatedClosed.insert(closed)
            }
        }
        return darts
    }

    // MARK: - Private helpers

    private static func highestOpenScamSegment(excluding closed: Set<Int>) -> Int? {
        (1 ... 20).reversed().first { !closed.contains($0) }
    }

    private static func resolveScamStopperDart(
        intended: DartInput,
        targetSegment: Int,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        guard intended.isMiss == false else { return intended }

        if Double.random(in: 0 ... 1, using: &rng) < profile.cricket.hitChances.single {
            return intended
        }

        if Double.random(in: 0 ... 1, using: &rng) < profile.cricket.offBoardMissChance {
            return DartInput(multiplier: .single, segment: .miss, isMiss: true)
        }

        let adjacent = adjacentClockSegment(to: targetSegment, rng: &rng)
        return DartInput(multiplier: .single, segment: .oneToTwenty(adjacent))
    }
}
