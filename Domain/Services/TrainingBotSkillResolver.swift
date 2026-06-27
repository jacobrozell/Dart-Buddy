import Foundation

public enum TrainingBotSkillTuning {
    public static let x01AvgMultiplier = 1.04
    public static let x01AvgOffset = 2.0
    public static let x01MinBump = 1.5
    public static let x01MaxAverage = 92.0

    public static let cricketMPRMultiplier = 1.05
    public static let cricketMPROffset = 0.10
    public static let cricketMinBump = 0.08
    public static let cricketMaxMPR = 3.8
}

public enum TrainingBotSkillResolver {
    public static func resolve(breakdown: PlayerStatBreakdown, mode: MatchType) -> BotSkillProfile {
        switch mode {
        case .x01:
            let playerAvg = breakdown.average3Dart
            if playerAvg > 0 {
                let target = min(
                    max(playerAvg * TrainingBotSkillTuning.x01AvgMultiplier + TrainingBotSkillTuning.x01AvgOffset, playerAvg + TrainingBotSkillTuning.x01MinBump),
                    TrainingBotSkillTuning.x01MaxAverage
                )
                return BotSkillProfileInterpolator.profile(forX01Average: target)
            }
            return bumpedEasyProfile(for: .x01)
        case .cricket:
            let playerMPR = breakdown.marksPerRound
            if playerMPR > 0 {
                let target = min(
                    max(
                        playerMPR * TrainingBotSkillTuning.cricketMPRMultiplier + TrainingBotSkillTuning.cricketMPROffset,
                        playerMPR + TrainingBotSkillTuning.cricketMinBump
                    ),
                    TrainingBotSkillTuning.cricketMaxMPR
                )
                return BotSkillProfileInterpolator.profile(forCricketMPR: target)
            }
            return bumpedEasyProfile(for: .cricket)
        case .baseball, .killer, .shanghai, .americanCricket, .mickeyMouse, .mulligan, .englishCricket,
             .knockout, .suddenDeath, .fiftyOneByFives, .golf, .football, .grandNational, .hareAndHounds,
             .aroundTheClock, .aroundTheClock180, .chaseTheDragon, .nineLives, .halveIt, .scam, .snooker, .ticTacToe, .blindKiller, .followTheLeader, .loop, .prisoner, .fleet, .raid:
            let playerAvg = breakdown.average3Dart
            if playerAvg > 0 {
                let target = min(
                    max(playerAvg * TrainingBotSkillTuning.x01AvgMultiplier + TrainingBotSkillTuning.x01AvgOffset, playerAvg + TrainingBotSkillTuning.x01MinBump),
                    TrainingBotSkillTuning.x01MaxAverage
                )
                return BotSkillProfileInterpolator.profile(forX01Average: target)
            }
            return bumpedEasyProfile(for: mode)
        case .bobs27:
            return bumpedEasyProfile(for: mode)
        }
    }

    private static func bumpedEasyProfile(for mode: MatchType) -> BotSkillProfile {
        switch mode {
        case .x01:
            return BotSkillProfileInterpolator.profile(forX01Average: 24)
        case .cricket:
            return BotSkillProfileInterpolator.profile(forCricketMPR: 1.35)
        case .baseball, .killer, .shanghai, .americanCricket, .mickeyMouse, .mulligan, .englishCricket,
             .knockout, .suddenDeath, .fiftyOneByFives, .golf, .football, .grandNational, .hareAndHounds,
             .aroundTheClock, .aroundTheClock180, .chaseTheDragon, .nineLives, .halveIt, .scam, .snooker, .blindKiller, .followTheLeader, .loop, .fleet, .raid,
             .prisoner, .ticTacToe, .bobs27:
            return BotSkillProfileInterpolator.profile(forX01Average: 24)
        }
    }
}
