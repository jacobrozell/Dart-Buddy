import Foundation

extension DartBotEngine {
    /// Generates 3 darts for a 180 Around the Clock turn, aiming at the treble of
    /// `targetSegment`. The bot always aims for the treble (maximum 3 pts); hit
    /// resolution uses the cricket hit-chance profile (segment-targeting game).
    public static func generateAroundTheClock180Turn(
        targetSegment: Int,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> [DartInput] {
        var darts: [DartInput] = []
        while darts.count < AroundTheClock180Engine.dartsPerNumber {
            // Always aim treble — highest value in ATC-180 scoring.
            let intended = DartInput(multiplier: .triple, segment: .oneToTwenty(targetSegment))
            let resolved = resolveATC180Dart(
                intended: intended,
                targetSegment: targetSegment,
                profile: profile,
                rng: &rng
            )
            darts.append(resolved)
        }
        return darts
    }

    // MARK: - Private resolution

    private static func resolveATC180Dart(
        intended: DartInput,
        targetSegment: Int,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        let hitChance = profile.cricket.hitChances.triple
        if Double.random(in: 0 ... 1, using: &rng) < hitChance {
            return intended
        }
        // Missed treble — may still land on the correct single/double bed.
        if Double.random(in: 0 ... 1, using: &rng) < profile.cricket.hitChances.single {
            let multiplier: DartMultiplier = Double.random(in: 0 ... 1, using: &rng) < 0.5 ? .single : .double
            return DartInput(multiplier: multiplier, segment: .oneToTwenty(targetSegment))
        }
        // Off the target — off-board miss or wrong segment.
        if Double.random(in: 0 ... 1, using: &rng) < profile.cricket.offBoardMissChance {
            return DartInput(multiplier: .single, segment: .miss, isMiss: true)
        }
        // Land on an adjacent segment (non-scoring for this number).
        let adjacent = adjacentSegment(to: targetSegment, rng: &rng)
        return DartInput(multiplier: .single, segment: .oneToTwenty(adjacent))
    }

    /// Returns a neighbouring segment value (1-20, not equal to `segment`).
    private static func adjacentSegment(
        to segment: Int,
        rng: inout some RandomNumberGenerator
    ) -> Int {
        // Clockwise order around the board.
        let clockwise = [20, 1, 18, 4, 13, 6, 10, 15, 2, 17, 3, 19, 7, 16, 8, 11, 14, 9, 12, 5]
        guard let idx = clockwise.firstIndex(of: segment) else { return segment == 1 ? 2 : segment - 1 }
        let offset = Bool.random(using: &rng) ? 1 : -1
        let neighbour = clockwise[(idx + offset + clockwise.count) % clockwise.count]
        return neighbour
    }
}
