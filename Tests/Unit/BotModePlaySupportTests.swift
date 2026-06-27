import Testing
@testable import DartBuddy

@Suite("Bot mode play support", .tags(.unit, .setupFlow, .regression))
struct BotModePlaySupportTests {
    @Test func raidDisallowsBots() {
        let support = BotModePlaySupport.support(for: .raid)
        #expect(support == .none)
        #expect(!support.allowsBots)
        #expect(!support.allowsTrainingAndCustomBots)
    }

    @Test func shippedModesAllowFullBots() {
        for matchType in [
            MatchType.baseball, .shanghai, .killer, .mickeyMouse, .prisoner,
            .x01, .cricket, .golf
        ] {
            let support = BotModePlaySupport.support(for: matchType)
            #expect(support == .full)
            #expect(support.allowsBots)
            #expect(support.allowsTrainingAndCustomBots)
        }
    }

    @Test func raidValidationUsesCoopHumansOnlyKey() {
        let errors = BotModePlaySupport.none.validationErrors(
            matchType: .raid,
            hasBot: true,
            hasTrainingOrCustomBot: false
        )
        #expect(errors == ["setup.validation.coopHumansOnly"])
    }

    @Test func fullSupportAllowsCustomBots() {
        let errors = BotModePlaySupport.full.validationErrors(
            matchType: .killer,
            hasBot: true,
            hasTrainingOrCustomBot: true
        )
        #expect(errors.isEmpty)
    }
}
