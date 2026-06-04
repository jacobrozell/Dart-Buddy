import Foundation

public struct CustomBotMetrics: Codable, Equatable, Sendable {
    public static let defaultX01Average = 30.0
    public static let defaultCricketMPR = 1.25

    public static let x01AverageRange: ClosedRange<Double> = 5 ... 110
    public static let cricketMPRRange: ClosedRange<Double> = 0.2 ... 5.0

    public let x01Average: Double
    public let cricketMPR: Double

    public init(x01Average: Double, cricketMPR: Double) {
        self.x01Average = Self.clampX01(x01Average)
        self.cricketMPR = Self.clampMPR(cricketMPR)
    }

    public static func clampX01(_ value: Double) -> Double {
        min(max(value, x01AverageRange.lowerBound), x01AverageRange.upperBound)
    }

    public static func clampMPR(_ value: Double) -> Double {
        min(max(value, cricketMPRRange.lowerBound), cricketMPRRange.upperBound)
    }

    private static let prefix = "custom:"

    public static func decode(botDifficultyRaw: String?) -> CustomBotMetrics? {
        guard let raw = botDifficultyRaw, raw.hasPrefix(prefix) else { return nil }
        let body = raw.dropFirst(prefix.count)
        let parts = body.split(separator: ":", omittingEmptySubsequences: false)
        guard parts.count == 2,
              let x01 = Double(parts[0]),
              let mpr = Double(parts[1]) else { return nil }
        return CustomBotMetrics(x01Average: x01, cricketMPR: mpr)
    }

    public func encode() -> String {
        "\(Self.prefix)\(x01Average):\(cricketMPR)"
    }
}
