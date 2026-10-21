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

    @Test func partyModesArePresetOnly() {
        for matchType in [MatchType.baseball, .shanghai, .killer] {
            let support = BotModePlaySupport.support(for: matchType)
            #expect(support == .presetOnly)
            #expect(support.allowsBots)
            #expect(!support.allowsTrainingAndCustomBots)
        }
    }

    @Test func fullModesAllowTrainingAndCustom() {
        for matchType in [MatchType.x01, .cricket, .golf, .mickeyMouse, .bobs27, .halveIt] {
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

    @Test func presetOnlyRejectsCustomBotsWithModeKey() {
        let killer = BotModePlaySupport.presetOnly.validationErrors(
            matchType: .killer,
            hasBot: true,
            hasTrainingOrCustomBot: true
        )
        #expect(killer == ["setup.validation.killerBotsPresetOnly"])

        let baseball = BotModePlaySupport.presetOnly.validationErrors(
            matchType: .baseball,
            hasBot: true,
            hasTrainingOrCustomBot: true
        )
        #expect(baseball == ["setup.validation.baseballBotsPresetOnly"])

        let shanghai = BotModePlaySupport.presetOnly.validationErrors(
            matchType: .shanghai,
            hasBot: true,
            hasTrainingOrCustomBot: true
        )
        #expect(shanghai == ["setup.validation.shanghaiBotsPresetOnly"])
    }

    @Test func presetOnlyAllowsPresetBots() {
        let errors = BotModePlaySupport.presetOnly.validationErrors(
            matchType: .killer,
            hasBot: true,
            hasTrainingOrCustomBot: false
        )
        #expect(errors.isEmpty)
    }

    @Test func fullSupportAllowsCustomBots() {
        let errors = BotModePlaySupport.full.validationErrors(
            matchType: .golf,
            hasBot: true,
            hasTrainingOrCustomBot: true
        )
        #expect(errors.isEmpty)
    }
}
