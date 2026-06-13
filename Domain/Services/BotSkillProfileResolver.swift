import Foundation

struct BotPlayContext: Sendable, Equatable {
    let matchType: MatchType
    let uiTemplate: GameplayUITemplate

    init(matchType: MatchType, uiTemplate: GameplayUITemplate) {
        self.matchType = matchType
        self.uiTemplate = uiTemplate
    }

    static func forMatchType(_ matchType: MatchType) -> BotPlayContext? {
        guard let entry = GameModeCatalog.entry(for: matchType) else { return nil }
        return BotPlayContext(matchType: matchType, uiTemplate: entry.uiTemplate)
    }
}

/// Template-based custom bot skill resolution. v1 returns the same canonical profile for every template.
enum BotSkillProfileResolver {
    static func profile(
        configuration: CustomBotConfiguration,
        context: BotPlayContext
    ) -> BotSkillProfile {
        _ = context
        return configuration.resolvedCanonicalProfile()
    }

    static func allShippedTemplates() -> [GameplayUITemplate] {
        GameModeCatalog.available.compactMap(\.matchType).compactMap { matchType in
            GameModeCatalog.entry(for: matchType)?.uiTemplate
        }
    }
}
