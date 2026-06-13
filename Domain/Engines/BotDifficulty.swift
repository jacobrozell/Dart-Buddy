import Foundation

/// Skill tiers for computer opponents. Each tier adjusts aim quality and
/// checkout consistency while keeping averages in a believable range.
public enum BotDifficulty: String, Codable, CaseIterable, Sendable {
    case veryEasy
    case easy
    case medium
    case hard
    case pro

    public var displayName: String {
        switch self {
        case .veryEasy: L10n.string("bot.difficulty.veryEasy")
        case .easy: L10n.string("bot.difficulty.easy")
        case .medium: L10n.string("bot.difficulty.medium")
        case .hard: L10n.string("bot.difficulty.hard")
        case .pro: L10n.string("bot.difficulty.pro")
        }
    }

    public var rosterName: String { L10n.format("bot.rosterNameFormat", displayName) }

    /// Rough per-visit scoring target when not on a finish.
    fileprivate var scoringVisitRange: ClosedRange<Int> {
        switch self {
        case .veryEasy: 10 ... 22
        case .easy: 18 ... 42
        case .medium: 22 ... 38
        case .hard: 28 ... 44
        case .pro: 34 ... 50
        }
    }

    fileprivate var checkoutAttemptChance: Double {
        switch self {
        case .veryEasy: 0.12
        case .easy: 0.25
        case .medium: 0.40
        case .hard: 0.50
        case .pro: 0.58
        }
    }

    fileprivate func hitChance(intendedMultiplier: DartMultiplier) -> Double {
        switch (self, intendedMultiplier) {
        case (.veryEasy, .triple): return 0.06
        case (.veryEasy, .double): return 0.14
        case (.veryEasy, .single): return 0.30
        case (.easy, .triple): return 0.18
        case (.easy, .double): return 0.28
        case (.easy, .single): return 0.42
        case (.medium, .triple): return 0.34
        case (.medium, .double): return 0.40
        case (.medium, .single): return 0.52
        case (.hard, .triple): return 0.38
        case (.hard, .double): return 0.44
        case (.hard, .single): return 0.54
        case (.pro, .triple): return 0.48
        case (.pro, .double): return 0.54
        case (.pro, .single): return 0.66
        }
    }

    fileprivate var prefersTripleOnScoringSegment: Double {
        switch self {
        case .veryEasy: 0.08
        case .easy: 0.25
        case .medium: 0.32
        case .hard: 0.32
        case .pro: 0.44
        }
    }

    fileprivate var innerBullAimChance: Double {
        switch self {
        case .veryEasy, .easy, .medium: 0
        case .hard: 0.12
        case .pro: 0.28
        }
    }

    fileprivate var masterInTripleOpenerChance: Double {
        switch self {
        case .veryEasy, .easy, .medium: 0
        case .hard: 0.15
        case .pro: 0.32
        }
    }

    /// Extra hit probability when trying to double/triple in at the start of a leg.
    fileprivate var checkInHitBoost: Double {
        switch self {
        case .veryEasy: 0.18
        case .easy: 0.16
        case .medium: 0.12
        case .hard: 0.08
        case .pro: 0.06
        }
    }

    /// Chance a dart completely misses the board after failing the intended target.
    fileprivate var offBoardMissChance: Double {
        switch self {
        case .veryEasy: 0.20
        case .easy: 0.12
        case .medium: 0.09
        case .hard: 0.07
        case .pro: 0.05
        }
    }

    fileprivate func cricketHitChance(intendedMultiplier: DartMultiplier) -> Double {
        switch (self, intendedMultiplier) {
        case (.veryEasy, .triple): return 0.04
        case (.veryEasy, .double): return 0.09
        case (.veryEasy, .single): return 0.20
        case (.easy, .triple): return 0.11
        case (.easy, .double): return 0.17
        case (.easy, .single): return 0.30
        case (.medium, .triple): return 0.20
        case (.medium, .double): return 0.26
        case (.medium, .single): return 0.36
        case (.hard, .triple): return 0.26
        case (.hard, .double): return 0.32
        case (.hard, .single): return 0.42
        case (.pro, .triple): return 0.32
        case (.pro, .double): return 0.38
        case (.pro, .single): return 0.50
        }
    }

    /// Off-board miss after failing the intended Cricket bed (within the miss branch).
    fileprivate var cricketOffBoardMissChance: Double {
        switch self {
        case .veryEasy: 0.34
        case .easy: 0.28
        case .medium: 0.22
        case .hard: 0.18
        case .pro: 0.14
        }
    }

    /// Lands on a non-Cricket segment (1–14) so the visit records zero marks.
    fileprivate var cricketWrongBedChance: Double {
        switch self {
        case .veryEasy: 0.42
        case .easy: 0.36
        case .medium: 0.30
        case .hard: 0.24
        case .pro: 0.20
        }
    }

    /// When a planned dart would bust, chance the bot throws it anyway instead of
    /// substituting a safe single (higher tiers still bust less often).
    fileprivate var riskyDartWhenWouldBustChance: Double {
        switch self {
        case .veryEasy: 0.70
        case .easy: 0.40
        case .medium: 0.20
        case .hard: 0.16
        case .pro: 0.12
        }
    }

    public var displayProfile: BotDifficultyDisplayProfile {
        BotDifficultyDisplayProfile(
            x01: .init(
                scoringVisitMin: scoringVisitRange.lowerBound,
                scoringVisitMax: scoringVisitRange.upperBound,
                hitChances: .init(
                    single: hitChance(intendedMultiplier: .single),
                    double: hitChance(intendedMultiplier: .double),
                    triple: hitChance(intendedMultiplier: .triple)
                ),
                checkoutAttemptChance: checkoutAttemptChance,
                offBoardMissChance: offBoardMissChance,
                riskyBustChance: riskyDartWhenWouldBustChance,
                triplePreference: prefersTripleOnScoringSegment,
                checkInHitBoost: checkInHitBoost,
                innerBullAimChance: innerBullAimChance,
                masterInTripleOpenerChance: masterInTripleOpenerChance
            ),
            cricket: .init(
                hitChances: .init(
                    single: cricketHitChance(intendedMultiplier: .single),
                    double: cricketHitChance(intendedMultiplier: .double),
                    triple: cricketHitChance(intendedMultiplier: .triple)
                ),
                offBoardMissChance: cricketOffBoardMissChance,
                wrongBedChance: cricketWrongBedChance
            )
        )
    }
}

public struct BotDifficultyDisplayProfile: Equatable, Sendable {
    public struct HitChances: Equatable, Sendable {
        public let single: Double
        public let double: Double
        public let triple: Double
    }

    public struct X01: Equatable, Sendable {
        public let scoringVisitMin: Int
        public let scoringVisitMax: Int
        public let hitChances: HitChances
        public let checkoutAttemptChance: Double
        public let offBoardMissChance: Double
        public let riskyBustChance: Double
        public let triplePreference: Double
        public let checkInHitBoost: Double
        public let innerBullAimChance: Double
        public let masterInTripleOpenerChance: Double
    }

    public struct Cricket: Equatable, Sendable {
        public let hitChances: HitChances
        public let offBoardMissChance: Double
        public let wrongBedChance: Double
    }

    public let x01: X01
    public let cricket: Cricket

    public static func percent(_ value: Double, signed: Bool = false) -> String {
        let formatted = String(format: "%.0f%%", value * 100)
        if signed, value > 0 { return "+\(formatted)" }
        return formatted
    }

    public static func range(_ min: Int, _ max: Int) -> String {
        "\(min)–\(max)"
    }
}
