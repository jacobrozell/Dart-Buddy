import Testing
@testable import DartBuddy

@Test(.tags(.unit, .regression))
func botPlaybackPolicyCombinesInstantSettingReduceMotionAndUITest() {
    #expect(
        BotPlaybackPolicy.instantBotTurnsActive(
            instantBotTurnsEnabled: false,
            reduceMotion: false,
            uiTestInstantBots: false
        ) == false
    )
    #expect(
        BotPlaybackPolicy.instantBotTurnsActive(
            instantBotTurnsEnabled: true,
            reduceMotion: false,
            uiTestInstantBots: false
        ) == true
    )
    #expect(
        BotPlaybackPolicy.instantBotTurnsActive(
            instantBotTurnsEnabled: false,
            reduceMotion: true,
            uiTestInstantBots: false
        ) == true
    )
    #expect(
        BotPlaybackPolicy.instantBotTurnsActive(
            instantBotTurnsEnabled: false,
            reduceMotion: false,
            uiTestInstantBots: true
        ) == true
    )
}

@Test(.tags(.unit, .regression))
func botTurnPacingModeTransitionsResolveToZeroWhenInstant() {
    let prefs = FeedbackPreferences()
    prefs.instantBotTurnsEnabled = true

    #expect(BotTurnPacing.shanghaiAchievementDelayNanoseconds(feedbackPreferences: prefs) == 0)
    #expect(BotTurnPacing.golfHoleCompleteDelayNanoseconds(feedbackPreferences: prefs) == 0)
    #expect(BotTurnPacing.killerBecameKillerDelayNanoseconds(feedbackPreferences: prefs) == 0)
    #expect(BotTurnPacing.briefModeFeedbackDelayNanoseconds(feedbackPreferences: prefs) == 0)
    #expect(BotTurnPacing.baseballPerfectInningDelayNanoseconds(feedbackPreferences: prefs) == 0)
}
