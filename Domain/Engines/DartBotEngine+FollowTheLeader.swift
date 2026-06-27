import Foundation

extension DartBotEngine {
    public static func generateFollowTheLeaderVisit(
        state: FollowTheLeaderState,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> [DartInput] {
        if state.needsOpeningTarget {
            let opening = preferredOpeningLeaderTarget(profile: profile, rng: &rng)
            let intended = followTheLeaderDartInput(for: opening)
            return [resolveFollowTheLeaderDart(intended: intended, target: opening, profile: profile, rng: &rng)]
        }

        guard let target = state.target else {
            return Array(repeating: DartInput(multiplier: .single, segment: .miss, isMiss: true), count: 3)
        }

        var darts: [DartInput] = []
        var matchIndex: Int?

        while darts.count < 3 {
            let intended = followTheLeaderDartInput(for: target)
            let resolved = resolveFollowTheLeaderDart(
                intended: intended,
                target: target,
                profile: profile,
                rng: &rng
            )
            darts.append(resolved)
            if matchIndex == nil, FollowTheLeaderEngine.dartMatchesTarget(resolved, target: target) {
                matchIndex = darts.count - 1
            }
        }

        guard let matchIndex else { return darts }

        for index in (matchIndex + 1) ..< darts.count {
            let spare = preferredSpareLeaderTarget(after: target, profile: profile, rng: &rng)
            let intended = followTheLeaderDartInput(for: spare)
            darts[index] = resolveFollowTheLeaderDart(
                intended: intended,
                target: spare,
                profile: profile,
                rng: &rng
            )
        }

        return darts
    }
}
