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

/// Rules guide for planned catalog entries that do not yet have a `MatchType`.
struct GameRulesPreviewGuide: Identifiable, Hashable, Sendable {
    /// Catalog id, e.g. `coop.raid`.
    let id: String
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
    static func hasGuide(for matchType: MatchType) -> Bool {
        all.contains { $0.matchType == matchType }
    }

    static func hasPreviewGuide(for catalogId: String) -> Bool {
        previewAll.contains { $0.id == catalogId }
    }

    static func guide(for matchType: MatchType) -> GameRulesGuide {
        guard let guide = all.first(where: { $0.matchType == matchType }) else {
            assertionFailure("No rules guide for \(matchType)")
            return x01
        }
        return guide
    }

    static func previewGuide(for catalogId: String) -> GameRulesPreviewGuide {
        guard let guide = previewAll.first(where: { $0.id == catalogId }) else {
            assertionFailure("No preview rules guide for \(catalogId)")
            return raidPreview
        }
        return guide
    }

    /// Modes shown in the onboarding rules picker (beginner path covers core modes only).
    static var supportedMatchTypes: [MatchType] {
        [.x01, .cricket]
    }

    private static let all: [GameRulesGuide] = [
        x01, cricket, americanCricket,
        baseball, killer, shanghai, mickeyMouse, mulligan, englishCricket,
        knockout, suddenDeath, fiftyOneByFives, golf, football, grandNational, hareAndHounds,
        aroundTheClock, aroundTheClock180, chaseTheDragon, nineLives, bobs27, halveIt, scam, snooker, ticTacToe, blindKiller, followTheLeader, loop, prisoner, fleet, raid
    ]

    private static func makeGuide(
        id: String,
        matchType: MatchType,
        _ sections: [(id: String, titleKey: String, bodyKey: String)]
    ) -> GameRulesGuide {
        GameRulesGuide(
            id: id,
            matchType: matchType,
            sections: sections.map { GameRulesSection(id: $0.id, titleKey: $0.titleKey, bodyKey: $0.bodyKey) }
        )
    }

    private static let x01 = makeGuide(id: "x01", matchType: .x01, [
        ("overview", "play.rules.x01.overview.title", "play.rules.x01.overview.body"),
        ("bust", "play.rules.x01.bust.title", "play.rules.x01.bust.body"),
        ("checkIn", "play.rules.x01.checkIn.title", "play.rules.x01.checkIn.body"),
        ("checkOut", "play.rules.x01.checkOut.title", "play.rules.x01.checkOut.body"),
        ("format", "play.rules.x01.format.title", "play.rules.x01.format.body")
    ])

    private static let cricket = makeGuide(id: "cricket", matchType: .cricket, [
        ("basics", "play.rules.cricket.basics.title", "play.rules.cricket.basics.body"),
        ("normalScore", "play.rules.cricket.normalScore.title", "play.rules.cricket.normalScore.body"),
        ("cutThroatScore", "play.rules.cricket.cutThroatScore.title", "play.rules.cricket.cutThroatScore.body"),
        ("noScore", "play.rules.cricket.noScore.title", "play.rules.cricket.noScore.body")
    ])

    private static let americanCricket = makeGuide(id: "americanCricket", matchType: .americanCricket, [
        ("overview", "play.rules.americanCricket.overview.title", "play.rules.americanCricket.overview.body"),
        ("marks", "play.rules.americanCricket.marks.title", "play.rules.americanCricket.marks.body"),
        ("scoring", "play.rules.americanCricket.scoring.title", "play.rules.americanCricket.scoring.body"),
        ("winning", "play.rules.americanCricket.winning.title", "play.rules.americanCricket.winning.body")
    ])

    private static let baseball = makeGuide(id: "baseball", matchType: .baseball, [
        ("overview", "play.rules.baseball.overview.title", "play.rules.baseball.overview.body"),
        ("innings", "play.rules.baseball.innings.title", "play.rules.baseball.innings.body"),
        ("tieBreakers", "play.rules.baseball.tieBreakers.title", "play.rules.baseball.tieBreakers.body"),
        ("stretch", "play.rules.baseball.stretch.title", "play.rules.baseball.stretch.body")
    ])

