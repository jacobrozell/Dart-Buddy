import Foundation

enum MatchConfigText {
    static func modeLabel(for type: MatchType) -> String {
        switch type {
        case .x01: L10n.string("play.x01.title")
        case .cricket: L10n.string("play.cricket.title")
        case .baseball: L10n.string("play.baseball.title")
        case .killer: L10n.string("play.killer.title")
        case .shanghai: L10n.string("play.shanghai.title")
        case .americanCricket: L10n.string("play.americanCricket.title")
        case .mickeyMouse: L10n.string("play.mickeyMouse.title")
        case .mulligan: L10n.string("play.mulligan.title")
        case .englishCricket: L10n.string("play.englishCricket.title")
        case .blindKiller: L10n.string("play.blindKiller.title")
        case .knockout: L10n.string("play.knockout.title")
        case .suddenDeath: L10n.string("play.suddenDeath.title")
        case .fiftyOneByFives: L10n.string("play.fiftyOneByFives.title")
        case .golf: L10n.string("play.golf.title")
        case .football: L10n.string("play.football.title")
        case .grandNational: L10n.string("play.grandNational.title")
        case .hareAndHounds: L10n.string("play.hareAndHounds.title")
        case .followTheLeader: L10n.string("play.followTheLeader.title")
        case .loop: L10n.string("play.loop.title")
        case .prisoner: L10n.string("play.prisoner.title")
        case .scam: L10n.string("play.scam.title")
        case .snooker: L10n.string("play.snooker.title")
        case .ticTacToe: L10n.string("play.ticTacToe.title")
        case .aroundTheClock: L10n.string("play.aroundTheClock.title")
        case .aroundTheClock180: L10n.string("play.aroundTheClock180.title")
        case .chaseTheDragon: L10n.string("play.chaseTheDragon.title")
        case .nineLives: L10n.string("play.nineLives.title")
        case .fleet: L10n.string("play.fleet.title")
        case .bobs27: L10n.string("play.bobs27.title")
        case .halveIt: L10n.string("play.halveIt.title")
        }
    }

    static func x01DetailParts(from config: MatchConfigX01) -> [String] {
        var parts = ["\(config.startScore)", config.checkoutMode.displayName]
        if config.checkInMode != .straightIn {
            parts.append(config.checkInMode.displayName)
        }
        let format = config.legFormat.displayName
        if config.setsEnabled {
            let sets = config.setsToWin ?? 1
            parts.append(targetSets(format: format, count: sets))
        }
        parts.append(targetLegs(format: format, count: config.legsToWin))
        return parts
    }

    static func x01CardConfig(from config: MatchConfigX01) -> String {
        L10n.format(
            "history.config.x01Format",
            modeLabel(for: .x01),
            x01DetailParts(from: config).joined(separator: ", ")
        )
    }

    static func x01InlineConfig(from config: MatchConfigX01) -> String {
        x01DetailParts(from: config).joined(separator: ", ")
    }

    static func cricketDetailParts(from config: MatchConfigCricket) -> [String] {
        var parts: [String] = []
        if !config.pointsEnabled {
            parts.append(L10n.string("play.cricket.subtitle.noScore"))
        } else {
            parts.append(config.scoringMode.displayName)
        }
        let format = config.legFormat.displayName
        if config.setsEnabled {
            let sets = config.setsToWin ?? 1
            parts.append(targetSets(format: format, count: sets))
        }
        parts.append(targetLegs(format: format, count: config.legsToWin))
        return parts
    }

    static func cricketMatchSubtitle(from config: MatchConfigCricket) -> String {
        if !config.pointsEnabled {
            return L10n.string("play.cricket.subtitle.noScore")
        }
        switch config.scoringMode {
        case .standard:
            return L10n.string("play.cricket.subtitle.normal")
        case .cutThroat:
            return L10n.string("play.cricket.subtitle.cutThroatLowest")
        }
    }

    static func cricketInlineConfig(from config: MatchConfigCricket) -> String {
        cricketDetailParts(from: config).joined(separator: " · ")
    }

    static func playerName(_ name: String?) -> String {
        name ?? L10n.string("common.playerFallback")
    }

    static func playerName(forIndex index: Int) -> String {
        L10n.format("common.playerNumberFormat", index + 1)
    }

    static func standingAccessibility(name: String, isWinner: Bool, score: Int) -> String {
        let role = isWinner ? L10n.string("history.standing.winnerRole") : ""
        return L10n.format("history.standing.accessibilityFormat", name, role, score)
    }

    private static func targetSets(format: String, count: Int) -> String {
        count == 1
            ? L10n.format("match.config.setSingular", format, count)
            : L10n.format("match.config.setsPlural", format, count)
    }

    private static func targetLegs(format: String, count: Int) -> String {
        count == 1
            ? L10n.format("match.config.legSingular", format, count)
            : L10n.format("match.config.legsPlural", format, count)
    }
}
