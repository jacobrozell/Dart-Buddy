import Testing
@testable import DartsScoreboard

@Test(.tags(.unit, .regression))
func botTurnPacingUsesStaggeredDelaysWhenEnabled() {
    #expect(BotTurnPacing.dartDelayNanoseconds(staggerEnabled: true) == BotTurnPacing.staggeredDartNanoseconds)
    #expect(BotTurnPacing.dartDelayNanoseconds(staggerEnabled: false) == BotTurnPacing.fastDartNanoseconds)
}

@Test(.tags(.unit, .regression))
func botTurnPacingUsesStaggeredSubmitDelayWhenEnabled() {
    #expect(BotTurnPacing.submitDelayNanoseconds(staggerEnabled: true) == BotTurnPacing.staggeredSubmitNanoseconds)
    #expect(BotTurnPacing.submitDelayNanoseconds(staggerEnabled: false) == BotTurnPacing.fastSubmitNanoseconds)
}

@Test(.tags(.unit, .regression))
func botTurnPacingFastPathIsShorterThanStaggeredPath() {
    let fastThreeDarts = BotTurnPacing.fastDartNanoseconds * 3 + BotTurnPacing.fastSubmitNanoseconds
    let staggeredThreeDarts = BotTurnPacing.staggeredDartNanoseconds * 3 + BotTurnPacing.staggeredSubmitNanoseconds
    #expect(fastThreeDarts < staggeredThreeDarts)
}