    private static let killer = makeGuide(id: "killer", matchType: .killer, [
        ("overview", "play.rules.killer.overview.title", "play.rules.killer.overview.body"),
        ("pick", "play.rules.killer.pick.title", "play.rules.killer.pick.body"),
        ("killerStatus", "play.rules.killer.killerStatus.title", "play.rules.killer.killerStatus.body"),
        ("attacks", "play.rules.killer.attacks.title", "play.rules.killer.attacks.body")
    ])

    private static let shanghai = makeGuide(id: "shanghai", matchType: .shanghai, [
        ("overview", "play.rules.shanghai.overview.title", "play.rules.shanghai.overview.body"),
        ("scoring", "play.rules.shanghai.scoring.title", "play.rules.shanghai.scoring.body"),
        ("shanghaiBonus", "play.rules.shanghai.bonus.title", "play.rules.shanghai.bonus.body")
    ])

    private static let mickeyMouse = makeGuide(id: "mickeyMouse", matchType: .mickeyMouse, [
        ("overview", "play.rules.mickeyMouse.overview.title", "play.rules.mickeyMouse.overview.body"),
        ("closing", "play.rules.mickeyMouse.closing.title", "play.rules.mickeyMouse.closing.body"),
        ("turns", "play.rules.mickeyMouse.turns.title", "play.rules.mickeyMouse.turns.body"),
        ("winning", "play.rules.mickeyMouse.winning.title", "play.rules.mickeyMouse.winning.body")
    ])

    private static let mulligan = makeGuide(id: "mulligan", matchType: .mulligan, [
        ("overview", "play.rules.mulligan.overview.title", "play.rules.mulligan.overview.body"),
        ("draw", "play.rules.mulligan.draw.title", "play.rules.mulligan.draw.body"),
        ("closing", "play.rules.mulligan.closing.title", "play.rules.mulligan.closing.body"),
        ("winning", "play.rules.mulligan.winning.title", "play.rules.mulligan.winning.body")
    ])

    private static let englishCricket = makeGuide(id: "englishCricket", matchType: .englishCricket, [
        ("overview", "play.rules.englishCricket.overview.title", "play.rules.englishCricket.overview.body"),
        ("batting", "play.rules.englishCricket.batting.title", "play.rules.englishCricket.batting.body"),
        ("bowling", "play.rules.englishCricket.bowling.title", "play.rules.englishCricket.bowling.body"),
        ("innings", "play.rules.englishCricket.innings.title", "play.rules.englishCricket.innings.body")
    ])

    private static let knockout = makeGuide(id: "knockout", matchType: .knockout, [
        ("overview", "play.rules.knockout.overview.title", "play.rules.knockout.overview.body"),
        ("highScore", "play.rules.knockout.highScore.title", "play.rules.knockout.highScore.body"),
        ("strikes", "play.rules.knockout.strikes.title", "play.rules.knockout.strikes.body"),
        ("rounds", "play.rules.knockout.rounds.title", "play.rules.knockout.rounds.body")
    ])

    private static let suddenDeath = makeGuide(id: "suddenDeath", matchType: .suddenDeath, [
        ("overview", "play.rules.suddenDeath.overview.title", "play.rules.suddenDeath.overview.body"),
        ("round", "play.rules.suddenDeath.round.title", "play.rules.suddenDeath.round.body"),
        ("ties", "play.rules.suddenDeath.ties.title", "play.rules.suddenDeath.ties.body"),
        ("winning", "play.rules.suddenDeath.winning.title", "play.rules.suddenDeath.winning.body")
    ])

