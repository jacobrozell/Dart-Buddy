import Foundation

public struct AchievementDefinition: Equatable, Sendable {
    public let id: String
    public let threshold: Int?
    public let isIncremental: Bool
    public let isHidden: Bool

    public init(id: String, threshold: Int? = nil, isIncremental: Bool = false, isHidden: Bool = false) {
        self.id = id
        self.threshold = threshold
        self.isIncremental = isIncremental
        self.isHidden = isHidden
    }
}

public enum AchievementCatalog {
    public static let phase1: [AchievementDefinition] = [
        AchievementDefinition(id: "db.play.first"),
        AchievementDefinition(id: "db.win.first"),
        AchievementDefinition(id: "db.dart.first_t20"),
        AchievementDefinition(id: "db.avg.match_60"),
        AchievementDefinition(id: "db.avg.match_80"),
        AchievementDefinition(id: "db.visit.180"),
        AchievementDefinition(id: "db.visit.180_20", threshold: 20, isIncremental: true),
        AchievementDefinition(id: "db.visit.180_100", threshold: 100, isIncremental: true),
        AchievementDefinition(id: "db.checkout.100_plus"),
        AchievementDefinition(id: "db.checkout.150_plus"),
        AchievementDefinition(id: "db.checkout.rate_50"),
        AchievementDefinition(id: "db.checkout.rate_100"),
        AchievementDefinition(id: "db.streak.win_3"),
        AchievementDefinition(id: "db.streak.days_3"),
        AchievementDefinition(id: "db.streak.days_7_consecutive"),
        AchievementDefinition(id: "db.streak.days_30_consecutive", threshold: 30, isIncremental: true),
        AchievementDefinition(id: "db.legs.win_100", threshold: 100, isIncremental: true),
        AchievementDefinition(id: "db.play.10", threshold: 10, isIncremental: true),
        AchievementDefinition(id: "db.play.50", threshold: 50, isIncremental: true),
        AchievementDefinition(id: "db.play.100", threshold: 100, isIncremental: true),
        AchievementDefinition(id: "db.play.250", threshold: 250, isIncremental: true),
        AchievementDefinition(id: "db.play.500", threshold: 500, isIncremental: true)
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
