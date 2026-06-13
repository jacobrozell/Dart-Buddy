import Foundation

/// Hunt and placement policy for Fleet bots (adjunct to `DartBotEngine`).
public enum FleetBotPolicy {

    public static func pickPlacementCells(
        count: Int,
        bullAllowed: Bool,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> Set<FleetBoardCell> {
        var pool = FleetEngine.placementPool(bullAllowed: bullAllowed)
        let tier = profile.x01.scoringBehaviorTier
        if tier == .hard || tier == .pro, bullAllowed {
            // Weight bull for Hard/Pro when enabled.
            if Bool.random(using: &rng) {
                pool.append(.bull)
            }
        }
        var selected: Set<FleetBoardCell> = []
        while selected.count < count, !pool.isEmpty {
            let index = Int.random(in: 0 ..< pool.count, using: &rng)
            selected.insert(pool.remove(at: index))
        }
        return selected
    }

    public static func pickCallCell(
        state: FleetState,
        botId: UUID,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> FleetBoardCell? {
        let pool = FleetEngine.placementPool(bullAllowed: state.config.bullAllowed)
        let probed = Set(state.probeMaps[botId, default: [:]].keys)
        let unprobed = pool.filter { !probed.contains($0) }
        guard !unprobed.isEmpty else { return pool.randomElement(using: &rng) }

        let tier = profile.x01.scoringBehaviorTier
        switch tier {
        case .veryEasy, .easy:
            return unprobed.randomElement(using: &rng)
        case .medium:
            if unprobed.count <= 3, (state.fleets[botId]?.sonarRemaining ?? 0) > 0 {
                return centerMassSegment(from: unprobed)
            }
            return unprobed.randomElement(using: &rng)
        case .hard, .pro:
            let highSegments = unprobed.filter {
                if case let .segment(value) = $0 { return (18 ... 20).contains(value) }
                return false
            }
            if probed.count * 2 >= pool.count, !highSegments.isEmpty, Bool.random(using: &rng) {
                return highSegments.randomElement(using: &rng)
            }
            return unprobed.randomElement(using: &rng)
        }
    }

    public static func pickSonarCell(
        state: FleetState,
        botId: UUID,
        rng: inout some RandomNumberGenerator
    ) -> FleetBoardCell? {
        let pool = FleetEngine.placementPool(bullAllowed: state.config.bullAllowed)
        let probed = Set(state.probeMaps[botId, default: [:]].keys)
        let unprobed = pool.filter { !probed.contains($0) }
        guard !unprobed.isEmpty else { return nil }
        return centerMassSegment(from: unprobed) ?? unprobed.randomElement(using: &rng)
    }

    public static func shouldUseSonar(
        state: FleetState,
        botId: UUID,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> Bool {
        guard state.config.sonarEnabled else { return false }
        guard (state.fleets[botId]?.sonarRemaining ?? 0) > 0 else { return false }
        let pool = FleetEngine.placementPool(bullAllowed: state.config.bullAllowed)
        let probed = state.probeMaps[botId, default: [:]]
        let remaining = pool.count - probed.count
        let tier = profile.x01.scoringBehaviorTier
        switch tier {
        case .veryEasy, .easy:
            return false
        case .medium:
            return remaining <= 4 && Bool.random(using: &rng)
        case .hard, .pro:
            return remaining <= 6
        }
    }

    private static func centerMassSegment(from cells: [FleetBoardCell]) -> FleetBoardCell? {
        cells.first { if case .segment(20) = $0 { return true }; return false }
            ?? cells.first { if case .segment(18) = $0 { return true }; return false }
            ?? cells.first { if case .segment(19) = $0 { return true }; return false }
    }
}