    private static let fiftyOneByFives = makeGuide(id: "fiftyOneByFives", matchType: .fiftyOneByFives, [
        ("overview", "play.rules.fiftyOneByFives.overview.title", "play.rules.fiftyOneByFives.overview.body"),
        ("scoring", "play.rules.fiftyOneByFives.scoring.title", "play.rules.fiftyOneByFives.scoring.body"),
        ("examples", "play.rules.fiftyOneByFives.examples.title", "play.rules.fiftyOneByFives.examples.body"),
        ("winning", "play.rules.fiftyOneByFives.winning.title", "play.rules.fiftyOneByFives.winning.body")
    ])

    private static let golf = makeGuide(id: "golf", matchType: .golf, [
        ("overview", "play.rules.golf.overview.title", "play.rules.golf.overview.body"),
        ("perHole", "play.rules.golf.perHole.title", "play.rules.golf.perHole.body"),
        ("strokes", "play.rules.golf.strokes.title", "play.rules.golf.strokes.body"),
        ("winning", "play.rules.golf.winning.title", "play.rules.golf.winning.body")
    ])

    private static let football = makeGuide(id: "football", matchType: .football, [
        ("overview", "play.rules.football.overview.title", "play.rules.football.overview.body"),
        ("kickoff", "play.rules.football.kickoff.title", "play.rules.football.kickoff.body"),
        ("goals", "play.rules.football.goals.title", "play.rules.football.goals.body"),
        ("winning", "play.rules.football.winning.title", "play.rules.football.winning.body")
    ])

    private static let grandNational = makeGuide(id: "grandNational", matchType: .grandNational, [
        ("overview", "play.rules.grandNational.overview.title", "play.rules.grandNational.overview.body"),
        ("course", "play.rules.grandNational.course.title", "play.rules.grandNational.course.body"),
        ("laps", "play.rules.grandNational.laps.title", "play.rules.grandNational.laps.body"),
        ("expert", "play.rules.grandNational.expert.title", "play.rules.grandNational.expert.body")
    ])

    private static let hareAndHounds = makeGuide(id: "hareAndHounds", matchType: .hareAndHounds, [
        ("overview", "play.rules.hareAndHounds.overview.title", "play.rules.hareAndHounds.overview.body"),
        ("hare", "play.rules.hareAndHounds.hare.title", "play.rules.hareAndHounds.hare.body"),
        ("hound", "play.rules.hareAndHounds.hound.title", "play.rules.hareAndHounds.hound.body"),
        ("winning", "play.rules.hareAndHounds.winning.title", "play.rules.hareAndHounds.winning.body")
    ])

    private static let aroundTheClock = makeGuide(id: "aroundTheClock", matchType: .aroundTheClock, [
        ("overview", "play.rules.aroundTheClock.overview.title", "play.rules.aroundTheClock.overview.body"),
        ("solo", "play.rules.aroundTheClock.solo.title", "play.rules.aroundTheClock.solo.body"),
        ("multiplayer", "play.rules.aroundTheClock.multiplayer.title", "play.rules.aroundTheClock.multiplayer.body"),
        ("reset", "play.rules.aroundTheClock.reset.title", "play.rules.aroundTheClock.reset.body")
    ])

    private static let aroundTheClock180 = makeGuide(id: "aroundTheClock180", matchType: .aroundTheClock180, [
        ("overview", "play.rules.aroundTheClock180.overview.title", "play.rules.aroundTheClock180.overview.body"),
        ("scoring", "play.rules.aroundTheClock180.scoring.title", "play.rules.aroundTheClock180.scoring.body"),
        ("solo", "play.rules.aroundTheClock180.solo.title", "play.rules.aroundTheClock180.solo.body"),
        ("headToHead", "play.rules.aroundTheClock180.headToHead.title", "play.rules.aroundTheClock180.headToHead.body")
    ])

