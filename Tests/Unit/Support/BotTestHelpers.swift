import Foundation
@testable import DartBuddy

struct BotTestSeededRandomNumberGenerator: RandomNumberGenerator {
    private var state: UInt64

    init(seed: UInt64) {
        state = seed == 0 ? 0xDEADBEEF : seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
}

enum BotBehaviorSamples {
    static let defaultCount = 80
}

func compareBotMetricTotals(
    lower: BotDifficulty,
    upper: BotDifficulty,
    samples: Int = BotBehaviorSamples.defaultCount,
    metric: (BotSkillProfile, inout BotTestSeededRandomNumberGenerator) -> Int
) -> (lowerTotal: Int, upperTotal: Int) {
    var lowerTotal = 0
    var upperTotal = 0
    for seed in 0 ..< samples {
        var lowerRNG = BotTestSeededRandomNumberGenerator(seed: UInt64(seed))
        var upperRNG = BotTestSeededRandomNumberGenerator(seed: UInt64(seed))
        lowerTotal += metric(lower.skillProfile, &lowerRNG)
        upperTotal += metric(upper.skillProfile, &upperRNG)
    }
    return (lowerTotal, upperTotal)
}

func cricketMarkValue(for dart: DartInput) -> Int {
    guard !dart.isMiss else { return 0 }
    switch dart.segment {
    case .innerBull:
        return 2
    case .outerBull:
        return 1
    case let .oneToTwenty(value):
        guard CricketTarget.allCases.contains(where: { Int($0.rawValue) == value }) else { return 0 }
        return dart.multiplier.markValue
    case .miss:
        return 0
    }
}
