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
        all.map(\.matchType).filter(isSupportedInCurrentProductSurface)
    }

    private static func isSupportedInCurrentProductSurface(_ matchType: MatchType) -> Bool {
        switch matchType {
        case .x01, .cricket:
            true
        case .baseball, .killer, .shanghai:
            ProductSurface.showsPartyModes
        }
    }

    private static let all: [GameRulesGuide] = [x01, cricket, baseball, killer, shanghai]

    private static let shanghai = GameRulesGuide(
        id: "shanghai",
        matchType: .shanghai,
        sections: [
            GameRulesSection(
                id: "overview",
                titleKey: "play.rules.shanghai.overview.title",
                bodyKey: "play.rules.shanghai.overview.body"
            ),
            GameRulesSection(
                id: "scoring",
                titleKey: "play.rules.shanghai.scoring.title",
                bodyKey: "play.rules.shanghai.scoring.body"
            ),
            GameRulesSection(
                id: "shanghaiBonus",
                titleKey: "play.rules.shanghai.bonus.title",
                bodyKey: "play.rules.shanghai.bonus.body"
            )
        ]
    )

    private static let killer = GameRulesGuide(
        id: "killer",
        matchType: .killer,
        sections: [
            GameRulesSection(
                id: "overview",
                titleKey: "play.rules.killer.overview.title",
                bodyKey: "play.rules.killer.overview.body"
            ),
            GameRulesSection(
                id: "pick",
                titleKey: "play.rules.killer.pick.title",
                bodyKey: "play.rules.killer.pick.body"
            ),
            GameRulesSection(
                id: "killerStatus",
                titleKey: "play.rules.killer.killerStatus.title",
                bodyKey: "play.rules.killer.killerStatus.body"
            ),
            GameRulesSection(
                id: "attacks",
                titleKey: "play.rules.killer.attacks.title",
                bodyKey: "play.rules.killer.attacks.body"
            )
        ]
    )

    private static let baseball = GameRulesGuide(
        id: "baseball",
        matchType: .baseball,
        sections: [
            GameRulesSection(
                id: "overview",
                titleKey: "play.rules.baseball.overview.title",
                bodyKey: "play.rules.baseball.overview.body"
            ),
            GameRulesSection(
                id: "innings",
                titleKey: "play.rules.baseball.innings.title",
                bodyKey: "play.rules.baseball.innings.body"
            ),
            GameRulesSection(
                id: "tieBreakers",
                titleKey: "play.rules.baseball.tieBreakers.title",
                bodyKey: "play.rules.baseball.tieBreakers.body"
            ),
            GameRulesSection(
                id: "stretch",
                titleKey: "play.rules.baseball.stretch.title",
                bodyKey: "play.rules.baseball.stretch.body"
            )
        ]
    )

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
