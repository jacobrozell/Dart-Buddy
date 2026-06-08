import Testing
@testable import DartBuddy

@Test(.tags(.unit, .regression))
func botTurnPacingUsesStaggeredDelaysWhenEnabled() {
    #expect(BotTurnPacing.resolvedDartDelayNanoseconds(staggerEnabled: true, instantBots: false) == BotTurnPacing.staggeredDartNanoseconds)
    #expect(BotTurnPacing.resolvedDartDelayNanoseconds(staggerEnabled: false, instantBots: false) == BotTurnPacing.fastDartNanoseconds)
}

@Test(.tags(.unit, .regression))
func botTurnPacingUsesStaggeredSubmitDelayWhenEnabled() {
    #expect(BotTurnPacing.resolvedSubmitDelayNanoseconds(staggerEnabled: true, instantBots: false) == BotTurnPacing.staggeredSubmitNanoseconds)
    #expect(BotTurnPacing.resolvedSubmitDelayNanoseconds(staggerEnabled: false, instantBots: false) == BotTurnPacing.fastSubmitNanoseconds)
}

@Test(.tags(.unit, .regression))
func botTurnPacingInstantBotsUsesZeroDelay() {
    #expect(BotTurnPacing.resolvedDartDelayNanoseconds(staggerEnabled: true, instantBots: true) == 0)
    #expect(BotTurnPacing.resolvedSubmitDelayNanoseconds(staggerEnabled: true, instantBots: true) == 0)
    #expect(BotTurnPacing.resolvedCricketClosureTransitionNanoseconds(instantBots: true) == 0)
    #expect(
        BotTurnPacing.resolvedCricketClosureTransitionNanoseconds(instantBots: false)
            == BotTurnPacing.cricketClosureTransitionNanoseconds
    )
}

@Test(.tags(.unit, .regression))
func botTurnPacingFastPathIsShorterThanStaggeredPath() {
    let fastThreeDarts = BotTurnPacing.fastDartNanoseconds * 3 + BotTurnPacing.fastSubmitNanoseconds
    let staggeredThreeDarts = BotTurnPacing.staggeredDartNanoseconds * 3 + BotTurnPacing.staggeredSubmitNanoseconds
    #expect(fastThreeDarts < staggeredThreeDarts)
}
