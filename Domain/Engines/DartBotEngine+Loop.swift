import Foundation

extension DartBotEngine {
    public static func generateLoopVisit(
        state: LoopState,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> [LoopSubmittedDart] {
        if state.needsOpeningTarget {
            let opening = preferredOpeningLoopTarget(profile: profile, rng: &rng)
            return [loopSubmittedDart(matching: opening, profile: profile, rng: &rng)]
        }

        guard let target = state.target else {
            let miss = DartInput(multiplier: .single, segment: .miss, isMiss: true)
            let wire = LoopWireTargetArea(segment: 20, kind: .standard, ring: .single)
            return Array(repeating: LoopSubmittedDart(dart: miss, wireTarget: wire), count: 3)
        }

        var darts: [LoopSubmittedDart] = []
        var matchIndex: Int?

        while darts.count < 3 {
            let submitted = loopSubmittedDart(matching: target, profile: profile, rng: &rng)
            darts.append(submitted)
            if matchIndex == nil, submitted.wireTarget == target {
                matchIndex = darts.count - 1
            }
        }

        guard let matchIndex else { return darts }

        for index in (matchIndex + 1) ..< darts.count {
            let spare = preferredSpareLoopTarget(after: target, profile: profile, rng: &rng)
            darts[index] = loopSubmittedDart(matching: spare, profile: profile, rng: &rng)
        }

        return darts
    }

    static func loopSubmittedDart(
        matching target: LoopWireTargetArea,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> LoopSubmittedDart {
        let intended = dartInput(forLoopTarget: target)
        let resolved = resolveLoopDart(intended: intended, target: target, profile: profile, rng: &rng)
        let candidates = LoopWireTargetArea.candidates(for: resolved)
        let wire = candidates.contains(target) ? target : (candidates.first ?? target)
        return LoopSubmittedDart(dart: resolved, wireTarget: wire)
    }

    static func dartInput(forLoopTarget target: LoopWireTargetArea) -> DartInput {
        switch target.kind {
        case .lowerLoop, .upperLoop, .split:
            return DartInput(multiplier: .single, segment: .oneToTwenty(target.segment))
        case .standard:
            guard let ring = target.ring else {
                return DartInput(multiplier: .single, segment: .oneToTwenty(target.segment))
            }
            return followTheLeaderDartInput(for: FollowTheLeaderTargetArea(segment: target.segment, ring: ring))
        }
    }

    static func resolveLoopDart(
        intended: DartInput,
        target: LoopWireTargetArea,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        switch target.kind {
        case .lowerLoop, .upperLoop, .split:
            return resolveSingleOnSegment(segment: target.segment, profile: profile, rng: &rng)
        case .standard:
            guard let ring = target.ring else {
                return resolveSingleOnSegment(segment: target.segment, profile: profile, rng: &rng)
            }
            let leaderTarget = FollowTheLeaderTargetArea(segment: target.segment, ring: ring)
            return resolveLoopLeaderDart(
                intended: intended,
                target: leaderTarget,
                profile: profile,
                rng: &rng
            )
        }
    }

    private static func resolveLoopLeaderDart(
        intended: DartInput,
        target: FollowTheLeaderTargetArea,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        guard !intended.isMiss else { return intended }

        let baseHit: Double
        switch target.ring {
        case .single:
            baseHit = profile.cricket.hitChances.single
        case .double, .triple:
            baseHit = profile.cricketHitChance(intendedMultiplier: intended.multiplier)
        case .outerBull, .innerBull:
            baseHit = profile.cricket.hitChances.single
        }

        let hitChance = min(
            0.95,
            baseHit * (0.78 + Double(profile.x01.scoringBehaviorTier.achievementRank) * 0.06)
        )
        if Double.random(in: 0 ... 1, using: &rng) < hitChance {
            return intended
        }

        if Double.random(in: 0 ... 1, using: &rng) < profile.cricket.offBoardMissChance {
            return DartInput(multiplier: .single, segment: .miss, isMiss: true)
        }

        switch target.ring {
        case .single:
            return DartInput(multiplier: .single, segment: .oneToTwenty(adjacentClockSegment(to: target.segment, rng: &rng)))
        case .double, .triple:
            return DartInput(multiplier: .single, segment: .oneToTwenty(target.segment))
        case .outerBull:
            return DartInput(multiplier: .single, segment: .innerBull)
        case .innerBull:
            let face = [16, 17, 18, 19, 20].randomElement(using: &rng) ?? 20
            return DartInput(multiplier: .single, segment: .oneToTwenty(face))
        }
    }

    static func preferredOpeningLoopTarget(
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> LoopWireTargetArea {
        let leader = preferredOpeningLeaderTarget(profile: profile, rng: &rng)
        if profile.x01.scoringBehaviorTier == .pro,
           Double.random(in: 0 ... 1, using: &rng) < 0.2,
           let loopSegment = LoopWireTargetArea.loopSegments.randomElement(using: &rng) {
            return LoopWireTargetArea(segment: loopSegment, kind: .lowerLoop)
        }
        return LoopWireTargetArea(
            segment: leader.segment,
            kind: .standard,
            ring: leader.ring
        )
    }

    static func preferredSpareLoopTarget(
        after current: LoopWireTargetArea,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> LoopWireTargetArea {
        switch current.kind {
        case .standard:
            let spare = preferredSpareLeaderTarget(
                after: FollowTheLeaderTargetArea(segment: current.segment, ring: current.ring ?? .single),
                profile: profile,
                rng: &rng
            )
            return LoopWireTargetArea(segment: spare.segment, kind: .standard, ring: spare.ring)
        case .lowerLoop, .upperLoop:
            let segment = LoopWireTargetArea.loopSegments.randomElement(using: &rng) ?? current.segment
            return LoopWireTargetArea(segment: segment, kind: current.kind)
        case .split:
            return LoopWireTargetArea(segment: LoopWireTargetArea.splitSegment, kind: .split)
        }
    }
}