    private static let chaseTheDragon = makeGuide(id: "chaseTheDragon", matchType: .chaseTheDragon, [
        ("overview", "play.rules.chaseTheDragon.overview.title", "play.rules.chaseTheDragon.overview.body"),
        ("sequence", "play.rules.chaseTheDragon.sequence.title", "play.rules.chaseTheDragon.sequence.body"),
        ("turns", "play.rules.chaseTheDragon.turns.title", "play.rules.chaseTheDragon.turns.body"),
        ("laps", "play.rules.chaseTheDragon.laps.title", "play.rules.chaseTheDragon.laps.body")
    ])

    private static let nineLives = makeGuide(id: "nineLives", matchType: .nineLives, [
        ("overview", "play.rules.nineLives.overview.title", "play.rules.nineLives.overview.body"),
        ("progress", "play.rules.nineLives.progress.title", "play.rules.nineLives.progress.body"),
        ("lives", "play.rules.nineLives.lives.title", "play.rules.nineLives.lives.body"),
        ("winning", "play.rules.nineLives.winning.title", "play.rules.nineLives.winning.body")
    ])

    private static let fleet = makeGuide(id: "fleet", matchType: .fleet, [
        ("overview", "play.rules.fleet.overview.title", "play.rules.fleet.overview.body"),
        ("placement", "play.rules.fleet.placement.title", "play.rules.fleet.placement.body"),
        ("shipHealth", "play.rules.fleet.shipHealth.title", "play.rules.fleet.shipHealth.body"),
        ("hunt", "play.rules.fleet.hunt.title", "play.rules.fleet.hunt.body"),
        ("hits", "play.rules.fleet.hits.title", "play.rules.fleet.hits.body"),
        ("sonar", "play.rules.fleet.sonar.title", "play.rules.fleet.sonar.body"),
        ("winning", "play.rules.fleet.winning.title", "play.rules.fleet.winning.body")
    ])

    private static let raid = makeGuide(id: "raid", matchType: .raid, [
        ("overview", "play.rules.raid.overview.title", "play.rules.raid.overview.body"),
        ("shield", "play.rules.raid.shield.title", "play.rules.raid.shield.body"),
        ("expose", "play.rules.raid.expose.title", "play.rules.raid.expose.body"),
        ("enrage", "play.rules.raid.enrage.title", "play.rules.raid.enrage.body"),
        ("hearts", "play.rules.raid.hearts.title", "play.rules.raid.hearts.body"),
        ("winning", "play.rules.raid.winning.title", "play.rules.raid.winning.body")
    ])

    private static let bobs27 = makeGuide(id: "bobs27", matchType: .bobs27, [
        ("overview", "play.rules.bobs27.overview.title", "play.rules.bobs27.overview.body"),
        ("hit", "play.rules.bobs27.hit.title", "play.rules.bobs27.hit.body"),
        ("miss", "play.rules.bobs27.miss.title", "play.rules.bobs27.miss.body"),
        ("gameOver", "play.rules.bobs27.gameOver.title", "play.rules.bobs27.gameOver.body")
    ])

    private static let halveIt = makeGuide(id: "halveIt", matchType: .halveIt, [
        ("overview", "play.rules.halveIt.overview.title", "play.rules.halveIt.overview.body"),
        ("start", "play.rules.halveIt.start.title", "play.rules.halveIt.start.body"),
        ("round", "play.rules.halveIt.round.title", "play.rules.halveIt.round.body"),
        ("winning", "play.rules.halveIt.winning.title", "play.rules.halveIt.winning.body")
    ])

    private static let scam = makeGuide(id: "scam", matchType: .scam, [
        ("overview", "play.rules.scam.overview.title", "play.rules.scam.overview.body"),
        ("stopper", "play.rules.scam.stopper.title", "play.rules.scam.stopper.body"),
        ("scorer", "play.rules.scam.scorer.title", "play.rules.scam.scorer.body"),
        ("halves", "play.rules.scam.halves.title", "play.rules.scam.halves.body")
    ])

