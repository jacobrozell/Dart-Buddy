import Foundation

enum MatchConfigDefaults {
    static func config(for matchType: MatchType) -> MatchConfigPayload {
        switch matchType {
        case .x01:
            return .x01(
                MatchConfigX01(
                    startScore: 501,
                    legsToWin: 1,
                    setsEnabled: false,
                    setsToWin: nil,
                    checkoutMode: .doubleOut
                )
            )
        case .cricket:
            return .cricket(MatchConfigCricket())
        case .baseball:
            return .baseball(MatchConfigBaseball())
        case .killer:
            return .killer(MatchConfigKiller())
        case .shanghai:
            return .shanghai(MatchConfigShanghai())
        case .americanCricket:
            return .americanCricket(MatchConfigAmericanCricket())
        case .mickeyMouse:
            return .mickeyMouse(MatchConfigMickeyMouse())
        case .mulligan:
            return .mulligan(makeMulliganConfig())
        case .englishCricket:
            return .englishCricket(MatchConfigEnglishCricket())
        case .knockout:
            return .knockout(MatchConfigKnockout())
        case .suddenDeath:
            return .suddenDeath(MatchConfigSuddenDeath())
        case .fiftyOneByFives:
            return .fiftyOneByFives(MatchConfigFiftyOneByFives())
        case .golf:
            return .golf(MatchConfigGolf())
        case .football:
            return .football(MatchConfigFootball())
        case .grandNational:
            return .grandNational(MatchConfigGrandNational())
        case .hareAndHounds:
            return .hareAndHounds(MatchConfigHareAndHounds())
        case .aroundTheClock:
            return .aroundTheClock(MatchConfigAroundTheClock())
        case .aroundTheClock180:
            return .aroundTheClock180(MatchConfigAroundTheClock180())
        case .chaseTheDragon:
            return .chaseTheDragon(MatchConfigChaseTheDragon())
        case .nineLives:
            return .nineLives(MatchConfigNineLives())
        case .fleet:
            return .fleet(MatchConfigFleet())
        case .raid:
            return .raid(MatchConfigRaid())
        case .bobs27:
            return .bobs27(MatchConfigBobs27())
        case .halveIt:
            return .halveIt(MatchConfigHalveIt())
        case .scam:
            return .scam(MatchConfigScam())
        case .snooker:
            return .snooker(MatchConfigSnooker())
        case .ticTacToe:
            return .ticTacToe(MatchConfigTicTacToe())
        case .blindKiller:
            return .blindKiller(
                MatchConfigBlindKiller(assignmentSeed: UInt64.random(in: UInt64.min ... UInt64.max))
            )
        case .followTheLeader:
            return .followTheLeader(MatchConfigFollowTheLeader())
        case .loop:
            return .loop(MatchConfigLoop())
        case .prisoner:
            return .prisoner(MatchConfigPrisoner())
        }
    }

    private static func makeMulliganConfig() -> MatchConfigMulligan {
        let seed = UInt64.random(in: UInt64.min ... UInt64.max)
        var rng = SeededRandomNumberGenerator(seed: seed)
        let sequence = MulliganEngine.generateSequence(count: 6, rng: &rng)
        return MatchConfigMulligan(targetCount: 6, rngSeed: seed, targetSequence: sequence)
    }
}
