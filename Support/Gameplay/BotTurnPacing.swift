import Foundation

/// Delays between bot dart reveals and submit, controlled by Settings feedback toggles.
enum BotTurnPacing {
    static let staggeredDartNanoseconds: UInt64 = 650_000_000
    static let fastDartNanoseconds: UInt64 = 220_000_000
    static let staggeredSubmitNanoseconds: UInt64 = 350_000_000
    static let fastSubmitNanoseconds: UInt64 = 180_000_000

    /// Pause that lets the Cricket closure banner register before returning to the ready state.
    static let cricketClosureTransitionNanoseconds: UInt64 = 550_000_000

    /// Pauses that let per-mode feedback states (banners, announcements) register
    /// before the match returns to the ready state.
    static let shanghaiAchievementTransitionNanoseconds: UInt64 = 800_000_000
    static let baseballPerfectInningTransitionNanoseconds: UInt64 = 800_000_000
    static let baseballStretchGateHintNanoseconds: UInt64 = 600_000_000
    static let killerBecameKillerTransitionNanoseconds: UInt64 = 700_000_000

    static func dartDelayNanoseconds(staggerEnabled: Bool) -> UInt64 {
        resolvedDartDelayNanoseconds(staggerEnabled: staggerEnabled, instantBots: UITestLaunchArguments.instantBotsActive)
    }

    static func submitDelayNanoseconds(staggerEnabled: Bool) -> UInt64 {
        resolvedSubmitDelayNanoseconds(staggerEnabled: staggerEnabled, instantBots: UITestLaunchArguments.instantBotsActive)
    }

    static func cricketClosureDelayNanoseconds() -> UInt64 {
        resolvedCricketClosureTransitionNanoseconds(instantBots: UITestLaunchArguments.instantBotsActive)
    }

    static func resolvedDartDelayNanoseconds(staggerEnabled: Bool, instantBots: Bool) -> UInt64 {
        if instantBots { return 0 }
        return staggerEnabled ? staggeredDartNanoseconds : fastDartNanoseconds
    }

    static func resolvedSubmitDelayNanoseconds(staggerEnabled: Bool, instantBots: Bool) -> UInt64 {
        if instantBots { return 0 }
        return staggerEnabled ? staggeredSubmitNanoseconds : fastSubmitNanoseconds
    }

    static func resolvedCricketClosureTransitionNanoseconds(instantBots: Bool) -> UInt64 {
        instantBots ? 0 : cricketClosureTransitionNanoseconds
    }
}
