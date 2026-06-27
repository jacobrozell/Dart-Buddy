import Foundation

/// Product-health telemetry for match rule variants chosen at start.
enum MatchConfigAnalytics {
    static func metadata(for config: MatchConfigPayload) -> [String: String] {
        switch config {
        case let .x01(cfg):
            return [
                "configStartScore": String(cfg.startScore),
                "configCheckoutMode": cfg.checkoutMode.rawValue,
                "configCheckInMode": cfg.checkInMode.rawValue,
                "configLegFormat": cfg.legFormat.rawValue,
                "configSetsEnabled": bool(cfg.setsEnabled)
            ]
        case let .cricket(cfg):
            return [
                "configPointsEnabled": bool(cfg.pointsEnabled),
                "configScoringMode": cfg.scoringMode.rawValue,
                "configLegFormat": cfg.legFormat.rawValue,
                "configSetsEnabled": bool(cfg.setsEnabled)
            ]
        case let .baseball(cfg):
            return [
                "configInningCount": String(cfg.inningCount),
                "configTieBreaker": cfg.tieBreaker.rawValue,
                "configSeventhInningStretch": bool(cfg.seventhInningStretch)
            ]
        case let .killer(cfg):
            return ["configStartingLives": String(cfg.startingLives)]
        case let .shanghai(cfg):
            return [
                "configRoundCount": String(cfg.roundCount),
                "configBonusRule": cfg.bonusRule.rawValue
            ]
        case let .americanCricket(cfg):
            return ["configPointsEnabled": bool(cfg.pointsEnabled)]
        case let .englishCricket(cfg):
            return [
                "configWicketsPerInnings": String(cfg.wicketsPerInnings),
                "configEndWhenTargetPassed": bool(cfg.endWhenTargetPassed)
            ]
        case let .knockout(cfg):
            return ["configStrikesToEliminate": String(cfg.strikesToEliminate)]
        case let .suddenDeath(cfg):
            return [
                "configVisitsPerRound": String(cfg.visitsPerRound),
                "configEliminationRule": cfg.eliminationRule.rawValue
            ]
        case let .fiftyOneByFives(cfg):
            return [
                "configTargetPoints": String(cfg.targetPoints),
                "configMustFinishExact": bool(cfg.mustFinishExact)
            ]
        case let .golf(cfg):
            return ["configCourseLength": String(cfg.courseLength.rawValue)]
        case let .football(cfg):
            return [
                "configGoalsToWin": String(cfg.goalsToWin),
                "configKickoffMode": cfg.kickoffMode.rawValue
            ]
        case let .grandNational(cfg):
            return [
                "configRuleset": cfg.ruleset.rawValue,
                "configLaps": String(cfg.laps)
            ]
        case let .hareAndHounds(cfg):
            return ["configHoundStart": cfg.houndStart.rawValue]
        case let .aroundTheClock(cfg):
            return [
                "configIncludeBullFinish": bool(cfg.includeBullFinish),
                "configResetPolicy": cfg.resetPolicy.rawValue
            ]
        case let .aroundTheClock180(cfg):
            if let parScore = cfg.parScore {
                return [
                    "configParScoreEnabled": "true",
                    "configParScore": String(parScore)
                ]
            }
            return ["configParScoreEnabled": "false"]
        case let .chaseTheDragon(cfg):
            return ["configLaps": String(cfg.laps.rawValue)]
        case let .nineLives(cfg):
            return ["configStartingLives": cfg.startingLives.rawValue]
        case let .fleet(cfg):
            return [
                "configShipCount": String(cfg.shipCount.rawValue),
                "configSonarEnabled": bool(cfg.sonarEnabled),
                "configHandoffEachTurn": bool(cfg.handoffEachTurn)
            ]
        case let .raid(cfg):
            return [
                "configBossTier": cfg.bossTier.rawValue,
                "configHeroHearts": String(cfg.heroHearts),
                "configEnrageEnabled": bool(cfg.enrageEnabled)
            ]
        case let .bobs27(cfg):
            return [
                "configBullSubtract": String(cfg.bullSubtract),
                "configGameOverAtZero": bool(cfg.gameOverAtZero)
            ]
        case let .halveIt(cfg):
            return [
                "configStartingScore": String(cfg.startingScore),
                "configTargetSequence": cfg.sequenceRaw
            ]
        case .scam:
            return [:]
        case .snooker:
            return [:]
        case let .ticTacToe(cfg):
            return ["configHandicapPreset": cfg.presetRaw]
        case let .blindKiller(cfg):
            return ["configHitsToEliminate": String(cfg.hitsToEliminate)]
        case let .followTheLeader(cfg):
            return ["configStartingLives": String(cfg.startingLives)]
        case let .loop(cfg):
            return ["configStartingLives": String(cfg.startingLives)]
        case .prisoner:
            return [:]
        case .mickeyMouse, .mulligan:
            return [:]
        }
    }

    private static func bool(_ value: Bool) -> String {
        value ? "true" : "false"
    }
}
