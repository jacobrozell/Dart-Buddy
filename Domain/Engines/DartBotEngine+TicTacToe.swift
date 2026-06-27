import Foundation

extension DartBotEngine {
    /// Generates a 3-dart Tic-Tac-Toe visit with basic win/block/center strategy.
    public static func generateTicTacToeTurn(
        state: TicTacToeState,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> [DartInput] {
        var simulatedGrid = state.grid
        var darts: [DartInput] = []
        for _ in 0 ..< 3 {
            guard let cellIndex = preferredTicTacToeCellIndex(
                grid: simulatedGrid,
                side: state.currentSide,
                profile: profile,
                rng: &rng
            ) else {
                darts.append(DartInput(multiplier: .single, segment: .miss, isMiss: true))
                continue
            }
            let target = state.config.cells[cellIndex]
            let dart = resolveTicTacToeDart(for: target, profile: profile, rng: &rng)
            darts.append(dart)
            if target.matches(dart) {
                simulatedGrid[cellIndex] = state.currentSide
            }
        }
        return darts
    }

    /// Picks the best open cell for `side` on the current grid.
    static func preferredTicTacToeCellIndex(
        grid: [TicTacToeSide?],
        side: TicTacToeSide,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> Int? {
        let open = grid.enumerated().compactMap { index, occupant in
            occupant == nil ? index : nil
        }
        guard !open.isEmpty else { return nil }

        let opponent: TicTacToeSide = side == .x ? .o : .x

        func completesWin(at cell: Int, for player: TicTacToeSide) -> Bool {
            var simulated = grid
            simulated[cell] = player
            return TicTacToeEngine.winningLineForSide(player, grid: simulated) != nil
        }

        if let winningCell = open.first(where: { completesWin(at: $0, for: side) }) {
            return winningCell
        }

        if shouldBlockOpponent(in: profile, rng: &rng),
           let blockingCell = open.first(where: { completesWin(at: $0, for: opponent) }) {
            return blockingCell
        }

        if open.contains(4) {
            return 4
        }

        let corners = [0, 2, 6, 8].filter { open.contains($0) }
        if let corner = corners.randomElement(using: &rng) {
            return corner
        }

        return open.randomElement(using: &rng)
    }

    // MARK: - Private helpers

    private static func shouldBlockOpponent(
        in profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> Bool {
        let chance: Double
        switch profile.x01.scoringBehaviorTier {
        case .veryEasy: chance = 0.40
        case .easy: chance = 0.60
        case .medium: chance = 0.80
        case .hard: chance = 0.92
        case .pro: chance = 1.0
        }
        return Double.random(in: 0 ... 1, using: &rng) < chance
    }

    private static func resolveTicTacToeDart(
        for target: TicTacToeCellTarget,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        let intended = intendedDart(for: target, profile: profile, rng: &rng)
        guard intended.isMiss == false else { return intended }

        let hitChance = boostedCricketHitChance(
            base: ticTacToeHitChance(for: target, profile: profile),
            profile: profile
        )
        if Double.random(in: 0 ... 1, using: &rng) <= hitChance {
            return intended
        }

        if Double.random(in: 0 ... 1, using: &rng) < profile.cricket.offBoardMissChance {
            return DartInput(multiplier: .single, segment: .miss, isMiss: true)
        }

        switch target {
        case let .single(segment), let .anySegment(segment):
            let adjacent = adjacentClockSegment(to: segment, rng: &rng)
            return DartInput(multiplier: .single, segment: .oneToTwenty(adjacent))
        case let .double(segment):
            return DartInput(multiplier: .single, segment: .oneToTwenty(segment))
        case let .triple(segment):
            if Double.random(in: 0 ... 1, using: &rng) < 0.5 {
                return DartInput(multiplier: .double, segment: .oneToTwenty(segment))
            }
            return DartInput(multiplier: .single, segment: .oneToTwenty(segment))
        case .innerBull:
            return DartInput(multiplier: .single, segment: .outerBull)
        case .outerBull, .anyBull:
            let face = [16, 17, 18, 19, 20].randomElement(using: &rng) ?? 20
            return DartInput(multiplier: .single, segment: .oneToTwenty(face))
        }
    }

    private static func intendedDart(
        for target: TicTacToeCellTarget,
        profile: BotSkillProfile,
        rng: inout some RandomNumberGenerator
    ) -> DartInput {
        switch target {
        case .innerBull:
            return DartInput(multiplier: .single, segment: .innerBull)
        case .outerBull:
            return DartInput(multiplier: .single, segment: .outerBull)
        case .anyBull:
            if Double.random(in: 0 ... 1, using: &rng) < profile.x01.innerBullAimChance {
                return DartInput(multiplier: .single, segment: .innerBull)
            }
            return DartInput(multiplier: .single, segment: .outerBull)
        case let .single(segment):
            return DartInput(multiplier: .single, segment: .oneToTwenty(segment))
        case let .double(segment):
            return DartInput(multiplier: .double, segment: .oneToTwenty(segment))
        case let .triple(segment):
            return DartInput(multiplier: .triple, segment: .oneToTwenty(segment))
        case let .anySegment(segment):
            return DartInput(multiplier: .single, segment: .oneToTwenty(segment))
        }
    }

    private static func ticTacToeHitChance(
        for target: TicTacToeCellTarget,
        profile: BotSkillProfile
    ) -> Double {
        switch target {
        case .innerBull:
            return max(profile.x01.innerBullAimChance, profile.cricket.hitChances.single * 0.35)
        case .outerBull, .anyBull:
            return profile.cricket.hitChances.single * 0.85
        case .single, .anySegment:
            return profile.x01.hitChances.single
        case .double:
            return profile.x01.hitChances.double
        case .triple:
            return profile.x01.hitChances.triple
        }
    }
}
