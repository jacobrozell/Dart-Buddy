import Foundation

struct GameRulesSection: Identifiable, Hashable, Sendable {
    let id: String
    let titleKey: String
    let bodyKey: String
}

/// One rules guide for a match type. Add new guides here when shipping additional game modes.
struct GameRulesGuide: Identifiable, Hashable, Sendable {
    let id: String
    let matchType: MatchType
    let sections: [GameRulesSection]
}

extension MatchSetupViewModel.SetupMode {
    var matchType: MatchType {
        switch self {
        case .x01: .x01
        case .cricket: .cricket
        }
    }
}

enum GameRulesCatalog {
    static func guide(for matchType: MatchType) -> GameRulesGuide {
        all.first { $0.matchType == matchType } ?? x01
    }

    static var supportedMatchTypes: [MatchType] {
        all.map(\.matchType)
    }

    private static let all: [GameRulesGuide] = [x01, cricket]

    private static let x01 = GameRulesGuide(
        id: "x01",
        matchType: .x01,
        sections: [
            GameRulesSection(
                id: "overview",
                titleKey: "play.rules.x01.overview.title",
                bodyKey: "play.rules.x01.overview.body"
            ),
            GameRulesSection(
                id: "bust",
                titleKey: "play.rules.x01.bust.title",
                bodyKey: "play.rules.x01.bust.body"
            ),
            GameRulesSection(
                id: "checkIn",
                titleKey: "play.rules.x01.checkIn.title",
                bodyKey: "play.rules.x01.checkIn.body"
            ),
            GameRulesSection(
                id: "checkOut",
                titleKey: "play.rules.x01.checkOut.title",
                bodyKey: "play.rules.x01.checkOut.body"
            ),
            GameRulesSection(
                id: "format",
                titleKey: "play.rules.x01.format.title",
                bodyKey: "play.rules.x01.format.body"
            )
        ]
    )

    private static let cricket = GameRulesGuide(
        id: "cricket",
        matchType: .cricket,
        sections: [
            GameRulesSection(
                id: "basics",
                titleKey: "play.rules.cricket.basics.title",
                bodyKey: "play.rules.cricket.basics.body"
            ),
            GameRulesSection(
                id: "normalScore",
                titleKey: "play.rules.cricket.normalScore.title",
                bodyKey: "play.rules.cricket.normalScore.body"
            ),
            GameRulesSection(
                id: "cutThroatScore",
                titleKey: "play.rules.cricket.cutThroatScore.title",
                bodyKey: "play.rules.cricket.cutThroatScore.body"
            ),
            GameRulesSection(
                id: "noScore",
                titleKey: "play.rules.cricket.noScore.title",
                bodyKey: "play.rules.cricket.noScore.body"
            )
        ]
    )
}
