import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Effective instant-bot policy — see `specs/InstantBotTurnsSpec.md` §5.
enum BotPlaybackPolicy {
    static func instantBotTurnsActive(
        instantBotTurnsEnabled: Bool,
        reduceMotion: Bool? = nil,
        uiTestInstantBots: Bool = UITestLaunchArguments.instantBotsActive
    ) -> Bool {
        let reduceMotionEnabled = reduceMotion ?? systemReduceMotionEnabled
        return instantBotTurnsEnabled || reduceMotionEnabled || uiTestInstantBots
    }

    private static var systemReduceMotionEnabled: Bool {
        #if canImport(UIKit)
        UIAccessibility.isReduceMotionEnabled
        #else
        false
        #endif
    }
}

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
    static let golfHoleCompleteTransitionNanoseconds: UInt64 = 600_000_000
    static let mickeyMouseTargetAdvancedTransitionNanoseconds: UInt64 = 600_000_000
    static let killerBecameKillerTransitionNanoseconds: UInt64 = 700_000_000
    static let briefModeFeedbackTransitionNanoseconds: UInt64 = 400_000_000

    static func instantBotsActive(_ feedbackPreferences: FeedbackPreferences) -> Bool {
        BotPlaybackPolicy.instantBotTurnsActive(
            instantBotTurnsEnabled: feedbackPreferences.instantBotTurnsEnabled
        )
    }

    static func dartDelayNanoseconds(feedbackPreferences: FeedbackPreferences) -> UInt64 {
        resolvedDartDelayNanoseconds(
            staggerEnabled: feedbackPreferences.botStaggerEnabled,
            instantBots: instantBotsActive(feedbackPreferences)
        )
    }

    static func submitDelayNanoseconds(feedbackPreferences: FeedbackPreferences) -> UInt64 {
        resolvedSubmitDelayNanoseconds(
            staggerEnabled: feedbackPreferences.botStaggerEnabled,
            instantBots: instantBotsActive(feedbackPreferences)
        )
    }

    static func cricketClosureDelayNanoseconds(feedbackPreferences: FeedbackPreferences) -> UInt64 {
        resolvedCricketClosureTransitionNanoseconds(instantBots: instantBotsActive(feedbackPreferences))
    }

    static func shanghaiAchievementDelayNanoseconds(feedbackPreferences: FeedbackPreferences) -> UInt64 {
        resolvedTransitionNanoseconds(
            base: shanghaiAchievementTransitionNanoseconds,
            instantBots: instantBotsActive(feedbackPreferences)
        )
    }

    static func baseballPerfectInningDelayNanoseconds(feedbackPreferences: FeedbackPreferences) -> UInt64 {
        resolvedTransitionNanoseconds(
            base: baseballPerfectInningTransitionNanoseconds,
            instantBots: instantBotsActive(feedbackPreferences)
        )
    }

    static func baseballStretchGateHintDelayNanoseconds(feedbackPreferences: FeedbackPreferences) -> UInt64 {
        resolvedTransitionNanoseconds(
            base: baseballStretchGateHintNanoseconds,
            instantBots: instantBotsActive(feedbackPreferences)
        )
    }

    static func golfHoleCompleteDelayNanoseconds(feedbackPreferences: FeedbackPreferences) -> UInt64 {
        resolvedTransitionNanoseconds(
            base: golfHoleCompleteTransitionNanoseconds,
            instantBots: instantBotsActive(feedbackPreferences)
        )
    }

    static func mickeyMouseTargetAdvancedDelayNanoseconds(feedbackPreferences: FeedbackPreferences) -> UInt64 {
        resolvedTransitionNanoseconds(
            base: mickeyMouseTargetAdvancedTransitionNanoseconds,
            instantBots: instantBotsActive(feedbackPreferences)
        )
    }

    static func killerBecameKillerDelayNanoseconds(feedbackPreferences: FeedbackPreferences) -> UInt64 {
        resolvedTransitionNanoseconds(
            base: killerBecameKillerTransitionNanoseconds,
            instantBots: instantBotsActive(feedbackPreferences)
        )
    }

    static func briefModeFeedbackDelayNanoseconds(feedbackPreferences: FeedbackPreferences) -> UInt64 {
        resolvedTransitionNanoseconds(
            base: briefModeFeedbackTransitionNanoseconds,
            instantBots: instantBotsActive(feedbackPreferences)
        )
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

    static func resolvedTransitionNanoseconds(base: UInt64, instantBots: Bool) -> UInt64 {
        instantBots ? 0 : base
    }
}
