import Foundation

extension DartBotEngine {
    public static func generatePrisonerVisit(
        state: PrisonerState,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> [PrisonerDartHit] {
        let dartCount = state.dartsAvailableThisVisit
        guard dartCount > 0 else { return [] }

        var hits: [PrisonerDartHit] = []
        var progressIndex = state.currentPlayer.progressIndex

        while hits.count < dartCount {
            if progressIndex >= MatchConfigPrisoner.clockwiseSequence.count { break }
            let target = MatchConfigPrisoner.clockwiseSequence[progressIndex]
            let hit = resolvePrisonerDartHit(target: target, profile: profile, rng: &rng)
            hits.append(hit)
            if case let .playable(segment) = hit, segment == target {
                progressIndex += 1
            }
        }
        return hits
    }

    private static func resolvePrisonerDartHit(
        target: Int,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> PrisonerDartHit {
        let roll = Double.random(in: 0 ... 1, using: &rng)
        let playableChance = profile.cricket.hitChances.single * 0.55
        if roll < playableChance {
            return .playable(segment: target)
        }
        if roll < playableChance + profile.cricket.hitChances.single * 0.2 {
            return .innerSingle(segment: target)
        }
        if Double.random(in: 0 ... 1, using: &rng) < profile.cricket.offBoardMissChance {
            return .outsideDouble
        }
        let adjacent = adjacentClockSegment(to: target, rng: &rng)
        return Bool.random(using: &rng)
            ? .innerSingle(segment: adjacent)
            : .playable(segment: adjacent)
    }
}