    private static let snooker = makeGuide(id: "snooker", matchType: .snooker, [
        ("overview", "play.rules.snooker.overview.title", "play.rules.snooker.overview.body"),
        ("reds", "play.rules.snooker.reds.title", "play.rules.snooker.reds.body"),
        ("colours", "play.rules.snooker.colours.title", "play.rules.snooker.colours.body"),
        ("breaks", "play.rules.snooker.breaks.title", "play.rules.snooker.breaks.body")
    ])

    private static let ticTacToe = makeGuide(id: "ticTacToe", matchType: .ticTacToe, [
        ("overview", "play.rules.ticTacToe.overview.title", "play.rules.ticTacToe.overview.body"),
        ("grid", "play.rules.ticTacToe.grid.title", "play.rules.ticTacToe.grid.body"),
        ("turns", "play.rules.ticTacToe.turns.title", "play.rules.ticTacToe.turns.body"),
        ("winning", "play.rules.ticTacToe.winning.title", "play.rules.ticTacToe.winning.body")
    ])

    private static let blindKiller = makeGuide(id: "blindKiller", matchType: .blindKiller, [
        ("overview", "play.rules.blindKiller.overview.title", "play.rules.blindKiller.overview.body"),
        ("secret", "play.rules.blindKiller.secret.title", "play.rules.blindKiller.secret.body"),
        ("throwing", "play.rules.blindKiller.throwing.title", "play.rules.blindKiller.throwing.body"),
        ("elimination", "play.rules.blindKiller.elimination.title", "play.rules.blindKiller.elimination.body")
    ])

    private static let followTheLeader = makeGuide(id: "followTheLeader", matchType: .followTheLeader, [
        ("overview", "play.rules.followTheLeader.overview.title", "play.rules.followTheLeader.overview.body"),
        ("target", "play.rules.followTheLeader.target.title", "play.rules.followTheLeader.target.body"),
        ("match", "play.rules.followTheLeader.match.title", "play.rules.followTheLeader.match.body"),
        ("pass", "play.rules.followTheLeader.pass.title", "play.rules.followTheLeader.pass.body")
    ])

    private static let loop = makeGuide(id: "loop", matchType: .loop, [
        ("overview", "play.rules.loop.overview.title", "play.rules.loop.overview.body"),
        ("targets", "play.rules.loop.targets.title", "play.rules.loop.targets.body"),
        ("play", "play.rules.loop.play.title", "play.rules.loop.play.body"),
        ("wires", "play.rules.loop.wires.title", "play.rules.loop.wires.body")
    ])

    private static let prisoner = makeGuide(id: "prisoner", matchType: .prisoner, [
        ("overview", "play.rules.prisoner.overview.title", "play.rules.prisoner.overview.body"),
        ("progress", "play.rules.prisoner.progress.title", "play.rules.prisoner.progress.body"),
        ("lost", "play.rules.prisoner.lost.title", "play.rules.prisoner.lost.body"),
        ("capture", "play.rules.prisoner.capture.title", "play.rules.prisoner.capture.body")
    ])

    private static let previewAll: [GameRulesPreviewGuide] = [
        raidPreview
    ]

    private static func makePreviewGuide(
        id: String,
        _ sections: [(id: String, titleKey: String, bodyKey: String)]
    ) -> GameRulesPreviewGuide {
        GameRulesPreviewGuide(
            id: id,
            sections: sections.map { GameRulesSection(id: $0.id, titleKey: $0.titleKey, bodyKey: $0.bodyKey) }
        )
    }

    private static let raidPreview = makePreviewGuide(id: "coop.raid", [
        ("overview", "play.rules.raid.overview.title", "play.rules.raid.overview.body"),
        ("shield", "play.rules.raid.shield.title", "play.rules.raid.shield.body"),
        ("expose", "play.rules.raid.expose.title", "play.rules.raid.expose.body"),
        ("enrage", "play.rules.raid.enrage.title", "play.rules.raid.enrage.body"),
        ("hearts", "play.rules.raid.hearts.title", "play.rules.raid.hearts.body"),
        ("winning", "play.rules.raid.winning.title", "play.rules.raid.winning.body")
    ])
}
