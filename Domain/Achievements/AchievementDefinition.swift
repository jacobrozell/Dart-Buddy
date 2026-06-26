import Foundation

public struct AchievementDefinition: Equatable, Sendable {
    public let id: String
    public let threshold: Int?
    public let isIncremental: Bool
    public let isHidden: Bool
    public let iconSystemName: String

    public init(
        id: String,
        threshold: Int? = nil,
        isIncremental: Bool = false,
        isHidden: Bool = false,
        iconSystemName: String = "medal.fill"
    ) {
        self.id = id
        self.threshold = threshold
        self.isIncremental = isIncremental
        self.isHidden = isHidden
        self.iconSystemName = iconSystemName
    }

    public func progressCount(from percent: Int) -> (current: Int, threshold: Int)? {
        guard isIncremental, let threshold, threshold > 0 else { return nil }
        let current = min(threshold, max(0, (percent * threshold + 50) / 100))
        return (current, threshold)
    }
}

public enum AchievementCatalog {
    public static let phase1: [AchievementDefinition] = [
        AchievementDefinition(id: "db.play.first", iconSystemName: "play.circle.fill"),
        AchievementDefinition(id: "db.win.first", iconSystemName: "trophy.fill"),
        AchievementDefinition(id: "db.dart.first_t20", iconSystemName: "target"),
        AchievementDefinition(id: "db.avg.match_60", iconSystemName: "chart.line.uptrend.xyaxis"),
        AchievementDefinition(id: "db.avg.match_80", iconSystemName: "chart.line.uptrend.xyaxis.circle.fill"),
        AchievementDefinition(id: "db.visit.180", iconSystemName: "flame.fill"),
        AchievementDefinition(id: "db.visit.180_20", threshold: 20, isIncremental: true, iconSystemName: "flame.circle.fill"),
        AchievementDefinition(id: "db.visit.180_100", threshold: 100, isIncremental: true, iconSystemName: "star.circle.fill"),
        AchievementDefinition(id: "db.checkout.100_plus", iconSystemName: "arrow.down.circle.fill"),
        AchievementDefinition(id: "db.checkout.150_plus", iconSystemName: "arrow.down.to.line.compact"),
        AchievementDefinition(id: "db.checkout.rate_50", iconSystemName: "percent"),
        AchievementDefinition(id: "db.checkout.rate_100", iconSystemName: "crown.fill"),
        AchievementDefinition(id: "db.streak.win_3", iconSystemName: "bolt.fill"),
        AchievementDefinition(id: "db.streak.days_3", iconSystemName: "calendar"),
        AchievementDefinition(id: "db.streak.days_7_consecutive", iconSystemName: "calendar.badge.clock"),
        AchievementDefinition(id: "db.streak.days_30_consecutive", threshold: 30, isIncremental: true, iconSystemName: "calendar.badge.checkmark"),
        AchievementDefinition(id: "db.legs.win_100", threshold: 100, isIncremental: true, iconSystemName: "flag.checkered"),
        AchievementDefinition(id: "db.play.10", threshold: 10, isIncremental: true, iconSystemName: "gamecontroller.fill"),
        AchievementDefinition(id: "db.play.50", threshold: 50, isIncremental: true, iconSystemName: "gamecontroller.fill"),
        AchievementDefinition(id: "db.play.100", threshold: 100, isIncremental: true, iconSystemName: "gamecontroller.fill"),
        AchievementDefinition(id: "db.play.250", threshold: 250, isIncremental: true, iconSystemName: "gamecontroller.fill"),
        AchievementDefinition(id: "db.play.500", threshold: 500, isIncremental: true, iconSystemName: "gamecontroller.fill")
    ]

    public static let byId: [String: AchievementDefinition] = {
        Dictionary(uniqueKeysWithValues: phase1.map { ($0.id, $0) })
    }()

    public static func definition(for id: String) -> AchievementDefinition? {
        byId[id]
    }

    public static func localizationKey(for achievementId: String, suffix: String) -> String {
        "achievement.\(achievementId.replacingOccurrences(of: ".", with: "_")).\(suffix)"
    }
}
