import Foundation

struct GameRulesSection: Identifiable, Hashable, Sendable {
    let id: String
    let symbolName: String
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
        _ sections: [(id: String, symbolName: String?, titleKey: String, bodyKey: String)]
    ) -> GameRulesGuide {
        GameRulesGuide(
            id: id,
            matchType: matchType,
            sections: sections.map {
                GameRulesSection(
                    id: $0.id,
                    symbolName: $0.symbolName ?? defaultSymbol(for: $0.id),
                    titleKey: $0.titleKey,
                    bodyKey: $0.bodyKey
                )
            }
        )
    }

    private static func defaultSymbol(for sectionId: String) -> String {
        sectionIcon(for: sectionId)
    }

    private static func sectionIcon(for sectionId: String) -> String {
        switch sectionId {
        case "overview", "basics": "sparkles"
        case "format", "rounds", "innings", "sequence", "course", "laps", "progress", "turns", "perHole", "round": "list.number"
        case "checkOut", "winning", "goals": "trophy.fill"
        case "solo": "person.fill"
        case "multiplayer", "headToHead": "person.2.fill"
        case "reset": "arrow.counterclockwise"
        case "scoring", "marks", "normalScore", "cutThroatScore", "noScore", "examples", "strokes": "sum"
        case "stretch": "figure.stretch"
        case "tieBreakers", "ties": "equal.circle.fill"
        case "pick", "draw", "placement": "hand.point.up.fill"
        case "killerStatus", "enrage": "bolt.fill"
        case "attacks", "hits", "hunt": "burst.fill"
        case "shanghaiBonus", "bonus": "star.fill"
        case "shield": "shield.fill"
        case "expose": "eye.fill"
        case "hearts", "lives": "heart.fill"
        case "bust", "strikes": "xmark.circle.fill"
        case "batting": "figure.cricket"
        case "bowling": "figure.bowling"
        case "highScore": "chart.line.uptrend.xyaxis"
        case "closing": "lock.fill"
        case "shipHealth": "ferry.fill"
        case "sonar": "dot.radiowaves.left.and.right"
        case "expert": "graduationcap.fill"
        case "hare": "hare.fill"
        case "hound": "pawprint.fill"
        case "kickoff": "soccerball"
        default: "doc.text.fill"
        }
    }

    private static let x01 = makeGuide(id: "x01", matchType: .x01, [
        ("overview", "target", "play.rules.x01.overview.title", "play.rules.x01.overview.body"),
        ("bust", "xmark.circle.fill", "play.rules.x01.bust.title", "play.rules.x01.bust.body"),
        ("checkIn", "arrow.right.to.line.compact", "play.rules.x01.checkIn.title", "play.rules.x01.checkIn.body"),
        ("checkOut", "flag.checkered.2.crossed", "play.rules.x01.checkOut.title", "play.rules.x01.checkOut.body"),
        ("format", "trophy.fill", "play.rules.x01.format.title", "play.rules.x01.format.body")
    ])

    private static let cricket = makeGuide(id: "cricket", matchType: .cricket, [
        ("basics", "circle.grid.3x3.fill", "play.rules.cricket.basics.title", "play.rules.cricket.basics.body"),
        ("normalScore", "plus.circle.fill", "play.rules.cricket.normalScore.title", "play.rules.cricket.normalScore.body"),
        ("cutThroatScore", "flame.fill", "play.rules.cricket.cutThroatScore.title", "play.rules.cricket.cutThroatScore.body"),
        ("noScore", "slash.circle", "play.rules.cricket.noScore.title", "play.rules.cricket.noScore.body")
    ])

    private static let americanCricket = makeGuide(id: "americanCricket", matchType: .americanCricket, [
        ("overview", "circle.grid.3x3", "play.rules.americanCricket.overview.title", "play.rules.americanCricket.overview.body"),
        ("marks", nil, "play.rules.americanCricket.marks.title", "play.rules.americanCricket.marks.body"),
        ("scoring", nil, "play.rules.americanCricket.scoring.title", "play.rules.americanCricket.scoring.body"),
        ("winning", nil, "play.rules.americanCricket.winning.title", "play.rules.americanCricket.winning.body")
    ])

    private static let baseball = makeGuide(id: "baseball", matchType: .baseball, [
        ("overview", "baseball.fill", "play.rules.baseball.overview.title", "play.rules.baseball.overview.body"),
        ("innings", nil, "play.rules.baseball.innings.title", "play.rules.baseball.innings.body"),
        ("tieBreakers", nil, "play.rules.baseball.tieBreakers.title", "play.rules.baseball.tieBreakers.body"),
        ("stretch", nil, "play.rules.baseball.stretch.title", "play.rules.baseball.stretch.body")
    ])

    private static let killer = makeGuide(id: "killer", matchType: .killer, [
        ("overview", "bolt.fill", "play.rules.killer.overview.title", "play.rules.killer.overview.body"),
        ("pick", nil, "play.rules.killer.pick.title", "play.rules.killer.pick.body"),
        ("killerStatus", nil, "play.rules.killer.killerStatus.title", "play.rules.killer.killerStatus.body"),
        ("attacks", nil, "play.rules.killer.attacks.title", "play.rules.killer.attacks.body")
    ])

    private static let shanghai = makeGuide(id: "shanghai", matchType: .shanghai, [
        ("overview", "star.fill", "play.rules.shanghai.overview.title", "play.rules.shanghai.overview.body"),
        ("scoring", nil, "play.rules.shanghai.scoring.title", "play.rules.shanghai.scoring.body"),
        ("shanghaiBonus", nil, "play.rules.shanghai.bonus.title", "play.rules.shanghai.bonus.body")
    ])

    private static let mickeyMouse = makeGuide(id: "mickeyMouse", matchType: .mickeyMouse, [
        ("overview", "circle.grid.2x2.fill", "play.rules.mickeyMouse.overview.title", "play.rules.mickeyMouse.overview.body"),
        ("closing", nil, "play.rules.mickeyMouse.closing.title", "play.rules.mickeyMouse.closing.body"),
        ("turns", nil, "play.rules.mickeyMouse.turns.title", "play.rules.mickeyMouse.turns.body"),
        ("winning", nil, "play.rules.mickeyMouse.winning.title", "play.rules.mickeyMouse.winning.body")
    ])

    private static let mulligan = makeGuide(id: "mulligan", matchType: .mulligan, [
        ("overview", "arrow.uturn.backward.circle.fill", "play.rules.mulligan.overview.title", "play.rules.mulligan.overview.body"),
        ("draw", nil, "play.rules.mulligan.draw.title", "play.rules.mulligan.draw.body"),
        ("closing", nil, "play.rules.mulligan.closing.title", "play.rules.mulligan.closing.body"),
        ("winning", nil, "play.rules.mulligan.winning.title", "play.rules.mulligan.winning.body")
    ])

    private static let englishCricket = makeGuide(id: "englishCricket", matchType: .englishCricket, [
        ("overview", "figure.cricket", "play.rules.englishCricket.overview.title", "play.rules.englishCricket.overview.body"),
        ("batting", nil, "play.rules.englishCricket.batting.title", "play.rules.englishCricket.batting.body"),
        ("bowling", nil, "play.rules.englishCricket.bowling.title", "play.rules.englishCricket.bowling.body"),
        ("innings", nil, "play.rules.englishCricket.innings.title", "play.rules.englishCricket.innings.body")
    ])

    private static let knockout = makeGuide(id: "knockout", matchType: .knockout, [
        ("overview", "bolt.horizontal.fill", "play.rules.knockout.overview.title", "play.rules.knockout.overview.body"),
        ("highScore", nil, "play.rules.knockout.highScore.title", "play.rules.knockout.highScore.body"),
        ("strikes", nil, "play.rules.knockout.strikes.title", "play.rules.knockout.strikes.body"),
        ("rounds", nil, "play.rules.knockout.rounds.title", "play.rules.knockout.rounds.body")
    ])

    private static let suddenDeath = makeGuide(id: "suddenDeath", matchType: .suddenDeath, [
        ("overview", "exclamationmark.triangle.fill", "play.rules.suddenDeath.overview.title", "play.rules.suddenDeath.overview.body"),
        ("round", nil, "play.rules.suddenDeath.round.title", "play.rules.suddenDeath.round.body"),
        ("ties", nil, "play.rules.suddenDeath.ties.title", "play.rules.suddenDeath.ties.body"),
        ("winning", nil, "play.rules.suddenDeath.winning.title", "play.rules.suddenDeath.winning.body")
    ])

    private static let fiftyOneByFives = makeGuide(id: "fiftyOneByFives", matchType: .fiftyOneByFives, [
        ("overview", "5.circle.fill", "play.rules.fiftyOneByFives.overview.title", "play.rules.fiftyOneByFives.overview.body"),
        ("scoring", nil, "play.rules.fiftyOneByFives.scoring.title", "play.rules.fiftyOneByFives.scoring.body"),
        ("examples", nil, "play.rules.fiftyOneByFives.examples.title", "play.rules.fiftyOneByFives.examples.body"),
        ("winning", nil, "play.rules.fiftyOneByFives.winning.title", "play.rules.fiftyOneByFives.winning.body")
    ])

    private static let golf = makeGuide(id: "golf", matchType: .golf, [
        ("overview", "figure.golf", "play.rules.golf.overview.title", "play.rules.golf.overview.body"),
        ("perHole", nil, "play.rules.golf.perHole.title", "play.rules.golf.perHole.body"),
        ("strokes", nil, "play.rules.golf.strokes.title", "play.rules.golf.strokes.body"),
        ("winning", nil, "play.rules.golf.winning.title", "play.rules.golf.winning.body")
    ])

    private static let football = makeGuide(id: "football", matchType: .football, [
        ("overview", "soccerball", "play.rules.football.overview.title", "play.rules.football.overview.body"),
        ("kickoff", nil, "play.rules.football.kickoff.title", "play.rules.football.kickoff.body"),
        ("goals", nil, "play.rules.football.goals.title", "play.rules.football.goals.body"),
        ("winning", nil, "play.rules.football.winning.title", "play.rules.football.winning.body")
    ])

    private static let grandNational = makeGuide(id: "grandNational", matchType: .grandNational, [
        ("overview", "flag.checkered", "play.rules.grandNational.overview.title", "play.rules.grandNational.overview.body"),
        ("course", nil, "play.rules.grandNational.course.title", "play.rules.grandNational.course.body"),
        ("laps", nil, "play.rules.grandNational.laps.title", "play.rules.grandNational.laps.body"),
        ("expert", nil, "play.rules.grandNational.expert.title", "play.rules.grandNational.expert.body")
    ])

    private static let hareAndHounds = makeGuide(id: "hareAndHounds", matchType: .hareAndHounds, [
        ("overview", "hare.fill", "play.rules.hareAndHounds.overview.title", "play.rules.hareAndHounds.overview.body"),
        ("hare", nil, "play.rules.hareAndHounds.hare.title", "play.rules.hareAndHounds.hare.body"),
        ("hound", nil, "play.rules.hareAndHounds.hound.title", "play.rules.hareAndHounds.hound.body"),
        ("winning", nil, "play.rules.hareAndHounds.winning.title", "play.rules.hareAndHounds.winning.body")
    ])

    private static let aroundTheClock = makeGuide(id: "aroundTheClock", matchType: .aroundTheClock, [
        ("overview", "clock.fill", "play.rules.aroundTheClock.overview.title", "play.rules.aroundTheClock.overview.body"),
        ("solo", nil, "play.rules.aroundTheClock.solo.title", "play.rules.aroundTheClock.solo.body"),
        ("multiplayer", nil, "play.rules.aroundTheClock.multiplayer.title", "play.rules.aroundTheClock.multiplayer.body"),
        ("reset", nil, "play.rules.aroundTheClock.reset.title", "play.rules.aroundTheClock.reset.body")
    ])

    private static let aroundTheClock180 = makeGuide(id: "aroundTheClock180", matchType: .aroundTheClock180, [
        ("overview", "clock.badge.fill", "play.rules.aroundTheClock180.overview.title", "play.rules.aroundTheClock180.overview.body"),
        ("scoring", nil, "play.rules.aroundTheClock180.scoring.title", "play.rules.aroundTheClock180.scoring.body"),
        ("solo", nil, "play.rules.aroundTheClock180.solo.title", "play.rules.aroundTheClock180.solo.body"),
        ("headToHead", nil, "play.rules.aroundTheClock180.headToHead.title", "play.rules.aroundTheClock180.headToHead.body")
    ])

    private static let chaseTheDragon = makeGuide(id: "chaseTheDragon", matchType: .chaseTheDragon, [
        ("overview", "flame.fill", "play.rules.chaseTheDragon.overview.title", "play.rules.chaseTheDragon.overview.body"),
        ("sequence", nil, "play.rules.chaseTheDragon.sequence.title", "play.rules.chaseTheDragon.sequence.body"),
        ("turns", nil, "play.rules.chaseTheDragon.turns.title", "play.rules.chaseTheDragon.turns.body"),
        ("laps", nil, "play.rules.chaseTheDragon.laps.title", "play.rules.chaseTheDragon.laps.body")
    ])

    private static let nineLives = makeGuide(id: "nineLives", matchType: .nineLives, [
        ("overview", "heart.fill", "play.rules.nineLives.overview.title", "play.rules.nineLives.overview.body"),
        ("progress", nil, "play.rules.nineLives.progress.title", "play.rules.nineLives.progress.body"),
        ("lives", nil, "play.rules.nineLives.lives.title", "play.rules.nineLives.lives.body"),
        ("winning", nil, "play.rules.nineLives.winning.title", "play.rules.nineLives.winning.body")
    ])

    private static let fleet = makeGuide(id: "fleet", matchType: .fleet, [
        ("overview", "ferry.fill", "play.rules.fleet.overview.title", "play.rules.fleet.overview.body"),
        ("placement", nil, "play.rules.fleet.placement.title", "play.rules.fleet.placement.body"),
        ("shipHealth", nil, "play.rules.fleet.shipHealth.title", "play.rules.fleet.shipHealth.body"),
        ("hunt", nil, "play.rules.fleet.hunt.title", "play.rules.fleet.hunt.body"),
        ("hits", nil, "play.rules.fleet.hits.title", "play.rules.fleet.hits.body"),
        ("sonar", nil, "play.rules.fleet.sonar.title", "play.rules.fleet.sonar.body"),
        ("winning", nil, "play.rules.fleet.winning.title", "play.rules.fleet.winning.body")
    ])

    private static let raid = makeGuide(id: "raid", matchType: .raid, [
        ("overview", "shield.lefthalf.filled", "play.rules.raid.overview.title", "play.rules.raid.overview.body"),
        ("shield", nil, "play.rules.raid.shield.title", "play.rules.raid.shield.body"),
        ("expose", nil, "play.rules.raid.expose.title", "play.rules.raid.expose.body"),
        ("enrage", nil, "play.rules.raid.enrage.title", "play.rules.raid.enrage.body"),
        ("hearts", nil, "play.rules.raid.hearts.title", "play.rules.raid.hearts.body"),
        ("winning", nil, "play.rules.raid.winning.title", "play.rules.raid.winning.body")
    ])

    private static let bobs27 = makeGuide(id: "bobs27", matchType: .bobs27, [
        ("overview", nil, "play.rules.bobs27.overview.title", "play.rules.bobs27.overview.body"),
        ("hit", nil, "play.rules.bobs27.hit.title", "play.rules.bobs27.hit.body"),
        ("miss", nil, "play.rules.bobs27.miss.title", "play.rules.bobs27.miss.body"),
        ("gameOver", nil, "play.rules.bobs27.gameOver.title", "play.rules.bobs27.gameOver.body")
    ])

    private static let halveIt = makeGuide(id: "halveIt", matchType: .halveIt, [
        ("overview", nil, "play.rules.halveIt.overview.title", "play.rules.halveIt.overview.body"),
        ("start", nil, "play.rules.halveIt.start.title", "play.rules.halveIt.start.body"),
        ("round", nil, "play.rules.halveIt.round.title", "play.rules.halveIt.round.body"),
        ("winning", nil, "play.rules.halveIt.winning.title", "play.rules.halveIt.winning.body")
    ])

    private static let scam = makeGuide(id: "scam", matchType: .scam, [
        ("overview", nil, "play.rules.scam.overview.title", "play.rules.scam.overview.body"),
        ("stopper", nil, "play.rules.scam.stopper.title", "play.rules.scam.stopper.body"),
        ("scorer", nil, "play.rules.scam.scorer.title", "play.rules.scam.scorer.body"),
        ("halves", nil, "play.rules.scam.halves.title", "play.rules.scam.halves.body")
    ])

    private static let snooker = makeGuide(id: "snooker", matchType: .snooker, [
        ("overview", nil, "play.rules.snooker.overview.title", "play.rules.snooker.overview.body"),
        ("reds", nil, "play.rules.snooker.reds.title", "play.rules.snooker.reds.body"),
        ("colours", nil, "play.rules.snooker.colours.title", "play.rules.snooker.colours.body"),
        ("breaks", nil, "play.rules.snooker.breaks.title", "play.rules.snooker.breaks.body")
    ])

    private static let ticTacToe = makeGuide(id: "ticTacToe", matchType: .ticTacToe, [
        ("overview", nil, "play.rules.ticTacToe.overview.title", "play.rules.ticTacToe.overview.body"),
        ("grid", nil, "play.rules.ticTacToe.grid.title", "play.rules.ticTacToe.grid.body"),
        ("turns", nil, "play.rules.ticTacToe.turns.title", "play.rules.ticTacToe.turns.body"),
        ("winning", nil, "play.rules.ticTacToe.winning.title", "play.rules.ticTacToe.winning.body")
    ])

    private static let blindKiller = makeGuide(id: "blindKiller", matchType: .blindKiller, [
        ("overview", nil, "play.rules.blindKiller.overview.title", "play.rules.blindKiller.overview.body"),
        ("secret", nil, "play.rules.blindKiller.secret.title", "play.rules.blindKiller.secret.body"),
        ("throwing", nil, "play.rules.blindKiller.throwing.title", "play.rules.blindKiller.throwing.body"),
        ("elimination", nil, "play.rules.blindKiller.elimination.title", "play.rules.blindKiller.elimination.body")
    ])

    private static let followTheLeader = makeGuide(id: "followTheLeader", matchType: .followTheLeader, [
        ("overview", nil, "play.rules.followTheLeader.overview.title", "play.rules.followTheLeader.overview.body"),
        ("target", nil, "play.rules.followTheLeader.target.title", "play.rules.followTheLeader.target.body"),
        ("match", nil, "play.rules.followTheLeader.match.title", "play.rules.followTheLeader.match.body"),
        ("pass", nil, "play.rules.followTheLeader.pass.title", "play.rules.followTheLeader.pass.body")
    ])

    private static let loop = makeGuide(id: "loop", matchType: .loop, [
        ("overview", nil, "play.rules.loop.overview.title", "play.rules.loop.overview.body"),
        ("targets", nil, "play.rules.loop.targets.title", "play.rules.loop.targets.body"),
        ("play", nil, "play.rules.loop.play.title", "play.rules.loop.play.body"),
        ("wires", nil, "play.rules.loop.wires.title", "play.rules.loop.wires.body")
    ])

    private static let prisoner = makeGuide(id: "prisoner", matchType: .prisoner, [
        ("overview", nil, "play.rules.prisoner.overview.title", "play.rules.prisoner.overview.body"),
        ("progress", nil, "play.rules.prisoner.progress.title", "play.rules.prisoner.progress.body"),
        ("lost", nil, "play.rules.prisoner.lost.title", "play.rules.prisoner.lost.body"),
        ("capture", nil, "play.rules.prisoner.capture.title", "play.rules.prisoner.capture.body")
    ])

    private static let previewAll: [GameRulesPreviewGuide] = [
        raidPreview
    ]

    private static func makePreviewGuide(
        id: String,
        _ sections: [(id: String, symbolName: String?, titleKey: String, bodyKey: String)]
    ) -> GameRulesPreviewGuide {
        GameRulesPreviewGuide(
            id: id,
            sections: sections.map {
                GameRulesSection(
                    id: $0.id,
                    symbolName: $0.symbolName ?? defaultSymbol(for: $0.id),
                    titleKey: $0.titleKey,
                    bodyKey: $0.bodyKey
                )
            }
        )
    }

    private static let raidPreview = makePreviewGuide(id: "coop.raid", [
        ("overview", "shield.lefthalf.filled", "play.rules.raid.overview.title", "play.rules.raid.overview.body"),
        ("shield", nil, "play.rules.raid.shield.title", "play.rules.raid.shield.body"),
        ("expose", nil, "play.rules.raid.expose.title", "play.rules.raid.expose.body"),
        ("enrage", nil, "play.rules.raid.enrage.title", "play.rules.raid.enrage.body"),
        ("hearts", nil, "play.rules.raid.hearts.title", "play.rules.raid.hearts.body"),
        ("winning", nil, "play.rules.raid.winning.title", "play.rules.raid.winning.body")
    ])
}
